//
//  File.swift
//  WWDCTools
//
//  Created by Michael Skiba on 24/03/2025.
//

import Foundation

extension URL {
    static let baseURL: URL! = URL(string: "https://developer.apple.com")
    static let topicsURL: URL! = URL(string: "/videos/topics", relativeTo: baseURL)
}
