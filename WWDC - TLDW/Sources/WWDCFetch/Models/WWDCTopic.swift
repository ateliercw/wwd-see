//
//  WWDCTopic.swift
//  WWDC 2023
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Fuzi

public struct WWDCTopic: Codable, Identifiable, Hashable {
    public var id: Self { self }

    public let name: String
    public let url: URL
    public let icon: String

    public let fragments: [WWDCVideoFragment]
}

extension WWDCTopic {
    init(element: Fuzi.XMLElement) async throws {
        let url = element["href"].flatMap { url in
            URL(string: url, relativeTo: .baseURL)
        }
        let name = element.firstChild(css: ".typography-label")?
            .childNodes(ofTypes: [.Text])
            .first?
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let icon = element.firstChild(css: ".topic-icon")?["src"]
            .flatMap(URL.init(string:))?
            .deletingPathExtension()
            .lastPathComponent
        guard let name, let url, let icon else {
            throw Failure.badData
        }

        self = WWDCTopic(
            name: name,
            url: url,
            icon: icon,
            fragments: try await WWDCFetchService.fetchFragments(url)
        )
    }
}

extension Array where Element == WWDCTopic {
    init(data: Data) async throws {
        let document = try HTMLDocument(data: data)
        self = try await withThrowingTaskGroup(of: WWDCTopic.self) { group in
            for node in document.css(".tile-link") {
                group.addTask {
                    try await WWDCTopic(element: node)
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
