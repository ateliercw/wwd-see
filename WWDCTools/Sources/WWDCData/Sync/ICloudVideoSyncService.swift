//
//  VideoSyncService.swift
//  WWDCTools
//
//  Created by Michael Skiba on 09/04/2025.
//

import Foundation
import CloudKit
import SharingGRDB
import IssueReporting

public extension DependencyValues {
    var videoSyncService: VideoSyncService {
        get { self[VideoSyncServiceKey.self] }
        set { self[VideoSyncServiceKey.self] = newValue }
    }
}

private enum VideoSyncServiceKey: DependencyKey {
    static let liveValue: any VideoSyncService = DefaultVideoSyncService()
    static let testValue: any VideoSyncService = DefaultVideoSyncService()
    static let previewValue: any VideoSyncService = DefaultVideoSyncService()
}

public protocol VideoSyncService: Sendable {
    func update(info: VideoViewedRecord) async throws
}

public actor DefaultVideoSyncService: VideoSyncService {
    public func update(info: VideoViewedRecord) async throws {
    }
}

public actor ICloudVideoSyncService: VideoSyncService {
    private static var syncURL: URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sync")
    }
    @Shared(.fileStorage(syncURL)) private var syncSerialization: CKSyncEngine.State.Serialization?
    @Dependency(\.defaultDatabase) private var database
    @ObservationIgnored
    @SharedReader(.fetch(VideoInfo())) var info

    static let container: CKContainer = CKContainer(identifier: CloudKitConfig.containerIdentifier)

    var syncEngine: CKSyncEngine {
        if internalSyncEngine == nil {
            initializeSyncEngine()
        }
        return internalSyncEngine!
    }
    var internalSyncEngine: CKSyncEngine?

    public init() {
        Task {
            await initializeSyncEngine()
        }
    }

    private func initializeSyncEngine() {
        var configuration = CKSyncEngine.Configuration(
            database: Self.container.privateCloudDatabase,
            stateSerialization: syncSerialization,
            delegate: self
        )
        configuration.automaticallySync = true
        let syncEngine = CKSyncEngine(configuration)
        internalSyncEngine = syncEngine
    }
}

