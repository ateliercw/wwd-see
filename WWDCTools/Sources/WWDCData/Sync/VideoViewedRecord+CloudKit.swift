//
//  VideoViewedRecord+CloudKit.swift
//  WWDCTools
//
//  Created by Michael Skiba on 09/04/2025.
//

import Foundation
import CloudKit
import IssueReporting

extension VideoViewedRecord {
    init(record: CKRecord) throws {
        guard let url = (record[CloudKitKeys.videoUrl.rawValue] as? String).flatMap(URL.init(string:)) else {
            throw Failure.noURL
        }

        self = VideoViewedRecord(
            videoUrl: url,
            ignored: record[CloudKitKeys.ignored.rawValue] as? Bool ?? false,
            ignoredUpdated: record[CloudKitKeys.ignoredUpdated.rawValue] as? Date,
            watchedDate: record[CloudKitKeys.watchedDate.rawValue] as? Date,
            watchedUpdated: record[CloudKitKeys.watchedUpdated.rawValue] as? Date
        )
    }

    var cloudKitID: CKRecord.ID {
        CKRecord.ID(
            recordName: videoUrl.absoluteString, zoneID
            : CKRecordZone.ID(zoneName: Self.zoneName)
        )
    }

    var record: CKRecord {
        let loadedRecord = syncRecord.flatMap { syncRecord in
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: syncRecord)
                unarchiver.requiresSecureCoding = true
                return CKRecord(coder: unarchiver)
            } catch {
                // Why would this happen? What could go wrong? 🔥
                reportIssue("Failed to decode local system fields record: \(error)")
                return nil
            }
        }
        let record = loadedRecord ?? CKRecord(
            recordType: Self.databaseTableName,
            recordID: cloudKitID
        )
        record.setValuesForKeys([
            CloudKitKeys.videoUrl.rawValue: videoUrl.absoluteString,
            CloudKitKeys.ignored.rawValue: ignored
        ])
        record.setValue(ignoredUpdated, forKey: CloudKitKeys.ignoredUpdated.rawValue)
        record.setValue(watchedDate, forKey: CloudKitKeys.watchedDate.rawValue)
        record.setValue(watchedUpdated, forKey: CloudKitKeys.watchedUpdated.rawValue)
        return record
    }

    mutating func merge(with record: CKRecord) {
        if let ignoredUpdated = record[CloudKitKeys.ignoredUpdated.rawValue] as? Date,
           let ignored = record[CloudKitKeys.ignored.rawValue] as? Bool {
            if ignoredUpdated > self.ignoredUpdated ?? .distantPast {
                self.ignoredUpdated = ignoredUpdated
                self.ignored = ignored
            }
        }
        if let watchedUpdated = record[CloudKitKeys.watchedUpdated.rawValue] as? Date {
            if watchedUpdated > self.watchedUpdated ?? .distantPast {
                self.watchedUpdated = watchedUpdated
                self.watchedDate = record[CloudKitKeys.watchedDate.rawValue] as? Date
            }
        }
        // if the new record is newer, store that
        if (record.modificationDate ?? .distantPast) >
            (self.record.modificationDate ?? .distantPast) {
            let coder = NSKeyedArchiver(requiringSecureCoding: true)
            record.encode(with: coder)
            syncRecord = coder.encodedData
        }
    }

    private enum CloudKitKeys: String {
        case videoUrl
        case ignored
        case ignoredUpdated
        case watchedDate
        case watchedUpdated
    }

    private enum Failure: Error {
        case noURL
    }
}
