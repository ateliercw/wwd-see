//
//  TopicSelection.swift
//  WWD See
//
//  Created by Michael Skiba on 16/04/2025.
//

import Foundation
import WWDCData

enum TopicWrapper: Hashable, Identifiable {
    var id: Self { self }

    case all
    case topic(TopicRecord)

    var topic: TopicRecord? {
        switch self {
        case .topic(let topic):
            return topic
        default:
            return nil
        }
    }

    init(topic: TopicRecord?) {
        self = topic.map(Self.topic) ?? .all
    }
}

typealias TopicSelectionTag = TopicWrapper
#if os(macOS)
typealias TopicSelection = TopicWrapper

extension TopicSelection {
    static var defaultValue: Self {
        .all
    }
}
#else
typealias TopicSelection = TopicWrapper?

extension Optional where Wrapped == TopicWrapper {
    var topic: TopicRecord? {
        self?.topic
    }

    static var defaultValue: Self {
        .none
    }

    init(topic: TopicRecord?) {
        self = TopicWrapper(topic: topic)
    }
}
#endif
