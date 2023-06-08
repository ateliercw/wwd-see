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
    var isFiltered: Bool = false
    @Relationship(inverse: \Video.categories) var videos: [Video]

    var isVisible: Bool {
        get { !isFiltered }
        set { isFiltered = !newValue }
    }

    init(url: URL, name: String, isFiltered: Bool = false, videos: [Video]? = nil) {
        self.url = url
        self.name = name
        self.isFiltered = isFiltered
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
