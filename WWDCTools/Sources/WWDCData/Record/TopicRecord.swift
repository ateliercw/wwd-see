//
//  TopicRecord.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB

public struct TopicRecord: FetchableRecord, PersistableRecord, TableRecord, Identifiable, Codable, Hashable, Sendable {
    public static let databaseTableName: String = "topic"

    public var id: String { url.absoluteString }

    public private(set) var name: String
    public private(set) var url: URL
    public private(set) var icon: String

    public init(name: String, url: URL, icon: String) {
        self.name = name
        self.url = url
        self.icon = icon
    }

    public static let videoTopics = hasMany(VideoTopicRecord.self)
    public static let videos = hasMany(VideoRecord.self, through: videoTopics, using: VideoTopicRecord.video)
    public var videos: QueryInterfaceRequest<VideoRecord> {
        request(for: TopicRecord.videos)
            .groupByPrimaryKey()
    }
}
