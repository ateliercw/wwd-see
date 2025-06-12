//
//  WatchedState.swift
//  WWDCTools
//
//  Created by Michael Skiba on 06/06/2025.
//

import Foundation
import SwiftData

@Model final class WatchedState: Identifiable, Hashable {
    public var videoUrl: URL?
    public var ignored: Bool = false
    public var ignoredUpdated: Date?
    public var watchedDate: Date?
    public var watchedUpdated: Date?

    public init(videoUrl: URL?,
                ignored: Bool,
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
}
