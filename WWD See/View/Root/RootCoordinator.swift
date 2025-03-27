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
class RootCoordinator {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    @ObservationIgnored
    @SharedReader(.fetch(Events())) var events

    private var underlyingEventSelection: EventRecord?
    var selectedEvent: EventRecord? {
        get {
            underlyingEventSelection ?? events.first
        }
        set {
            underlyingEventSelection = newValue ?? events.first
        }
    }

    var selectedTopic: TopicRecord?
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
        for data in DataAsset.Event.all {
            let decoder = JSONDecoder()
            let eventContainer = try decoder.decode(EventContainer.self, from: data)
            try await database.write { db in
                try eventContainer.event.save(db)
                try eventContainer.topics.forEach { try $0.save(db) }
                try eventContainer.videos.forEach { try $0.save(db) }
                try eventContainer.videoTopics.forEach { try $0.save(db) }
            }
        }
    }
}
