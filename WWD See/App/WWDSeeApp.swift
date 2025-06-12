//
//  WWD_SeeApp.swift
//  WWD See
//
//  Created by Michael Skiba on 25/03/2025.
//

import SwiftUI
import Dependencies
import WWDCData
import SwiftData
import SharingGRDB
import IssueReporting

extension DependencyValues {
    public var syncManager: SyncManager? {
      get { self[SyncManagerKey.self] }
      set { self[SyncManagerKey.self] = newValue }
    }

    private enum SyncManagerKey: DependencyKey {
        static var liveValue: SyncManager? { nil }
    }
}

@main
struct WWDSeeApp: App {
    let modelContainer: ModelContainer
    let syncManager: SyncManager

    init() {
        do {
            let database = try DatabaseManager.prepareDatabase(
                fallback: NSDataAsset(name: "Data/db", bundle: .main),
                inMemory: false
            )
            modelContainer = try CloudKitConfig.prepareModelContainer()
            syncManager = SyncManager(database: database, modelContainer: modelContainer)
            prepareDependencies {
                $0.defaultDatabase = database
                $0.syncManager = syncManager
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
