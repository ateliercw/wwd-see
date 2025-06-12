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
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
    let video: VideoRecord
    var info: VideoViewedRecord?

    init(video: VideoRecord, info: VideoViewedRecord?) {
        self.video = video
        self.info = info
    }

    func toggleHidden() {
        var info = info ?? VideoViewedRecord(videoUrl: video.url)
        info.toggleIgnored()
        try? database.write { db in
            try info.save(db)
        }
    }

    func toggleViewed() {
        var info = info ?? VideoViewedRecord(videoUrl: video.url)
        if !info.isWatched {
            info.updateIgnored(false)
        }
        info.toggleWatched()
        try? database.write { db in
            try info.save(db)
        }
    }

    var isVideoWatched: Bool {
        info?.isWatched ?? false
    }

    var isVideoIgnored: Bool {
        info?.ignored ?? false
    }
}
