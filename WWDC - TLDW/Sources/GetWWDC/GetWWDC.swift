import Foundation
import ArgumentParser
import SwiftHTMLParser
import TabularData
import WWDCData

extension URL {
    static let baseURL: URL! = URL(string: "https://developer.apple.com")
    static let topicsURL: URL! = URL(string: "/videos/topics", relativeTo: baseURL)
}

@main
struct GetWWDC: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for getting WWDC session data.",

        version: "0.0.1"
    )

    mutating func run() async throws {
        do {
            try FileManager.default.createDirectory(at: URL.currentDirectory().appending(path: "csv"),
                                                    withIntermediateDirectories: false)
        } catch {}

        var allTopics = [CompleteTopic]()
        for topic in try await Topic.fetchAll() {
            let videos = try await Video.fetchAll(in: topic)
            allTopics.append(CompleteTopic(topic: topic, videos: videos))
            let names = Column(name: "Name", contents: videos.map(\.name))
                .eraseToAnyColumn()
            let urls = Column(name: "URL", contents: videos.map(\.url).map(\.absoluteString))
                .eraseToAnyColumn()
            let focuses = Column(name: "Focuses", contents: videos.map(\.focus).map { $0.joined(separator: ", ") })
                .eraseToAnyColumn()
            let chart = DataFrame(columns: [names, urls, focuses])
            try chart.writeCSV(to: URL.currentDirectory().appending(path: "csv/\(topic.name).csv"))
        }
        print(URL.currentDirectory().absoluteString)
        let encoder = JSONEncoder()
        let data = try encoder.encode(allTopics)
        if !FileManager.default.fileExists(atPath: URL.currentDirectory().appending(path: "json/").absoluteString) {
           try FileManager.default.createDirectory(at: URL.currentDirectory().appending(path: "json/"), withIntermediateDirectories: true)
        }
        try data.write(to: URL.currentDirectory().appending(path: "json/events.json"))
    }
}

private extension FileManager {
    var currentURL: URL! {
        URL(string: currentDirectoryPath)
    }
}

enum Failure: Error {
    case unimplemented
    case failedToCreateString
    case badData
}
