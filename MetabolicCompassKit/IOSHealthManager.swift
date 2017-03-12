//
//  HealthManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/27/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Darwin
import HealthKit
import WatchConnectivity
import Async
import SwiftDate
import MCCircadianQueries

public class IOSHealthManager: NSObject, WCSessionDelegate {

    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?){
    }
    
    public func sessionDidBecomeInactive(session: WCSession) {
    }
    
    public func sessionDidDeactivate(session: WCSession) {
    }
    
    public static let sharedManager = IOSHealthManager()
    var observerQueries: [HKQuery] = []

    private override init() {
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
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }

    func updateWatchContext() {
        // This release currently removed watch support
        guard WCSession.isSupported() && WCSession.defaultSession().watchAppInstalled else {
            return
        }
        do {
            let applicationContext = [:]
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
            try WCSession.defaultSession().updateApplicationContext(["context": applicationContext])
        } catch {
            log.error((error as NSError).localizedDescription)
        }
    }


    // MARK: - Push-based HealthKit data access.

    private func fetchAnchoredSamplesOfType(type: HKSampleType, predicate: NSPredicate?, anchor: HKQueryAnchor?,
                                            maxResults: Int, callContinuously: Bool, completion: HMAnchorSamplesBlock)
    {
        let hkAnchor = anchor ?? noAnchor
        let onAnchorQueryResults: HMAnchorQueryBlock = {
            (query, addedObjects, deletedObjects, newAnchor, nsError) -> Void in
            completion(added: addedObjects ?? [], deleted: deletedObjects ?? [], newAnchor: newAnchor, error: nsError)
        }
        let anchoredQuery = HKAnchoredObjectQuery(type: type, predicate: predicate, anchor: hkAnchor, limit: Int(maxResults), resultsHandler: onAnchorQueryResults)
        if callContinuously {
            anchoredQuery.updateHandler = onAnchorQueryResults
        }
        MCHealthManager.sharedManager.healthKitStore.executeQuery(anchoredQuery)
    }

    public func startBackgroundObserverForType(type: HKSampleType, maxResultsPerQuery: Int = Int(HKObjectQueryNoLimit),
                                               getAnchorCallback: HKSampleType -> (Bool, HKQueryAnchor?, NSPredicate?),
                                               anchorQueryCallback: HMAnchorSamplesCBlock) -> Void
    {
        let onBackgroundStarted = {(success: Bool, nsError: NSError?) -> Void in
            guard success else {
                log.error(nsError!.localizedDescription)
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
                Async.background {
                    let tname = type.displayText ?? type.identifier
                    let asCircadian = type.identifier == HKWorkoutTypeIdentifier || type.identifier == HKCategoryTypeIdentifierSleepAnalysis

                    let (needsOldestSamples, anchor, predicate) = getAnchorCallback(type)
                    if needsOldestSamples {
                        Async.background(after: 0.5) {
                            log.debug("Registering bulk ingestion availability for: \(tname)", feature: "registerObservers")
                            MCHealthManager.sharedManager.getOldestSampleDateForType(type) { date in
                                if let minDate = date {
                                    log.debug("Lower bound date for \(type.displayText ?? type.identifier): \(minDate)", feature: "registerObservers")
                                    UserManager.sharedManager.setHistoricalRangeMinForType(type, min: minDate, sync: true)
                                }
                            }
                        }
                    }

                    log.debug("Anchor query for \(tname)", feature: "anchorQuery")
                    self.fetchAnchoredSamplesOfType(type, predicate: predicate, anchor: anchor, maxResults: maxResultsPerQuery, callContinuously: false) {
                        (added, deleted, newAnchor, error) -> Void in

                        log.debug("Anchor query completion for \(tname), size: +\(added.count) -\(deleted.count)", feature: "anchorQuery")
                        if added.count > 0 || deleted.count > 0 {
                            MCHealthManager.sharedManager.invalidateCacheForUpdates(type, added: (asCircadian ? added : nil))
                        }

                        // Data-driven notifications.
                        if asCircadian {
                            NotificationManager.sharedManager.onCircadianEvents(added)
                        }

                        // Callback invocation.
                        anchorQueryCallback(added: added, deleted: deleted, newAnchor: newAnchor, error: error, completion: completion)
                    }
                }
            }
            self.observerQueries.append(obsQuery)
            MCHealthManager.sharedManager.healthKitStore.executeQuery(obsQuery)
        }
        MCHealthManager.sharedManager.healthKitStore.enableBackgroundDeliveryForType(type, frequency: HKUpdateFrequency.Immediate, withCompletion: onBackgroundStarted)
    }

    public func stopAllBackgroundObservers(completion: (Bool, NSError?) -> Void) {
        MCHealthManager.sharedManager.healthKitStore.disableAllBackgroundDeliveryWithCompletion { (success, error) in
            if !(success && error == nil) { log.error(error!.localizedDescription) }
            else {
                self.observerQueries.forEach { MCHealthManager.sharedManager.healthKitStore.stopQuery($0) }
                self.observerQueries.removeAll()
            }
            completion(success, error)
        }
    }

    
    // MARK: - Chart data access

    public func collectDataForCharts() {
        log.debug("Clearing HMAggregateCache expired objects", feature: "clearCache")
        MCHealthManager.sharedManager.aggregateCache.removeExpiredObjects()
        MCHealthManager.sharedManager.circadianCache.removeExpiredObjects()

        let periods: [HealthManagerStatisticsRangeType] = [
            HealthManagerStatisticsRangeType.Week
            , HealthManagerStatisticsRangeType.Month
            , HealthManagerStatisticsRangeType.Year
        ]

        let group = dispatch_group_create()

        for sampleType in PreviewManager.manageChartsSampleTypes {
            let type = sampleType.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : sampleType.identifier

            let keyPrefix = type

            for period in periods {
                log.debug("Collecting chart data for \(keyPrefix) \(period)", feature: "fetchCharts")

                dispatch_group_enter(group)
                // We should get max and min values. because for this type we are using scatter chart
                if type == HKQuantityTypeIdentifierHeartRate || type == HKQuantityTypeIdentifierUVExposure {
                    MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) {
                        if $2 != nil { log.error($2!.localizedDescription) }
                        dispatch_group_leave(group)
                    }
                } else if type == HKQuantityTypeIdentifierBloodPressureSystolic {
                    // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
                    let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
                    let bloodPressureGroup = dispatch_group_create()

                    dispatch_group_enter(bloodPressureGroup)
                    MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                        if $2 != nil { log.error($2!.localizedDescription) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    let diastolicType = HKQuantityTypeIdentifierBloodPressureDiastolic
                    dispatch_group_enter(bloodPressureGroup)
                    MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                        if $2 != nil { log.error($2!.localizedDescription) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        dispatch_group_leave(group) //leave main group
                    }

                } else {
                    MCHealthManager.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) {
                        if $1 != nil { log.error($1!.localizedDescription) }
                        dispatch_group_leave(group) //leave main group
                    }
                }
            }
        }

        // After completion, notify that we finished collecting statistics for all types
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdatedChartsData, object: nil)
        }
    }

    public func getChartDataForQuantity(sampleType: HKSampleType, inPeriod period: HealthManagerStatisticsRangeType, completion: AnyObject -> Void) {
        let type = sampleType.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : sampleType.identifier
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

        if  type == HKQuantityTypeIdentifierHeartRate ||
            type == HKQuantityTypeIdentifierUVExposure ||
            type == HKQuantityTypeIdentifierBloodPressureSystolic
        {
            key = MCHealthManager.sharedManager.getPeriodCacheKey(keyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: period)
            asMinMax = true
            asBP = type == HKQuantityTypeIdentifierBloodPressureSystolic
        } else {
            key = MCHealthManager.sharedManager.getPeriodCacheKey(keyPrefix, aggOp: .DiscreteAverage, period: period)
        }

        if let aggArray = MCHealthManager.sharedManager.aggregateCache[key] {
            log.debug("Cache hit for \(key) (size \(aggArray.aggregates.count))", feature: "fetchCharts")
        } else {
            log.debug("Cache miss for \(key)", feature: "fetchCharts")
        }

        if asMinMax {
            if asBP {
                let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
                let diastolicType = HKQuantityTypeIdentifierBloodPressureDiastolic
                let bloodPressureGroup = dispatch_group_create()

                dispatch_group_enter(bloodPressureGroup)
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_enter(bloodPressureGroup)
                MCHealthManager.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                    if $2 != nil { log.error($2!.localizedDescription) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let diastolicKey = MCHealthManager.sharedManager.getPeriodCacheKey(diastolicKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: period)

                    if let systolicAggArray = MCHealthManager.sharedManager.aggregateCache[key],
                           diastolicAggArray = MCHealthManager.sharedManager.aggregateCache[diastolicKey]
                    {
                        completion([systolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMax, $0).numeralValue! },
                                    systolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMin, $0).numeralValue! },
                                    diastolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMax, $0).numeralValue! },
                                    diastolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMin, $0).numeralValue! }])
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
                        let mins = aggArray.aggregates.map { return finalizeAgg(.DiscreteMin, $0).numeralValue! }
                        let maxs = aggArray.aggregates.map { return finalizeAgg(.DiscreteMax, $0).numeralValue! }
                        completion([maxs, mins])
                    }
                }
            }
        } else {
            MCHealthManager.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) { (_, error) in
                guard error == nil || MCHealthManager.sharedManager.aggregateCache[key] != nil else {
                    completion([])
                    return
                }

                if let aggArray = MCHealthManager.sharedManager.aggregateCache[key] {
                    completion(aggArray.aggregates.map { return finalize($0).numeralValue! })
                }
            }
        }
    }
    
    //MARK: Working with cache
    public func cleanCache() {
        log.debug("Clearing HMAggregateCache", feature: "clearCache")
        MCHealthManager.sharedManager.aggregateCache.removeAllObjects()
    }
}

