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
import SwiftyBeaver

//let log = SwiftyBeaver.self

// Sorted array helpers.
// From http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array/33674192#33674192

public extension Collection where Index: Strideable {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: (Generator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
//            let mid = low.advancedBy(low.distanceTo(high) / 2)
            let mid = low.advanced(by: low.distance(to: high))
            if predicate(self[mid]) {
                low = mid.advanced(by: 1)
            } else {
                high = mid
            }
        }
        return low
    }
}

public extension Array {
    func splitBy(size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map { startIndex in
            let endIndex = startIndex.advanced(by: size)
            return Array(self[startIndex ..< endIndex])
        }
    }
}

// Constants  
let remoteLogSeqKey             = "ios_log"
let remoteLogSeqDeviceCnt       = "0"
let remoteLogSeqIdKey           = "seq_id"
let remoteLogSeqDataKey         = "seq_data"
let remoteLogSeqDevKey          = "seq_dvc"

let remoteSyncSeqIdKey = "seq_id"

let minute:TimeInterval = 60.0
let hour:TimeInterval = 60.0 * minute
let day:TimeInterval = 24 * hour

// Randomized, truncated exponential backoff constants

public let retryPeriodBase = 300
public let maxBackoffExponent = 7
public let maxBackoff = (2 << maxBackoffExponent) * retryPeriodBase
public let maxRetries = 10

public let uploadBlockSize = 100
public let uploadBufferThrottleLimit = 1000

private let HMAnchorKey      = DefaultsKey<[String: Any]?>("HKClientAnchorKey")
private let HMAnchorTSKey    = DefaultsKey<[String: Any]?>("HKAnchorTSKey")

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
        self.uuid = UMSampleUUID.nsDataOfUUID(uuid: insertion.uuid as NSUUID)
    }

    public convenience init(deletion: HKDeletedObject) {
        self.init()
        self.uuid = UMSampleUUID.nsDataOfUUID(uuid: deletion.uuid as NSUUID)
    }

    public static func nsDataOfUUID(uuid: NSUUID) -> NSData {
        var uuidBytes: [UInt8] = [UInt8](repeating: 0, count: 16)
        uuid.getBytes(&uuidBytes)
        return NSData(bytes: &uuidBytes, length: 16)
    }

    public static func uuidOfNSData(data: NSData) -> NSUUID {
//        return NSUUID(UUIDBytes: UnsafePointer<UInt8>(data.bytes))
//        return NSUUID(uuidBytes: data.bytes)
//        let uuidString = NSUUID().uuidString
//        return uuidString as! NSUUID
        var ptr = data.bytes.assumingMemoryBound(to: UInt8.self)
        return NSUUID(uuidBytes: ptr)
    }
}

public class UMLogEntry: Object {
    public dynamic var id: Int = 0
    public dynamic var msid = String()
    public dynamic var ts = Date()
    public dynamic var anchor = NSData()

    let insert_uuids = List<UMSampleUUID>()
    let delete_uuids = List<UMSampleUUID>()

    public dynamic var retry_ts = Date()
    public dynamic var retry_count: Int = 1

    // Note: because we may add a LSN for this type, this initializer must be called in a write block.
    public convenience init(realm: Realm!, sampleType: HKSampleType, ts: Date = Date(), anchor: HKQueryAnchor, added: [HKSample], deleted: [HKDeletedObject]) {
        self.init()

        self.id = self.incrSequenceNumberForType(realm: realm, sampleType: sampleType)
        self.msid = sampleType.identifier
        self.ts = ts
        self.anchor = UploadManager.sharedManager.encodeRemoteAnchorAsData(anchor: anchor)
        self.insert_uuids.append(objectsIn: added.map { return UMSampleUUID(insertion: $0) })
        self.delete_uuids.append(objectsIn: deleted.map { return UMSampleUUID(deletion: $0) })
        self.retry_ts = Date() + retryPeriodBase.seconds
        self.compoundKey = compoundKeyValue()
        log.debug("Created UMLogEntry", "entryConstruction")
        self.logEntry(feature: "entryConstruction")
    }

    public static func initSequenceNumberForType(realm: Realm!, sampleType: HKSampleType, seqNumber: Int) {
        let seq = UMLogSequenceNumber(type: sampleType, seqNumber: seqNumber)
        realm.add(seq, update: true)
    }

    public static func sequenceNumberForType(realm: Realm!, sampleType: HKSampleType) -> UMLogSequenceNumber? {
        return realm.object(ofType: UMLogSequenceNumber.self, forPrimaryKey: sampleType.identifier as AnyObject)
    }

