//
//  CategoryView.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI
import SwiftData

struct CategoryView: View {
    let category: Category

    var body: some View {
        List {
            ForEach(category.videos) { video in
                NavigationLink("\(video.symbol) \(video.name)") {
                    VideoView(video: video)
                }
            }
        }
        .navigationTitle(category.name)
    }
}

extension Video {
    var symbol: Image {
        if excluded {
            Image(systemName: "xmark")
        } else if watched {
            Image(systemName: "checkmark")
        } else {
            Image(systemName: "circle")
        }
    }
}

#Preview {
//    CategoryView()
}
