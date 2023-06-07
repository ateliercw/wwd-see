//
//  WWDSeeApp.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI
import SwiftData

@main
struct WWDSeeApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Category.self, Video.self])
    }
}
