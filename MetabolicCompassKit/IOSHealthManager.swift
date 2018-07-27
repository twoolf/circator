//
//  HealthManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/27/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Darwin
import HealthKit
import WatchConnectivity
import Async
import SwiftDate
import MCCircadianQueries

public class IOSHealthManager: NSObject, WCSessionDelegate {
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    public static let sharedManager = IOSHealthManager()
    var observerQueries: [HKQuery] = []
    
    let anchoredQueriesQueue : OperationQueue

    private override init() {
        anchoredQueriesQueue = OperationQueue()
        anchoredQueriesQueue.maxConcurrentOperationCount = 5
        super.init()
        connectWatch()
    }

    public func reset() {
        MCHealthManager.sharedManager.reset()
        self.updateWatchContext()
    }


    // MARK: - Apple Watch

    func connectWatch() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func updateWatchContext() {
        // This release currently removed watch support
        guard WCSession.isSupported() && WCSession.default.isWatchAppInstalled else {
            return
        }
        do {
            let applicationContext = [String:Any]()
            /*
            let sampleFormatter = SampleFormatter()
            let applicationContext = MCHealthManager.sharedManager.mostRecentSamples.map {
                (sampleType, results) -> [String: String] in
                return [
                    "sampleTypeIdentifier": sampleType.identifier,
                    "displaySampleType": sampleType.displayText!,
                    "value": sampleFormatter.stringFromSamples(results)
                ]
            }
            */
            try WCSession.default.updateApplicationContext(["context": applicationContext])
        } catch {
            log.error((error as Error).localizedDescription)
        }
    }


    // MARK: - Push-based HealthKit data access.

