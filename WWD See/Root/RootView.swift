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
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories.filteredBy(searchText)) { category in
                    CategorySection(category: category, searchText: searchText)
                }
            }
            .listStyle(.plain)
            .navigationTitle("WWD See")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: ViewingProgress(categories: categories), preview: SharePreview("Share progress"))
                }
            }
            .searchable(text: $searchText, prompt: "Search for a video")
            .safeAreaInset(edge: .bottom) {
                ProgressSummary()
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.capsule)
                    .shadow(radius: 4)
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

// MARK: - Category Section
private struct CategorySection: View {
    let category: Category
    let searchText: String

    private var filteredVideos: some RandomAccessCollection<Video> {
        category.videos
            .filteredBy(searchText)
            .sorted(using: SortDescriptor(\.name, comparator: .localizedStandard))
    }

    var body: some View {
        Section {
            ForEach(filteredVideos) { video in
                VideoCell(video: video)
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text(category.name)
                Text("\(category.viewedCount) / \(category.toWatchCount)")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Progress Summary
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

// MARK: - Video Cel
struct VideoCell: View {
    let video: Video

    var body: some View {
        NavigationLink {
            VideoView(video: video)
        } label: {
            HStack {
                symbol
                    .foregroundColor(.accentColor)
                Text(video.name)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            toggleWatchedButton
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            toggleExcludeButton
        }
    }

    private var toggleWatchedButton: some View {
        Button {
            video.watched.toggle()
        } label: {
            if video.watched {
                Label("Mark as unwatched", systemImage: "circle.dotted")
            } else {
                Label("Mark as watched", systemImage: "circle.fill")
            }
        }
        .tint(.blue)
    }

    private var toggleExcludeButton: some View {
        Button(role: video.excluded ? .destructive : .none) {
            video.excluded.toggle()
        } label: {
            if video.excluded {
                Label("Include video", systemImage: "eye")
            } else {
                Label("Exclude video", systemImage: "eye.slash")
            }
        }
        .tint(video.excluded ? .green : .red)
    }

    private var symbol: Image {
        if video.excluded {
            Image(systemName: "xmark")
        } else if video.watched {
            Image(systemName: "circle.fill")
        } else {
            Image(systemName: "circle")
        }
    }
}

// MARK: - Filtering helpers
extension Array where Element == Category {
    func filteredBy(_ searchText: String) -> some RandomAccessCollection<Category> {
        if searchText.isEmpty {
            return self
        } else {
            return filter {
                $0.videos.contains { $0.matches(searchText) }
            }
        }
    }
}

extension Array where Element == Video {
    func filteredBy(_ searchText: String) -> some RandomAccessCollection<Video> {
        if searchText.isEmpty {
            return self
        } else {
            return filter {
                $0.matches(searchText)
            }
        }
    }
}

extension Video {
    func matches(_ search: String) -> Bool {
        name.localizedCaseInsensitiveContains(search)
    }
}

#Preview {
    RootView()
        .modelContainer(for: Category.self, inMemory: true)
}
