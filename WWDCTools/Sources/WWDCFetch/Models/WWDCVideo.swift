//
//  WWDCVideoFragment.swift
//  WWDCTools
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Fuzi

public struct WWDCVideo: Codable, Identifiable, Hashable, Sendable {
    public var id: Self { self }
    public let title: String
    public let eventName: String
    public let url: URL
    public let datePublished: Date
    public var event: WWDCEvent
    public var topics: [WWDCTopic] = []
    public let duration: TimeInterval
    public let summary: String

    public var numericSortComponent: Int {
        do {
            return try Int(url.lastPathComponent, format: .number)
        } catch {
            debugPrint(error)
            return -1
        }
    }
}

public extension WWDCVideo {
    init(fragment: WWDCVideoFragment, data: Data) throws {
        title = fragment.title
        eventName = fragment.eventName
        url = fragment.url
        let document = try HTMLDocument(data: data)
        let dateString = document.xpath("//html/head/meta").first { tag in
            tag["itemprop"] == "datePublished"
        }?["content"]
        let formatString: Date.FormatString = "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)"

        let formatter = Date.VerbatimFormatStyle(
            format: formatString,
            timeZone: TimeZone(identifier: "America/Los_Angeles")!,
            calendar: Calendar(identifier: .gregorian)
        )
            .locale(Locale(identifier: "en_US_POSIX"))
        guard let dateString else {
            throw Failure.badData
        }
        self.datePublished = try Date(dateString, strategy: formatter.parseStrategy)
        let summary = document.firstChild(css: ".details")?
            .xpath(".//p/text()")
            .map(\.stringValue)
            .joined(separator: "\n")
        guard let summary else {
            throw Failure.badData
        }
        self.summary = summary
        self.duration = fragment.duration
        self.event = WWDCEvent(name: "Temp", url: .baseURL, fragments: [])
    }
}
