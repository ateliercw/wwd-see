//
//  SyncManager.swift
//  WWDCTools
//
//  Created by Michael Skiba on 06/06/2025.
//

import Foundation
import GRDB
import SwiftData
import Combine
import IssueReporting

@ModelActor
public actor SyncManager {
    private var database: DatabaseWriter!
    private var task: Task<Void, Never>?
    private var cancellable: AnyDatabaseCancellable?
    private var localState = Set<VideoViewedRecord>()
    private var remoteState = [WatchedState]()
    private var localStateLoaded: Bool = false
    private var remoteStateLoaded: Bool = false

    public init(database: DatabaseWriter, modelContainer: ModelContainer) {
        self.init(modelContainer: modelContainer)
        Task {
            await setup(database: database)
        }
    }

    public func setup(database: DatabaseWriter) {
        self.database = database
    }

    public func start() async {
        observeContext()
        do {
            try fetchRemoteState()
            try fetchInitialLocalState()
        } catch {
            debugPrint(error)
        }

        let observation = ValueObservation.tracking(VideoViewedRecord.fetchAll)
        Task {
            let cancellable = await observation.start(in: database, scheduling: .mainActor) { error in
                debugPrint(error)
            } onChange: { records in
                Task {
                    await self.updateLocalRecords(records)
                }
            }
            self.cancellable = cancellable
            self.updateCancellable(cancellable)
        }
    }

    deinit {
        task?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}

private extension SyncManager {
    func observeContext() {
        NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: modelContext,
            queue: nil
        ) { [weak self] _ in
            Task {
                try await self?.fetchRemoteState()
            }
        }
    }

    func fetchRemoteState() throws {
        updateRemoteRecords(try modelContext.fetch(FetchDescriptor<WatchedState>()))
    }

    func fetchInitialLocalState() throws {
        updateLocalRecords(try database.read(VideoViewedRecord.fetchAll))
    }

    func updateCancellable(_ cancellable: AnyDatabaseCancellable) {
        self.cancellable = cancellable
    }

    func updateRemoteRecords(_ records: [WatchedState]) {
        remoteStateLoaded = true
        remoteState = records
        processUpdate()
    }

    func updateLocalRecords(_ records: [VideoViewedRecord]) {
        localStateLoaded = true
        let recordSet = Set(records)
        if recordSet != localState {
            localState = recordSet
            processUpdate()
        }
    }
    func processUpdate() {
        guard remoteStateLoaded, localStateLoaded else { return }
        var changes = [ChangeType]()
        for local in localState {
            let remote = remoteState.first { $0.videoUrl == local.videoUrl }
            changes.append(contentsOf: reconcile(local: local, remote: remote))
        }
        for remote in remoteState where !localState.contains(where: { $0.videoUrl == remote.videoUrl }) {
            changes.append(contentsOf: reconcile(local: nil, remote: remote))
        }
        let localChanges = changes.compactMap(\.local)
        debugPrint("__ \(localChanges.count) local changes after reconciling")
        if !localChanges.isEmpty {
            do {
                try database.write { db in
                    for localChange in localChanges {
                        try localChange.save(db)
                    }
                }
            } catch {
                reportIssue(error)
            }
        }

        let remoteChanges = changes.compactMap(\.remote)
        debugPrint("__ \(remoteChanges.count) remote changes after reconciling")
        if !remoteChanges.isEmpty {
            for remoteChange in remoteChanges {
                modelContext.insert(remoteChange)
            }
            do {
                try modelContext.save()
            } catch {
                reportIssue(error)
            }
        }
    }

    enum ChangeType {
        case local(VideoViewedRecord)
        case remote(WatchedState)

        var local: VideoViewedRecord? {
            guard case .local(let local) = self else { return nil}
            return local
        }

        var remote: WatchedState? {
            guard case .remote(let remote) = self else { return nil }
            return remote
        }
    }

    func compareWatched(
        local: inout VideoViewedRecord,
        remote: WatchedState,
        hasRemoteChange: inout Bool,
        hasLocalChange: inout Bool
    ) {
        switch (local.watchedUpdated, remote.watchedUpdated) {
        case let (localDate?, remoteDate?):
            if localDate == remoteDate {
                break
            } else if localDate > remoteDate {
                hasRemoteChange = true
                remote.watchedDate = local.watchedDate
                remote.watchedUpdated = local.watchedUpdated
            } else {
                hasLocalChange = true
                local.watchedDate = remote.watchedDate
                local.watchedUpdated = remote.watchedUpdated
            }
        case (.none, .some):
            hasLocalChange = true
            local.watchedDate = remote.watchedDate
            local.watchedUpdated = remote.watchedUpdated
        case (.some, .none):
            hasRemoteChange = true
            remote.watchedDate = local.watchedDate
            remote.watchedUpdated = local.watchedUpdated
        case (.none, .none):
            break
        }
    }

    func compareIgnored(
        local: inout VideoViewedRecord,
        remote: WatchedState,
        hasRemoteChange: inout Bool,
        hasLocalChange: inout Bool
    ) {
        switch (local.ignoredUpdated, remote.ignoredUpdated) {
        case let (localDate?, remoteDate?):
            if localDate == remoteDate {
                break
            } else if localDate > remoteDate {
                hasRemoteChange = true
                remote.ignored = local.ignored
                remote.ignoredUpdated = local.ignoredUpdated
            } else {
                hasLocalChange = true
                local.ignored = remote.ignored
                local.ignoredUpdated = remote.ignoredUpdated
            }
        case (.none, .some):
            hasLocalChange = true
            local.ignored = remote.ignored
            local.ignoredUpdated = remote.ignoredUpdated
        case (.some, .none):
            hasRemoteChange = true
            remote.ignored = local.ignored
            remote.ignoredUpdated = local.ignoredUpdated
        case (.none, .none):
            break
        }
    }

    func reconcile(local: VideoViewedRecord?, remote: WatchedState?) -> [ChangeType] {
        guard var local else {
            if let local = remote.flatMap(VideoViewedRecord.init) {
                return [.local(local)]
            } else {
                return []
            }
        }
        guard let remote else {
            return [.remote(.init(local: local))]
        }
        var hasLocalChange = false
        var hasRemoteChange = false
        compareWatched(
            local: &local,
            remote: remote,
            hasRemoteChange: &hasRemoteChange,
            hasLocalChange: &hasLocalChange
        )
        compareIgnored(
            local: &local,
            remote: remote,
            hasRemoteChange: &hasRemoteChange,
            hasLocalChange: &hasLocalChange
        )
        return [
            (hasLocalChange ? .local(local) : nil),
            (hasRemoteChange ? .remote(remote) : nil)
        ].compactMap { $0 }
    }
}

private extension WatchedState {
    convenience init(local: VideoViewedRecord) {
        self.init(
            videoUrl: local.videoUrl,
            ignored: local.ignored,
            ignoredUpdated: local.ignoredUpdated,
            watchedDate: local.watchedDate,
            watchedUpdated: local.watchedUpdated
        )
    }
}

private extension VideoViewedRecord {
    init?(remote: WatchedState) {
        guard let url = remote.videoUrl else { return nil }
        self = .init(
            videoUrl: url,
            ignored: remote.ignored,
            ignoredUpdated: remote.ignoredUpdated,
            watchedDate: remote.watchedDate,
            watchedUpdated: remote.watchedUpdated
        )
    }
}
