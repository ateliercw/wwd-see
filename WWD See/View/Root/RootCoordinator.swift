//
//  RootCoordinator.swift
//  WWD See
//
//  Created by Michael Skiba on 26/03/2025.
//

import Foundation
import SharingGRDB
import IssueReporting
import WWDCData

@Observable
@MainActor
class RootCoordinator {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    @ObservationIgnored
    @SharedReader(.fetch(Events())) var events
    private var needsLoading = true

    private var underlyingEventSelection: EventRecord?
    var selectedEvent: EventRecord? {
        get {
            underlyingEventSelection ?? events.first
        }
        set {
            underlyingEventSelection = newValue ?? events.first
        }
    }

    var selectedTopic = TopicSelection.defaultValue
}

private struct Events: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [EventRecord] {
        try EventRecord.all()
            .order(Column("name").desc)
            .fetchAll(db)
    }
}

private struct EventTopics: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [TopicRecord] {
        try TopicRecord.all()
            .order(Column("name").desc)
            .fetchAll(db)
    }
}

extension RootCoordinator {
    func loadData() async throws {
        guard needsLoading else { return }
        needsLoading = false
        let urls = try await WWDCApiService.fetchEventURLs()
        let containers = try await withThrowingTaskGroup(of: EventContainer.self) { group in
            for url in urls {
                group.addTask {
                    try await WWDCApiService.loadEvent(url)
                }
            }
            var containers = [EventContainer]()
            while let container = try await group.next() {
                containers.append(container)
            }
            return containers
        }
        try await database.write { db in
            for container in containers {
                try container.event.save(db)
                try container.topics.forEach { try $0.save(db) }
                try container.videos.forEach { try $0.save(db) }
                try container.videoTopics.forEach { try $0.save(db) }
            }
        }
    }
}