    private func fetchAnchoredSamplesOfType(type: HKSampleType, predicate: NSPredicate?, anchor: HKQueryAnchor?,
                                            maxResults: Int, callContinuously: Bool, completion: @escaping HMAnchorSamplesBlock)
    {
        let hkAnchor = anchor ?? noAnchor
        let onAnchorQueryResults: HMAnchorQueryBlock = {
            (query, addedObjects, deletedObjects, newAnchor, Error) -> Void in
            completion(addedObjects ?? [], deletedObjects ?? [], newAnchor, Error)
        }
        let anchoredQuery = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: hkAnchor, limit: Int(maxResults), resultsHandler: onAnchorQueryResults )
        if callContinuously {
            anchoredQuery.updateHandler = onAnchorQueryResults 
        }
        MCHealthManager.sharedManager.healthKitStore.execute(anchoredQuery)
    }

    public func startBackgroundObserverForType(type: HKSampleType, maxResultsPerQuery: Int = Int(HKObjectQueryNoLimit),
                                               getAnchorCallback: @escaping (HKSampleType) -> (Bool, HKQueryAnchor?, NSPredicate?),
                                               anchorQueryCallback: @escaping HMAnchorSamplesCBlock) -> Void
    {
        let onBackgroundStarted = {(success: Bool, Error: Error?) -> Void in
            guard success else {
                log.error(Error!.localizedDescription)
                return
            }

            let obsQuery = HKObserverQuery(sampleType: type, predicate: nil) {
                query, completion, obsError in
                guard obsError == nil else {
                    log.error(obsError!.localizedDescription)
                    return
                }

                // Run the anchor query as a background task, to support interactive queries for UI
                // components that run at higher priority.
                
                self.anchoredQueriesQueue.addOperation {
                    let tname = type.displayText ?? type.identifier
                    let asCircadian = type.identifier == HKWorkoutTypeIdentifier.description || type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue

                    let (needsOldestSamples, anchor, predicate) = getAnchorCallback(type)
                    if needsOldestSamples {
                        Async.background(after: 0.5) {
                            log.debug("Registering bulk ingestion availability for: \(tname)", "registerObservers")
                            MCHealthManager.sharedManager.getOldestSampleDateForType(type) { date in
                                if let minDate = date {
                                    log.debug("Lower bound date for \(type.displayText ?? type.identifier): \(minDate)", "registerObservers")
                                    UserManager.sharedManager.setHistoricalRangeMinForType(type: type, min: minDate as Date, sync: true)
                                }
                            }
                        }
                    }

                    log.debug("Anchor query for \(tname)", "anchorQuery")
                    self.fetchAnchoredSamplesOfType(type: type, predicate: predicate, anchor: anchor, maxResults: maxResultsPerQuery, callContinuously: false) {
                        (added, deleted, newAnchor, error) -> Void in

                        log.debug("Anchor query completion for \(tname), size: +\(added.count) -\(deleted.count)", "anchorQuery")
                        if added.count > 0 || deleted.count > 0 {
                            MCHealthManager.sharedManager.invalidateCacheForUpdates(type, added: (asCircadian ? added : nil))
                        }

                        // Data-driven notifications.
                        if asCircadian {
                            NotificationManager.sharedManager.onCircadianEvents(events: added)
                        }

                        // Callback invocation.
                        anchorQueryCallback(added, deleted, newAnchor, error, completion)
                    }
                }
            }
            self.observerQueries.append(obsQuery)
            MCHealthManager.sharedManager.healthKitStore.execute(obsQuery)
        }
        MCHealthManager.sharedManager.healthKitStore.enableBackgroundDelivery(for: type, frequency: HKUpdateFrequency.immediate, withCompletion: onBackgroundStarted)
    }

    public func stopAllBackgroundObservers(completion: @escaping (Bool, Error?) -> Void) {
        MCHealthManager.sharedManager.healthKitStore.disableAllBackgroundDelivery { (success, error) in
            if !(success && error == nil) { log.error(error!.localizedDescription) }
            else {
                self.observerQueries.forEach { MCHealthManager.sharedManager.healthKitStore.stop($0) }
                self.observerQueries.removeAll()
            }
            completion(success, error)
        }
    }

    
    // MARK: - Chart data access

    private func iterate(periods: [HealthManagerStatisticsRangeType], forType sampleType: HKSampleType, inGroup group: DispatchGroup) {
        let type = sampleType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : sampleType.identifier
        
        let keyPrefix = type
        
        for period in periods {
            //                log.debug("Collecting chart data for \(keyPrefix) \(period)", "fetchCharts")
            
            group.enter()
            // We should get max and min values. because for this type we are using scatter chart
            switch type {
            case HKQuantityTypeIdentifier.heartRate.rawValue, HKQuantityTypeIdentifier.uvExposure.rawValue:
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    group.leave()
                }
            case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:
                // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
                let diastolicKeyPrefix = HKQuantityTypeIdentifier.bloodPressureDiastolic
                let bloodPressureGroup = DispatchGroup()
                
                bloodPressureGroup.enter()
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: type))!, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    bloodPressureGroup.leave()
                }
                
                let diastolicType = HKQuantityTypeIdentifier.bloodPressureDiastolic
                bloodPressureGroup.enter()
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix.rawValue, sampleType: HKObjectType.quantityType(forIdentifier: diastolicType)!, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    bloodPressureGroup.leave()
                }
                
                group.notify(queue: DispatchQueue.main) {
                    group.leave() //leave main group
                }
            default:
                MCHealthManager.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .discreteAverage) {
                    if $1 != nil { log.error($1!.localizedDescription) }
                    group.leave() //leave main group
                }
            }
        }
    }
    
    public func collectDataForCharts(shouldCleanCache: Bool = true) {
        
        log.debug("Clearing HMAggregateCache expired objects", "clearCache")
        if shouldCleanCache {
            MCHealthManager.sharedManager.aggregateCache.removeExpiredObjects()
            MCHealthManager.sharedManager.circadianCache.removeExpiredObjects()
        }

        let periods: [HealthManagerStatisticsRangeType] = [
            HealthManagerStatisticsRangeType.week
            , HealthManagerStatisticsRangeType.month
            , HealthManagerStatisticsRangeType.year
        ]

        let group = DispatchGroup()

        for sampleType in PreviewManager.manageChartsSampleTypes {
            self.iterate(periods: periods, forType: sampleType, inGroup: group)
        }

        // After completion, notify that we finished collecting statistics for all types
        group.notify(queue: DispatchQueue.global()) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: HMDidUpdatedChartsData), object: nil)
        }
    }

    public func getChartDataForQuantity(sampleType: HKSampleType, inPeriod period: HealthManagerStatisticsRangeType, completion: @escaping (Any) -> Void) {
        let type = sampleType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : sampleType.identifier
        let keyPrefix = type
        var key : String

        var asMinMax = false
        var asBP = false

        let finalize : (MCAggregateSample) -> MCSample = {
            var agg = $0; agg.final(); return agg as MCSample
        }

        let finalizeAgg : (HKStatisticsOptions, MCAggregateSample) -> MCSample = {
            var agg = $1; agg.finalAggregate($0); return agg as MCSample
        }

        if  type == HKQuantityTypeIdentifier.heartRate.rawValue ||
            type == HKQuantityTypeIdentifier.uvExposure.rawValue ||
            type == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
            key = MCHealthManager.sharedManager.getPeriodCacheKey(keyPrefix, aggOp: [.discreteMin, .discreteMax], period: period)
            asMinMax = true
            asBP = type == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue
        } else {
            key = MCHealthManager.sharedManager.getPeriodCacheKey(keyPrefix, aggOp: .discreteAverage, period: period)
        }

