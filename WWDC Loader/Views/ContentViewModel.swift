//
//  ContentViewModel.swift
//  WWD See
//
//  Created by Michael Skiba on 24/03/2025.
//

import SwiftUI
import WWDCFetch
import WWDCData

@MainActor
@Observable
class ContentViewModel {
    private let actor = ContentWorker()
    private(set) var topics = [WWDCTopic]()
    private(set) var events = [WWDCEvent]()
    private(set) var loadedVideos = [URL: WWDCVideo]()
    private(set) var isLoading = false

    func loadContent() {
        isLoading = true
        Task {
            do {
                topics = try await actor.loadTopics()
                events = try await actor.loadEventsFor(topics)
            } catch {
                debugPrint(error)
            }
            isLoading = false
        }
    }

    func loadVideosFor(_ topic: WWDCTopic) {
        isLoading = true
        Task {
            do {
                for video in try await actor.loadVideosFor(
                    fragments: topic.fragments,
                    events: events,
                    topics: topics
                ) {
                    loadedVideos[video.url] = video
                }
            } catch {
                debugPrint(error)
            }
            isLoading = false
        }
    }

    func loadVideosFor(_ event: WWDCEvent) {
        isLoading = true
        Task {
            do {
                for video in try await actor.loadVideosFor(
                    fragments: event.fragments,
                    events: events,
                    topics: topics
                ) {
                    loadedVideos[video.url] = video
                }
            } catch {
                debugPrint(error)
            }
            isLoading = false
        }
    }

    func export(event: WWDCEvent) -> EventContainer {
        EventContainer(
            event: event,
            topics: topics,
            videos: event.fragments.compactMap({ loadedVideos[$0.url] })
        )
    }
}

private extension Collection where Element == WWDCVideo {
    var urlDictionary: [URL: Element] {
        [URL: Element].init( map { ($0.url, $0) }) { item, _ in
            item
        }
    }
}

private actor ContentWorker {
    private var loadedVideos: [URL: WWDCVideo] = [:]
    private var loadingVideos: Set<URL> = []

    func loadTopics() async throws -> [WWDCTopic] {
        try await WWDCFetchService.fetchAllTopics()
    }

    func loadEventsFor(_ topics: [WWDCTopic]) async throws -> [WWDCEvent] {
        try await WWDCFetchService.fetchAllEvents(for: topics)
    }

    private func beginLoading(url: URL) {
        loadingVideos.insert(url)
    }

    private func updateCache(url: URL, video: WWDCVideo) {
        loadingVideos.remove(url)
        loadedVideos[url] = video
    }

    private func addAssociationsTo(
        _ video: inout WWDCVideo,
        events: [WWDCEvent],
        topics: [WWDCTopic]
    ) {
        if let event = events.first(where: { $0.fragments.map(\.url.absoluteString).contains(video.url.absoluteString)
        }) {
            video.event = event
        }
        video.topics = topics.filter {
            $0.fragments.map(\.url.absoluteString).contains(video.url.absoluteString)
        }
        if video.topics.isEmpty {
            print("empty topics \(video.title)")
        }
    }

    func loadVideosFor(
        fragments: [WWDCVideoFragment],
        events: [WWDCEvent],
        topics: [WWDCTopic]
    ) async throws -> [WWDCVideo] {
        try await withThrowingTaskGroup(of: WWDCVideo.self) { [weak self] group in
            guard let self else { return [] }
            var results = [WWDCVideo]()
            for fragment in Set(fragments) {
                if let loaded = await loadedVideos[fragment.url] {
                    results.append(loaded)
                } else if await !loadingVideos.contains(fragment.url) {
                    await beginLoading(url: fragment.url)
                    group.addTask { [weak self] in
                        var video = try await WWDCFetchService.fetchVideo(fragment: fragment)
                        await self?.addAssociationsTo(&video, events: events, topics: topics)
                        await self?.updateCache(url: fragment.url, video: video)
                        return video
                    }
                }
            }
            while let result = try await group.next() {
                results.append(result)
            }
            return results
        }
    }
}
