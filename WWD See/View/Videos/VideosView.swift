//
//  VideosView.swift
//  WWD See
//
//  Created by Michael Skiba on 26/03/2025.
//

import SwiftUI
import WWDCData
import SharingGRDB
import IssueReporting

struct VideosView: View {
    let event: EventRecord
    let topic: TopicRecord?

    @State.SharedReader(value: []) private var dates: [(Date, [FullVideo])]
    @State var query: String = ""

    var body: some View {
        List {
            ForEach(dates, id: \.0) { date, videos in
                Section {
                    ForEach(videos) { full in
                        VideoView(video: full.video, info: full.videoViewed)
                    }
                } header: {
                    Text(date, style: .date)
                }
            }
        }
        .task(id: [event, topic, query] as [AnyHashable]) {
            do {
                try await $dates.load(.fetch(VideosRequest(event: event, topic: topic, query: query)))
            } catch {
                reportIssue(error)
            }
        }
        .navigationTitle(topic?.name ?? event.name)
        .searchable(text: $query, prompt: "Search")
    }
}

private extension VideosView {
    struct VideosRequest: FetchKeyRequest {
        let event: EventRecord
        let topic: TopicRecord?
        let query: String

        func fetch(_ db: Database) throws -> [(Date, [FullVideo])] {
            let fullVideos: [VideosView.FullVideo]
            if query.isEmpty {
                let request = (topic?.videos.filter(Column("eventUrl") == event.url) ?? event.videos)
                    .order([Column("sortValue"), Column("title")])
                    .including(optional: VideoRecord.viewed)
                fullVideos = try FullVideo.fetchAll(db, request)
            } else {
                let request = (topic?.videos.filter(Column("eventUrl") == event.url) ?? event.videos)
                    .filter(Column("title").like("%\(query)%"))
                    .order([Column("sortValue"), Column("title")])
                    .including(optional: VideoRecord.viewed)
                fullVideos = try FullVideo.fetchAll(db, request)
            }
            let dict = [Date: [FullVideo]](grouping: fullVideos, by: \.video.datePublished)
            return dict.sorted { $0.key < $1.key }
        }
    }

    struct FullVideo: FetchableRecord, Decodable, Identifiable, Hashable {
        var id: VideoRecord.ID { video.id }
        var video: VideoRecord
        var videoViewed: VideoViewedRecord?
    }
}
