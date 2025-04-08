//
//  EventContainer+initFromFetch.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import WWDCData

public extension EventContainer {
    init(event: WWDCEvent, topics: [WWDCTopic], videos: [WWDCVideo]) {
        let videos = videos.filter {
            $0.event.url.absoluteString == event.url.absoluteString
        }
        for video in videos where video.topics.isEmpty {
            print(video.title)
        }
        self = EventContainer(
            event: EventRecord(event: event),
            topics: [TopicRecord](topics: topics, videos: videos),
            videos: [VideoRecord](videos: videos),
            videoTopics: [VideoTopicRecord](videos: videos)
        )
    }
}

private extension EventRecord {
    init(event: WWDCEvent) {
        self = EventRecord(
            name: event.name,
            url: event.url
        )
    }
}

private extension Array where Element == TopicRecord {
    init(topics: [WWDCTopic], videos: [WWDCVideo]) {
        self = topics.filter { topic in
            videos.contains { video in
                video.topics.map(\.url.absoluteString).contains(topic.url.absoluteString)
            }
        }.map { topic in
            TopicRecord(
                name: topic.name,
                url: topic.url,
                icon: topic.icon
            )
        }
    }
}

private extension Array where Element == VideoRecord {
    init(videos: [WWDCVideo]) {
        self = videos.map { video in
            VideoRecord(
                title: video.title,
                url: video.url,
                datePublished: video.datePublished,
                platforms: video.platforms,
                duration: video.duration,
                summary: video.summary,
                eventUrl: video.event.url
            )
        }
    }
}

private extension Array where Element == VideoTopicRecord {
    init(videos: [WWDCVideo]) {
        self = videos.flatMap { video in
            video.topics.map { topic in
                VideoTopicRecord(videoUrl: video.url, topicUrl: topic.url)
            }
        }
    }
}
