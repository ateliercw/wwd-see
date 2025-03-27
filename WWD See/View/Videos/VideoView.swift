//
//  VideoView.swift
//  WWD See
//
//  Created by Michael Skiba on 26/03/2025.
//

import SwiftUI
import WWDCData
import SharingGRDB
import IssueReporting

struct VideoView: View {
    let video: VideoRecord
    var info: VideoViewedRecord?
    @Dependency(\.defaultDatabase) var database
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(action: open) {
            HStack {
                Text(video.title)
                Spacer()
                icon
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: toggleHidden) {
                Label {
                    Text(info?.ignored == true ? "Show" : "Hide")
                } icon: {
                    Image(systemName: info?.ignored == true ? "eye" : "eye.slash")
                }
            }
            .tint(.gray)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: toggleViewed) {
                Label {
                    Text(info?.watchedDate == nil ? "March watched" : "Mark unwatched")
                } icon: {
                    Image(systemName: info?.watchedDate == nil ? "checkmark" : "square")
                }
            }
        }
        .foregroundStyle(foregroundStyle)
    }
}

private extension VideoView {
    func open() {
        openURL(video.url)
    }
    func toggleHidden() {
        var info = info ?? VideoViewedRecord(videoUrl: video.url, ignored: false)
        info.ignored.toggle()
        save(info)
    }

    func toggleViewed() {
        var info = info ?? VideoViewedRecord(videoUrl: video.url, ignored: false)
        if info.watchedDate == nil {
            info.watchedDate = Date()
        } else {
            info.watchedDate = nil
        }
        save(info)
    }

    func save(_ info: VideoViewedRecord) {
        do {
            try database.write { db in
                try info.save(db)
            }
        } catch {
            reportIssue(error)
        }
    }

    @ViewBuilder
    var icon: some View {
        if info?.ignored == true {
            Image(systemName: "eye.slash")
        } else if info?.watchedDate != nil {
            Image(systemName: "checkmark")
        }
    }

    var foregroundStyle: some ShapeStyle {
        if info?.ignored == true || info?.watchedDate != nil {
            Color.secondary
        } else {
            Color.primary
        }
    }
}
