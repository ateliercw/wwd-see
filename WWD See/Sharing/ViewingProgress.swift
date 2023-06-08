//
//  ViewingProgress.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation
import SwiftUI

struct ViewingProgress: Transferable {
    let categories: [Category]
    let videos: [Video]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { @MainActor progress in
            let renderer = ImageRenderer(content: ProgressView(categories: progress.categories,
                                                               videos: progress.videos))
            guard let image = renderer.uiImage?.pngData() else { fatalError() }
            return image
        }
    }
}

private struct ProgressView: View {
    let categories: [Category]
    let videos: [Video]

    var body: some View {
        VStack {
            label(name: "WWDC23",
                  viewed: videos.filter(\.included).filter(\.watched).count,
                  total: videos.filter(\.included).count)
            ForEach(categories) { category in
                label(name: category.name, viewed: category.viewedCount, total: category.toWatchCount)
            }
        }
    }

    func label(name: String, viewed: Int, total: Int) -> some View {
        VStack(alignment: .leading) {
            Text(name)
            Text("\(viewed) of \(total)")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color.black.opacity(0.05))
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(Color.black.opacity(0.1))
                        .frame(width: proxy.size.width * CGFloat(viewed) / CGFloat(total))
                }
            }
        }
    }
}
