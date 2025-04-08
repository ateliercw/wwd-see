//
//  WWDCApiService.swift
//  WWDCTools
//
//  Created by Michael Skiba on 08/04/2025.
//

import Foundation
import Dependencies

public enum WWDCApiService {
    private static let baseURL: URL! = URL(string: "https://atelierclockwork.net/wwd-see/")
    private static let decoder = JSONDecoder()

    public static func fetchEventURLs() async throws -> [URL] {
        let eventsURL: URL! = URL.init(string: "events.json", relativeTo: baseURL)
        let session = Dependency(\.urlSession).wrappedValue
        let (data, _) = try await session.data(from: eventsURL)
        let eventNames = try decoder.decode([String].self, from: data)
        return eventNames.compactMap {
            URL(string: $0, relativeTo: baseURL)
        }
    }

    public static func loadEvent(_ url: URL) async throws -> EventContainer {
        let session = Dependency(\.urlSession).wrappedValue
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(EventContainer.self, from: data)
    }
}
