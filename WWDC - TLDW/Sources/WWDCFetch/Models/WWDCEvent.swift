//
//  WWDCEvent.swift
//  WWDC 2023
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Fuzi

public struct WWDCEvent: Codable, Identifiable, Hashable {
    public var id: Self { self }

    public let name: String
    public let url: URL
    public let fragments: [WWDCVideoFragment]
}

extension WWDCEvent {
    public init(url: URL, data: Data) throws {
        let document = try HTMLDocument(data: data)
        let name = document.firstChild(css: ".collection-title")?
            .firstChild(xpath: ".//text()")?
            .stringValue
        guard let name else {
            throw Failure.badData
        }
        let fragments = try [WWDCVideoFragment](data: data, eventName: name)
        self = .init(
            name: name,
            url: url,
            fragments: fragments
        )
    }
}
