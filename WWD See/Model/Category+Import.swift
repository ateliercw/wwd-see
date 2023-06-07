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
            let category = Category(url: wrapper.topic.url, name: wrapper.topic.name)
            self.insert(object: category)
            for apiVideo in wrapper.videos {
                let videoPredicate = #Predicate<Video> { $0.url == apiVideo.url }
                var videoFetch = FetchDescriptor(predicate: videoPredicate)
                videoFetch.fetchLimit = 1
                if let video = (try? fetch(videoFetch))?.first {
                    video.categories.append(category)
                } else {
                    let video = Video(video: apiVideo)
                    video.categories.append(category)
                    self.insert(object: video)
                }
            }
        }
    }

    private enum Failure: Error {
        case noData
    }
}
