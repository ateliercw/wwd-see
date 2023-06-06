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

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { @MainActor progress in
            let renderer = ImageRenderer(content: ProgressView(categories: progress.categories))
            guard let image = renderer.uiImage?.pngData() else { fatalError() }
            return image
        }
    }
}

private struct ProgressView: View {
    let categories: [Category]

    var body: some View {
        VStack {
            ForEach(categories) { category in
                VStack(alignment: .leading) {
                    Text(category.name)
                    Text("\(category.viewedCount) of \(category.toWatchCount)")
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
                                .frame(width: proxy.size.width * category.progress)
                        }
                    }
                }
            }
        }
    }
}

private extension Category {
    var progress: CGFloat {
        CGFloat(viewedCount) / CGFloat(toWatchCount)
    }
}
