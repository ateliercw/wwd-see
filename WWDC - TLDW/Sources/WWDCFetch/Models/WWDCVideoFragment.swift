//
//  WWDCVideoFragment.swift
//  WWDC 2023
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Fuzi

public struct WWDCVideoFragment: Codable, Identifiable, Hashable {
    public var id: Self { self }
    public let title: String
    public let eventName: String
    public let platforms: [String]
    public let url: URL
    public let duration: TimeInterval
}

extension WWDCVideoFragment {
    init(element: Fuzi.XMLElement, eventName: String?) throws {
        let url = element.firstChild(css: ".video-image-link")?["href"].flatMap { url in
            URL(string: url, relativeTo: .baseURL)
        }
        let title = element.firstChild(css: ".video-title")?
            .childNodes(ofTypes: [.Text])
            .first?
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let loadedName = element.firstChild(css: ".event")?
            .firstChild(xpath: ".//text()")?
            .stringValue
        let tags = element.firstChild(css: ".focus")?
            .firstChild(xpath: ".//text()")?
            .stringValue
        let platforms = tags?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
        let duration = element.firstChild(css: ".video-duration")?
            .stringValue
        let numberFormat = FloatingPointFormatStyle<TimeInterval>()
        let strings = duration?.split(separator: ":") ?? []
        guard strings.count == 2, let minutes = strings.first, let seconds = strings.last else {
            throw Failure.badData
        }
        let minutesValue = try TimeInterval(String(minutes), format: numberFormat) * 60
        let secondsValue = try TimeInterval(String(seconds), format: numberFormat)
        let durationValue = minutesValue + secondsValue
        guard let url, let title, let eventName = loadedName ?? eventName else {
            throw Failure.badData
        }
        self = WWDCVideoFragment(
            title: title,
            eventName: eventName,
            platforms: platforms,
            url: url,
            duration: durationValue
        )
    }
}

extension Array where Element == WWDCVideoFragment {
    init(data: Data, eventName: String? = nil) throws {
        let document = try HTMLDocument(data: data)
        self = try document.css(".collection-item").map { element in
            try WWDCVideoFragment(element: element, eventName: eventName)
        }
    }
}