//        if let aggArray = MCHealthManager.sharedManager.aggregateCache[key] {
//            log.debug("Cache hit for \(key) (size \(aggArray.aggregates.count))", "fetchCharts")
//        } else {
//            log.debug("Cache miss for \(key)", "fetchCharts")
//        }

        if asMinMax {
            if asBP {
                let diastolicKeyPrefix = HKQuantityTypeIdentifier.bloodPressureDiastolic
                let diastolicType = HKQuantityTypeIdentifier.bloodPressureDiastolic
                let bloodPressureGroup = DispatchGroup()

                bloodPressureGroup.enter()
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: type))!, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    bloodPressureGroup.leave()
                }

                bloodPressureGroup.enter()
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix.rawValue, sampleType: HKObjectType.quantityType(forIdentifier: diastolicType)!, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    bloodPressureGroup.leave()
                }


                bloodPressureGroup.notify(queue: DispatchQueue.main) {
                    let diastolicKey = MCHealthManager.sharedManager.getPeriodCacheKey(diastolicKeyPrefix.rawValue, aggOp: [.discreteMin, .discreteMax], period: period)

                    if let systolicAggArray = MCHealthManager.sharedManager.aggregateCache[key],
                           let diastolicAggArray = MCHealthManager.sharedManager.aggregateCache[diastolicKey] {
                        completion([systolicAggArray.aggregates.map { return finalizeAgg(.discreteMax, $0).numeralValue! },
                                    systolicAggArray.aggregates.map { return finalizeAgg(.discreteMin, $0).numeralValue! },
                                    diastolicAggArray.aggregates.map { return finalizeAgg(.discreteMax, $0).numeralValue! },
                                    diastolicAggArray.aggregates.map { return finalizeAgg(.discreteMin, $0).numeralValue! }])
                    } else {
                        completion([])
                    }
                }
            } else {
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) { (_, _, error) in
                    guard error == nil || MCHealthManager.sharedManager.aggregateCache[key] != nil else {
                        completion([])
                        return
                    }

                    if let aggArray = MCHealthManager.sharedManager.aggregateCache[key] {
                        let mins = aggArray.aggregates.map { return finalizeAgg(.discreteMin, $0).numeralValue! }
                        let maxs = aggArray.aggregates.map { return finalizeAgg(.discreteMax, $0).numeralValue! }
                        completion([maxs, mins])
                    }
                }
            }
        } else {
            MCHealthManager.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix,
                                                                            sampleType: sampleType,
                                                                                period: period,
                                                                                 aggOp: .discreteAverage) { (_, error) in
                guard error == nil || MCHealthManager.sharedManager.aggregateCache[key] != nil else {
                    completion([])
                    return
                }

            if sampleType == HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) {
            let array = self.arrayOfSleepAggregates(key: key)
            completion(array.map{$0.numeralValue})
        } else {
            if let aggArray = MCHealthManager.sharedManager.aggregateCache[key] {
                completion(aggArray.aggregates.map { return finalize($0).numeralValue! })
            }
        }
    }
}
}

    func arrayOfSleepAggregates(key: String) -> [MCAggregateSample] {
        var array = [MCAggregateSample]()
        if let aggArray = MCHealthManager.sharedManager.aggregateCache[key] {
            for sample in aggArray.aggregates {
                let value = Double(sample.endDate.timeIntervalSince(sample.startDate))
                var hoursValue = value / 3600
                if sample.numeralValue == 0.0 {
                    hoursValue = 0.0
                }
                let type = HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)
                let sample = MCAggregateSample(startDate: sample.startDate,
                                                     endDate: sample.endDate,
                                                       value: hoursValue,
                                                  sampleType: type,
                                                          op: sample.aggOp)
                array.append(sample)
            }
        }
        return array
    }


    //MARK: Working with cache
    public func cleanCache() {
//        log.debug("Clearing HMAggregateCache", "clearCache")
        MCHealthManager.sharedManager.aggregateCache.removeAllObjects()
        MCHealthManager.sharedManager.circadianCache.removeAllObjects()
    }
}

