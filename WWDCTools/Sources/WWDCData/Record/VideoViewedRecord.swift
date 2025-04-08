//
//  VideoViewedRecord.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB

public struct VideoViewedRecord: FetchableRecord, PersistableRecord, TableRecord,
                                 Identifiable, Codable, Hashable, Sendable {
    public static let databaseTableName = "videoViewed"

    public var id: URL { videoUrl }

    public var videoUrl: URL
    public var ignored: Bool
    public var watchedDate: Date?

    public static let video = belongsTo(VideoRecord.self)
    public var video: QueryInterfaceRequest<VideoRecord> {
        request(for: VideoViewedRecord.video)
    }

    public init(videoUrl: URL, ignored: Bool, watchedDate: Date? = nil) {
        self.videoUrl = videoUrl
        self.ignored = ignored
        self.watchedDate = watchedDate
    }
}
