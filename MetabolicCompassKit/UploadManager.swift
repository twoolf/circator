//
//  ReplicationManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import GameplayKit
import MCCircadianQueries
import Realm
import RealmSwift
import Async
import Granola
import SwiftDate
import SwiftyUserDefaults

// Sorted array helpers.
// From http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array/33674192#33674192

public extension CollectionType where Index: RandomAccessIndexType {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: Generator.Element -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = low.advancedBy(low.distanceTo(high) / 2)
            if predicate(self[mid]) {
                low = mid.advancedBy(1)
            } else {
                high = mid
            }
        }
        return low
    }
}

public extension Array {
    func splitBy(size: Int) -> [[Element]] {
        return 0.stride(to: self.count, by: size).map { startIndex in
            let endIndex = startIndex.advancedBy(size, limit: self.count)
            return Array(self[startIndex ..< endIndex])
        }
    }
}

// Constants
let remoteLogSeqKey = "ios_log"
let remoteLogSeqIdKey = "seq_id"
let remoteLogSeqDataKey = "seq_data"

let remoteSyncSeqIdKey = "seq_id"

// Randomized, truncated exponential backoff constants

public let retryPeriodBase = 300
public let maxBackoffExponent = 7
public let maxBackoff = (2 << maxBackoffExponent) * retryPeriodBase
public let maxRetries = 10

public let uploadBlockSize = 100
public let uploadBufferThrottleLimit = 1000

private let HMAnchorKey      = DefaultsKey<[String: AnyObject]?>("HKClientAnchorKey")
private let HMAnchorTSKey    = DefaultsKey<[String: AnyObject]?>("HKAnchorTSKey")

public let syncNotificationLimit = 100
public let SyncBeganNotification = "SyncBeganNotification"
public let SyncEndedNotification = "SyncEndedNotification"
public let SyncProgressNotification = "SyncProgressNotification"

public class UMLogSequenceNumber: Object {
    public dynamic var msid = String()
    public dynamic var seqid: Int = 0

    public convenience init(type: HKSampleType) {
        self.init()
        self.msid = type.identifier
        self.seqid = 0
    }

    public convenience init(type: HKSampleType, seqNumber: Int) {
        self.init()
        self.msid = type.identifier
        self.seqid = seqNumber
    }

    public override static func primaryKey() -> String? {
        return "msid"
    }

    public func incr() -> Int { seqid += 1; return seqid-1 }
}

public class UMSampleUUID: Object {
    dynamic var uuid = NSData()
    public convenience init(insertion: HKObject) {
        self.init()
        self.uuid = UMSampleUUID.nsDataOfUUID(insertion.UUID)
    }

    public convenience init(deletion: HKDeletedObject) {
        self.init()
        self.uuid = UMSampleUUID.nsDataOfUUID(deletion.UUID)
    }

    public static func nsDataOfUUID(uuid: NSUUID) -> NSData {
        var uuidBytes: [UInt8] = [UInt8](count: 16, repeatedValue: 0)
        uuid.getUUIDBytes(&uuidBytes)
        return NSData(bytes: &uuidBytes, length: 16)
    }

    public static func uuidOfNSData(data: NSData) -> NSUUID {
        return NSUUID(UUIDBytes: UnsafePointer<UInt8>(data.bytes))
    }
}

public class UMLogEntry: Object {
    public dynamic var id: Int = 0
    public dynamic var msid = String()
    public dynamic var ts = NSDate()
    public dynamic var anchor = NSData()

    let insert_uuids = List<UMSampleUUID>()
    let delete_uuids = List<UMSampleUUID>()

    public dynamic var retry_ts = NSDate()
    public dynamic var retry_count: Int = 1

    // Note: because we may add a LSN for this type, this initializer must be called in a write block.
    public convenience init(realm: Realm!, sampleType: HKSampleType, ts: NSDate = NSDate(), anchor: HKQueryAnchor, added: [HKSample], deleted: [HKDeletedObject]) {
        self.init()

        self.id = self.incrSequenceNumberForType(realm, sampleType: sampleType)
        self.msid = sampleType.identifier
        self.ts = ts
        self.anchor = UploadManager.sharedManager.encodeRemoteAnchorAsData(anchor)
        self.insert_uuids.appendContentsOf(added.map { return UMSampleUUID(insertion: $0) })
        self.delete_uuids.appendContentsOf(deleted.map { return UMSampleUUID(deletion: $0) })
        self.retry_ts = NSDate() + retryPeriodBase.seconds
        self.compoundKey = compoundKeyValue()
        log.info("Created UMLogEntry")
        self.logEntry()
    }

    public static func initSequenceNumberForType(realm: Realm!, sampleType: HKSampleType, seqNumber: Int) {
        let seq = UMLogSequenceNumber(type: sampleType, seqNumber: seqNumber)
        realm.add(seq, update: true)
    }

    public static func sequenceNumberForType(realm: Realm!, sampleType: HKSampleType) -> UMLogSequenceNumber? {
        return realm.objectForPrimaryKey(UMLogSequenceNumber.self, key: sampleType.identifier)
    }

    public func incrSequenceNumberForType(realm: Realm!, sampleType: HKSampleType) -> Int {
        if let seq = UMLogEntry.sequenceNumberForType(realm, sampleType: sampleType) {
            return seq.incr()
        } else {
            let seq = UMLogSequenceNumber(type: sampleType)
            realm.add(seq)
            return seq.incr()
        }
    }

    public func setMSID(sampleType: HKSampleType) {
        self.msid = sampleType.identifier
        self.compoundKey = compoundKeyValue()
    }

    public func setTS(ts: NSDate = NSDate()) {
        self.ts = ts
        self.compoundKey = compoundKeyValue()
    }

    public dynamic var compoundKey: String = ""

    public func compoundKeyValue() -> String {
        return "\(ts.timeIntervalSince1970)\(msid)"
    }

    public override static func primaryKey() -> String? {
        return "compoundKey"
    }

    public func logEntry() {
        log.info("id:\(self.id)")
        log.info("msid:\(self.msid)")
        log.info("ts:\(self.ts.timeIntervalSince1970)")
        //log.info("anchor:\(self.anchor.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))")
        log.info("insert_uuids:\(self.insert_uuids.count)")
        log.info("delete_uuids:\(self.delete_uuids.count)")
        //log.info("retry_ts:\(self.retry_ts)")
        //log.info("retry_count:\(self.retry_count)")
    }

    public func logEntryCompact() {
        log.info("id:\(self.id)")
        log.info("msid:\(self.msid)")
        log.info("ts:\(self.ts.timeIntervalSince1970)")
        log.info("retry_count:\(self.retry_count)")
    }

}

public class UploadManager: NSObject {
    public static let sharedManager: UploadManager = UploadManager()

