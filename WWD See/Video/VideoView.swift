//
//  VideoView.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI

struct VideoView: View {
    @Bindable private(set) var video: Video

    var body: some View {
        List {
            Toggle("Watched", isOn: $video.watched)
            Toggle("Excluded", isOn: $video.excluded)
        }
        .safeAreaInset(edge: .top) {
            Text(video.name)
                .font(.title)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
    }
}
