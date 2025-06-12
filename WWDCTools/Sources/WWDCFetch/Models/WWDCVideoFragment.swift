//
//  WWDCVideoFragment.swift
//  WWDCTools
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Fuzi

public struct WWDCVideoFragment: Codable, Identifiable, Hashable, Sendable {
    public var id: Self { self }
    public let title: String
    public let eventName: String
    public let url: URL
    public let duration: TimeInterval
}

extension WWDCVideoFragment {
    init(element: Fuzi.XMLElement, event: String? = nil) throws {
        let title = element.firstChild(css: ".vc-card__title")?
            .firstChild(xpath: ".//text()")?
            .stringValue
        let eventName = event ?? element.firstChild(css: ".vc-card__tag--event")?
            .firstChild(xpath: ".//text()")?
            .stringValue
        let duration = try (element.firstChild(css: ".vc-card__duration")?
            .firstChild(xpath: ".//text()")?
            .stringValue)
            .map(TimeInterval.init(durationText:))
        let url = element["href"].flatMap { url in
            URL(string: url, relativeTo: .baseURL)
        }
        guard let title, let eventName, let duration, let url else { throw Failure.badData
        }
        self.title = title
        self.eventName = eventName
        self.duration = duration
        self.url = url
    }
}

private extension TimeInterval {
    init(durationText: String) throws {
        let numberFormat = FloatingPointFormatStyle<TimeInterval>()
        let strings = durationText.split(separator: ":")
        guard strings.count == 2, let minutes = strings.first, let seconds = strings.last else {
            throw Failure.badData
        }
        let minutesValue = try TimeInterval(String(minutes), format: numberFormat) * 60
        let secondsValue = try TimeInterval(String(seconds), format: numberFormat)
        self = minutesValue + secondsValue
    }
}
