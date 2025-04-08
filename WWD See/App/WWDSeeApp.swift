//
//  WWD_SeeApp.swift
//  WWD See
//
//  Created by Michael Skiba on 25/03/2025.
//

import SwiftUI
import Dependencies
import WWDCData
import SharingGRDB
import IssueReporting

@main
struct WWDSeeApp: App {
    init() {
        prepareDependencies {
            do {
                $0.defaultDatabase = try DatabaseManager.prepareDatabase(
                    fallback: NSDataAsset(name: "Data/db", bundle: .main),
                    inMemory: false
                )
            } catch {
                reportIssue(error)
                fatalError("Failed to create the default database")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
