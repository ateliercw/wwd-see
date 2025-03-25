//
//  ContentView.swift
//  WWDC Loader
//
//  Created by Michael Skiba on 24/03/2025.
//

import SwiftUI
import WWDCFetch

struct ContentView: View {
    enum Selection: Hashable, Identifiable {
        var id: Self { self}

        case event(WWDCEvent)
        case topic(WWDCTopic)
    }
    @State private var viewModel = ContentViewModel()
    @State private var selection: Selection?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if !viewModel.events.isEmpty {
                    Section("Events") {
                        ForEach(viewModel.events) { event in
                            Text(event.name)
                                .tag(Selection.event(event))
                        }
                    }
                }
                if !viewModel.topics.isEmpty {
                    Section("Topics") {
                        ForEach(viewModel.topics) { topic in
                            Text(topic.name)
                                .tag(Selection.topic(topic))
                        }
                    }
                }
            }
            .disabled(viewModel.isLoading)
        } detail: {
            selectionView
        }
        .navigationSplitViewStyle(.prominentDetail)
    }
}

private extension ContentView {
    @ViewBuilder private var selectionView: some View {
        switch selection {
        case let .event(event):
            EventView(
                event: event,
                loadedVideos: viewModel.loadedVideos,
                isLoading: viewModel.isLoading
            ) {
                viewModel.loadVideosFor(event)
            }
        case let .topic(topic):
            TopicView(
                topic: topic,
                loadedVideos: viewModel.loadedVideos,
                isLoading: viewModel.isLoading
            ) {
                viewModel.loadVideosFor(topic)
            }
        case nil:
            if !viewModel.topics.isEmpty || !viewModel.events.isEmpty {
                ContentUnavailableView("Get Started", systemImage: "map", description: Text("Select a topic or event"))
            } else {
                ContentUnavailableView {
                    Text("No topics or events available")
                } description: {
                    Text("Fetch topics and events to get started")
                } actions: {
                    fetchTopicsAndEventsButton
                        .transition(.opacity)
                        .animation(.default, value: viewModel.isLoading)
                }
            }
        }
    }

    @ViewBuilder
    var fetchTopicsAndEventsButton: some View {
        ZStack {
            if !viewModel.isLoading {
                Button("Load") {
                    viewModel.loadContent()
                }
            } else {
                ProgressView()
            }
        }
    }
}

struct TopicView: View {
    let topic: WWDCTopic
    let loadedVideos: [URL: WWDCVideo]
    let isLoading: Bool
    let load: () -> Void

    var body: some View {
        SectionedVideoList(
            fragments: topic.fragments,
            loadedVideos: loadedVideos,
            isLoading: isLoading,
            load: load
        )
        .navigationTitle(topic.name)
    }
}

struct EventView: View {
    let event: WWDCEvent
    let loadedVideos: [URL: WWDCVideo]
    let isLoading: Bool
    let load: () -> Void

    var body: some View {
        SectionedVideoList(
            fragments: event.fragments,
            loadedVideos: loadedVideos,
            isLoading: isLoading,
            load: load
        )
        .navigationTitle(event.name)
    }
}

struct SectionedVideoList: View {
    let fragments: [WWDCVideoFragment]
    let loadedVideos: [URL: WWDCVideo]
    let isLoading: Bool
    let load: () -> Void

    private var needsLoading: [WWDCVideoFragment] {
        fragments
            .filter { loadedVideos[$0.url] == nil }
            .sorted(using: KeyPathComparator(\.title, comparator: .localizedStandard))
    }

    private var dateSections: [(Date, [WWDCVideo])] {
        let loaded = fragments.compactMap { loadedVideos[$0.url] }
        return [Date: [WWDCVideo]](grouping: loaded, by: \.datePublished).mapValues { videos in
            videos.sorted(using: [KeyPathComparator(\.numericSortComponent), KeyPathComparator(\.url.lastPathComponent, comparator: .localizedStandard)])
        }
        .sorted(using: KeyPathComparator(\.key))
    }

    var body: some View {
        let needsLoading = needsLoading
        List {
            if !needsLoading.isEmpty {
                Section("Needs to load") {
                    ForEach(needsLoading) { fragment in
                        Text(fragment.title)
                    }
                }
                .foregroundStyle(.secondary)
            }
            let dateSections = dateSections
            if !dateSections.isEmpty {
                ForEach(dateSections, id:\.0) { idx in
                    let (key, value) = idx
                    Section(key.formatted(.dateTime.year().month().day())) {
                        ForEach(value) { video in
                            VideoView(video: video)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.linear)
                } else {
                    if !needsLoading.isEmpty {
                        Button(action: load) {
                            Label("Load", systemImage: "arrow.down")
                        }
                    }
                }
            }
        }
    }
}



private struct VideoView: View {
    let video: WWDCVideo

    var body: some View {
        HStack {
            Text(video.title)
            Group {
                Text(video.event.name)
                if !video.topics.isEmpty {
                    Text(video.topics.map(\.name).joined(separator: ", "))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
