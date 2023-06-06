//
//  VideoView.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI

struct VideoView: View {
    let video: Video

    var body: some View {
        List {
            Text(video.name)
                .font(.title)
            Section {
                Button {
                    video.watched.toggle()
                } label: {
                    HStack {
                        Text("Watched")
                        if video.watched {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Section {
                Button {
                    video.excluded.toggle()
                } label: {
                    HStack {
                        Text("Excluded")
                        if video.excluded {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}
