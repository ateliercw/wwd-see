import Foundation

public struct Video: Hashable, Codable {
    public let name: String
    public let url: URL
    public let focus: [String]

    public init(name: String, url: URL, focus: [String]) {
        self.name = name
        self.url = url
        self.focus = focus
    }
}
