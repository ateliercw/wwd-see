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
    let url: URL
    var category: Category!
    var watched: Bool = false
    var excluded: Bool = false

    init(name: String, url: URL) {
        self.url = url
        self.name = name
    }
}