extension ICloudVideoSyncService: CKSyncEngineDelegate {
    public func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {

        case let .stateUpdate(event):
            $syncSerialization.withLock { syncSerialization in
                syncSerialization = event.stateSerialization
            }
        case let .accountChange(event):
            handleAccountChange(event)
        case let .fetchedDatabaseChanges(event):
            handleFetchedDatabaseChanges(event)
        case let .fetchedRecordZoneChanges(event):
            handleFetchedRecordZoneChanges(event)
        case .sentDatabaseChanges:
            debugPrint("Attempted to send database changes, this is ignored")
        case let .sentRecordZoneChanges(event):
            handleSentRecordZoneChanges(event)
        case .willFetchChanges, .willFetchRecordZoneChanges, .didFetchRecordZoneChanges,
                .didFetchChanges, .willSendChanges, .didSendChanges:
            // We don't do anything here in the sample app, but these events
            // might be helpful if you need to do any setup/cleanup when sync
            // starts/ends.
            break
        @unknown default:
            reportIssue("Received unknown event: \(event)")
        }
    }

    public func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {

        let scope = context.options.scope
        let changes = syncEngine.state.pendingRecordZoneChanges.filter(scope.contains)
        let info = info

        let batch = await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: changes) { recordID in
            if let event = info[recordID: recordID] {
                return event.record
            } else {
                syncEngine.state.remove(pendingRecordZoneChanges: [ .saveRecord(recordID) ])
                return nil
            }
        }
        return batch
    }

    func handleAccountChange(_ event: CKSyncEngine.Event.AccountChange) {
        let shouldDeleteLocalData: Bool
        let shouldReUploadLocalData: Bool

        switch event.changeType {

        case .signIn:
            shouldDeleteLocalData = false
            shouldReUploadLocalData = true

        case .switchAccounts:
            shouldDeleteLocalData = true
            shouldReUploadLocalData = false

        case .signOut:
            shouldDeleteLocalData = true
            shouldReUploadLocalData = false

        @unknown default:
            reportIssue("Unknown account change type: \(event)")
            shouldDeleteLocalData = false
            shouldReUploadLocalData = false
        }

        if shouldDeleteLocalData {
            do {
                _ = try database.write { db in
                    try VideoViewedRecord.deleteAll(db)
                }
            } catch {
                reportIssue(error)
            }
        }

        if shouldReUploadLocalData {
            let recordZoneChanges = info.map(\.cloudKitID).map(CKSyncEngine.PendingRecordZoneChange.saveRecord)
            syncEngine.state.add(pendingDatabaseChanges: [
                .saveZone(CKRecordZone(zoneName: VideoViewedRecord.zoneName))
            ])
            syncEngine.state.add(pendingRecordZoneChanges: recordZoneChanges)
        }
    }

    func handleFetchedDatabaseChanges(_ event: CKSyncEngine.Event.FetchedDatabaseChanges) {
        // If a zone was deleted, we should delete everything for that zone locally.
        for deletion in event.deletions {
            switch deletion.zoneID.zoneName {
            case VideoViewedRecord.zoneName:
                do {
                    _ = try database.write { db in
                        try VideoViewedRecord.deleteAll(db)
                    }
                } catch {
                    reportIssue(error)
                }
            default:
                reportIssue("Received deletion for unknown zone: \(deletion.zoneID)")
            }
        }
    }

    func handleFetchedRecordZoneChanges(_ event: CKSyncEngine.Event.FetchedRecordZoneChanges) {
        let updated = event.modifications.compactMap { modification in
            // The sync engine fetched a record, and we want to merge it into our local persistence.
            // If we already have this object locally, let's merge the data from the server.
            // Otherwise, let's create a new local object.
            let record = modification.record

            do {
                if var existing = info[recordID: record.recordID] {
                    existing.merge(with: record)
                    return existing
                } else {
                    return try VideoViewedRecord(record: record)
                }
            } catch {
                reportIssue(error)
                return nil
            }
        }

        let deleted = event.deletions.compactMap { deletion in

            // A record was deleted on the server, so let's remove it from our local persistence.
            return info[recordID: deletion.recordID]
        }

        if !updated.isEmpty || !deleted.isEmpty {
            do {
                try database.write { db in
                    for updated in updated {
                        try updated.save(db)
                    }
                    for toDelete in deleted {
                        try toDelete.delete(db)
                    }
                }
            } catch {
                reportIssue(error)
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func handleSentRecordZoneChanges(_ event: CKSyncEngine.Event.SentRecordZoneChanges) {

            // If we failed to save a record, we might want to retry depending on the error code.
            var newPendingRecordZoneChanges = [CKSyncEngine.PendingRecordZoneChange]()
            var newPendingDatabaseChanges = [CKSyncEngine.PendingDatabaseChange]()

            // Update the last known server record for each of the saved records.
            var saved = event.savedRecords.compactMap {  savedRecord in
                if var existing = info[recordID: savedRecord.recordID] {
                    existing.merge(with: savedRecord)
                    return existing
                } else {
                    do {
                        return try VideoViewedRecord(record: savedRecord)
                    } catch {
                        reportIssue(error)
                        return nil
                    }
                }
            }

            // Handle any failed record saves.
            for failedRecordSave in event.failedRecordSaves {
                let failedRecord = failedRecordSave.record

                switch failedRecordSave.error.code {

                case .serverRecordChanged:
                    // Let's merge the record from the server into our own local copy.
                    // The `mergeFromServerRecord` function takes care of the conflict resolution.
                    guard let serverRecord = failedRecordSave.error.serverRecord else {
                        reportIssue("No server record for conflict \(failedRecordSave.error)")
                        continue
                    }
                    guard var item = info[recordID: failedRecord.recordID] else {
                        reportIssue("No local object for conflict \(failedRecordSave.error)")
                        continue
                    }
                    item.merge(with: serverRecord)
                    saved.append(item)
                    newPendingRecordZoneChanges.append(.saveRecord(failedRecord.recordID))

                case .zoneNotFound:
                    // Looks like we tried to save a record in a zone that doesn't exist.
                    // Let's save that zone and retry saving the record.
                    // Also clear the last known server record if we have one, it's no longer valid.
                    let zone = CKRecordZone(zoneID: failedRecord.recordID.zoneID)
                    newPendingDatabaseChanges.append(.saveZone(zone))
                    newPendingRecordZoneChanges.append(.saveRecord(failedRecord.recordID))

                case .unknownItem:
                    // We tried to save a record with a locally-cached server
                    // record, but that record no longer exists on the server.
                    // This might mean that another device deleted the record, but
                    // we still have the data for that record locally.
                    // We have the choice of either deleting the local data or re-uploading the local data.
                    // For this sample app, let's re-upload the local data.
                    newPendingRecordZoneChanges.append(.saveRecord(failedRecord.recordID))

                case .networkFailure, .networkUnavailable, .zoneBusy,
                        .serviceUnavailable, .notAuthenticated, .operationCancelled:
                    // There are several errors that the sync engine will
                    // automatically retry, let's just log and move on.
                    reportIssue("Retryable error saving \(failedRecord.recordID): \(failedRecordSave.error)")

                default:
                    // We got an error, but we don't know what it is or how to
                    // handle it. If you have any sort of telemetry system, you
                    // should consider tracking this scenario so you can understand
                    // which errors you see in the wild.
                    reportIssue("Unknown error saving record \(failedRecord.recordID): \(failedRecordSave.error)")
                }
            }

            syncEngine.state.add(pendingDatabaseChanges: newPendingDatabaseChanges)
            syncEngine.state.add(pendingRecordZoneChanges: newPendingRecordZoneChanges)

        do {
            try database.write { db in
                for item in saved {
                    try item.save(db)
                }
            }
        } catch {
            reportIssue(error)
        }
    }

    public func update(info: VideoViewedRecord) async throws {
        do {
            try await database.write { db in
                try info.save(db)
            }
//            try await _ = syncEngine.database.modifyRecords(saving: [info.record], deleting: [])
            syncEngine.state.add(pendingRecordZoneChanges: [.saveRecord(info.cloudKitID)])
            print("trying to save")
        } catch {
            reportIssue(error)
        }
    }
}

private struct VideoInfo: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [VideoViewedRecord] {
        try VideoViewedRecord
            .fetchAll(db)
    }
}

private extension RandomAccessCollection where Element == VideoViewedRecord {
    subscript(recordID recordID: CKRecord.ID) -> Element? {
        first(where: { $0.cloudKitID == recordID })
    }
}
