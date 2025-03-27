//
//  V1Migrator.swift
//  WWDC 2023
//
//  Created by Michael Skiba on 25/03/2025.
//

import Foundation
import GRDB

enum V1Migrator {
    static func createTablesIn(_ database: Database) throws {
        try createEventTableIn(database)
        try createTopicTableIn(database)
        try createVideoTableIn(database)
        try createVideoTopicTableIn(database)
        try createVideoViewedTableIn(database)
    }
}

// MARK: - V1 Base Tables
private extension V1Migrator {
     static func createEventTableIn(_ database: Database) throws {
         try database.create(table: "event") { table in
             table.column("name", .text)
                 .notNull()
             table.column("url", .text)
                 .notNull()
                 .indexed()
                 .primaryKey(onConflict: .replace)
         }
     }

     static func createTopicTableIn(_ database: Database) throws {
         try database.create(table: "topic") { table in
             table.column("name", .text)
                 .notNull()
             table.column("url", .text)
                 .notNull()
                 .indexed()
                 .primaryKey(onConflict: .replace)
             table.column("icon", .text)
                 .notNull()
         }
     }

     static func createVideoTableIn(_ database: Database) throws {
         try database.create(table: "video") { table in
             table.column("title", .text)
                 .notNull()
             table.column("url", .text)
                 .indexed()
                 .notNull()
                 .primaryKey(onConflict: .replace)
             table.column("sortValue", .integer)
                 .indexed()
                 .notNull()
             table.column("datePublished", .date)
                 .notNull()
             table.column("platforms", .jsonText)
                 .notNull()
                 .defaults(to: "[]")
             table.column("duration", .numeric)
                 .notNull()
             table.column("summary", .text)
                 .notNull()
             table.belongsTo(
                "event",
                onDelete: .cascade
             )
         }
     }

     static func createVideoViewedTableIn(_ database: Database) throws {
         try database.create(table: "videoViewed") { table in
             table.column("ignored", .boolean)
                 .defaults(to: false)
                 .notNull()
             table.column("watchedDate")
             table.belongsTo(
                "video",
                onDelete: .cascade
             )
             .unique()
             table.primaryKey(["videoUrl"])
         }
     }

     static func createVideoTopicTableIn(_ database: Database) throws {
         try database.create(table: "videoTopic") { table in
             table.belongsTo("video", onDelete: .cascade)
             table.belongsTo("topic", onDelete: .cascade)
             table.primaryKey(["videoUrl", "topicUrl"])
         }
     }
}
