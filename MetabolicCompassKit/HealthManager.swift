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
import Alamofire
import SwiftyJSON
import SwiftyBeaver
import SwiftyUserDefaults
import SwiftDate
import AwesomeCache
import MCcircadianQueries

// Constants.

private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noLimit  = Int(HKObjectQueryNoLimit)
private let dateAsc  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
private let dateDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
private let lastChartsDataCacheKey = "lastChartsDataCacheKey"

public typealias HMAuthorizationBlock  = (success: Bool, error: NSError?) -> Void
public typealias HMSampleBlock         = (samples: [MCSample], error: NSError?) -> Void
public typealias HMTypedSampleBlock    = (samples: [HKSampleType: [MCSample]], error: NSError?) -> Void
public typealias HMAggregateBlock      = (aggregates: AggregateQueryResult, error: NSError?) -> Void
public typealias HMCorrelationBlock    = ([MCSample], [MCSample], NSError?) -> Void

public typealias HMCircadianBlock          = (intervals: [(NSDate, CircadianEvent)], error: NSError?) -> Void
public typealias HMCircadianAggregateBlock = (aggregates: [(NSDate, Double)], error: NSError?) -> Void
public typealias HMCircadianCategoryBlock  = (categories: [Int:Double], error: NSError?) -> Void

public typealias HMFastingCorrelationBlock = ([(NSDate, Double, MCSample)], NSError?) -> Void

public typealias HMAnchorQueryBlock    = (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, NSError?) -> Void
public typealias HMAnchorSamplesBlock  = (added: [HKSample], deleted: [HKDeletedObject], newAnchor: HKQueryAnchor?, error: NSError?) -> Void
public typealias HMAnchorSamplesCBlock = (added: [HKSample], deleted: [HKDeletedObject], newAnchor: HKQueryAnchor?, error: NSError?, completion: () -> Void) -> Void

public typealias HMAggregateCache = Cache<MCAggregateArray>

public let HMErrorDomain                        = "HMErrorDomain"
public let HMSampleTypeIdentifierSleepDuration  = "HMSampleTypeIdentifierSleepDuration"
public let HMDidUpdateRecentSamplesNotification = "HMDidUpdateRecentSamplesNotification"
public let HMDidUpdatedChartsData = "HMDidUpdatedChartsData"


public class HealthManager: NSObject, WCSessionDelegate {

    public static let sharedManager = HealthManager()

    lazy var healthKitStore: HKHealthStore = HKHealthStore()
    var aggregateCache: HMAggregateCache
    var observerQueries: [HKQuery] = []

    public var mostRecentSamples = [HKSampleType: [MCSample]]() {
        didSet {
            self.updateWatchContext()
        }
    }

    private override init() {
        do {
            self.aggregateCache = try HMAggregateCache(name: "HMAggregateCache")
        } catch _ {
            fatalError("Unable to create HealthManager aggregate cache.")
        }
        super.init()
        connectWatch()
    }

    public func reset() {
        mostRecentSamples = [:]
        aggregateCache.removeAllObjects()
    }

    public func authorizeHealthKit(completion: HMAuthorizationBlock)
    {
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: HMErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this Device"])
            completion(success: false, error:error)
            return
        }

