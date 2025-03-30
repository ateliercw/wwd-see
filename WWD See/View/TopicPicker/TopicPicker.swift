//
//  TopicPicker.swift
//  WWD See
//
//  Created by Michael Skiba on 26/03/2025.
//

import SwiftUI
import WWDCData
import SharingGRDB
import IssueReporting

struct TopicPicker: View {
    let event: EventRecord
    @Binding var selection: TopicRecord?
    @State.SharedReader(value: []) private var topics: Topics.Value

    var body: some View {
        let rebinding = Binding<TopicRecord??> {
            Optional(selection)
        } set: {
            selection = $0 ?? nil
        }
        List(selection: rebinding) {
            ForEach(topics, id: \.id) { result in
                HStack {
                    Text(result.topic?.name ?? "All Videos")
                    Spacer()
                    Text("\(result.watched, format: .number)/\(result.total, format: .number)")
                }
            }
        }
        .listStyle(.sidebar)
        .task(id: event) {
            await updateQuery()
            if selection == nil {
                selection = topics.first?.topic
            }
        }
    }
}

private extension TopicPicker {
    func updateQuery() async {
        do {
            try await $topics.load(.fetch(Topics(event: event)))
        } catch {
            reportIssue(error)
        }
    }

    struct Topics: FetchKeyRequest {
        var event: EventRecord

        func fetch(_ db: Database) throws -> [TopicDisplayRow] {
            let eventViewedAlias = TableAlias()

            let baseEventVideos = event
                .videos
                .joining(optional: VideoRecord.viewed.aliased(eventViewedAlias))
                .filter(
                    eventViewedAlias[Column("ignored")] == nil ||
                    eventViewedAlias[Column("ignored")] == false
                )

            let topics = try event
                .topics
                .fetchAll(db)
            let totalRemaining = try baseEventVideos.fetchCount(db)
            let totalWatched = try baseEventVideos.filter(eventViewedAlias[Column("watchedDate")] != nil).fetchCount(db)
            let results = try topics.compactMap { topic -> TopicDisplayRow? in
                let viewedAlias = TableAlias()

                let baseRows = topic.videos
                    .filter(Column("eventUrl") == event.url)
                    .joining(optional: VideoRecord.viewed.aliased(viewedAlias))
                    .filter(
                        viewedAlias[Column("ignored")] == nil ||
                        viewedAlias[Column("ignored")] == false
                    )

                let total = try baseRows
                    .fetchCount(db)

                let watched = try baseRows
                    .filter(viewedAlias[Column("watchedDAte") != nil])
                    .fetchCount(db)
                return TopicDisplayRow(topic: topic, watched: watched, total: total)
            }
            return [TopicDisplayRow(watched: totalWatched, total: totalRemaining)] + results
        }
    }

    struct TopicRow: FetchableRecord, Decodable {
        var watched: Int { 0 }
        var total: Int
    }

    struct TopicDisplayRow: Hashable, Identifiable {
        var id: TopicRecord? { topic }

        var topic: TopicRecord?
        var watched: Int
        var total: Int
    }
}

private extension TopicPicker.TopicDisplayRow {
    init(topic: TopicRecord, row: TopicPicker.TopicRow) {
        self.topic = topic
        self.watched = row.watched
        self.total = row.total
    }
}