    public func incrSequenceNumberForType(realm: Realm!, sampleType: HKSampleType) -> Int {
        if let seq = UMLogEntry.sequenceNumberForType(realm: realm, sampleType: sampleType) {
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

    public func setTS(ts: Date = Date()) {
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

    public func logEntry(feature: String = "logEntries") {
//        log.debug([
//            "id:\(self.id)",
//            "msid:\(self.msid)",
//            "ts:\(self.ts.timeIntervalSince1970)",
            //"anchor:\(self.anchor.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))",
 //           "insert_uuids:\(self.insert_uuids.count)",
//            "delete_uuids:\(self.delete_uuids.count)",
            //"retry_ts:\(self.retry_ts)",
            //"retry_count:\(self.retry_count)",
 //       ].componentsJoinedByString("\n"), feature)
    }

    public func logEntryCompact(feature: String = "logEntries") {
 //       log.debug([
 //           "id:\(self.id)",
//            "msid:\(self.msid)",
//            "ts:\(self.ts.timeIntervalSince1970)",
 //           "retry_count:\(self.retry_count)"
//        ].componentsJoinedByString("\n"), feature)
    }

}

public class UploadManager: NSObject {
    public static let sharedManager: UploadManager = UploadManager()

    // Random number generation
    let rng = GKARC4RandomSource(seed: "1234".data(using: String.Encoding.utf8)!)
    let rngSource = GKRandomDistribution(lowestValue: 1, highestValue: maxBackoff)

    // Custom upload task queue
//    let uploadQueue: DispatchQueue.async!

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
//        self.uploadQueue = dispatch_queue_create("UploadQueue", DISPATCH_QUEUE_SERIAL)
        super.init()
    }

    // MARK: - initialize uploads.

    public func resetUploadManager() {
        log.debug("Upload Manager state before reset", "metadata:resetState")
        logMetadata()

        let realm = try! Realm()
        try! realm.write {
            // Initialize sequence numbers based on remote values.
            let seqs = UserManager.sharedManager.getAcquisitionSeq()

            if seqs.isEmpty {
                log.debug("Skipping initsync, no remote seqnos found", "skip:resetState")
            }

            for (type, deviceData) in seqs {
                if let deviceInfo = deviceData as? [String:AnyObject],
                       let seqForIOS = deviceInfo[remoteLogSeqKey] as? [String: AnyObject],
                       let seqInfo = seqForIOS[remoteLogSeqDeviceCnt] as? [String: AnyObject],
                       let remoteSeqNum = seqInfo[remoteLogSeqIdKey] as? Int
                {
                    var doInit = false
                    var onDeviceSeq = 0
                    let nextSeqNum = remoteSeqNum + 1

                    if let seq = UMLogEntry.sequenceNumberForType(realm: realm, sampleType: type) {
                        doInit = seq.seqid < nextSeqNum
                        onDeviceSeq = seq.seqid
                    } else {
                        doInit = true
                    }

                    if doInit {
                        log.debug("Initsync seq for \(type.identifier): \(nextSeqNum)", "resetState")
                        UMLogEntry.initSequenceNumberForType(realm: realm, sampleType: type, seqNumber: nextSeqNum)
                    } else {
                        log.debug("Skipping initsync seq for \(type.identifier) (found \(onDeviceSeq) on device vs \(remoteSeqNum) remotely)", "skip:resetState")
                    }
                } else {
                    log.debug("Skipping initsync seq for \(type.identifier) (no remote seq found)", "skip:resetState")
                }
            }

            // Clean log entries.
            for logEntry in realm.objects(UMLogEntry.self) {
                if logEntry.insert_uuids.count > uploadBlockSize || logEntry.delete_uuids.count > uploadBlockSize {
                    log.debug("Clearing log entry", "resetState")
                    logEntry.logEntry()
                    realm.delete(logEntry)
                }
            }
        }

        log.debug("Upload Manager state after reset", "metadata:resetState")
        logMetadata()
    }

    public func logMetadata() {
        let realm = try! Realm()

        realm.objects(UMLogSequenceNumber.self).forEach { seqno in
            log.debug("SEQ msid: \(seqno.msid) id: \(seqno.seqid)", "metadata:resetState")
        }


        realm.objects(UMLogEntry.self).forEach { logEntry in
            logEntry.logEntry(feature: "metadata:resetState")
        }
    }

    // MARK: - Remote encoding helpers.

    public func encodeRemoteAnchorAsData(anchor: HKQueryAnchor) -> NSData {
        return NSKeyedArchiver.archivedData(withRootObject: anchor) as NSData
    }

    public func encodeRemoteAnchor(anchor: HKQueryAnchor) -> String {
        return encodeRemoteAnchorAsData(anchor: anchor).base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    public func decodeRemoteAnchorFromData(remoteAnchor: NSData) -> HKQueryAnchor? {
        return NSKeyedUnarchiver.unarchiveObject(with: remoteAnchor as Data) as? HKQueryAnchor
    }

    public func decodeRemoteAnchor(remoteAnchor: String) -> HKQueryAnchor? {
        if let encodedAnchor = NSData(base64Encoded: remoteAnchor, options: NSData.Base64DecodingOptions(rawValue: 0)) {
            return decodeRemoteAnchorFromData(remoteAnchor: encodedAnchor)
        }
        return nil
    }

    // MARK: - Anchor metadata accessors 

    // Setter and getter for the anchor object returned by HealthKit, as stored in user defaults.
    public func getAnchorForType(type: HKSampleType) -> HKQueryAnchor {
        if let anchorDict = Defaults[HMAnchorKey] {
            if let encodedAnchor = anchorDict[type.identifier] as? NSData {
                return NSKeyedUnarchiver.unarchiveObject(with: encodedAnchor as Data) as! HKQueryAnchor
            }
        }
        return noAnchor
    }

    public func setAnchorForType(anchor: HKQueryAnchor, forType type: HKSampleType) {
        let encodedAnchor = NSKeyedArchiver.archivedData(withRootObject: anchor)
        if !Defaults.hasKey(HMAnchorKey) {
            Defaults[HMAnchorKey] = [type.identifier: encodedAnchor]
        } else {
            Defaults[HMAnchorKey]![type.identifier] = encodedAnchor
        }
        Defaults.synchronize()
    }

    public func getRemoteAnchorForType(type: HKSampleType) -> HKQueryAnchor? {
        let tname = type.displayText ?? type.identifier
        if let deviceInfo = UserManager.sharedManager.getAcquisitionSeq(type: type) as? [String:AnyObject]
        {
            if let seqForIOS = deviceInfo[remoteLogSeqKey] as? [String: AnyObject],
                   let seqInfo = seqForIOS[remoteLogSeqDeviceCnt] as? [String: AnyObject],
                   let remoteAnchor = seqInfo[remoteLogSeqDataKey] as? String
            {
                if let remoteDevice = seqInfo[remoteLogSeqDevKey] as? String {
                    let currentDevice = UIDevice.current.identifierForVendor?.uuidString ?? "<no-id>"
                    if currentDevice == remoteDevice {
                        return decodeRemoteAnchor(remoteAnchor: remoteAnchor)
                    } else {
                        log.debug("Detected device mismatch, ignoring remote anchor for \(tname) (\(remoteDevice) vs \(currentDevice))", "remoteAnchor")
                    }
                } else {
                    log.debug("No remote device found for anchor, ignoring remote anchor for \(tname)", "remoteAnchor")
                }
            } else {
                log.debug("Invalid seq fields for remote anchor decode on \(tname)", "remoteAnchor")
            }
        } else {
            log.debug("Invalid seq dict for remote anchor decode on \(tname)", "remoteAnchor")
        }
        return nil
    }

    public func resetAnchors() {
        HMConstants.sharedInstance.healthKitTypesToObserve.forEach { type in
            self.setAnchorForType(anchor: noAnchor, forType: type)
        }
    }

    public func getNextAnchor(type: HKSampleType) -> (Bool, HKQueryAnchor?, NSPredicate?) {
        var remoteAnchor = false
        var needOldestSamples = false
        var anchor = getAnchorForType(type: type)
        var predicate : NSPredicate? = nil

        let tname = type.displayText ?? type.identifier

        // When initializing an anchor query, apply a predicate to limit the initial results.
        // If we already have a historical range, we filter samples to the current timestamp.
        if anchor == noAnchor
        {
            // We use anchors stored in the remote profile if available,
            // to grab all data since the last anchor uploaded to the server.
            if let anchorForType = getRemoteAnchorForType(type: type) {
                // We have a remote anchor available, and do not use a temporal predicate.
                anchor = anchorForType
                remoteAnchor = true
                log.debug("Data import from anchor \(anchor): \(tname)", "getNextAnchor")
            }
            else if let (_, hend) = UserManager.sharedManager.getHistoricalRangeForType(type: type) {
                // We have no server anchor available.
                // Here, we upload all samples between the end of the historical range (i.e., when the
                // app was first run on the device), to a point in the near future.
//                let nearFuture = 1.minutes.fromNow
                let minute:TimeInterval = 60.0
                let nearFuture = Date(timeIntervalSinceNow: minute)
                let pstart = Date(timeIntervalSinceReferenceDate: hend)
                predicate = HKQuery.predicateForSamples(withStart: pstart as Date, end: nearFuture, options: [])
                log.debug("Data import from \(pstart) \(nearFuture): \(tname)", "getNextAnchor")
            }
            else {
                // We have no anchor or archive span available.
                // We consider this the first run of the app on this device, and initialize the historical range
                // (i.e., the archive span).
                // This captures how much data is available on the device prior to using our app.
                let (start, end) = UserManager.sharedManager.initializeHistoricalRangeForType(type: type, sync: true)
                let (dstart, dend) = (Date(timeIntervalSinceReferenceDate: start), Date(timeIntervalSinceReferenceDate: end))
                predicate = HKQuery.predicateForSamples(withStart: dstart as Date, end: dend as Date, options: [])
                needOldestSamples = true
                log.debug("Initialized historical range for \(tname): \(dstart) \(dend)", "getNextAnchor")
            }
        }

        log.debug("Anchor for \(tname)(\(remoteAnchor)): \(anchor)", "getNextAnchor")
        return (needOldestSamples, anchor, predicate)
    }

    // MARK: - Upload helpers.

    public func jsonifySample(sample : HKSample) throws -> [String : AnyObject] {
        return try UploadManager.serializer.dict(for: sample)
    }

    public func jsonifyLogEntry(logEntry: UMLogEntry, added: [HKSample], deleted: [NSUUID]) -> [String:AnyObject]? {
        var addedJson: [[String:AnyObject]] = []
        do {
            addedJson = try added.map(self.jsonifySample)
        } catch let error {
            log.error((error).localizedDescription)
            return nil
        }

        let seqInfo: [String: AnyObject] = [
            remoteLogSeqIdKey   : logEntry.id as AnyObject,
            remoteLogSeqDataKey : logEntry.anchor.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) as AnyObject,
            remoteLogSeqDevKey  : UIDevice.current.identifierForVendor!.uuidString as AnyObject
        ]

        let deviceInfo: [String: AnyObject] = [
            remoteLogSeqKey: ([remoteLogSeqDeviceCnt: seqInfo] as AnyObject)
        ]

        let commands: [String:Any] = [
            "inserts": addedJson as Any,
            "deletes": deleted.map { return ["uuid": $0.uuidString] }
        ]

        var measures: [String] = []
        if let measureSeqId = seqIdOfSampleTypeId(typeIdentifier: logEntry.msid) {
            measures = [measureSeqId]
        } else {
            log.error("No MCDB seq id found for \(logEntry.msid)")
            return nil
        }

        return [
            "seq": deviceInfo as AnyObject,
            "measures": measures as AnyObject,
            "commands": commands as AnyObject
        ]
    }

    public func putSample(jsonObj: [String: AnyObject]) -> () {
        Service.string(route: MCRouter.AddMeasures(jsonObj), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.debug("Upload: \(result.value)", "uploadStatus")
        }
    }

    public func putBlockSample(jsonObjBlock: [[String:AnyObject]]) -> () {
        Service.string(route: MCRouter.AddMeasures(["block":jsonObjBlock as AnyObject]), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.debug("Upload: \(result.value)", "uploadStatus")
        }
    }

    public func putSample(type: HKSampleType, added: [HKSample]) {
        do {
            let tname = type.displayText ?? type.identifier
            log.debug("Uploading \(added.count) \(tname) samples", "uploadProgress")

            let blockSize = 100
            let totalBlocks = ((added.count / blockSize)+1)
            if ( added.count > 20 ) {
                for i in 0..<totalBlocks {
                    autoreleasepool { _ in
                        do {
                            log.debug("Uploading block \(i) / \(totalBlocks)", "uploadProgress")
                            let jsonObjs = try added[(i*blockSize)..<(min((i+1)*blockSize, added.count))].map(self.jsonifySample)
                            self.putBlockSample(jsonObjBlock: jsonObjs)
                        } catch {
                            log.error((error).localizedDescription)
                        }
                    }
                }
            } else {
                let jsons = try added.map(self.jsonifySample)
                jsons.forEach(self.putSample)
            }
        } catch {
            log.error((error).localizedDescription)
        }
    }

    public func retryPendingUploads(force: Bool = false) {
        // Dispatch retries based on the persistent pending list
        let now = Date()
        let realm = try! Realm()

        for logEntry in realm.objects(UMLogEntry.self).filter({ return (force || $0.retry_ts < now) }) {
            log.debug("Retrying pending upload", "uploadRetries")
            logEntry.logEntryCompact(feature: "uploadRetries")

            let entryKey: String = logEntry.compoundKey
            var sampleType: HKSampleType! = nil

            switch logEntry.msid {
            case HKCategoryTypeIdentifier.sleepAnalysis.rawValue, HKCategoryTypeIdentifier.appleStandHour.rawValue:
                sampleType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: logEntry.msid))

            case HKCorrelationTypeIdentifier.bloodPressure.rawValue:
                sampleType = HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier(rawValue: logEntry.msid))

            case HKWorkoutTypeIdentifier:
                sampleType = HKObjectType.workoutType()

            default:
                sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: logEntry.msid))
            }

            if let type = sampleType {
                let uuids = Set(logEntry.insert_uuids.map { return UMSampleUUID.uuidOfNSData(data: $0.uuid) })
                let deleted: [NSUUID] = logEntry.delete_uuids.map { return UMSampleUUID.uuidOfNSData(data: $0.uuid) }

                log.debug("Retry upload invoking fetchSamplesByUUID for \(entryKey)", "uploadRetries")

                MCHealthManager.sharedManager.fetchSamplesByUUID(type, uuids: uuids as Set<UUID>) { (samples, error) in
                    // We need a new Realm instance since this completion will execute in a different thread
                    // than the realm instance outside the above loop.
                    log.debug("Retry upload in fetchSamplesByUUID completion for \(entryKey)", "uploadRetries")
                    let realm = try! Realm()
                    if error != nil {
                        log.error(error!.localizedDescription)
                        // Refetch the obejct since we are in a background thread from the health manager.
                        if let logEntry = realm.object(ofType: UMLogEntry.self, forPrimaryKey: entryKey as AnyObject) {
                            try! realm.write {
                                realm.delete(logEntry)
                            }
                        } else {
                            log.debug("No realm object found for deleting \(entryKey)", "uploadRealmSync")
                        }
                    }
                    else {
                        if let logEntry = realm.object(ofType: UMLogEntry.self, forPrimaryKey: entryKey as AnyObject) {
                            log.debug("Enqueueing retried upload \(logEntry.id) \(logEntry.compoundKey) with \(samples.count) inserts, \(deleted.count) deletions", "uploadRetries")

                            let added: [HKSample] = samples.map { $0 as! HKSample }
//                            self.batchLogEntryUpload(logEntryKey: logEntry.compoundKey, added: added, deleted: deleted)

                            try! realm.write {
                                if logEntry.retry_count < maxRetries {
                                    // Plan for the next retry regardless of whether the above log entry upload request fails.
                                    let backoff = max(maxBackoff, self.rngSource.nextInt(upperBound: logEntry.retry_count) * retryPeriodBase)
                                    logEntry.retry_ts = now + backoff.seconds
                                    logEntry.retry_count += 1
                                    log.debug("Backed off log entry \(logEntry.id) \(logEntry.compoundKey) to \(logEntry.retry_count) \(logEntry.retry_ts)", "uploadRetries")
                                } else {
                                    log.debug("Too many retries for \(logEntry.id) \(logEntry.compoundKey) \(logEntry.retry_count), deleting...", "uploadRetries")
                                    realm.delete(logEntry)
                                }
                            }
                        } else {
//                            log.debug("No realm object found for \(entryKey)", feature: "uploadRealmSync")
                        }
                    }
                }
            }
            else {
                log.debug("No sample type found for retried upload", "uploadRetries")
                logEntry.logEntryCompact(feature: "uploadRetries")
            }
        }
    }

    func onCompletedUpload(success: Bool, sampleKeys: [String]) {
        // Clear completed uploads from the persistent pending list
        let realm = try! Realm()
        try! realm.write {
            if success {
                log.debug("Completed pending uploads \(sampleKeys.joined(separator: ", "))", "uploadProgress")
                let objects = sampleKeys.flatMap { realm.object(ofType: UMLogEntry.self, forPrimaryKey: $0 as AnyObject) }
                realm.delete(objects)
            }

            // Dispatch pending upload retries
            self.retryPendingUploads()

            if syncMode{
                if logEntryBatchBuffer.isEmpty {
                    syncMode = false
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncEndedNotification), object: nil)
                } else {
                    let info = ["count": logEntryBatchBuffer.count]
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncProgressNotification), object: nil, userInfo: info)
                }
            }
        }
    }

    func syncLogEntryBuffer() {
        if !logEntryBatchBuffer.isEmpty {
            log.debug("Sync start", "uploadExec")
            autoreleasepool { _ in
                let batchSize = min(logEntryBatchBuffer.count, logEntryUploadBatchSize)
                let uploadSlice = logEntryBatchBuffer[0..<batchSize]

                var block: [[String:AnyObject]] = []
                var blockKeys: [String] = []

                let realm = try! Realm()

                let blockBuildStart = Date()
                uploadSlice.forEach { batch in
                    autoreleasepool { _ in
                        if let logEntry = realm.object(ofType: UMLogEntry.self, forPrimaryKey: batch.0 as AnyObject) {
                            if let params = self.jsonifyLogEntry(logEntry: logEntry, added: batch.1, deleted: batch.2) {
                                log.debug("Serialized UMLogEntry \(batch.1.count) \(batch.2.count)", "uploadExec")
                                logEntry.logEntryCompact(feature: "uploadExec")
                                block.append(params)
                                blockKeys.append(batch.0)
                            } else {
                                log.warning("Unable to JSONify log entry", "serialize:uploadExec")
                                logEntry.logEntry(feature: "serialize:uploadExec")
                            }
                        } else {
                            log.debug("No log entry found for key: \(batch.0)", "realm:uploadExec")
                        }
                    }
                }

//                log.debug("Blockbuild: \(Date().timeIntervalSinceDate(blockBuildStart))", "uploadExec")
             

                if block.count > 0 {
                    log.debug("Syncing \(block.count) log entries with keys \(blockKeys.joined(separator: ", "))", "uploadExec")

                    Service.json(route: MCRouter.AddSeqMeasures(["block": block as AnyObject]), statusCode: 200..<300, tag: "UPLOADLOG") {
                        _, response, result in
                        log.debug("Upload log entries: \(result.value)", "uploadExec")
                        self.onCompletedUpload(success: result.isSuccess, sampleKeys: blockKeys)
                    }
                }
                else {
                    log.debug("Skipping log entry sync, no log entries to upload", "uploadExec")
                }

                // Recur as an upload loop while we still have elements in the upload queue.
                logEntryBatchBuffer.removeFirst(batchSize)
                if !logEntryBatchBuffer.isEmpty {
                    log.debug("Remaining batches: \(logEntryBatchBuffer.count)", "uploadExec")
                    logEntryUploadAsync?.cancel()
//                    logEntryUploadAsync = Async(self.uploadQueue, after: logEntryUploadDelay) {
                        self.syncLogEntryBuffer()
                    }
                }
//            }
        } else {
            log.debug("Skipping syncLogEntryBuffer, empty upload buffer", "uploadExec")
        }
    }

    func batchLogEntryUpload(logEntryKey: String, added: [HKSample], deleted: [NSUUID]) {
        if logEntryBatchBuffer.isEmpty {
            logEntryBatchBuffer.append((logEntryKey, added, deleted))
        }
        else if logEntryKey < logEntryBatchBuffer[0].0 {
            logEntryBatchBuffer.insert((logEntryKey, added, deleted), at: 0)
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
                    logEntryBatchBuffer.insert((logEntryKey, added, deleted), at: index)
                } else {
                    log.debug("Skipping duplicate pending for \(logEntryKey)", "uploadExec")
                }
            }
        }


        logEntryUploadAsync?.cancel()
