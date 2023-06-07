//
//  ContentView.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    var body: some View {
        NavigationStack {
            List {
                ProgressSummary()
                ForEach(categories) { category in
                    Section {
                        ForEach(category.videos) { video in
                            VideoCell(video: video)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text(category.name)
                            Text("\(category.viewedCount) / \(category.toWatchCount)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("WWD See")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: ViewingProgress(categories: categories), preview: SharePreview("Share progress"))
                }
            }
        }
        .task {
            guard categories.isEmpty else { return }
            do {
                try modelContext.loadStoredCategories()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

struct ProgressSummary: View {
    @Query private var videos: [Video]

    var body: some View {
        let watched = videos.filter(\.included).filter(\.watched).count
        let ignored = videos.filter(\.excluded).count
        let total = videos.count - ignored
        let progress = Float(watched) / Float(total)
        let progressFormat = FloatingPointFormatStyle<Float>.Percent().precision(.fractionLength(2))
        return Text("\(watched) of \(total) \(progress, format: progressFormat), \(ignored) ignored")
    }
}

struct VideoCell: View {
    let video: Video

    var body: some View {
        NavigationLink {
            VideoView(video: video)
        } label: {
            HStack {
                symbol
                Text(video.name)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                video.watched.toggle()
            } label: {
                if video.watched {
                    Label("Mark as unwatched", systemImage: "circle")
                } else {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: video.excluded ? .destructive : .none) {
                video.excluded.toggle()
            } label: {
                if video.excluded {
                    Label("Include video", systemImage: "eye.slash")
                } else {
                    Label("Exclude video", systemImage: "eye")
                }
            }
            .tint(video.excluded ? .green : .red)
        }
    }

    var symbol: Image {
        if video.excluded {
            Image(systemName: "xmark")
        } else if video.watched {
            Image(systemName: "checkmark")
        } else {
            Image(systemName: "circle")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Category.self, inMemory: true)
}
