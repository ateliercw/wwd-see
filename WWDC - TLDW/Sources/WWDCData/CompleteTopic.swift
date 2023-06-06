//
//  CompleteTopic.swift
//
//
//  Created by Michael Skiba on 06/06/2023.
//

import Foundation

public struct CompleteTopic: Codable {
    public let topic: Topic
    public let videos: [Video]
}
