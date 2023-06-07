//
//  Video.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation
import SwiftData

@Model
final class Video {
    var id: URL { url }
    let name: String
    @Attribute(.unique) let url: URL
    var categories: [Category]
    var watched: Bool = false
    var excluded: Bool = false

    var included: Bool { !excluded }

    init(name: String, url: URL) {
        self.url = url
        self.name = name
    }
}
