//
//  WWDCTopic.swift
//  WWDCTools
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Dependencies
@preconcurrency import Fuzi

public struct WWDCTopic: Codable, Identifiable, Hashable, Sendable {
    public var id: Self { self }

    public let name: String
    public let url: URL
    public let icon: String

    public let fragments: [WWDCVideoFragment]
}

extension WWDCTopic {
    init(name: String, url: URL, icon: String) async throws {
        self.name = name
        self.url = url
        self.icon = icon

        let session = Dependency(\.urlSession).wrappedValue
        let (data, _) = try await session.data(from: url)
        let document = try HTMLDocument(data: data)
        let fragmentNodes = document.css(".vc-card")
        self.fragments = try fragmentNodes.map {
            try WWDCVideoFragment.init(element: $0)
        }
    }
}

extension Array where Element == WWDCTopic {
    init(data: Data) async throws {
        self = []
        let document = try HTMLDocument(data: data)
        self = try await withThrowingTaskGroup(of: WWDCTopic.self) { group in
            for node in document.css(".tile-link") {
                let (name, url, icon) = try node.extractTopicInfo()
                group.addTask {
                    try await WWDCTopic(name: name, url: url, icon: icon)
                }
            }
            var array = [WWDCTopic]()
            while let item = try await group.next() {
                array.append(item)
            }
            return array.sorted { $0.name < $1.name }
        }
    }
}

extension Fuzi.XMLElement {
    // swiftlint:disable:next large_tuple
    func extractTopicInfo() throws -> (name: String, url: URL, icon: String) {
        let url = self["href"].flatMap { url in
            URL(string: url, relativeTo: .baseURL)
        }
        let name = self.firstChild(css: ".typography-label")?
            .childNodes(ofTypes: [.Text])
            .first?
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let icon = self.firstChild(css: ".topic-icon")?["src"]
            .flatMap(URL.init(string:))?
            .deletingPathExtension()
            .lastPathComponent
        guard let name, let url, let icon else {
            throw Failure.badData
        }
        return (name, url, icon)
    }
}
