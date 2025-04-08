//
//  DatabaseManager.swift
//  WWDCTools
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB
import IssueReporting

public enum DatabaseManager {
    public static func prepareDatabase(inMemory: Bool = false) throws -> DatabaseWriter {
        let databaseWriter: DatabaseWriter = if inMemory {
            try DatabaseQueue(named: UUID().uuidString, configuration: Configuration())
        } else {
            try loadOrCreateDatabase()
        }
        do {
            try performMigrations(databaseWriter)
        } catch {
            reportIssue(error)
        }
        return databaseWriter
    }
}

private extension DatabaseManager {
    static func loadOrCreateDatabase() throws -> DatabaseWriter {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
        debugPrint(databaseURL)
        return try DatabaseQueue(path: databaseURL.path)
    }

    static func performMigrations(_ database: DatabaseWriter) throws {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true
        migrator.registerMigration("v1") { database in
            try V1Migrator.createTablesIn(database)
        }
        try migrator.migrate(database)
    }
}
