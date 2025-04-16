//
//  VideoViewedRecord.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB
import Dependencies

public struct VideoViewedRecord: FetchableRecord, PersistableRecord, TableRecord,
                                 Identifiable, Codable, Hashable, Sendable {
    public static let databaseTableName = "videoViewed"
    public static let zoneName = "videoViewed"

    public var id: URL { videoUrl }

    public internal(set) var videoUrl: URL
    public internal(set) var ignored: Bool
    public internal(set) var ignoredUpdated: Date?
    public internal(set) var watchedDate: Date?
    public internal(set) var watchedUpdated: Date?
    var syncRecord: Data?

    public static let video = belongsTo(VideoRecord.self)
    public var video: QueryInterfaceRequest<VideoRecord> {
        request(for: VideoViewedRecord.video)
    }

    public var isWatched: Bool {
        return watchedDate != nil
    }

    public init(
        videoUrl: URL,
        ignored: Bool = false,
        ignoredUpdated: Date? = nil,
        watchedDate: Date? = nil,
        watchedUpdated: Date? = nil
    ) {
        self.videoUrl = videoUrl
        self.ignored = ignored
        self.ignoredUpdated = ignoredUpdated
        self.watchedDate = watchedDate
        self.watchedUpdated = watchedUpdated
    }

    public mutating func toggleIgnored(_ date: Date = Dependency(\.date).wrappedValue.now) {
        updateIgnored(!ignored, updated: date)
    }

    public mutating func toggleWatched(_ date: Date = Dependency(\.date).wrappedValue.now) {
        updateWatchedDate(watchedDate == nil ? date : nil, updated: date)
    }

    public mutating func updateIgnored(_ ignored: Bool, updated: Date = Dependency(\.date).wrappedValue.now) {
        guard (ignoredUpdated ?? .distantPast) < updated else { return }
        self.ignored = ignored
        self.ignoredUpdated = updated
    }

    public mutating func updateWatchedDate(_ date: Date?, updated: Date = Dependency(\.date).wrappedValue.now) {
        guard (watchedUpdated ?? .distantPast) < updated else { return }
        watchedDate = date
        watchedUpdated = updated
    }
}
