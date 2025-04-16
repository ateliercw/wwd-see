//
//  VideoViewModel.swift
//  WWD See
//
//  Created by Michael Skiba on 09/04/2025.
//

import Foundation
import SharingGRDB
import WWDCData

@Observable
class VideoViewModel {
    let video: VideoRecord
    var info: VideoViewedRecord?

    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
    @ObservationIgnored
    @Dependency(\.videoSyncService) private var syncService

    init(video: VideoRecord, info: VideoViewedRecord?) {
        self.video = video
        self.info = info
    }

    func toggleHidden() {
        var info = info ?? VideoViewedRecord(videoUrl: video.url)
        info.toggleIgnored()
        save(info)
    }

    func toggleViewed() {
        var info = info ?? VideoViewedRecord(videoUrl: video.url)
        if !info.isWatched {
            info.updateIgnored(false)
        }
        info.toggleWatched()
        save(info)
    }

    func save(_ info: VideoViewedRecord) {
        Task { [syncService] in
            do {
                try await syncService.update(info: info)
            } catch {
                reportIssue(error)
            }
        }
    }

    var isVideoWatched: Bool {
        info?.isWatched ?? false
    }

    var isVideoIgnored: Bool {
        info?.ignored ?? false
    }
}
