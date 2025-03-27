//
//  VideoRecord.swift
//  WWDC 2023
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB

public struct VideoRecord: FetchableRecord, PersistableRecord, TableRecord, Identifiable, Codable, Hashable, Sendable {
    public static var databaseTableName: String = "video"

    public var id: String { url.absoluteString }

    public var title: String
    public var url: URL
    public var sortValue: Int
    public var datePublished: Date
    public var platforms: [String]
    public var duration: TimeInterval
    public var summary: String
    public var eventUrl: URL

    public static let event = belongsTo(EventRecord.self, using: ForeignKey(["eventUrl"], to: ["url"]))
    public var event: QueryInterfaceRequest<EventRecord> {
        request(for: VideoRecord.event)
    }

    public static let viewed = hasOne(VideoViewedRecord.self)
    public var viewed: QueryInterfaceRequest<VideoViewedRecord> {
        request(for: VideoRecord.viewed)
    }

    public static let videoTopics = hasMany(VideoTopicRecord.self)
    public static let topics = hasMany(TopicRecord.self, through: videoTopics, using: VideoTopicRecord.topic)

    public var topics: QueryInterfaceRequest<TopicRecord> {
        request(for: VideoRecord.topics)
            .groupByPrimaryKey()
    }

    public init(
        title: String,
        url: URL,
        datePublished: Date,
        platforms: [String],
        duration: TimeInterval,
        summary: String,
        eventUrl: URL
    ) {
        self.title = title
        self.url = url
        self.sortValue = Int(url.lastPathComponent) ?? -1
        self.datePublished = datePublished
        self.platforms = platforms
        self.duration = duration
        self.summary = summary
        self.eventUrl = eventUrl
    }
}
