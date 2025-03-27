//
//  DataAsset.swift
//  WWD See
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import SwiftUI

enum DataAsset {
    enum Event {
        static var wwdc14: Data! { NSDataAsset(name: "Data/Event/wwdc14")?.data }
        static var wwdc15: Data! { NSDataAsset(name: "Data/Event/wwdc15")?.data }
        static var wwdc16: Data! { NSDataAsset(name: "Data/Event/wwdc16")?.data }
        static var wwdc17: Data! { NSDataAsset(name: "Data/Event/wwdc17")?.data }
        static var wwdc18: Data! { NSDataAsset(name: "Data/Event/wwdc18")?.data }
        static var wwdc19: Data! { NSDataAsset(name: "Data/Event/wwdc19")?.data }
        static var wwdc20: Data! { NSDataAsset(name: "Data/Event/wwdc20")?.data }
        static var wwdc21: Data! { NSDataAsset(name: "Data/Event/wwdc21")?.data }
        static var wwdc22: Data! { NSDataAsset(name: "Data/Event/wwdc22")?.data }
        static var wwdc23: Data! { NSDataAsset(name: "Data/Event/wwdc23")?.data }
        static var wwdc24: Data! { NSDataAsset(name: "Data/Event/wwdc24")?.data }
        static var techTalks: Data! { NSDataAsset(name: "Data/Event/tech_talks")?.data }

        static var all: [Data] {
            [
                wwdc14,
                wwdc15,
                wwdc16,
                wwdc17,
                wwdc18,
                wwdc19,
                wwdc20,
                wwdc21,
                wwdc22,
                wwdc23,
                wwdc24,
                techTalks
            ]
        }
    }
}
