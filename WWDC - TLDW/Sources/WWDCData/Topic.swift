import Foundation

public struct Topic: Hashable, Codable {
    public let name: String
    public let url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