//        logEntryUploadAsync = Async(self.uploadQueue, after: logEntryUploadDelay) {
 //           self.syncLogEntryBuffer() 
 //       }

        // Post notifications if we have a substantial amount of work.
        if !syncMode && logEntryBatchBuffer.count > syncNotificationLimit {
            syncMode = true
            let info = ["count": logEntryBatchBuffer.count]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncBeganNotification), object: nil, userInfo: info)
        }

        // Throttle if upload buffer is large.
        if logEntryBatchBuffer.count > uploadBufferThrottleLimit && !Thread.isMainThread {
            log.debug("Throttling upload enqueueing for \(logEntryUploadDelay * 3) secs", "perf:uploadExec")
            Thread.sleep(forTimeInterval: logEntryUploadDelay * 3)
        } else {
            log.debug("Batched after UL: \(logEntryBatchBuffer.count)", "uploadExec")
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
//                    batchLogEntryUpload(logEntryKey: logEntry.compoundKey, added: added, deleted: deleted.map { $0.uuid as! NSUUID })
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
//                            batchLogEntryUpload(logEntryKey: logEntry.compoundKey, added: lAdded, deleted: lDeleted.map { $0.uuid as! NSUUID })
                        }
                    }
                }

                // Set the latest anchor for which we're attempting an upload (rather than on upload success).  
                // This ensures subsequent parallel anchor queries move forward from this anchor.
