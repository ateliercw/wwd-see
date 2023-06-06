//
//  Category+Import.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation
import SwiftData
#if os(iOS)
import UIKit.NSDataAsset
#elseif os(macOS)
import AppKit
#endif
import WWDCData

extension Video {
    convenience init(video: WWDCData.Video) {
        self.init(name: video.name, url: video.url)
    }
}

extension ModelContext {
    func loadStoredCategories() throws {
        guard let rawData = NSDataAsset(name: "Data/events")?.data else {
            throw Failure.noData
        }
        let completedTopics = try JSONDecoder().decode([CompleteTopic].self, from: rawData)
        for wrapper in completedTopics {
            let videos = wrapper.videos.map(Video.init)
            let category = Category(url: wrapper.topic.url, name: wrapper.topic.name, videos: videos)
            self.insert(object: category)
            for video in category.videos {
                video.category = category
                self.insert(object: video)
            }
        }
    }

    private enum Failure: Error {
        case noData
    }
}
