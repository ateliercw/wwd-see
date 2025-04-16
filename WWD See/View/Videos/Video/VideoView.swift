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
    @Environment(\.openURL) private var openURL

    private let viewModel: VideoViewModel

    init(video: VideoRecord, info: VideoViewedRecord?) {
        viewModel = VideoViewModel(video: video, info: info)
    }

    var body: some View {
        HStack {
            Button(action: open) {
                HStack {
                    Text(viewModel.video.title)
                    Spacer()
#if os(iOS)
                    icon
#endif
                }
                .contentShape(Rectangle())
            }
#if os(macOS)
            hiddenButton(invert: true)
                .foregroundStyle(viewModel.isVideoWatched && !viewModel.isVideoIgnored ? .secondary : Color.accentColor)
            viewedButton(invert: true)
                .foregroundStyle(viewModel.isVideoIgnored ? .secondary : Color.accentColor)
#endif
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            hiddenButton()
                .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            viewedButton()
                .tint(.green)
        }
        .foregroundStyle(foregroundStyle)
    }
}

private extension VideoView {
    func hiddenButton(invert: Bool = false) -> some View {
        Button(action: viewModel.toggleHidden) {
            Label {
                Text(viewModel.isVideoIgnored ? "Show" : "Hide")
            } icon: {
                Image(systemName: viewModel.isVideoIgnored != invert ? "eye" : "eye.slash")
            }
        }
    }

    func viewedButton(invert: Bool = false) -> some View {
        Button(action: viewModel.toggleViewed) {
            Label {
                Text(viewModel.isVideoWatched ? "Mark as unwatched" : "Mark as watched")
            } icon: {
                Image(systemName: viewModel.isVideoWatched != invert ? "square" : "checkmark")
            }
        }
    }

    func open() {
        openURL(viewModel.video.url)
    }

    @ViewBuilder
    var icon: some View {
        if viewModel.isVideoIgnored {
            Image(systemName: "eye.slash")
        } else if viewModel.isVideoWatched {
            Image(systemName: "checkmark")
        }
    }

    var foregroundStyle: some ShapeStyle {
        if viewModel.isVideoIgnored {
            Color.secondary
        } else {
            Color.primary
        }
    }
}
