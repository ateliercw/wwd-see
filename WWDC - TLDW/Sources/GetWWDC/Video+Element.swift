//
//  Video+Element.swift
//
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation
import SwiftHTMLParser
import WWDCData

extension Video {
    init?(element: Element) throws {
        guard HTMLTraverser.findElements(in: element.childNodes, matching: Self.eventTagQuery)
            .flatMap(\.textNodes)
            .map(\.text)
            .contains("WWDC23") else {
            return nil
        }
        guard let titleElement = HTMLTraverser.findElements(in: element.childNodes, matching: Self.titleQuery)
            .first(where: { HTMLTraverser.hasMatchingNode(in: $0.childNodes, matching: Self.titleTextQuery) }),
                let url = titleElement.attributeValue(for: "href").flatMap({ URL(string: $0, relativeTo: .baseURL) })
        else {
            throw Failure.badData
        }
        guard let name = HTMLTraverser.findElements(
            in: titleElement.childNodes,
            matching: Self.titleTextQuery
        )
            .flatMap(\.textNodes)
            .map(\.text)
            .first else {
            throw Failure.badData
        }
        let focuses = HTMLTraverser.findElements(in: element.childNodes, matching: Self.focusTagQuery)
            .flatMap(\.textNodes)
            .map(\.text)
        self = Video(name: name, url: url, focus: focuses)
    }
}

extension Video {
    static func fetchAll(in topic: Topic) async throws -> [Video] {
        let (videosData, _) = try await URLSession.shared.data(from: topic.url)

        guard let string = String(data: videosData, encoding: .utf8) else {
            throw Failure.failedToCreateString
        }

        let document = try HTMLParser.parse(string)
        let videos = HTMLTraverser.findElements(in: document, matching: Video.query)
        return try videos.compactMap(Video.init(element:))
    }
}

private extension Video {
    static let query = [
        ElementSelector().withTagName("html"),
        ElementSelector().withTagName("body"),
        ElementSelector().withTagName("main"),
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("ul"),
        ElementSelector().withTagName("li"),
        ElementSelector().withTagName("ul"),
        ElementSelector().withTagName("li").withClassName("collection-item"),
    ]

    static let titleQuery = [
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("a")
    ]

    static let titleTextQuery = [
        ElementSelector().withTagName("h4").withClassName("video-title")
    ]

    static let tagsQuery = [
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("section"),
        ElementSelector().withTagName("ul"),
    ]

    static let eventTagQuery = tagsQuery +
    [
        ElementSelector().withTagName("li")
            .withClassName("event"),
        ElementSelector().withTagName("span")
    ]

    static let focusTagQuery = tagsQuery +
    [
        ElementSelector().withTagName("li")
            .withClassName("focus"),
        ElementSelector().withTagName("span")
    ]
}
