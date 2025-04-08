//
//  VideoTopicRecord.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB

public struct VideoTopicRecord: FetchableRecord, PersistableRecord, TableRecord,
                                Identifiable, Codable, Hashable, Sendable {
    public static let databaseTableName: String = "videoTopic"

    public var id: [URL] { [videoUrl, topicUrl]  }

    public var videoUrl: URL
    public var topicUrl: URL

    static let video = belongsTo(VideoRecord.self, using: ForeignKey(["videoUrl"], to: ["url"]))
    static let topic = belongsTo(TopicRecord.self, using: ForeignKey(["topicUrl"], to: ["url"]))

    public init(videoUrl: URL, topicUrl: URL) {
        self.videoUrl = videoUrl
        self.topicUrl = topicUrl
    }
}
