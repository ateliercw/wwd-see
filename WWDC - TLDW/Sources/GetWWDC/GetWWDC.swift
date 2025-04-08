//
//  GetWWDC.swift
//  WWDC 2023
//
//  Created by Michael Skiba on 02/04/2025.
//

import Foundation
import ArgumentParser
import WWDCFetch
import WWDCData

@main
struct GetWWDC: AsyncParsableCommand {
    mutating func run() async throws {
        print("Fetching Topics")
        let topics = try await WWDCFetchService.fetchAllTopics()
        print("Fetching Events")
        let events = try await WWDCFetchService.fetchAllEvents(for: topics)
        var videos: [WWDCVideo] = []
        for event in events {
            print("Fetching \(event.fragments.count) videos for \(event.name)")
            let eventVideos = try await withThrowingTaskGroup(of: WWDCVideo.self) { group in
                var videos: Set<WWDCVideo> = []
                let allFragments = event.fragments
                for fragment in allFragments {
                    group.addTask {
                        var video = try await WWDCFetchService.fetchVideo(fragment: fragment)
                        video.event = event
                        video.topics = topics.filter { $0.fragments.contains(fragment) }
                        return video
                    }
                }
                while let video = try await group.next() {
                    videos.insert(video)
                }
                return videos
            }
            videos.append(contentsOf: eventVideos)
        }
        let encoder = JSONEncoder()
        for event in events {
            print("Writing \(event.fileName)")
            let container = EventContainer(
                event: event,
                topics: topics,
                videos: videos
            )
            let data = try encoder.encode(container)
            FileManager.default.createFile(atPath: "\(event.fileName)", contents: data)
        }
        let list = try encoder.encode(events.map((\.fileName)))
        print("Writing events.json")
        FileManager.default.createFile(atPath: "events.json", contents: list)
    }
}

private extension WWDCEvent {
    var fileName: String {
        "\(name.lowercased().replacingOccurrences(of: " ", with: "_")).json"
    }
}