    // Random number generation
    let rng = GKARC4RandomSource(seed: "1234".dataUsingEncoding(NSUTF8StringEncoding)!)
    let rngSource = GKRandomDistribution(lowestValue: 1, highestValue: maxBackoff)

    // Custom upload task queue
    let uploadQueue: dispatch_queue_t!

    // Granola serializer
    public static let serializer = OMHSerializer()

    // A buffer for creating batches of log entries prior to transmission.
    // Each element is a UMLogEntry primary key, an array of samples added, and an array of sample uuids deleted.
    // This is maintained as a sorted array on the UMLogEntry primary key.
    var logEntryBatchBuffer: [(String, [HKSample], [NSUUID])] = []

    // Log entry upload configuration.
    var logEntryUploadBatchSize: Int = 10
    var logEntryUploadAsync: Async? = nil
    var logEntryUploadDelay: Double = 0.5

    // Sync notification state.
    var syncMode: Bool = false

    // Device sync.
    var deviceSync: Async? = nil

    public override init() {
        self.uploadQueue = dispatch_queue_create("UploadQueue", DISPATCH_QUEUE_SERIAL)
        super.init()
    }

    // MARK: - initialize uploads.

    public func resetUploadManager() {
        log.info("Upload Manager state before reset")
        logMetadata()

        let realm = try! Realm()
        try! realm.write {
            // Initialize sequence numbers based on remote values.
            let seqs = UserManager.sharedManager.getAcquisitionSeq()

            if seqs.isEmpty {
                log.warning("Skipping initsync, no remote seqnos found")
            }

            for (type, deviceData) in seqs {
                if let deviceInfo = deviceData as? [String:AnyObject],
                       seqForIOS = deviceInfo[remoteLogSeqKey] as? [String: AnyObject],
                       seqInfo = seqForIOS["0"] as? [String: AnyObject],
                       remoteSeqNum = seqInfo[remoteLogSeqIdKey] as? Int
                {
                    var doInit = false
                    var onDeviceSeq = 0
                    let nextSeqNum = remoteSeqNum + 1

                    if let seq = UMLogEntry.sequenceNumberForType(realm, sampleType: type) {
                        doInit = seq.seqid < nextSeqNum
                        onDeviceSeq = seq.seqid
                    } else {
                        doInit = true
                    }

                    if doInit {
                        log.warning("Initsync seq for \(type.identifier): \(nextSeqNum)")
                        UMLogEntry.initSequenceNumberForType(realm, sampleType: type, seqNumber: nextSeqNum)
                    } else {
                        log.warning("Skipping initsync seq for \(type.identifier) (found \(onDeviceSeq) on device vs \(remoteSeqNum) remotely)")
                    }
                } else {
                    log.warning("Skipping initsync seq for \(type.identifier) (no remote seq found)")
                }
            }

            // Clean log entries.
            for logEntry in realm.objects(UMLogEntry.self) {
                if logEntry.insert_uuids.count > uploadBlockSize || logEntry.delete_uuids.count > uploadBlockSize {
                    log.warning("Clearing log entry")
                    logEntry.logEntry()
                    realm.delete(logEntry)
                }
            }
        }

        log.info("Upload Manager state after reset")
        logMetadata()
    }

    public func logMetadata() {
        let realm = try! Realm()

        realm.objects(UMLogSequenceNumber.self).forEach { seqno in
            log.info("SEQ msid: \(seqno.msid) id: \(seqno.seqid)")
        }


        realm.objects(UMLogEntry.self).forEach { logEntry in
            logEntry.logEntry()
        }
    }

    // MARK: - Remote encoding helpers.

