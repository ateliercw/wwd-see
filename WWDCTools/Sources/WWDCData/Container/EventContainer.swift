//
//  EventContainer.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct EventContainer: Codable, FileDocument {
    public static let readableContentTypes: [UTType] = [.json]

    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            let decoder = JSONDecoder()
            self = try decoder.decode(EventContainer.self, from: data)
        } else {
            fatalError()
        }
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard configuration.contentType == .json else {
            fatalError()
        }
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }

    public var event: EventRecord
    public var topics: [TopicRecord]
    public var videos: [VideoRecord]
    public var videoTopics: [VideoTopicRecord]

    public init(
        event: EventRecord,
        topics: [TopicRecord],
        videos: [VideoRecord],
        videoTopics: [VideoTopicRecord]
    ) {
        self.event = event
        self.topics = topics
        self.videos = videos
        self.videoTopics = videoTopics
    }
}
