//
//  WWDCEvent.swift
//  WWDCTools
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation
import Fuzi
import Dependencies

public struct WWDCEvent: Codable, Identifiable, Hashable, Sendable {
    public var id: Self { self }

    public let name: String
    public let url: URL
    public let fragments: [WWDCVideoFragment]
}

extension WWDCEvent {
    init(url: URL) async throws {
        let (data, _) = try await Dependency(\.urlSession).wrappedValue.data(from: url)
        let document = try HTMLDocument(data: data)
        let name = document.firstChild(css: ".collection-title")?
            .firstChild(xpath: ".//text()")?
            .stringValue
        guard let name else {
            throw Failure.badData
        }
        self.name = name
        self.url = url
        let fragmentNodes = document.css(".vc-card")
        self.fragments = try fragmentNodes.map {
            try WWDCVideoFragment.init(element: $0, event: name)
        }
    }
}
