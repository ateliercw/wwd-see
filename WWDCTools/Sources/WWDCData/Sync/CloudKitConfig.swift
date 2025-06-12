//
//  CloudKitConfig.swift
//  WWDCTools
//
//  Created by Michael Skiba on 09/04/2025.
//
import Foundation
@preconcurrency import CoreData
import SwiftData

public enum CloudKitConfig {
    static let containerIdentifier = "iCloud.com.atelierclockwork.wwd-see-sessions"

    public static func prepareModelContainer() throws -> ModelContainer {
#if DEBUG
        // Use an autorelease pool to make sure Swift deallocates the persistent
        // container before setting up the SwiftData stack.
        try autoreleasepool {
            let config = ModelConfiguration(cloudKitDatabase: .private(self.containerIdentifier))
            let desc = NSPersistentStoreDescription(url: config.url)
            let opts = NSPersistentCloudKitContainerOptions(containerIdentifier: self.containerIdentifier)
            desc.cloudKitContainerOptions = opts
            // Load the store synchronously so it completes before initializing the
            // CloudKit schema.
            desc.shouldAddStoreAsynchronously = false
            if let mom = NSManagedObjectModel.makeManagedObjectModel(for: [WatchedState.self]) {
                let container = NSPersistentCloudKitContainer(name: "Watched", managedObjectModel: mom)
                container.persistentStoreDescriptions = [desc]
                container.loadPersistentStores {_, err in
                    if let err {
                        fatalError(err.localizedDescription)
                    }
                }
                // Initialize the CloudKit schema after the store finishes loading.
                try container.initializeCloudKitSchema()
                // Remove and unload the store from the persistent container.
                if let store = container.persistentStoreCoordinator.persistentStores.first {
                    let sema = DispatchSemaphore(value: 0)

                    DispatchQueue(label: "store removal").asyncAfter(
                        deadline: .now().advanced(by: .milliseconds(500))
                    ) { [store] in
                        do {
                            try container.persistentStoreCoordinator.remove(store)
                        } catch {
                            fatalError("Failed to remove store")
                        }
                        sema.signal()
                    }
                    sema.wait()
                }
            }
        }
#endif
        let config = ModelConfiguration(cloudKitDatabase: .private(self.containerIdentifier))
            return try ModelContainer(for: WatchedState.self, configurations: config)
    }
}
