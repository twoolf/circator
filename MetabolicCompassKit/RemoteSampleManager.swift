//
//  UploadManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import Async
import Granola
import SwiftDate

public class RemoteSampleManager {
    public static let sharedManager = RemoteSampleManager()
    public static let serializer = OMHSerializer()

    // For now we keep this in-memory, and do not persist the buffer.
    // This buffer is lost when the app is killed, but given that we retrieve
    // anchors from the server on restart, we will upload on-device data from
    // the last successfully uploaded anchor regardless of whether we had in-flight
    // uploads present in this buffer.
    var logEntryBuffer: [[String:AnyObject]] = []

    // Log entry upload configuration.
    var logEntryUploadBatchSize: Int = 10
    var logEntryUploadAsync: Async? = nil
    var logEntryUploadDelay: Double = 0.5

    // MARK: - Remote encoding helpers.
    public func encodeRemoteAnchor(anchor: HKQueryAnchor) -> String {
        let encodedAnchor = NSKeyedArchiver.archivedDataWithRootObject(anchor)
        return encodedAnchor.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }

    public func encodeLocalAnchorAsRemote(type: String, localAnchor: AnyObject) -> (String, String)? {
        if let encodedKey = HMConstants.sharedInstance.hkToMCDB[type], data = localAnchor as? NSData {
            return (encodedKey, data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))
        }
        else {
            log.error("Error encoding anchor for \(type)")
            return nil
        }
    }

    public func decodeRemoteAnchor(remoteAnchor: String) -> HKQueryAnchor? {
        if let encodedAnchor = NSData(base64EncodedString: remoteAnchor, options: NSDataBase64DecodingOptions(rawValue: 0)) {
            return NSKeyedUnarchiver.unarchiveObjectWithData(encodedAnchor) as? HKQueryAnchor
        }
        return nil
    }


    // MARK: - Upload helpers.

    public func jsonifySample(sample : HKSample) throws -> [String : AnyObject] {
        return try RemoteSampleManager.serializer.dictForSample(sample)
    }

    public func putSample(jsonObj: [String: AnyObject]) -> () {
        Service.string(MCRouter.AddMeasures(jsonObj), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.info("Upload: \(result.value)")
        }
    }

    public func putSample(jsonObjBlock: [[String:AnyObject]]) -> () {
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
                            self.putSample(jsonObjs)
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

    func syncLogEntryBuffer() {
        if !logEntryBuffer.isEmpty {
            let batchSize = min(logEntryBuffer.count, logEntryUploadBatchSize)
            let uploadSlice = logEntryBuffer[0..<batchSize]
            let params: [String:AnyObject] = ["block": uploadSlice.map {$0}]
            Service.json(MCRouter.AddSeqMeasures(params), statusCode: 200..<300, tag: "UPLOADLOG") {
                _, response, result in
                log.verbose("Upload log entries: \(result.value)")
                self.logEntryBuffer.removeFirst(batchSize)
            }
        }
    }

    func putDeferredLogEntry(logEntry: [String:AnyObject]) {
        logEntryBuffer.append(logEntry)
        logEntryUploadAsync?.cancel()
        logEntryUploadAsync = Async.background(after: logEntryUploadDelay) {
            self.syncLogEntryBuffer()
        }
    }

    public func putLogEntry(type: HKSampleType, anchor: HKQueryAnchor?, added: [HKSample], deleted: [HKDeletedObject], completion: () -> Void) {
        do {
            let tname = type.displayText ?? type.identifier
            if let uploadAnchor = anchor
            {
                let seqid = encodeRemoteAnchor(uploadAnchor)

                let commands: [String:AnyObject] = [
                    "inserts": try added.map(self.jsonifySample),
                    "deletes": deleted.map { return ["uuid": $0.UUID.UUIDString] }
                ]

                var measures: [String] = []
                if let measureid = HMConstants.sharedInstance.hkToMCDB[type.identifier] {
                    measures = [measureid]
                } else if type.identifier == HKWorkoutType.workoutType().identifier {
                    measures = ["meal_duration", "food_type", "activity_duration", "activity_type", "activity_value"]
                } else {
                    log.error("No MCDB measure found for \(type.identifier)")
                    completion()
                    return
                }

                let params: [String:AnyObject] = [
                    "seqid": seqid,
                    "measures": measures,
                    "commands": commands
                ]

                self.putDeferredLogEntry(params)
                completion()

            } else {
                log.error("Unable to upload log entry for \(tname), no valid anchor specified")
                completion()
            }
        } catch {
            log.error(error)
            completion()
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
}