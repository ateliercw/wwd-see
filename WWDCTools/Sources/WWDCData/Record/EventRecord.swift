//
//  EventRecord.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import SharingGRDB

public struct EventRecord: FetchableRecord, PersistableRecord, TableRecord, Identifiable, Codable, Hashable, Sendable {
    public static let databaseTableName: String = "event"
    public var id: String {
        url.absoluteString
    }

    public private(set) var name: String
    public private(set) var url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }

    public static let videos = hasMany(VideoRecord.self)

    public var videos: QueryInterfaceRequest<VideoRecord> {
        request(for: EventRecord.videos)
            .groupByPrimaryKey()
    }

    public static let topics = hasMany(TopicRecord.self, through: videos, using: VideoRecord.topics)

    public var topics: QueryInterfaceRequest<TopicRecord> {
        request(for: EventRecord.topics)
            .groupByPrimaryKey()
    }
}