        healthKitStore.requestAuthorizationToShareTypes(HMConstants.sharedInstance.healthKitTypesToWrite, readTypes: HMConstants.sharedInstance.healthKitTypesToRead, completion: completion)
    }

    public func isGeneratedSample(sample: HKSample) -> Bool {
        if let unwrappedMetadata = sample.metadata, _ = unwrappedMetadata[HMConstants.sharedInstance.generatedSampleKey] {
            return true
        }
        return false
    }

    public func getBiologicalSex() -> HKBiologicalSexObject? {
        do {
            return try self.healthKitStore.biologicalSex()
        } catch {
            log.error("Failed to get biological sex.")
        }
        return nil
    }

    public func fetchSamplesByUUID(sampleType: HKSampleType, uuids: Set<NSUUID>, predicate: NSPredicate? = nil, limit: Int = noLimit,
                                   sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        var uuidPredicate: NSPredicate = HKQuery.predicateForObjectsWithUUIDs(uuids)
        if let p = predicate {
            uuidPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p, uuidPredicate])
        }
        MCcircadianQueries.sharedManager.fetchSamplesOfType(sampleType, predicate: uuidPredicate, limit: limit, sortDescriptors: sortDescriptors, completion: completion)
    }

    public func fetchMostRecentSample(sampleType: HKSampleType, completion: HMSampleBlock)
    {
        MCcircadianQueries.sharedManager.fetchSamplesOfType(sampleType, predicate: nil, limit: 1, sortDescriptors: [dateDesc], completion: completion)
    }

    public func fetchMostRecentSamples(ofTypes types: [HKSampleType] = PreviewManager.previewSampleTypes, completion: HMTypedSampleBlock)
    {
        let group = dispatch_group_create()
        var samples = [HKSampleType: [MCSample]]()

        let updateSamples : (HKSampleType, [MCSample], NSError?) -> Void = { (type, statistics, error) in
            guard error == nil else {
                log.error("Could not fetch recent samples for \(type.displayText): \(error)")
                dispatch_group_leave(group)
                return
            }
            guard statistics.isEmpty == false else {
                log.warning("No recent samples available for \(type.displayText)")
                dispatch_group_leave(group)
                return
            }
            samples[type] = statistics
            dispatch_group_leave(group)
        }

        let onStatistic : HKSampleType -> Void = { type in
            // First run a pilot query to retrieve the acquisition date of the last sample.
            self.fetchMostRecentSample(type) { (samples, error) in
                guard error == nil else {
                    log.error("Could not fetch recent samples for \(type.displayText): \(error)")
                    dispatch_group_leave(group)
                    return
                }

                if let lastSample = samples.last {
                    // Then run a statistics query to aggregate relative to the recent sample date.
                    let recentWindowStartDate = lastSample.startDate - 4.days
                    let predicate = HKSampleQuery.predicateForSamplesWithStartDate(recentWindowStartDate, endDate: nil, options: .None)
                    MCcircadianQueries.sharedManager.fetchStatisticsOfType(type, predicate: predicate) { (statistics, error) in
                        updateSamples(type, statistics, error)
                    }
                } else {
                    updateSamples(type, samples, error)
                }
            }
        }

        let onCatOrCorr = { type in
            self.fetchMostRecentSample(type) { (statistics, error) in
                updateSamples(type, statistics, error)
            }
        }

        let onWorkout = { type in
            MCcircadianQueries.sharedManager.fetchPreparationAndRecoveryWorkout(false) { (statistics, error) in
                updateSamples(type, statistics, error)
            }
        }

        types.forEach { (type) -> () in
            dispatch_group_enter(group)
            if (type.identifier == HKCategoryTypeIdentifierSleepAnalysis) {
                onCatOrCorr(type)
            } else if (type.identifier == HKCorrelationTypeIdentifierBloodPressure) {
                onCatOrCorr(type)
            } else if (type.identifier == HKWorkoutTypeIdentifier) {
                onWorkout(type)
            } else {
                onStatistic(type)
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            self.mostRecentSamples = samples
            completion(samples: samples, error: nil)
        }
    }

    private func getOldestSampleForType(type: HKSampleType, completion: HKSampleType -> ()) {
        let tname = type.displayText ?? type.identifier
        MCcircadianQueries.sharedManager.fetchSamplesOfType(type, predicate: nil, limit: 1) { (samples, error) in
            guard error == nil else {
                log.error("Could not get oldest sample for: \(tname)")
                return
            }
            let minDate = samples.isEmpty ? NSDate() : samples[0].startDate
            UserManager.sharedManager.setHistoricalRangeMinForType(type.identifier, min: minDate, sync: true)
            log.info("Lower bound date for \(tname): \(minDate)")
            completion(type)
        }
    }

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
        healthKitStore.executeQuery(anchoredQuery)
    }

    private func getCacheDateKeyFormatter(aggUnit: NSCalendarUnit) -> NSDateFormatter {
        let formatter = NSDateFormatter()

        if aggUnit.contains(.Day) {
            formatter.dateFormat = "yyMMdd"
        } else if aggUnit.contains(.WeekOfYear) {
            formatter.dateFormat = "yyww"
        } else if aggUnit.contains(.Month) {
            formatter.dateFormat = "yyMM"
        } else if aggUnit.contains(.Year) {
            formatter.dateFormat = "yy"
        } else {
            fatalError("Unsupported aggregation calendar unit: \(aggUnit)")
        }

        return formatter
    }

    // Cache keys.
    public func getAggregateCacheKey(keyPrefix: String, aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions) -> String
    {
        let currentUnit = NSDate().startOf(aggUnit)
        let formatter = getCacheDateKeyFormatter(aggUnit)
        return "\(keyPrefix)_\(aggOp.rawValue)_\(formatter.stringFromDate(currentUnit))"
    }

    public func startBackgroundObserverForType(type: HKSampleType, maxResultsPerQuery: Int = Int(HKObjectQueryNoLimit),
                                               getAnchorCallback: HKSampleType -> (Bool, HKQueryAnchor?, NSPredicate?),
                                               anchorQueryCallback: HMAnchorSamplesCBlock) -> Void
    {
        let onBackgroundStarted = {(success: Bool, nsError: NSError?) -> Void in
            guard success else {
                log.error(nsError)
                return
            }

            let obsQuery = HKObserverQuery(sampleType: type, predicate: nil) {
                query, completion, obsError in
                guard obsError == nil else {
                    log.error(obsError)
                    return
                }

                let tname = type.displayText ?? type.identifier
                let (needsOldestSamples, anchor, predicate) = getAnchorCallback(type)
                if needsOldestSamples {
                    Async.background(after: 0.5) {
                        log.verbose("Registering bulk ingestion availability for: \(tname)")
                        self.getOldestSampleForType(type) { _ in () }
                    }
                }

                self.fetchAnchoredSamplesOfType(type, predicate: predicate, anchor: anchor, maxResults: maxResultsPerQuery, callContinuously: false) {
                    (added, deleted, newAnchor, error) -> Void in

                    if added.count > 0 || deleted.count > 0 {
                        MCcircadianQueries.sharedManager.invalidateCache(type)
                    }

                    anchorQueryCallback(added: added, deleted: deleted, newAnchor: newAnchor, error: error, completion: completion)
                }
            }
            self.observerQueries.append(obsQuery)
            self.healthKitStore.executeQuery(obsQuery)
        }
        healthKitStore.enableBackgroundDeliveryForType(type, frequency: HKUpdateFrequency.Immediate, withCompletion: onBackgroundStarted)
    }

    public func stopAllBackgroundObservers(completion: (Bool, NSError?) -> Void) {
        healthKitStore.disableAllBackgroundDeliveryWithCompletion { (success, error) in
            if !(success && error == nil) { log.error(error) }
            else {
                self.observerQueries.forEach { self.healthKitStore.stopQuery($0) }
                self.observerQueries.removeAll()
            }
            completion(success, error)
        }
    }

    public func collectDataForCharts() {
        log.verbose("Clearing HMAggregateCache expired objects")
        aggregateCache.removeExpiredObjects()

        let periods: [HealthManagerStatisticsRangeType] = [
            HealthManagerStatisticsRangeType.Week
            , HealthManagerStatisticsRangeType.Month
            , HealthManagerStatisticsRangeType.Year
        ]

        let group = dispatch_group_create()

        for sampleType in PreviewManager.manageChartsSampleTypes {
            let type = sampleType.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : sampleType.identifier

            if #available(iOS 9.3, *) {
                if type == HKQuantityTypeIdentifierAppleExerciseTime {
                    continue
                }
            }

            let keyPrefix = type

            for period in periods {
                log.verbose("Collecting chart data for \(keyPrefix) \(period)")

                dispatch_group_enter(group)
                // We should get max and min values. because for this type we are using scatter chart
                if type == HKQuantityTypeIdentifierHeartRate || type == HKQuantityTypeIdentifierUVExposure {
                    MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) {
                        if $2 != nil { log.error($2) }
                        dispatch_group_leave(group)
                    }
                } else if type == HKQuantityTypeIdentifierBloodPressureSystolic {
                    // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
                    let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
                    let bloodPressureGroup = dispatch_group_create()

                    dispatch_group_enter(bloodPressureGroup)
                    MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                        if $2 != nil { log.error($2) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    let diastolicType = HKQuantityTypeIdentifierBloodPressureDiastolic
                    dispatch_group_enter(bloodPressureGroup)
                    MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                        if $2 != nil { log.error($2) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        dispatch_group_leave(group) //leave main group
                    }

                } else {
                    MCcircadianQueries.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) {
                        if $1 != nil { log.error($1) }
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
            key = MCcircadianQueries.sharedManager.getPeriodCacheKey(keyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: period)
            asMinMax = true
            asBP = type == HKQuantityTypeIdentifierBloodPressureSystolic
        } else {
            key = MCcircadianQueries.sharedManager.getPeriodCacheKey(keyPrefix, aggOp: .DiscreteAverage, period: period)
        }

        if let aggArray = aggregateCache[key] {
            log.verbose("Cache hit for \(key) (size \(aggArray.aggregates.count))")
        } else {
            log.verbose("Cache miss for \(key)")
        }

        if asMinMax {
            if asBP {
                let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
                let diastolicType = HKQuantityTypeIdentifierBloodPressureDiastolic
                let bloodPressureGroup = dispatch_group_create()

                dispatch_group_enter(bloodPressureGroup)
                MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                    if $2 != nil { log.error($2) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_enter(bloodPressureGroup)
                MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                    if $2 != nil { log.error($2) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let diastolicKey = MCcircadianQueries.sharedManager.getPeriodCacheKey(diastolicKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: period)

                    if let systolicAggArray = self.aggregateCache[key], diastolicAggArray = self.aggregateCache[diastolicKey] {
                        completion([systolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMax, $0).numeralValue! },
                                    systolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMin, $0).numeralValue! },
                                    diastolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMax, $0).numeralValue! },
                                    diastolicAggArray.aggregates.map { return finalizeAgg(.DiscreteMin, $0).numeralValue! }])
                    } else {
                        completion([])
                    }
                }
            } else {
                MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) { (_, _, error) in
                    guard error == nil || self.aggregateCache[key] != nil else {
                        completion([])
                        return
                    }

                    if let aggArray = self.aggregateCache[key] {
                        let mins = aggArray.aggregates.map { return finalizeAgg(.DiscreteMin, $0).numeralValue! }
                        let maxs = aggArray.aggregates.map { return finalizeAgg(.DiscreteMax, $0).numeralValue! }
                        completion([maxs, mins])
                    }
                }
            }
        } else {
            MCcircadianQueries.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) { (_, error) in
                guard error == nil || self.aggregateCache[key] != nil else {
                    completion([])
                    return
                }

                if let aggArray = self.aggregateCache[key] {
                    completion(aggArray.aggregates.map { return finalize($0).numeralValue! })
                }
            }
        }
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
            let sampleFormatter = SampleFormatter()
            let applicationContext = mostRecentSamples.map { (sampleType, results) -> [String: String] in
                return [
                    "sampleTypeIdentifier": sampleType.identifier,
                    "displaySampleType": sampleType.displayText!,
                    "value": sampleFormatter.stringFromSamples(results)
                ]
            }
            try WCSession.defaultSession().updateApplicationContext(["context": applicationContext])
        } catch {
            log.error(error)
        }
    }  
}