//                setAnchorForType(anchor: anchor, forType: type)
            }
        }
    }
    

    public func deleteSamples(startDate: Date, endDate: Date, measures: [String:AnyObject], completion: @escaping (Bool) -> Void) {
        // Delete remotely.
        let params: [String: AnyObject] = [
            "tstart"  : Int(floor(startDate.timeIntervalSince1970)) as AnyObject,
            "tend"    : Int(ceil(endDate.timeIntervalSince1970)) as AnyObject,
            "columns" : measures as AnyObject
        ]

        Service.json(route: MCRouter.RemoveMeasures(params), statusCode: 200..<300, tag: "DELPOST") {
            _, response, result in
            log.debug("Deletions: \(result.value)", "deleteSamples")
            if !result.isSuccess {
                log.error("Failed to delete samples on the server, server may potentially diverge from device.", "deleteSamples")
            }
            completion(result.isSuccess)
        }
    }

    // MARK: - Upload helpers.

    private func uploadInitialAnchorForType(type: HKSampleType, completion: @escaping (Bool, (Bool, Date)?) -> Void) {
        let tname = type.displayText ?? type.identifier
        if let wend = UserManager.sharedManager.getHistoricalRangeStartForType(type: type) {
            let dwend = Date(timeIntervalSinceReferenceDate: wend)
            let dwstart = UserManager.sharedManager.decrAnchorDate(d: dwend)
            let pred = HKQuery.predicateForSamples(withStart: dwstart as Date, end: dwend as Date, options: [])
            MCHealthManager.sharedManager.fetchSamplesOfType(type, predicate: pred) { (samples, error) in
                guard error == nil else {
                    log.error("Could not get initial anchor samples for: \(tname) \(dwstart) \(dwend)")
                    return
                }

                let hksamples = samples as! [HKSample]
                UploadManager.sharedManager.putSample(type: type, added: hksamples)
                UserManager.sharedManager.decrHistoricalRangeStartForType(type: type)

                log.debug("Uploaded \(tname) to \(dwstart)", "uploadAcqRange")
                if let min = UserManager.sharedManager.getHistoricalRangeMinForType(type: type) {
                    let dmin = Date(timeIntervalSinceReferenceDate: min)
                    if dwstart > dmin {
                        completion(false, (false, dwstart))
                        Async.background(after: 0.5) { self.uploadInitialAnchorForType(type: type, completion: completion) }
                    } else {
                        completion(false, (true, dmin))
                    }
                } else {
                    log.error("No earliest sample found for \(tname)", "uploadAcqRange")
                }
            }
        } else {
            log.debug("No bulk anchor date found for \(tname)", "uploadAcqRange")
        }
    }

    private func backgroundUploadForType(type: HKSampleType, completion: @escaping (Bool, (Bool, Date)?) -> Void) {
        let tname = type.displayText ?? type.identifier
        if let _ = UserManager.sharedManager.getHistoricalRangeForType(type: type),
            let _ = UserManager.sharedManager.getHistoricalRangeMinForType(type: type)
        {
//            self.uploadInitialAnchorForType(type: type, completion: completion)
        } else {
            log.warning("No historical range found for \(tname)", "uploadAcqRange")
            completion(true, nil)
        }
    }

    // MARK: - Observers

    public func registerUploadObservers() {
        MCHealthManager.sharedManager.authorizeHealthKit { (success, _) -> Void in
            guard success else { return }

            UploadManager.sharedManager.resetUploadManager()
            UploadManager.sharedManager.retryPendingUploads(force: true)

            let typeChunks = HMConstants.sharedInstance.healthKitTypesToObserve.splitBy(size: 5)

            typeChunks.enumerated().forEach { (index, types) in
//                Async(after: 0.5 + (Double(index) * 0.2)) {
                Async.main(after: 0.5 + (Double(index) * 0.2)) {
                    types.forEach { type in
                        IOSHealthManager.sharedManager.startBackgroundObserverForType(type: type, getAnchorCallback: UploadManager.sharedManager.getNextAnchor)
                        { (added, deleted, newAnchor, error, completion) -> Void in
                            guard error == nil else {
                                log.error("Failed to register observers: \(error)", "uploadObservers")
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
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncDidUpdateCircadianEvents), object: nil)
                            }

                            if ( userAdded.count > 0 || deleted.count > 0 ) {
//                                UploadManager.sharedManager.uploadAnchorCallback(type: type, anchor: newAnchor, added: userAdded, deleted: deleted)
                            }
                            else {
                                // Advance the anchor for this type so that we don't see the synchronized entries again.
                                if let anchor = newAnchor, withSyncInfo {
//                                    setAnchorForType(anchor: anchor, forType: type)
                                }

                                log.debug("Skipping upload for \(typeId): \(userAdded.count) insertions \(deleted.count) deletions", "uploadObservers")
                            }
                            completion()
                        }
                    }
                }
            }
        }
    }

    public func deregisterUploadObservers(completion: @escaping (Bool, Error?) -> Void) {
        MCHealthManager.sharedManager.authorizeHealthKit { (success, _) -> Void in
            guard success else { return }
            IOSHealthManager.sharedManager.stopAllBackgroundObservers { (success, error) in
                guard success && error == nil else {
                    log.error(error!.localizedDescription)
                    return
                }
//                logEntryUploadAsync?.cancel()
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

        if let column = HMConstants.sharedInstance.hkToMCDB[type.identifier.hash] {
            columnGroups.append([column])
        }
        else if let (activity_category, quantity) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[type.identifier] {
            columnGroups.append(["activity_duration", "activity_type", "activity_value"])
        }
        else if type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue {
            // Issue queries for both systolic and diastolic.
            columnGroups.append([HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifier.bloodPressureDiastolic.hashValue]!,
                                 HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifier.bloodPressureSystolic.hashValue]!])
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
    func columnDictOfType(type: HKSampleType) -> [String:Any] {
        var columnIndex = 0
        var columns : [String:Any] = [:]

        if let column = HMConstants.sharedInstance.hkToMCDB[type.identifier.hash] {
            columns[String(columnIndex)] = column
            columnIndex += 1
        }
        else if let (activity_category, quantity) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[type.identifier] {
            columns[String(columnIndex)]   = ["activity_duration"]
            columns[String(columnIndex+1)] = ["activity_type"]
            columns[String(columnIndex+2)] = ["activity_value"]
            columnIndex += 3
        }
        else if type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue {
            // Issue queries for both systolic and diastolic.
            columns[String(columnIndex)]   = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifier.bloodPressureDiastolic.hashValue]!
            columns[String(columnIndex+1)] = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifier.bloodPressureSystolic.hashValue]!
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
//        self.deviceSync = Async.background(after: 30.0) {
            // Refresh last acquired
            UserManager.sharedManager.pullAcquisitionSeq { result in
                guard result.error == nil else {

                    // TODO: exponential backoff.
                    log.warning("Failed to get acquisition state", "syncSeqIds")
 //                   self.syncDeviceMeasuresPeriodically()
                    return
                }

                // Invoke sync
//                self.syncDeviceMeasures(type: HKWorkoutType.workoutType(), deviceClass: "alexa", deviceId: "0")

                // Tail call
//                self.syncDeviceMeasuresPeriodically()
            }
        }
//    }

    func syncToSeqId(type: HKSampleType, deviceClass: String, deviceId: String,
                     queryOffset: Int, localSeq: Int, remoteSeq: Int, columns: [String: AnyObject])
    {
        let limit: Int = 100

        let params: [String: AnyObject] = [
            "with_ids": true as AnyObject,
            "sstart": localSeq as AnyObject,
            "send": remoteSeq as AnyObject,
            "device_class": deviceClassParam(deviceClass: deviceClass) as AnyObject,
            "device_id": deviceId as AnyObject,
            "columns": columns as AnyObject,
            "offset": queryOffset as AnyObject,
            "limit": limit  as AnyObject
        ]

        log.debug("Sync \(type.identifier) \(deviceClass) \(deviceId) from \(localSeq) to \(remoteSeq) with params \(params)", "syncSeqIds")

        Service.json(route: MCRouter.GetMeasures(params), statusCode: 200..<300, tag: "GETMEAS") {
            _, response, result in

            guard result.isSuccess else {
                // TODO: retry w/ backoff.
                log.error("Failed to sync server samples, server may potentially diverge from device.", "syncSeqIds")
                return
            }

            log.info("Sync response on \(queryOffset) \(localSeq) \(remoteSeq) for \(type.identifier) \(deviceClass) \(deviceId)", "syncSeqIds")

            // Write retrieved data into HealthKit, ensuring that we add metadata tags for sample ids.
            self.writeDeviceMeasures(type: type, deviceClass: deviceClass, deviceId: deviceId, payload: result.value as AnyObject?) {
                (success, completedSeq, payloadSize, err) in
                guard success && err == nil else {
                    log.error("Sync failed to parse and write measures: \(completedSeq) \(payloadSize)", "syncSeqIds")
                    log.error(err!.localizedDescription, "syncSeqIds")
                    return
                }

                // Recur while we got a non-empty set of measures, and we have not yet reached our target remote seq.
                // TODO: throttling.

                log.info("Sync recur on \(queryOffset) \(completedSeq) \(localSeq) \(remoteSeq) \(payloadSize) for \(type.identifier) \(deviceClass) \(deviceId)", "syncSeqIds")

                if let numMeasures = payloadSize, let seq = completedSeq, numMeasures == limit && seq < remoteSeq {
                    let nextOffset = queryOffset + numMeasures
                    self.syncToSeqId(type: type, deviceClass: deviceClass, deviceId: deviceId, queryOffset: nextOffset, localSeq: seq, remoteSeq: remoteSeq, columns: columns)
                }
                else if let numMeasures = payloadSize, let seq = completedSeq {
                    log.warning("Sync stopped for \(type.identifier) \(deviceClass) \(deviceId) at \(seq), offset \(queryOffset), #results \(numMeasures)", "syncSeqIds")
                }
                else {
                    log.error("Sync stopped for \(type.identifier) \(deviceClass) \(deviceId) with \(completedSeq) \(payloadSize), offset \(queryOffset)", "syncSeqIds")
                }
            }
        }
    }

    // Note: we should make sure that when we add the events to the local HealthKit store,
    // we include metadata to ensure it will not be processed for uploads by our anchor query.
    public func syncDeviceMeasures(type: HKSampleType, deviceClass: String, deviceId: String) {
        if let classInfo = UserManager.sharedManager.getAcquisitionSeq(type: type) as? [String:AnyObject]
        {
            log.warning("Retrieving remote seq for \(type.identifier), \(deviceClass), \(deviceId) from \(classInfo)", "syncSeqIds")
            if let dataForClass = classInfo[deviceClass] as? [String: AnyObject],
                let seqInfo = dataForClass[deviceId] as? [String: AnyObject],
                let syncSeqId = seqInfo[remoteSyncSeqIdKey] as? Int
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

                let columns = columnDictOfType(type: type)

                let key = seqCacheKey(type: type, deviceClass: deviceClass, deviceId: deviceId)

                if Defaults.hasKey(key) {

                    log.debug("Cache fetch local seq for key \(key)", "syncSeqIds")

                    localSeq = Defaults.integer(forKey: key)
                    if let localSeq = localSeq, localSeq < remoteSeq {
                        syncToSeqId(type: type, deviceClass: deviceClass, deviceId: deviceId, queryOffset: 0, localSeq: localSeq + 1, remoteSeq: remoteSeq, columns: columns as [String : AnyObject])
                    }
                    else {
                        log.debug("Cache hit result for key \(key) \(localSeq)", "syncSeqIds")
                    }
                }
                else {

                    log.debug("HK fetch local seq for key \(key)", "syncSeqIds")

                    let conjuncts = [
                        HKQuery.predicateForObjects(withMetadataKey: "DeviceClass", operatorType: NSComparisonPredicate.Operator.equalTo, value: deviceClass),
                        HKQuery.predicateForObjects(withMetadataKey: "DeviceId", operatorType: NSComparisonPredicate.Operator.equalTo, value: deviceId),
                        HKQuery.predicateForObjects(withMetadataKey: "SeqId")
                    ]

                    let devicePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: conjuncts)

                    MCHealthManager.sharedManager.fetchSamplesOfType(type, predicate: devicePredicate, limit: 1, sortDescriptors: [dateDesc]) { (samples, error) in
                        guard error == nil else {
                            log.error(error!.localizedDescription)
                            return
                        }

                        let rmin = samples.reduce(Int.min, { (acc, sample) in
                            if let s = sample as? HKObject, let m = s.metadata {
                                if let seq = m["SeqId"] as? Int {
                                    return min(acc, seq)
                                }
                                else if let s = m["SeqId"] as? String, let seq = Int(s) {
                                    return min(acc, seq)
                                }
                            }
                            return acc
                        })

                        if rmin != Int.min { localSeq = rmin + 1 }
                        else if localSeq == nil { localSeq = 0 }

                        if let localSeq = localSeq, localSeq < remoteSeq {
                            self.syncToSeqId(type: type, deviceClass: deviceClass, deviceId: deviceId, queryOffset: 0, localSeq: localSeq, remoteSeq: remoteSeq, columns: columns as [String : AnyObject])
                        }
                        else {
                            log.debug("HK result for key \(key) \(localSeq)", "syncSeqIds")
                        }

                    }
                }
            }
            else {
                log.warning("Invalid seq for \(type.identifier), \(deviceClass), \(deviceId)", "status:syncSeqIds")
            }
        }
        else {
            log.warning("Invalid seq for \(type.identifier), \(deviceClass), \(deviceId)", "status:syncSeqIds")
        }
    }

    private func processSyncMeasure(type: HKSampleType, deviceClass: String, deviceId: String,
                                    sample: [String: AnyObject], columnGroups: [[String]]) -> (Bool, Int?, [HKSample])
    {
        log.debug("Process sync for \(type.displayText ?? type.identifier): \(sample)", "syncSeqIds")

        var id: Int! = nil
        var ts: Date! = nil

        if let s = sample["id"] as? String, let i = Int(s) { id = i }
        else if let i = sample["id"] as? Int { id = i }

//        if let s = sample["ts"] as? String, let t = s.toDate(.ISO8601Format(.Full)) { ts = t }
//        if let s = sample["ts"] as? String, let t = s.) { ts = t }
//        if let s = sample["ts"] as? String, let t = Date(s) { ts = t }

        let values: [[AnyObject]] = columnGroups.flatMap { cgroup in
            var vgroup: [AnyObject] = []

            if cgroup.contains("meal_duration") {
                if let m = sample["meal_duration"], let f = sample["food_type"] {
                    vgroup = [m, f]
                }
                else if let d = sample["activity_duration"], let t = sample["activity_type"], let v = sample["activity_value"] {
                    vgroup = [d,t,v]
                }
                return vgroup.count > 0 ? vgroup : nil
            }

            vgroup = cgroup.flatMap { sample[$0] }
            return vgroup.count == cgroup.count ? vgroup : nil
        }

        guard !(id == nil || ts == nil || values.count != columnGroups.count) else {
            log.warning("Failed to sync \(type.identifier) \(deviceClass) \(deviceId) for \(id) \(ts) \(values.count) \(columnGroups.count) \(sample)", "syncSeqIds")
            return (false, nil, [])
        }

        var samples: [HKSample] = []
        let metadata: [String: AnyObject] = ["DeviceClass": deviceClass as AnyObject, "DeviceID": deviceId as AnyObject, "SeqId": id as AnyObject]

        columnGroups.enumerated().forEach { (index, cgroup) in
            let vgroup = values[index]

            var meal: [String: AnyObject] = [:]
            var activity: [String: AnyObject] = [:]

            cgroup.enumerated().forEach { (index, column) in
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
                        if let s = vgroup[index] as? String, let d = Double(s) { dvalue = d }

                        if let value = dvalue, let typeIdentifier = HMConstants.sharedInstance.mcdbToHK[column] {
                            switch typeIdentifier {
                            case HKCategoryTypeIdentifier.sleepAnalysis.hashValue:
                                let sampleType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
                                let ts_end = ts.addingTimeInterval(value)

                                let catval = HKCategoryValueSleepAnalysis.asleep.rawValue
                                let hkSample = HKCategorySample(type: sampleType, value: catval, start: ts as Date, end: ts_end as Date, metadata: metadata)

                                samples.append(hkSample)

                            case HKCategoryTypeIdentifier.appleStandHour.hashValue:
                                let sampleType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.appleStandHour)!
                                let ts_end = ts.addingTimeInterval(value)

                                let catval = HKCategoryValueAppleStandHour.stood.rawValue
                                let hkSample = HKCategorySample(type: sampleType, value: catval, start: ts as Date, end: ts_end as Date, metadata: metadata)

                                samples.append(hkSample)

                            default:
                                let sampleType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.appleStandHour)!
 //                               let hkQuantity = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: value)
                                let ts_end = ts.addingTimeInterval(value)
                                
                                let catval = HKCategoryValueAppleStandHour.stood.rawValue
                                let hkSample = HKCategorySample(type: sampleType, value: catval, start: ts as Date, end: ts_end as Date, metadata: metadata)
//                                let hkSample = HKQuantitySample(type: sampleType, quantity: hkQuantity, startDate: ts, endDate: ts, metadata: metadata)
                                
                                samples.append(hkSample)
                            }
                        }
                    }
                }
            }

            if meal.count > 0 {
                // Add meal object
                var duration: Double! = nil
                if let s = meal["meal_duration"] as? String, let d = Double(s) { duration = d }
                else if let d = meal["meal_duration"] as? Double { duration = d }

                if let duration = duration,
                    let food_type = meal["food_type"] as? [[String: AnyObject]],
                    let meal_type = food_type[0]["value"] as? String
                {
                    let ts_end = ts.addingTimeInterval(duration)
                    let energy = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0.0)
                    let distance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0.0)
                    let wMetadata: [String: AnyObject] = ["Meal Type": meal_type as AnyObject, "DeviceClass": deviceClass as AnyObject, "DeviceId": deviceId as AnyObject, "SeqId": id as AnyObject]

                    let hkSample = HKWorkout(activityType: HKWorkoutActivityType.preparationAndRecovery, start: ts as Date, end: ts_end as Date, duration: duration, totalEnergyBurned: energy, totalDistance: distance, metadata: wMetadata)

                    samples.append(hkSample)
                }
            }

            if activity.count > 0 {
                // Add activity object
                var duration: Double! = nil
                var activity_type: Int! = nil

                if let s = activity["activity_duration"] as? String, let d = Double(s) { duration = d }
                else if let d = activity["activity_duration"] as? Double { duration = d }

                if let s = activity["activity_type"] as? String, let i = Int(s) { activity_type = i }
                else if let i = activity["activity_type"] as? Int { activity_type = i }

                if let duration = duration, let activity_type = activity_type {
                    let ts_end = ts.addingTimeInterval(duration)

                    if let typeIdentifier = HMConstants.sharedInstance.mcActivityToHKQuantity[activity_type] {
                        let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: typeIdentifier))!

                        var qKey = ""
                        switch typeIdentifier {
                        case HKQuantityTypeIdentifier.stepCount.rawValue:
                            qKey = "step_count"

                        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                            qKey = "flights_climbed"


                        case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
                            qKey = "distance_walking_running"

                        default:
                            qKey = ""
                        }

                        if !qKey.isEmpty {
                            var hkQuantity: HKQuantity! = nil
                            if let quantities = activity["activity_value"] as? [String: AnyObject], let s = quantities["step_count"] as? String, let i = Int(s)
                            {
                                hkQuantity = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: Double(i))
                            }
                            else if let quantities = activity["activity_value"] as? [String: AnyObject], let i = quantities["step_count"] as? Int
                            {
                                hkQuantity = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: Double(i))

                            }
                            let hkSample = HKQuantitySample(type: sampleType, quantity: hkQuantity, start: ts as Date, end: ts as Date, metadata: metadata)

                            samples.append(hkSample)
                        }
                    }
                    else if let hkActivityType = HMConstants.sharedInstance.mcActivityToHKActivity[activity_type] {
                        var energy: Double! = nil
                        var distance: Double! = nil

                        if let v = activity["activity_value"] as? [String: AnyObject], let e = v["kcal_burned"] as? Double { energy = e }
                        else if let v = activity["activity_value"] as? [String: AnyObject], let s = v["kcal_burned"] as? String, let e = Double(s) { energy = e }

                        if let v = activity["activity_value"] as? [String: AnyObject], let d = v["distance"] as? Double { distance = d }
                        else if let v = activity["activity_value"] as? [String: AnyObject], let s = v["distance"] as? String, let d = Double(s) { distance = d }

                        let energyQ = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: energy == nil ? 0.0 : energy!)
                        let distanceQ = HKQuantity(unit: HKUnit.meter(), doubleValue: distance == nil ? 0.0 : distance!)

                        let hkSample = HKWorkout(activityType: hkActivityType, start: ts as Date, end: ts_end as Date, duration: duration, totalEnergyBurned: energyQ, totalDistance: distanceQ, metadata: metadata)

                        samples.append(hkSample)
                    }
                }
            }
        }

        return (true, id, samples)
    }

    private func writeDeviceMeasures(type: HKSampleType, deviceClass: String, deviceId: String, payload: AnyObject?,
                                     completion: @escaping (Bool, Int?, Int?, Error?) -> Void)
    {
        var failed = false

        var maxSampleId: Int! = nil
        var samples: [HKSample] = []

        let columnGroups = columnGroupsOfType(type: type)

        if let response = payload as? [String:AnyObject], let measures = response["items"] as? [[String:AnyObject]] {
            for sample in measures {
                let (success, sampleId, newSamples) = processSyncMeasure(type: type, deviceClass: deviceClass, deviceId: deviceId, sample: sample, columnGroups: columnGroups)

                failed = !success
                if failed { break }
                if let cmax = sampleId { maxSampleId = maxSampleId == nil ? cmax : max(maxSampleId, cmax) }
                samples.append(contentsOf: newSamples)
            }

            log.info("Write parsed \(samples.count) samples", "syncSeqIds")

            // Only add samples if there were no parsing errors.
            if let maxId = maxSampleId, !failed {
                MCHealthManager.sharedManager.saveSamples(samples) { (success, err) in
                    guard success && err == nil else {
                        log.error("Failed to sync \(type.identifier) \(deviceClass) \(deviceId) to \(maxId)", "syncSeqIds")
                        return completion(!failed, nil, measures.count, err)
                    }

                    log.info("Advance pptr for \(type.identifier) \(deviceClass) \(deviceId) advance pptr to \(maxId)", "syncSeqIds")

                    let key = self.seqCacheKey(type: type, deviceClass: deviceClass, deviceId: deviceId)
                    Defaults.set(maxId, forKey: key)
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
