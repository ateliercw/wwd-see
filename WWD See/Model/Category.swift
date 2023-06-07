//
//  Category.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: URL { url }
    @Attribute(.unique) let url: URL
    let name: String
    @Relationship(inverse: \Video.categories) var videos: [Video]

    init(url: URL, name: String, videos: [Video]? = nil) {
        self.url = url
        self.name = name
        self.videos = videos ?? []
    }
}

extension Category {
    var viewedCount: Int {
        videos.filter { !$0.excluded }.filter(\.watched).count
    }

    var toWatchCount: Int {
        videos.filter { !$0.excluded }.count
    }
}