    public func encodeRemoteAnchorAsData(anchor: HKQueryAnchor) -> NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(anchor)
    }

    public func encodeRemoteAnchor(anchor: HKQueryAnchor) -> String {
        return encodeRemoteAnchorAsData(anchor).base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    public func decodeRemoteAnchorFromData(remoteAnchor: NSData) -> HKQueryAnchor? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(remoteAnchor) as? HKQueryAnchor
    }

    public func decodeRemoteAnchor(remoteAnchor: String) -> HKQueryAnchor? {
        if let encodedAnchor = NSData(base64EncodedString: remoteAnchor, options: NSDataBase64DecodingOptions(rawValue: 0)) {
            return decodeRemoteAnchorFromData(encodedAnchor)
        }
        return nil
    }

    // MARK: - Anchor metadata accessors

    // Setter and getter for the anchor object returned by HealthKit, as stored in user defaults.
    public func getAnchorForType(type: HKSampleType) -> HKQueryAnchor {
        if let anchorDict = Defaults[HMAnchorKey] {
            if let encodedAnchor = anchorDict[type.identifier] as? NSData {
                return NSKeyedUnarchiver.unarchiveObjectWithData(encodedAnchor) as! HKQueryAnchor
            }
        }
        return noAnchor
    }

    public func setAnchorForType(anchor: HKQueryAnchor, forType type: HKSampleType) {
        let encodedAnchor = NSKeyedArchiver.archivedDataWithRootObject(anchor)
        if !Defaults.hasKey(HMAnchorKey) {
            Defaults[HMAnchorKey] = [type.identifier: encodedAnchor]
        } else {
            Defaults[HMAnchorKey]![type.identifier] = encodedAnchor
        }
        Defaults.synchronize()
    }

    public func getRemoteAnchorForType(type: HKSampleType) -> HKQueryAnchor? {
        if let deviceInfo = UserManager.sharedManager.getAcquisitionSeq(type) as? [String:AnyObject]
        {
            if let seqForIOS = deviceInfo[remoteLogSeqKey] as? [String: AnyObject],
                   seqInfo = seqForIOS["0"] as? [String: AnyObject],
                   remoteAnchor = seqInfo[remoteLogSeqDataKey] as? String
            {
                return decodeRemoteAnchor(remoteAnchor)
            } else {
                log.warning("ULM Invalid seq fields for remote anchor decode on \(type.identifier)")
            }
        } else {
            log.warning("ULM Invalid seq dict for remote anchor decode on \(type.identifier)")
        }
        return nil
    }

    public func resetAnchors() {
        HMConstants.sharedInstance.healthKitTypesToObserve.forEach { type in
            self.setAnchorForType(noAnchor, forType: type)
        }
    }

    public func getNextAnchor(type: HKSampleType) -> (Bool, HKQueryAnchor?, NSPredicate?) {
        var remoteAnchor = false
        var needOldestSamples = false
        var anchor = getAnchorForType(type)
        var predicate : NSPredicate? = nil

        let tname = type.displayText ?? type.identifier

        // When initializing an anchor query, apply a predicate to limit the initial results.
        // If we already have a historical range, we filter samples to the current timestamp.
        if anchor == noAnchor
        {
            // We use anchors stored in the remote profile if available,
            // to grab all data since the last anchor uploaded to the server.
            if let anchorForType = getRemoteAnchorForType(type) {
                // We have a remote anchor available, and do not use a temporal predicate.
                anchor = anchorForType
                remoteAnchor = true
                log.info("Data import from anchor \(anchor): \(tname)")
            }
            else if let (_, hend) = UserManager.sharedManager.getHistoricalRangeForType(type) {
                // We have no server anchor available.
                // Here, we upload all samples between the end of the historical range (i.e., when the
                // app was first run on the device), to a point in the near future.
                let nearFuture = 1.minutes.fromNow
                let pstart = NSDate(timeIntervalSinceReferenceDate: hend)
                predicate = HKQuery.predicateForSamplesWithStartDate(pstart, endDate: nearFuture, options: .None)
                log.info("Data import from \(pstart) \(nearFuture): \(tname)")
            }
            else {
                // We have no anchor or archive span available.
                // We consider this the first run of the app on this device, and initialize the historical range
                // (i.e., the archive span).
                // This captures how much data is available on the device prior to using our app.
                let (start, end) = UserManager.sharedManager.initializeHistoricalRangeForType(type, sync: true)
                let (dstart, dend) = (NSDate(timeIntervalSinceReferenceDate: start), NSDate(timeIntervalSinceReferenceDate: end))
                predicate = HKQuery.predicateForSamplesWithStartDate(dstart, endDate: dend, options: .None)
                needOldestSamples = true
                log.info("Initialized historical range for \(tname): \(dstart) \(dend)")

            }
        }

        log.info("Anchor for \(tname)(\(remoteAnchor)): \(anchor)")
        return (needOldestSamples, anchor, predicate)
    }

    // MARK: - Upload helpers.

    public func jsonifySample(sample : HKSample) throws -> [String : AnyObject] {
        return try UploadManager.serializer.dictForSample(sample)
    }

    public func jsonifyLogEntry(logEntry: UMLogEntry, added: [HKSample], deleted: [NSUUID]) -> [String:AnyObject]? {
        var addedJson: [[String:AnyObject]] = []
        do {
            addedJson = try added.map(self.jsonifySample)
        } catch let error {
            log.error(error)
            return nil
        }

        let seqInfo: [String: AnyObject] = [
            remoteLogSeqIdKey   : logEntry.id,
            remoteLogSeqDataKey : logEntry.anchor.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        ]

        let deviceInfo: [String: AnyObject] = [
            remoteLogSeqKey: (["0": seqInfo] as AnyObject)
        ]

        let commands: [String:AnyObject] = [
            "inserts": addedJson,
            "deletes": deleted.map { return ["uuid": $0.UUIDString] }
        ]

        var measures: [String] = []
        if let measureSeqId = seqIdOfSampleTypeId(logEntry.msid) {
            measures = [measureSeqId]
        } else {
            log.error("ULM No MCDB seq id found for \(logEntry.msid)")
            return nil
        }

        return [
            "seq": deviceInfo,
            "measures": measures,
            "commands": commands
        ]
    }

    public func putSample(jsonObj: [String: AnyObject]) -> () {
        Service.string(MCRouter.AddMeasures(jsonObj), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.info("Upload: \(result.value)")
        }
    }

    public func putBlockSample(jsonObjBlock: [[String:AnyObject]]) -> () {
        Service.string(MCRouter.AddMeasures(["block":jsonObjBlock]), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.info("Upload: \(result.value)")
        }
    }

    public func putSample(type: HKSampleType, added: [HKSample]) {
        do {
            let tname = type.displayText ?? type.identifier
            log.info("Uploading \(added.count) \(tname) samples")

            let blockSize = 100
            let totalBlocks = ((added.count / blockSize)+1)
            if ( added.count > 20 ) {
                for i in 0..<totalBlocks {
                    autoreleasepool { _ in
                        do {
                            log.info("Uploading block \(i) / \(totalBlocks)")
                            let jsonObjs = try added[(i*blockSize)..<(min((i+1)*blockSize, added.count))].map(self.jsonifySample)
                            self.putBlockSample(jsonObjs)
                        } catch {
                            log.error(error)
                        }
                    }
                }
            } else {
                let jsons = try added.map(self.jsonifySample)
                jsons.forEach(self.putSample)
            }
        } catch {
            log.error(error)
        }
    }

    public func retryPendingUploads(force: Bool = false) {
        // Dispatch retries based on the persistent pending list
        let now = NSDate()
        let realm = try! Realm()

        for logEntry in realm.objects(UMLogEntry.self).filter({ return (force || $0.retry_ts < now) }) {
            log.info("Retrying pending upload")
            logEntry.logEntryCompact()

            let entryKey: String = logEntry.compoundKey
            var sampleType: HKSampleType! = nil

            switch logEntry.msid {
            case HKCategoryTypeIdentifierSleepAnalysis, HKCategoryTypeIdentifierAppleStandHour:
                sampleType = HKObjectType.categoryTypeForIdentifier(logEntry.msid)

            case HKCorrelationTypeIdentifierBloodPressure:
                sampleType = HKObjectType.correlationTypeForIdentifier(logEntry.msid)

            case HKWorkoutTypeIdentifier:
                sampleType = HKObjectType.workoutType()

            default:
                sampleType = HKObjectType.quantityTypeForIdentifier(logEntry.msid)
            }

            if let type = sampleType {
                let uuids = Set(logEntry.insert_uuids.map { return UMSampleUUID.uuidOfNSData($0.uuid) })
                let deleted: [NSUUID] = logEntry.delete_uuids.map { return UMSampleUUID.uuidOfNSData($0.uuid) }

                log.info("Retry upload invoking fetchSamplesByUUID for \(entryKey)")

                MCHealthManager.sharedManager.fetchSamplesByUUID(type, uuids: uuids) { (samples, error) in
                    // We need a new Realm instance since this completion will execute in a different thread
                    // than the realm instance outside the above loop.
                    log.info("Retry upload in fetchSamplesByUUID completion for \(entryKey)")
                    let realm = try! Realm()
                    if error != nil {
                        log.error(error)
                        // Refetch the obejct since we are in a background thread from the health manager.
                        if let logEntry = realm.objectForPrimaryKey(UMLogEntry.self, key: entryKey) {
                            try! realm.write {
                                realm.delete(logEntry)
                            }
                        } else {
                            log.warning("No realm object found for deleting \(entryKey)")
                        }
                    } else {
                        if let logEntry = realm.objectForPrimaryKey(UMLogEntry.self, key: entryKey) {
                            log.info("Enqueueing retried upload \(logEntry.id) \(logEntry.compoundKey) with \(samples.count) inserts, \(deleted.count) deletions")

                            let added: [HKSample] = samples.map { $0 as! HKSample }
                            self.batchLogEntryUpload(logEntry.compoundKey, added: added, deleted: deleted)

                            try! realm.write {
                                if logEntry.retry_count < maxRetries {
                                    // Plan for the next retry regardless of whether the above log entry upload request fails.
                                    let backoff = max(maxBackoff, self.rngSource.nextIntWithUpperBound(logEntry.retry_count) * retryPeriodBase)
                                    logEntry.retry_ts = now + backoff.seconds
                                    logEntry.retry_count += 1
                                    log.info("Backed off log entry \(logEntry.id) \(logEntry.compoundKey) to \(logEntry.retry_count) \(logEntry.retry_ts)")
                                } else {
                                    log.info("Too many retries for \(logEntry.id) \(logEntry.compoundKey) \(logEntry.retry_count), deleting...")
                                    realm.delete(logEntry)
                                }
                            }
                        } else {
                            log.warning("No realm object found for \(entryKey)")
                        }
                    }
                }
            }
            else {
                log.warning("No sample type found for retried upload")
                logEntry.logEntryCompact()
            }
        }
    }

    func onCompletedUpload(success: Bool, sampleKeys: [String]) {
        // Clear completed uploads from the persistent pending list
        let realm = try! Realm()
        try! realm.write {
            if success {
                log.info("Completed pending uploads \(sampleKeys.joinWithSeparator(", "))")
                let objects = sampleKeys.flatMap { realm.objectForPrimaryKey(UMLogEntry.self, key: $0) }
                realm.delete(objects)
            }

            // Dispatch pending upload retries
            self.retryPendingUploads()

            if syncMode{
                if logEntryBatchBuffer.isEmpty {
                    syncMode = false
                    NSNotificationCenter.defaultCenter().postNotificationName(SyncEndedNotification, object: nil)
                } else {
                    let info = ["count": logEntryBatchBuffer.count]
                    NSNotificationCenter.defaultCenter().postNotificationName(SyncProgressNotification, object: nil, userInfo: info)
                }
            }
        }
    }

    func syncLogEntryBuffer() {
        if !logEntryBatchBuffer.isEmpty {
            log.warning("ULM SYNC")
            autoreleasepool { _ in
                let batchSize = min(logEntryBatchBuffer.count, logEntryUploadBatchSize)
                let uploadSlice = logEntryBatchBuffer[0..<batchSize]

                var block: [[String:AnyObject]] = []
                var blockKeys: [String] = []

                let realm = try! Realm()

                let blockBuildStart = NSDate()
                uploadSlice.forEach { batch in
                    autoreleasepool { _ in
                        if let logEntry = realm.objectForPrimaryKey(UMLogEntry.self, key: batch.0) {
                            if let params = self.jsonifyLogEntry(logEntry, added: batch.1, deleted: batch.2) {
                                log.info("Serialized UMLogEntry \(batch.1.count) \(batch.2.count)")
                                logEntry.logEntryCompact()
                                block.append(params)
                                blockKeys.append(batch.0)
                            } else {
                                log.warning("Unable to JSONify log entry")
                                logEntry.logEntry()
                            }
                        } else {
                            log.warning("No log entry found for key: \(batch.0)")
                        }
                    }
                }

                log.warning("ULM blockbuild: \(NSDate().timeIntervalSinceDate(blockBuildStart))")

                if block.count > 0 {
                    log.info("Syncing \(block.count) log entries with keys \(blockKeys.joinWithSeparator(", "))")

                    Service.json(MCRouter.AddSeqMeasures(["block": block]), statusCode: 200..<300, tag: "UPLOADLOG") {
                        _, response, result in
                        log.verbose("Upload log entries: \(result.value)")
                        self.onCompletedUpload(result.isSuccess, sampleKeys: blockKeys)
                    }
                }
                else {
                    log.info("Skipping log entry sync, no log entries to upload")
                }

                // Recur as an upload loop while we still have elements in the upload queue.
                logEntryBatchBuffer.removeFirst(batchSize)
                if !logEntryBatchBuffer.isEmpty {
                    log.warning("ULM BBSR \(logEntryBatchBuffer.count)")
                    logEntryUploadAsync?.cancel()
                    logEntryUploadAsync = Async.customQueue(self.uploadQueue, after: logEntryUploadDelay) {
                        self.syncLogEntryBuffer()
                    }
                }
            }
        } else {
            log.info("Skipping syncLogEntryBuffer, empty upload buffer")
        }
    }

    func batchLogEntryUpload(logEntryKey: String, added: [HKSample], deleted: [NSUUID]) {
        if logEntryBatchBuffer.isEmpty {
            logEntryBatchBuffer.append((logEntryKey, added, deleted))
        }
        else if logEntryKey < logEntryBatchBuffer[0].0 {
            logEntryBatchBuffer.insert((logEntryKey, added, deleted), atIndex: 0)
        }
        else {
            var inserted = false
            if let lst = logEntryBatchBuffer.last {
                if logEntryKey > lst.0 {
                    inserted = true
                    logEntryBatchBuffer.append((logEntryKey, added, deleted))
                }
            }

            if !inserted {
                let index = logEntryBatchBuffer.binarySearch { $0.0 < logEntryKey }
                if logEntryBatchBuffer[index].0 != logEntryKey {
                    logEntryBatchBuffer.insert((logEntryKey, added, deleted), atIndex: index)
                } else {
                    log.warning("ULM skipping duplicate pending for \(logEntryKey)")
                }
            }
        }


        logEntryUploadAsync?.cancel()
        logEntryUploadAsync = Async.customQueue(self.uploadQueue, after: logEntryUploadDelay) {
            self.syncLogEntryBuffer()
        }

        // Post notifications if we have a substantial amount of work.
        if !syncMode && logEntryBatchBuffer.count > syncNotificationLimit {
            syncMode = true
            let info = ["count": logEntryBatchBuffer.count]
            NSNotificationCenter.defaultCenter().postNotificationName(SyncBeganNotification, object: nil, userInfo: info)
        }

        // Throttle if upload buffer is large.
        if logEntryBatchBuffer.count > uploadBufferThrottleLimit && !NSThread.isMainThread() {
            log.warning("Throttling upload enqueueing for \(logEntryUploadDelay * 3) secs")
            NSThread.sleepForTimeInterval(logEntryUploadDelay * 3)
        } else {
            log.warning("ULM BBSA \(logEntryBatchBuffer.count)")
        }
    }


    public func uploadAnchorCallback(type: HKSampleType, anchor: HKQueryAnchor?, added: [HKSample], deleted: [HKDeletedObject]) {
        // Add to pending list
        if let anchor = anchor {
            let realm = try! Realm()
            try! realm.write {

                // Create log entry blocks
                let totalBlocks = Int(ceil(Double(added.count + deleted.count) / Double(uploadBlockSize)))
                if totalBlocks == 1 {
                    let logEntry = UMLogEntry(realm: realm, sampleType: type, anchor: anchor, added: added, deleted: deleted)
                    realm.add(logEntry)

                    // Add to upload queue
                    batchLogEntryUpload(logEntry.compoundKey, added: added, deleted: deleted.map { $0.UUID })
                }
                else {
                    var addedIndex = 0
                    var deletedIndex = 0

                    (0..<totalBlocks).forEach { _ in
                        autoreleasepool { _ in
                            let lAdded = (addedIndex < added.count ? added[addedIndex..<min(addedIndex + uploadBlockSize, added.count)] : []).map { $0 }

                            let numDeleted = uploadBlockSize - lAdded.count
                            let lDeleted = (numDeleted > 0 && deletedIndex < deleted.count ? deleted[deletedIndex..<min(deletedIndex + numDeleted, deleted.count)] : []).map { $0 }

                            let logEntry = UMLogEntry(realm: realm, sampleType: type, anchor: anchor, added: lAdded, deleted: lDeleted)
                            realm.add(logEntry)

                            addedIndex += lAdded.count
                            deletedIndex += lDeleted.count

                            // Add to upload queue
                            batchLogEntryUpload(logEntry.compoundKey, added: lAdded, deleted: lDeleted.map { $0.UUID })
                        }
                    }
                }

                // Set the latest anchor for which we're attempting an upload (rather than on upload success).
                // This ensures subsequent parallel anchor queries move forward from this anchor.
                setAnchorForType(anchor, forType: type)
            }
        }
    }
    

    public func deleteSamples(startDate: NSDate, endDate: NSDate, measures: [String:AnyObject], completion: Bool -> Void) {
        // Delete remotely.
        let params: [String: AnyObject] = [
            "tstart"  : Int(floor(startDate.timeIntervalSince1970)),
            "tend"    : Int(ceil(endDate.timeIntervalSince1970)),
            "columns" : measures
        ]

        Service.json(MCRouter.RemoveMeasures(params), statusCode: 200..<300, tag: "DELPOST") {
            _, response, result in
            log.verbose("Deletions: \(result.value)")
            if !result.isSuccess {
                log.error("Failed to delete samples on the server, server may potentially diverge from device.")
            }
            completion(result.isSuccess)
        }
    }

    // MARK: - Upload helpers.

    private func uploadInitialAnchorForType(type: HKSampleType, completion: (Bool, (Bool, NSDate)?) -> Void) {
        let tname = type.displayText ?? type.identifier
        if let wend = UserManager.sharedManager.getHistoricalRangeStartForType(type) {
            let dwend = NSDate(timeIntervalSinceReferenceDate: wend)
            let dwstart = UserManager.sharedManager.decrAnchorDate(dwend)
            let pred = HKQuery.predicateForSamplesWithStartDate(dwstart, endDate: dwend, options: .None)
            MCHealthManager.sharedManager.fetchSamplesOfType(type, predicate: pred) { (samples, error) in
                guard error == nil else {
                    log.error("Could not get initial anchor samples for: \(tname) \(dwstart) \(dwend)")
                    return
                }

                let hksamples = samples as! [HKSample]
                UploadManager.sharedManager.putSample(type, added: hksamples)
                UserManager.sharedManager.decrHistoricalRangeStartForType(type)

                log.info("Uploaded \(tname) to \(dwstart)")
                if let min = UserManager.sharedManager.getHistoricalRangeMinForType(type) {
                    let dmin = NSDate(timeIntervalSinceReferenceDate: min)
                    if dwstart > dmin {
                        completion(false, (false, dwstart))
                        Async.background(after: 0.5) { self.uploadInitialAnchorForType(type, completion: completion) }
                    } else {
                        completion(false, (true, dmin))
                    }
                } else {
                    log.error("No earliest sample found for \(tname)")
                }
            }
        } else {
            log.info("No bulk anchor date found for \(tname)")
        }
    }

    private func backgroundUploadForType(type: HKSampleType, completion: (Bool, (Bool, NSDate)?) -> Void) {
        let tname = type.displayText ?? type.identifier
        if let _ = UserManager.sharedManager.getHistoricalRangeForType(type),
            _ = UserManager.sharedManager.getHistoricalRangeMinForType(type)
        {
            self.uploadInitialAnchorForType(type, completion: completion)
        } else {
            log.warning("No historical range found for \(tname)")
            completion(true, nil)
        }
    }

    // MARK: - Observers

    public func registerUploadObservers() {
        MCHealthManager.sharedManager.authorizeHealthKit { (success, _) -> Void in
            guard success else { return }

            UploadManager.sharedManager.resetUploadManager()
            UploadManager.sharedManager.retryPendingUploads(true)

            let typeChunks = HMConstants.sharedInstance.healthKitTypesToObserve.splitBy(5)

            typeChunks.enumerate().forEach { (index, types) in
                Async.background(after: 0.5 + (Double(index) * 0.2)) {
                    types.forEach { type in
                        IOSHealthManager.sharedManager.startBackgroundObserverForType(type, getAnchorCallback: UploadManager.sharedManager.getNextAnchor)
                        { (added, deleted, newAnchor, error, completion) -> Void in
                            guard error == nil else {
                                log.error("Failed to register observers: \(error)")
                                completion()
                                return
                            }

                            var typeId = type.displayText ?? type.identifier
                            typeId = typeId.isEmpty ? "X\(type.identifier)" : typeId

                            var withSyncInfo = false
                            let userAdded = added.filter {
                                var withSeq = false
                                if let meta = $0.metadata { withSeq = meta["SeqId"] != nil }
                                withSyncInfo = withSyncInfo || withSeq
                                let skip = MCHealthManager.sharedManager.isGeneratedSample($0) || withSeq
                                return !skip
                            }

                            if withSyncInfo {
                                log.warning("Found sync info in \(added.map { $0.metadata })")
                                NSNotificationCenter.defaultCenter().postNotificationName(SyncDidUpdateCircadianEvents, object: nil)
                            }

                            if ( userAdded.count > 0 || deleted.count > 0 ) {
                                UploadManager.sharedManager.uploadAnchorCallback(type, anchor: newAnchor, added: userAdded, deleted: deleted)
                            }
                            else {
                                // Advance the anchor for this type so that we don't see the synchronized entries again.
                                if let anchor = newAnchor where withSyncInfo {
                                    self.setAnchorForType(anchor, forType: type)
                                }

                                log.info("Skipping upload for \(typeId): \(userAdded.count) insertions \(deleted.count) deletions")
                            }
                            completion()
                        }
                    }
                }
            }
        }
    }

    public func deregisterUploadObservers(completion: (Bool, NSError?) -> Void) {
        MCHealthManager.sharedManager.authorizeHealthKit { (success, _) -> Void in
            guard success else { return }
            IOSHealthManager.sharedManager.stopAllBackgroundObservers { (success, error) in
                guard success && error == nil else {
                    log.error(error)
                    return
                }
                self.logEntryUploadAsync?.cancel()
                completion(success, error)
            }
        }
    }

    // MARK : - Alexa and other device synchronization

    func seqCacheKey(type: HKSampleType, deviceClass: String, deviceId: String) -> String {
        return "\(type.identifier)_\(deviceClass)_\(deviceId)"
    }

    func deviceClassParam(deviceClass: String) -> String {
        if deviceClass == "alexa" { return "Alexa" }
        return deviceClass
    }

    // What about meal_duration, activity_duration, etc?
    func columnGroupsOfType(type: HKSampleType) -> [[String]] {
        var columnGroups : [[String]] = []

        if let column = HMConstants.sharedInstance.hkToMCDB[type.identifier] {
            columnGroups.append([column])
        }
        else if let (activity_category, quantity) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[type.identifier] {
            columnGroups.append(["activity_duration", "activity_type", "activity_value"])
        }
        else if type.identifier == HKCorrelationTypeIdentifierBloodPressure {
            // Issue queries for both systolic and diastolic.
            columnGroups.append([HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureDiastolic]!,
                                 HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureSystolic]!])
        }
        else if type.identifier == HKWorkoutType.workoutType().identifier {
            columnGroups.append(["meal_duration", "food_type", "activity_duration", "activity_type", "activity_value"])
        }
        else {
            log.warning("No device query column available for \(type.identifier)")
        }

        return columnGroups
    }

    // What about meal_duration, activity_duration, etc?
    // TODO: category filter for activities.
    func columnDictOfType(type: HKSampleType) -> [String:AnyObject] {
        var columnIndex = 0
        var columns : [String:AnyObject] = [:]

        if let column = HMConstants.sharedInstance.hkToMCDB[type.identifier] {
            columns[String(columnIndex)] = column
            columnIndex += 1
        }
        else if let (activity_category, quantity) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[type.identifier] {
            columns[String(columnIndex)]   = ["activity_duration"]
            columns[String(columnIndex+1)] = ["activity_type"]
            columns[String(columnIndex+2)] = ["activity_value"]
            columnIndex += 3
        }
        else if type.identifier == HKCorrelationTypeIdentifierBloodPressure {
            // Issue queries for both systolic and diastolic.
            columns[String(columnIndex)]   = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureDiastolic]!
            columns[String(columnIndex+1)] = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureSystolic]!
            columnIndex += 2
        }
        else if type.identifier == HKWorkoutType.workoutType().identifier {
            columns[String(columnIndex)]   = ["meal_duration"]
            columns[String(columnIndex+1)] = ["food_type"]
            columns[String(columnIndex+2)] = ["activity_duration"]
            columns[String(columnIndex+3)] = ["activity_type"]
            columns[String(columnIndex+4)] = ["activity_value"]
            columnIndex += 5
        }
        else {
            log.warning("No device query column available for \(type.identifier)")
        }

        return columns
    }

    public func syncDeviceMeasuresPeriodically() {
        deviceSync = Async.background(after: 30.0) {
            // Refresh last acquired
            UserManager.sharedManager.pullAcquisitionSeq { result in
                guard result.error == nil else {

                    // TODO: exponential backoff.
                    log.warning("Failed to get acquisition state")
                    self.syncDeviceMeasuresPeriodically()
                    return
                }

                // Invoke sync
                self.syncDeviceMeasures(HKWorkoutType.workoutType(), deviceClass: "alexa", deviceId: "0")

                // Tail call
                self.syncDeviceMeasuresPeriodically()
            }
        }
    }

    func syncToSeqId(type: HKSampleType, deviceClass: String, deviceId: String,
                     queryOffset: Int, localSeq: Int, remoteSeq: Int, columns: [String: AnyObject])
    {
        let limit: Int = 100

        let params: [String: AnyObject] = [
            "with_ids": true,
            "sstart": localSeq,
            "send": remoteSeq,
            "device_class": deviceClassParam(deviceClass),
            "device_id": deviceId,
            "columns": columns,
            "offset": queryOffset,
            "limit": limit
        ]

        log.info("ULM RSYNC \(type.identifier) \(deviceClass) \(deviceId) from \(localSeq) to \(remoteSeq) with params \(params)")

        Service.json(MCRouter.GetMeasures(params), statusCode: 200..<300, tag: "GETMEAS") {
            _, response, result in

            guard result.isSuccess else {
                // TODO: retry w/ backoff.
                log.error("Failed to sync server samples, server may potentially diverge from device.")
                return
            }

            log.info("ULM RSYNC response on \(queryOffset) \(localSeq) \(remoteSeq) for \(type.identifier) \(deviceClass) \(deviceId)")

            // Write retrieved data into HealthKit, ensuring that we add metadata tags for sample ids.
            self.writeDeviceMeasures(type, deviceClass: deviceClass, deviceId: deviceId, payload: result.value) {
                (success, completedSeq, payloadSize, err) in
                guard success && err == nil else {
                    log.error("Sync failed to parse and write measures: \(completedSeq) \(payloadSize)")
                    log.error(err)
                    return
                }

                // Recur while we got a non-empty set of measures, and we have not yet reached our target remote seq.
                // TODO: throttling.

                log.info("ULM RSYNC recur on \(queryOffset) \(completedSeq) \(localSeq) \(remoteSeq) \(payloadSize) for \(type.identifier) \(deviceClass) \(deviceId)")

                if let numMeasures = payloadSize, seq = completedSeq where numMeasures == limit && seq < remoteSeq {
                    let nextOffset = queryOffset + numMeasures
                    self.syncToSeqId(type, deviceClass: deviceClass, deviceId: deviceId, queryOffset: nextOffset, localSeq: seq, remoteSeq: remoteSeq, columns: columns)
                }
                else if let numMeasures = payloadSize, seq = completedSeq {
                    log.warning("ULM RSYNC stopped sync for \(type.identifier) \(deviceClass) \(deviceId) at \(seq), offset \(queryOffset), #results \(numMeasures)")
                }
                else {
                    log.error("ULM RSYNC stopped sync for \(type.identifier) \(deviceClass) \(deviceId) with \(completedSeq) \(payloadSize), offset \(queryOffset)")
                }
            }
        }
    }

    // Note: we should make sure that when we add the events to the local HealthKit store,
    // we include metadata to ensure it will not be processed for uploads by our anchor query.
    public func syncDeviceMeasures(type: HKSampleType, deviceClass: String, deviceId: String) {
        if let classInfo = UserManager.sharedManager.getAcquisitionSeq(type) as? [String:AnyObject]
        {
            log.warning("ULM RSYNC retrieving remote seq for \(type.identifier), \(deviceClass), \(deviceId) from \(classInfo)")
            if let dataForClass = classInfo[deviceClass] as? [String: AnyObject],
                seqInfo = dataForClass[deviceId] as? [String: AnyObject],
                syncSeqId = seqInfo[remoteSyncSeqIdKey] as? Int
            {
                // Retrieve all remote samples between max local seq, and max known remote seq
                //  -- where do we store the max local seq?
                //  -- this is a remote sample id, and can be stored as sample metadata.
                //  -- we can then query for sample only with this metadata key.
                //  -- we can accelerate by keeping the last retrieved seq id in UserDefaults.
                //
                // We need to extend our getMeasures backend route to support seq ranges not just timestamp ranges

                // Fetch best known local sample from UserDefaults if available, otherwise HealthKit.

                var localSeq: Int! = nil
                let remoteSeq = syncSeqId

                let columns = columnDictOfType(type)

                let key = seqCacheKey(type, deviceClass: deviceClass, deviceId: deviceId)

                if Defaults.hasKey(key) {

                    log.info("ULM RSYNC get local seq from cache for key \(key)")

                    localSeq = Defaults.integerForKey(key)
                    if let localSeq = localSeq where localSeq < remoteSeq {
                        syncToSeqId(type, deviceClass: deviceClass, deviceId: deviceId, queryOffset: 0, localSeq: localSeq + 1, remoteSeq: remoteSeq, columns: columns)
                    }
                    else {
                        log.info("ULM RSYNC fresh (from cache) for key \(key) \(localSeq)")
                    }
                }
                else {

                    log.info("ULM RSYNC get local seq from DB for key \(key)")

                    let conjuncts = [
                        HKQuery.predicateForObjectsWithMetadataKey("DeviceClass", operatorType: NSPredicateOperatorType.EqualToPredicateOperatorType, value: deviceClass),
                        HKQuery.predicateForObjectsWithMetadataKey("DeviceId", operatorType: NSPredicateOperatorType.EqualToPredicateOperatorType, value: deviceId),
                        HKQuery.predicateForObjectsWithMetadataKey("SeqId")
                    ]

                    let devicePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: conjuncts)

                    MCHealthManager.sharedManager.fetchSamplesOfType(type, predicate: devicePredicate, limit: 1, sortDescriptors: [dateDesc]) { (samples, error) in
                        guard error == nil else {
                            log.error(error)
                            return
                        }

                        let rmin = samples.reduce(Int.min, combine: { (acc, sample) in
                            if let s = sample as? HKObject, m = s.metadata {
                                if let seq = m["SeqId"] as? Int {
                                    return min(acc, seq)
                                }
                                else if let s = m["SeqId"] as? String, seq = Int(s) {
                                    return min(acc, seq)
                                }
                            }
                            return acc
                        })

                        if rmin != Int.min { localSeq = rmin + 1 }
                        else if localSeq == nil { localSeq = 0 }

                        if let localSeq = localSeq where localSeq < remoteSeq {
                            self.syncToSeqId(type, deviceClass: deviceClass, deviceId: deviceId, queryOffset: 0, localSeq: localSeq, remoteSeq: remoteSeq, columns: columns)
                        }
                        else {
                            log.info("ULM RSYNC fresh (from HK) for key \(key) \(localSeq)")
                        }

                    }
                }
            }
            else {
                log.warning("ULM Invalid seq for \(type.identifier), \(deviceClass), \(deviceId)")
            }
        }
        else {
            log.warning("ULM Invalid seq for \(type.identifier), \(deviceClass), \(deviceId)")
        }
    }

    private func processSyncMeasure(type: HKSampleType, deviceClass: String, deviceId: String,
                                    sample: [String: AnyObject], columnGroups: [[String]]) -> (Bool, Int?, [HKSample])
    {
        log.info("ULM RSYNC PSM \(sample)")

        var id: Int! = nil
        var ts: NSDate! = nil

        if let s = sample["id"] as? String, i = Int(s) { id = i }
        else if let i = sample["id"] as? Int { id = i }

        if let s = sample["ts"] as? String, t = s.toDate(.ISO8601Format(.Full)) { ts = t }

        let values: [[AnyObject]] = columnGroups.flatMap { cgroup in
            var vgroup: [AnyObject] = []

            if cgroup.contains("meal_duration") {
                if let m = sample["meal_duration"], f = sample["food_type"] {
                    vgroup = [m, f]
                }
                else if let d = sample["activity_duration"], t = sample["activity_type"], v = sample["activity_value"] {
                    vgroup = [d,t,v]
                }
                return vgroup.count > 0 ? vgroup : nil
            }

            vgroup = cgroup.flatMap { sample[$0] }
            return vgroup.count == cgroup.count ? vgroup : nil
        }

        guard !(id == nil || ts == nil || values.count != columnGroups.count) else {
            log.warning("Failed to sync \(type.identifier) \(deviceClass) \(deviceId) for \(id) \(ts) \(values.count) \(columnGroups.count) \(sample)")
            return (false, nil, [])
        }

        var samples: [HKSample] = []
        let metadata: [String: AnyObject] = ["DeviceClass": deviceClass, "DeviceID": deviceId, "SeqId": id]

        columnGroups.enumerate().forEach { (index, cgroup) in
            let vgroup = values[index]

            var meal: [String: AnyObject] = [:]
            var activity: [String: AnyObject] = [:]

            cgroup.enumerate().forEach { (index, column) in
                if index < vgroup.count {
                    if column == "meal_duration" || column == "food_type" {
                        meal[column] = vgroup[index]
                    }
                    else if column == "activity_duration" || column == "activity_type" || column == "activity_value" {
                        activity[column] = vgroup[index]
                    }
                    else {
                        var dvalue: Double! = nil
                        if let d = vgroup[index] as? Double { dvalue = d }
                        if let s = vgroup[index] as? String, d = Double(s) { dvalue = d }

                        if let value = dvalue, typeIdentifier = HMConstants.sharedInstance.mcdbToHK[column] {
                            switch typeIdentifier {
                            case HKCategoryTypeIdentifierSleepAnalysis:
                                let sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
                                let ts_end = ts.dateByAddingTimeInterval(value)

                                let catval = HKCategoryValueSleepAnalysis.Asleep.rawValue
                                let hkSample = HKCategorySample(type: sampleType, value: catval, startDate: ts, endDate: ts_end, metadata: metadata)

                                samples.append(hkSample)

                            case HKCategoryTypeIdentifierAppleStandHour:
                                let sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!
                                let ts_end = ts.dateByAddingTimeInterval(value)

                                let catval = HKCategoryValueAppleStandHour.Stood.rawValue
                                let hkSample = HKCategorySample(type: sampleType, value: catval, startDate: ts, endDate: ts_end, metadata: metadata)

                                samples.append(hkSample)

                            default:
                                let sampleType = HKObjectType.quantityTypeForIdentifier(typeIdentifier)!
                                let hkQuantity = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: value)
                                let hkSample = HKQuantitySample(type: sampleType, quantity: hkQuantity, startDate: ts, endDate: ts, metadata: metadata)
                                
                                samples.append(hkSample)
                            }
                        }
                    }
                }
            }

            if meal.count > 0 {
                // Add meal object
                var duration: Double! = nil
                if let s = meal["meal_duration"] as? String, d = Double(s) { duration = d }
                else if let d = meal["meal_duration"] as? Double { duration = d }

                log.info("ULM RSYNC found meal \(meal) \(duration)")

                if let duration = duration,
                    food_type = meal["food_type"] as? [[String: AnyObject]],
                    meal_type = food_type[0]["value"] as? String
                {
                    let ts_end = ts.dateByAddingTimeInterval(duration)
                    let energy = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 0.0)
                    let distance = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: 0.0)
                    let wMetadata: [String: AnyObject] = ["Meal Type": meal_type, "DeviceClass": deviceClass, "DeviceId": deviceId, "SeqId": id]

                    let hkSample = HKWorkout(activityType: HKWorkoutActivityType.PreparationAndRecovery, startDate: ts, endDate: ts_end, duration: duration, totalEnergyBurned: energy, totalDistance: distance, metadata: wMetadata)

                    samples.append(hkSample)
                } else {

                }
            }

            if activity.count > 0 {
                // Add activity object
                var duration: Double! = nil
                var activity_type: Int! = nil

                log.info("ULM RSYNC found activity \(activity)")

                if let s = activity["activity_duration"] as? String, d = Double(s) { duration = d }
                else if let d = activity["activity_duration"] as? Double { duration = d }

                if let s = activity["activity_type"] as? String, i = Int(s) { activity_type = i }
                else if let i = activity["activity_type"] as? Int { activity_type = i }

                if let duration = duration, activity_type = activity_type {
                    let ts_end = ts.dateByAddingTimeInterval(duration)

                    if let typeIdentifier = HMConstants.sharedInstance.mcActivityToHKQuantity[activity_type] {
                        let sampleType = HKObjectType.quantityTypeForIdentifier(typeIdentifier)!

                        var qKey = ""
                        switch typeIdentifier {
                        case HKQuantityTypeIdentifierStepCount:
                            qKey = "step_count"

                        case HKQuantityTypeIdentifierDistanceWalkingRunning:
                            qKey = "flights_climbed"


                        case HKQuantityTypeIdentifierFlightsClimbed:
                            qKey = "distance_walking_running"

                        default:
                            qKey = ""
                        }

                        if !qKey.isEmpty {
                            var hkQuantity: HKQuantity! = nil
                            if let quantities = activity["activity_value"] as? [String: AnyObject], s = quantities["step_count"] as? String, i = Int(s)
                            {
                                hkQuantity = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: Double(i))
                            }
                            else if let quantities = activity["activity_value"] as? [String: AnyObject], i = quantities["step_count"] as? Int
                            {
                                hkQuantity = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: Double(i))

                            }
                            let hkSample = HKQuantitySample(type: sampleType, quantity: hkQuantity, startDate: ts, endDate: ts, metadata: metadata)

                            samples.append(hkSample)
                        }
                    }
                    else if let hkActivityType = HMConstants.sharedInstance.mcActivityToHKActivity[activity_type] {
                        var energy: Double! = nil
                        var distance: Double! = nil

                        if let v = activity["activity_value"] as? [String: AnyObject], e = v["kcal_burned"] as? Double { energy = e }
                        else if let v = activity["activity_value"] as? [String: AnyObject], s = v["kcal_burned"] as? String, e = Double(s) { energy = e }

                        if let v = activity["activity_value"] as? [String: AnyObject], d = v["distance"] as? Double { distance = d }
                        else if let v = activity["activity_value"] as? [String: AnyObject], s = v["distance"] as? String, d = Double(s) { distance = d }

                        let energyQ = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: energy == nil ? 0.0 : energy!)
                        let distanceQ = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: distance == nil ? 0.0 : distance!)

                        let hkSample = HKWorkout(activityType: hkActivityType, startDate: ts, endDate: ts_end, duration: duration, totalEnergyBurned: energyQ, totalDistance: distanceQ, metadata: metadata)

                        samples.append(hkSample)
                    }
                }
            }
        }

        return (true, id, samples)
    }

    private func writeDeviceMeasures(type: HKSampleType, deviceClass: String, deviceId: String, payload: AnyObject?,
                                     completion: (Bool, Int?, Int?, NSError?) -> Void)
    {
        var failed = false

        var maxSampleId: Int! = nil
        var samples: [HKSample] = []

        let columnGroups = columnGroupsOfType(type)

        if let response = payload as? [String:AnyObject], measures = response["items"] as? [[String:AnyObject]] {
            for sample in measures {
                let (success, sampleId, newSamples) = processSyncMeasure(type, deviceClass: deviceClass, deviceId: deviceId, sample: sample, columnGroups: columnGroups)

                failed = !success
                if failed { break }
                if let cmax = sampleId { maxSampleId = maxSampleId == nil ? cmax : max(maxSampleId, cmax) }
                samples.appendContentsOf(newSamples)
            }

            log.info("ULM RSYNC parsed \(samples.count) samples")

            // Only add samples if there were no parsing errors.
            if let maxId = maxSampleId where !failed {
                MCHealthManager.sharedManager.saveSamples(samples) { (success, err) in
                    guard success && err == nil else {
                        log.error("Failed to sync \(type.identifier) \(deviceClass) \(deviceId) to \(maxId)")
                        return completion(!failed, nil, measures.count, err)
                    }

                    log.info("ULM RSYNC \(type.identifier) \(deviceClass) \(deviceId) advance pptr to \(maxId)")

                    let key = self.seqCacheKey(type, deviceClass: deviceClass, deviceId: deviceId)
                    Defaults.setInteger(maxId, forKey: key)
                    completion(!failed, maxId, measures.count, nil)
                }
            }
            else {
                completion(!failed, maxSampleId, measures.count, nil)
            }
        }
        else {
            completion(false, nil, nil, nil)
        }
    }

}