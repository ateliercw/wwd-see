//
//  File.swift
//  
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation
import SwiftHTMLParser
import WWDCData

extension Topic {
    init(element: Element) throws {
        guard let url = element.attributeValue(for: "href")
            .flatMap({ URL(string: $0, relativeTo: .baseURL) })
        else {
            throw Failure.badData
        }
        guard let name = HTMLTraverser.findElements(
            in: element.childNodes,
            matching: Self.titleQuery
        )
            .flatMap(\.textNodes)
            .map(\.text)
            .first
        else {
            throw Failure.badData
        }
        self = Topic(name: name, url: url)
    }

    static func fetchAll() async throws -> [Topic] {
        let (topicData, _) = try await URLSession.shared.data(from: URL.topicsURL)

        guard let string = String(data: topicData, encoding: .utf8) else {
            throw Failure.failedToCreateString
        }

        let document = try HTMLParser.parse(string)
        let topics = HTMLTraverser.findElements(in: document, matching: Topic.query)

        return try topics.map(Topic.init(element:))
    }
}

private extension Topic {
    static let query = [
        ElementSelector().withTagName("html"),
        ElementSelector().withTagName("body"),
        ElementSelector().withTagName("main"),
        ElementSelector().withTagName("div"),
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("div"),
        ElementSelector().withTagName("div"),
        ElementSelector().withTagName("div"),
        ElementSelector().withTagName("a").withClassName("tile-link"),
    ]

    static let titleQuery = [
        ElementSelector().withTagName("div"),
        ElementSelector().withTagName("h4")
    ]
}
