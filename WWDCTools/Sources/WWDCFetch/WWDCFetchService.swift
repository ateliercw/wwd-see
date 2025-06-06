import Foundation
import WWDCData
import Dependencies
import Fuzi

public enum WWDCFetchService {
    private static var session: URLSession {
        Dependency(\.urlSession).wrappedValue
    }

    public static func fetchAllTopics() async throws -> [WWDCTopic] {
        let (data, _) = try await session.data(from: .topicsURL)
        return try await [WWDCTopic](data: data)
    }

    public static func fetchAllEvents(for topics: [WWDCTopic]) async throws -> [WWDCEvent] {
        let eventNames = Set(topics.flatMap(\.fragments).map(\.eventName))
            .map(\.localizedLowercase)
            .map { string in
                string
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "wwdc", with: "wwdc20")
            }
        return try await withThrowingTaskGroup(of: WWDCEvent.self) { group in
            for eventName in eventNames {
                guard let eventURL = URL(string: "videos/\(eventName)", relativeTo: .baseURL) else {
                    throw Failure.badData
                }
                group.addTask {
                    return try await WWDCEvent(url: eventURL)
                }
            }
            var results = [WWDCEvent]()
            while let result = try await group.next() {
                results.append(result)
            }
            return results.sorted { lhs, rhs in
                if lhs.name == "Tech Talks" {
                    false
                } else if rhs.name == "Tech Talks" {
                    true
                } else {
                    lhs.name < rhs.name
                }
            }
        }
    }

    public static func fetchVideo(fragment: WWDCVideoFragment) async throws -> WWDCVideo {
        let (data, _) = try await session.data(from: fragment.url)
        return try WWDCVideo(fragment: fragment, data: data)
    }
}
