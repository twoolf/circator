//
//  HealthManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/27/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit
import WatchConnectivity
import Async
import Alamofire
import SwiftyJSON
import SwiftyBeaver
import SwiftyUserDefaults
import SwiftDate
import AwesomeCache

// Constants.
private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noLimit  = Int(HKObjectQueryNoLimit)
private let dateAsc  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
private let dateDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
private let lastChartsDataCacheKey = "lastChartsDataCacheKey"

// Enums
public enum HealthManagerStatisticsRangeType : Int {
    case Week = 0
    case Month
    case Year
}

public enum AggregateQueryResult {
    case AggregatedSamples([MCAggregateSample])
    case Statistics([HKStatistics])
    case None
}

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


/**
 This is the main manager of information reads/writes from HealthKit.  We use AnchorQueries to support continued updates.  Please see Apple Docs for syntax on reading/writing

 */
public class HealthManager: NSObject, WCSessionDelegate {

    public static let sharedManager = HealthManager()

    lazy var healthKitStore: HKHealthStore = HKHealthStore()
    var aggregateCache: HMAggregateCache

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

    // Not guaranteed to be on main thread
    public func authorizeHealthKit(completion: HMAuthorizationBlock)
    {
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: HMErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this Device"])
            completion(success: false, error:error)
            return
        }

        healthKitStore.requestAuthorizationToShareTypes(HMConstants.sharedInstance.healthKitTypesToWrite, readTypes: HMConstants.sharedInstance.healthKitTypesToRead, completion: completion)
    }

    // MARK: - Predicate construction

    public func mealsSincePredicate(startDate: NSDate? = nil, endDate: NSDate = NSDate()) -> NSPredicate? {
        var predicate : NSPredicate? = nil
        if let st = startDate {
            let conjuncts = [
                HKQuery.predicateForSamplesWithStartDate(st, endDate: endDate, options: .None),
                HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery),
                HKQuery.predicateForObjectsWithMetadataKey("Meal Type")
            ]
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: conjuncts)
        } else {
            predicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
        }
        return predicate
    }

    public func periodAggregation(statisticsRange: HealthManagerStatisticsRangeType) -> (NSPredicate, NSDate, NSDate, NSCalendarUnit)
    {
        var unit : NSCalendarUnit
        var startDate : NSDate
        var endDate : NSDate = NSDate()

        switch statisticsRange {
        case .Week:
            unit = .Day
            endDate = endDate.startOf(.Day) + 1.days
            startDate = endDate - 1.weeks

        case .Month:
            // Retrieve a full 31 days worth of data, regardless of the month duration (e.g., 28/29/30/31 days)
            unit = .Day
            endDate = endDate.startOf(.Day) + 1.days
            startDate = endDate - 32.days

        case .Year:
            unit = .Month
            endDate = endDate.startOf(.Month) + 1.months
            startDate = endDate - 1.years
        }

        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
        return (predicate, startDate, endDate, unit)
    }

    // MARK: - Sample testing
    public func isGeneratedSample(sample: HKSample) -> Bool {
        if let unwrappedMetadata = sample.metadata, _ = unwrappedMetadata[HMConstants.sharedInstance.generatedSampleKey] {
            return true
        }
        return false
    }

    // MARK: - Characteristic type queries

    public func getBiologicalSex() -> HKBiologicalSexObject? {
        do {
            return try self.healthKitStore.biologicalSex()
        } catch {
            log.error("Failed to get biological sex.")
        }
        return nil
    }

    // MARK: - HealthKit sample and statistics retrieval.

    // Retrieves Healthit samples for the given type, predicate, limit and sorting
    // Completion handler is on background queue
    public func fetchSamplesOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int = noLimit,
                                   sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) {
            (query, samples, error) -> Void in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            completion(samples: samples?.map { $0 as MCSample } ?? [], error: nil)
        }
        healthKitStore.executeQuery(query)
    }

    // Retrieves the HealthKit samples for the given UUIDs, further filtering them according to the specified predicate.
    public func fetchSamplesByUUID(sampleType: HKSampleType, uuids: Set<NSUUID>, predicate: NSPredicate? = nil, limit: Int = noLimit,
                                   sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        var uuidPredicate: NSPredicate = HKQuery.predicateForObjectsWithUUIDs(uuids)
        if let p = predicate {
            uuidPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p, uuidPredicate])
        }
        fetchSamplesOfType(sampleType, predicate: uuidPredicate, limit: limit, sortDescriptors: sortDescriptors, completion: completion)
    }


    // Fetches HealthKit samples of the given type for the last day, ordered by their collection date.
    public func fetchMostRecentSample(sampleType: HKSampleType, completion: HMSampleBlock)
    {
        let mostRecentPredicate: NSPredicate
        let limit: Int

        if sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis {
            mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(1.days.ago, endDate: NSDate(), options: .None)
            limit = noLimit
        } else {
            mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(NSDate.distantPast(), endDate: NSDate(), options: .None)
            limit = 1
        }

        fetchSamplesOfType(sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [dateDesc], completion: completion)
    }

    // Fetches HealthKit samples for multiple types, using GCD to retrieve each type asynchronously and concurrently.
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
            let predicate = HKSampleQuery.predicateForSamplesWithStartDate(4.days.ago, endDate: nil, options: HKQueryOptions())
            self.fetchStatisticsOfType(type, predicate: predicate) { (statistics, error) in
                updateSamples(type, statistics, error)
            }
        }

        let onCatOrCorr = { type in
            self.fetchMostRecentSample(type) { (statistics, error) in
                updateSamples(type, statistics, error)
            }
        }

        let onWorkout = { type in
            self.fetchPreparationAndRecoveryWorkout(false) { (statistics, error) in
                updateSamples(type, statistics, error)
            }
        }

        types.forEach { (type) -> () in
            dispatch_group_enter(group)
            if ( (type.identifier != HKCategoryTypeIdentifierSleepAnalysis)
                && (type.identifier != HKCorrelationTypeIdentifierBloodPressure)
                && (type.identifier != HKWorkoutTypeIdentifier))
            {
                onStatistic(type)
            } else if (type.identifier == HKCategoryTypeIdentifierSleepAnalysis) {
                onCatOrCorr(type)
            } else if (type.identifier == HKCorrelationTypeIdentifierBloodPressure) {
                onCatOrCorr(type)
            } else if (type.identifier == HKWorkoutTypeIdentifier) {
                onWorkout(type)
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            self.mostRecentSamples = samples
            completion(samples: samples, error: nil)
        }
    }

    // MARK: - Bulk generic retrieval

    // Fetches HealthKit samples for multiple types, using GCD to retrieve each type asynchronously and concurrently.
    public func fetchSamples(typesAndPredicates: [HKSampleType: NSPredicate?], completion: HMTypedSampleBlock)
    {
        let group = dispatch_group_create()
        var samplesByType = [HKSampleType: [MCSample]]()

        typesAndPredicates.forEach { (type, predicate) -> () in
            dispatch_group_enter(group)
            self.fetchSamplesOfType(type, predicate: predicate, limit: noLimit) { (samples, error) in
                guard error == nil else {
                    log.error("Could not fetch recent samples for \(type.displayText): \(error)")
                    dispatch_group_leave(group)
                    return
                }
                guard samples.isEmpty == false else {
                    log.warning("No recent samples available for \(type.displayText)")
                    dispatch_group_leave(group)
                    return
                }
                samplesByType[type] = samples
                dispatch_group_leave(group)
            }
        }

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            // TODO: partial error handling, i.e., when a subset of the desired types fail in their queries.
            completion(samples: samplesByType, error: nil)
        }
    }

    // MARK: - Oldest sample retrieval

    private func getOldestSampleForType(type: HKSampleType, completion: HKSampleType -> ()) {
        let tname = type.displayText ?? type.identifier
        HealthManager.sharedManager.fetchSamplesOfType(type, predicate: nil, limit: 1) { (samples, error) in
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

    // MARK: - Anchor queries
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

    // MARK: - Aggregate caching helpers.
    private func getCacheDateKeyFormatter(aggUnit: NSCalendarUnit) -> NSDateFormatter {
        let formatter = NSDateFormatter()

        // Return the formatter based on the finest-grained unit.
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

    public func getPeriodCacheKey(keyPrefix: String, aggOp: HKStatisticsOptions, period: HealthManagerStatisticsRangeType) -> String {
        return "\(keyPrefix)_\(aggOp.rawValue)_\(period.rawValue)"
    }

    private func getCacheExpiry(period: HealthManagerStatisticsRangeType) -> NSDate {
        switch period {
        case .Week:
            return NSDate() + 2.minutes

        case .Month:
            return NSDate() + 5.minutes

        case .Year:
            return NSDate() + 1.days
        }
    }


    // MARK: - Aggregate retrieval.

    private func queryResultAsAggregates(aggOp: HKStatisticsOptions, result: AggregateQueryResult, error: NSError?,
                                         completion: ([MCAggregateSample], NSError?) -> Void)
    {
        // MCAggregateSample.final is idempotent, thus this function can be called multiple times.
        let finalize: MCAggregateSample -> MCAggregateSample = { var agg = $0; agg.final(); return agg }

        guard error == nil else {
            completion([], error)
            return
        }

        switch result {
        case .AggregatedSamples(let aggregates):
            completion(aggregates.map(finalize), error)
        case .Statistics(let statistics):
            completion(statistics.map { return MCAggregateSample(statistic: $0, op: aggOp) }, error)
        case .None:
            completion([], error)
        }
    }

    // Convert an AggregateQueryResult value into an MCSample array, and fire the completion.
    private func queryResultAsSamples(result: AggregateQueryResult, error: NSError?, completion: HMSampleBlock)
    {
        // MCAggregateSample.final is idempotent, thus this function can be called multiple times.
        let finalize: MCAggregateSample -> MCSample = { var agg = $0; agg.final(); return agg as MCSample }

        guard error == nil else {
            completion(samples: [], error: error)
            return
        }
        switch result {
        case .AggregatedSamples(let aggregates):
            completion(samples: aggregates.map(finalize), error: error)
        case .Statistics(let statistics):
            completion(samples: statistics.map { $0 as MCSample }, error: error)
        case .None:
            completion(samples: [], error: error)
        }
    }

    private func aggregateSamplesManually(sampleType: HKSampleType, aggOp: HKStatisticsOptions, samples: [MCSample]) -> MCAggregateSample {
        if samples.count == 0 {
            return MCAggregateSample(value: 0.0, sampleType: sampleType, op: aggOp)
        }

        var agg = MCAggregateSample(sample: samples[0], op: aggOp)
        samples.dropFirst().forEach { sample in agg.incr(sample) }
        return agg
    }

    // Group-by the desired aggregation calendar unit, returning a dictionary of MCAggregateSamples.
    private func aggregateByPeriod(aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions, samples: [MCSample]) -> [NSDate: MCAggregateSample] {
        var byPeriod: [NSDate: MCAggregateSample] = [:]
        samples.forEach { sample in
            let periodStart = sample.startDate.startOf(aggUnit)
            if var agg = byPeriod[periodStart] {
                agg.incr(sample)
                byPeriod[periodStart] = agg
            } else {
                byPeriod[periodStart] = MCAggregateSample(sample: sample, op: aggOp)
            }
        }
        return byPeriod
    }

    private func finalizePartialAggregation(aggUnit: NSCalendarUnit,
                                            aggOp: HKStatisticsOptions,
                                            result: AggregateQueryResult,
                                            error: NSError?,
                                            completion: (([MCAggregateSample], NSError?) -> Void))
    {
        self.queryResultAsSamples(result, error: error) { (samples, error) in
            guard error == nil else {
                completion([], error)
                return
            }
            let byPeriod = self.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            completion(byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }, nil)
        }
    }

    private func finalizePartialAggregationAsSamples(aggUnit: NSCalendarUnit,
                                                     aggOp: HKStatisticsOptions,
                                                     result: AggregateQueryResult,
                                                     error: NSError?,
                                                     completion: HMSampleBlock)
    {
        self.queryResultAsSamples(result, error: error) { (samples, error) in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            let byPeriod = self.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            completion(samples: byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }, error: nil)
        }
    }

    private func coverAggregatePeriod<T>(tag: String, sampleType: HKSampleType, startDate: NSDate, endDate: NSDate,
                                      aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions,
                                      sparseAggs: [MCAggregateSample], withFinalization: Bool = false,
                                      transform: MCAggregateSample -> T)
                                      -> [T]
    {
        // MCAggregateSample.final is idempotent, thus this function can be called multiple times.
        let finalize: MCAggregateSample -> MCAggregateSample = { var agg = $0; agg.final(); return agg }

        let delta = NSDateComponents()
        delta.setValue(1, forComponent: aggUnit)

        var i: Int = 0
        var aggregates: [T] = []
        let dateRange = DateRange(startDate: startDate, endDate: endDate, stepUnits: aggUnit)

        /*
        if sampleType.identifier == HKQuantityTypeIdentifierBasalEnergyBurned || sampleType.identifier == HKQuantityTypeIdentifierStepCount {
            log.verbose("\(tag) dates \(startDate) \(endDate)")
        }

        if sampleType.identifier == HKQuantityTypeIdentifierBasalEnergyBurned || sampleType.identifier == HKQuantityTypeIdentifierStepCount {
            log.info("\(tag) aggs \(sparseAggs.count) \(sparseAggs)")
            if sparseAggs.count > 0 && sparseAggs[0].startDate < startDate {
                log.verbose("\(tag) aggs starts before range \(startDate) \(sparseAggs[0].startDate)")
            }
        }
        */

        while i < sparseAggs.count && sparseAggs[i].startDate.startOf(aggUnit) < startDate.startOf(aggUnit) {
            i += 1
        }

        for date in dateRange {
            if i < sparseAggs.count && date.startOf(aggUnit) == sparseAggs[i].startDate.startOf(aggUnit) {
                aggregates.append(transform(withFinalization ? finalize(sparseAggs[i]) : sparseAggs[i]))
                i += 1
            } else {
                aggregates.append(transform(MCAggregateSample(startDate: date, endDate: date + delta, value: 0.0, sampleType: sampleType, op: aggOp)))
            }
            /*
            if sampleType.identifier == HKQuantityTypeIdentifierBasalEnergyBurned || sampleType.identifier == HKQuantityTypeIdentifierStepCount {
                log.verbose("\(tag) \(date) \(i) \(aggregates.last!)")
            }
            */
        }
        return aggregates
    }

    private func coverStatisticsPeriod<T>(tag: String, sampleType: HKSampleType, startDate: NSDate, endDate: NSDate,
                                          aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions,
                                          sparseStats: [HKStatistics], transform: MCAggregateSample -> T)
                                          -> [T]
    {
        let delta = NSDateComponents()
        delta.setValue(1, forComponent: aggUnit)

        var i: Int = 0
        var statistics: [T] = []
        let dateRange = DateRange(startDate: startDate, endDate: endDate, stepUnits: aggUnit)

        /*
        if sampleType.identifier == HKQuantityTypeIdentifierBasalEnergyBurned || sampleType.identifier == HKQuantityTypeIdentifierStepCount {
            log.verbose("\(tag) dates \(startDate) \(endDate)")
        }

        if sampleType.identifier == HKQuantityTypeIdentifierBasalEnergyBurned || sampleType.identifier == HKQuantityTypeIdentifierStepCount {
            log.verbose("\(tag) stats \(sparseStats.count) \(sparseStats)")
            if sparseStats.count > 0 && sparseStats[0].startDate < startDate {
                log.verbose("\(tag) stats starts before range \(startDate) \(sparseStats[0].startDate)")
            }
        }
        */

        while i < sparseStats.count && sparseStats[i].startDate.startOf(aggUnit) < startDate.startOf(aggUnit) {
            i += 1
        }

        for date in dateRange {
            if i < sparseStats.count && date.startOf(aggUnit) == sparseStats[i].startDate.startOf(aggUnit) {
                statistics.append(transform(MCAggregateSample(statistic: sparseStats[i], op: aggOp)))
                i += 1
            } else {
                statistics.append(transform(MCAggregateSample(startDate: date, endDate: date + delta, value: 0.0, sampleType: sampleType, op: aggOp)))
            }
            /*
            if sampleType.identifier == HKQuantityTypeIdentifierBasalEnergyBurned || sampleType.identifier == HKQuantityTypeIdentifierStepCount {
                log.verbose("\(tag) \(date) \(i) \(statistics.last!)")
            }
            */
        }
        return statistics
    }

    // Period-covering variants of the above helpers.
    // These ensure that there is a sample for every calendar unit contained within the given time period.
    private func queryResultAsAggregatesForPeriod(sampleType: HKSampleType, startDate: NSDate, endDate: NSDate,
                                                  aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions,
                                                  result: AggregateQueryResult, error: NSError?,
                                                  completion: ([MCAggregateSample], NSError?) -> Void)
    {
        guard error == nil else {
            completion([], error)
            return
        }

        var aggregates: [MCAggregateSample] = []

        switch result {
        case .AggregatedSamples(let sparseAggs):
            aggregates = self.coverAggregatePeriod("QRAP", sampleType: sampleType, startDate: startDate, endDate: endDate,
                                                   aggUnit: aggUnit, aggOp: aggOp, sparseAggs: sparseAggs, withFinalization: true, transform: { $0 })

        case .Statistics(let statistics):
            aggregates = self.coverStatisticsPeriod("QRAP", sampleType: sampleType, startDate: startDate, endDate: endDate,
                                                    aggUnit: aggUnit, aggOp: aggOp, sparseStats: statistics, transform: { $0 })

        case .None:
            aggregates = []
        }

        completion(aggregates, error)
    }

    private func queryResultAsSamplesForPeriod(sampleType: HKSampleType, startDate: NSDate, endDate: NSDate,
                                               aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions,
                                               result: AggregateQueryResult, error: NSError?, completion: HMSampleBlock)
    {
        guard error == nil else {
            completion(samples: [], error: error)
            return
        }

        var samples: [MCSample] = []

        switch result {
        case .AggregatedSamples(let sparseAggs):
            samples = self.coverAggregatePeriod("QRASP", sampleType: sampleType, startDate: startDate, endDate: endDate,
                                                aggUnit: aggUnit, aggOp: aggOp, sparseAggs: sparseAggs, withFinalization: true,
                                                transform: { $0 as MCSample })

        case .Statistics(let statistics):
            samples = self.coverStatisticsPeriod("QRASP", sampleType: sampleType, startDate: startDate, endDate: endDate,
                                                aggUnit: aggUnit, aggOp: aggOp, sparseStats: statistics, transform: { $0 as MCSample })

        case .None:
            samples = []
        }

        completion(samples: samples, error: error)
    }


    private func finalizePartialAggregationForPeriod(sampleType: HKSampleType, startDate: NSDate, endDate: NSDate,
                                                     aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions,
                                                     result: AggregateQueryResult, error: NSError?,
                                                     completion: (([MCAggregateSample], NSError?) -> Void))
    {
        self.queryResultAsSamples(result, error: error) { (samples, error) in
            guard error == nil else {
                completion([], error)
                return
            }
            let byPeriod = self.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            let sparseAggs = byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }
            let aggregates = self.coverAggregatePeriod("FPAP", sampleType: sampleType, startDate: startDate, endDate: endDate,
                                                       aggUnit: aggUnit, aggOp: aggOp, sparseAggs: sparseAggs, transform: { $0 })
            completion(aggregates, nil)
        }
    }

    private func finalizePartialAggregationAsSamplesForPeriod(sampleType: HKSampleType, startDate: NSDate, endDate: NSDate,
                                                              aggUnit: NSCalendarUnit, aggOp: HKStatisticsOptions,
                                                              result: AggregateQueryResult, error: NSError?,
                                                              completion: HMSampleBlock)
    {
        self.queryResultAsSamples(result, error: error) { (samples, error) in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }

            let byPeriod = self.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            let sparseAggs = byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }
            let samples = self.coverAggregatePeriod("FPASP", sampleType: sampleType, startDate: startDate, endDate: endDate,
                                                    aggUnit: aggUnit, aggOp: aggOp, sparseAggs: sparseAggs, transform: { $0 as MCSample })

            completion(samples: samples, error: nil)
        }
    }


    // Returns aggregate values by processing samples retrieved from HealthKit.
    // We return an aggregate for each calendar unit as specified by the aggUnit parameter.
    // Here the aggregation is done at the application-level (rather than inside HealthKit, as a statistics query).
    public func fetchSampleAggregatesOfType(
                    sampleType: HKSampleType, predicate: NSPredicate? = nil,
                    aggUnit: NSCalendarUnit = .Day, aggOp: HKStatisticsOptions,
                    limit: Int = noLimit, sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMAggregateBlock)
    {
        fetchSamplesOfType(sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { samples, error in
            guard error == nil else {
                completion(aggregates: .AggregatedSamples([]), error: error)
                return
            }
            let byPeriod = self.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            completion(aggregates: .AggregatedSamples(byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }), error: nil)
        }
    }

    // Returns aggregate values as above, except converting to MCSamples for the completion.
    public func fetchSampleStatisticsOfType(
                    sampleType: HKSampleType, predicate: NSPredicate? = nil,
                    aggUnit: NSCalendarUnit = .Day, aggOp: HKStatisticsOptions,
                    limit: Int = noLimit, sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {

        fetchSampleAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: aggOp, limit: limit, sortDescriptors: sortDescriptors) {
            self.queryResultAsSamples($0, error: $1, completion: completion)
        }
    }

    // Fetches statistics as defined by the predicate, aggregation unit, and per-type operation.
    // The predicate should span the time interval of interest for the query.
    // The aggregation unit defines the granularity at which statistics are computed (i.e., per day/week/month/year).
    // The aggregation operator defines the type of aggregate (avg/min/max/sum) for each valid HKSampleType.
    //
    public func fetchAggregatesOfType(sampleType: HKSampleType,
                                      predicate: NSPredicate? = nil,
                                      aggUnit: NSCalendarUnit = .Day,
                                      aggOp: HKStatisticsOptions,
                                      completion: HMAggregateBlock)
    {
        switch sampleType {
        case is HKCategoryType:
            fallthrough

        case is HKCorrelationType:
            fallthrough

        case is HKWorkoutType:
            fetchSampleAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: aggOp, completion: completion)

        case is HKQuantityType:
            let interval = NSDateComponents()
            interval.setValue(1, forComponent: aggUnit)

            // Indicates whether to use a HKStatisticsQuery or a HKSampleQuery.
            var querySamples = false

            let quantityType = sampleType as! HKQuantityType

            switch quantityType.aggregationStyle {
            case .Discrete:
                querySamples = aggOp.contains(.CumulativeSum)
            case .Cumulative:
                querySamples = aggOp.contains(.DiscreteAverage) || aggOp.contains(.DiscreteMin) || aggOp.contains(.DiscreteMax)
            }

            if querySamples {
                // Query processing via manual aggregation over HKSample numeralValues.
                // This allows us to calculate avg/min/max over cumulative types, and sums over discrete types.
                fetchSampleAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: aggOp, completion: completion)
            } else {
                // Query processing via a HealthKit statistics query.
                // Set the anchor date to the start of the temporal aggregation unit (i.e., day/week/month/year).
                let anchorDate = NSDate().startOf(aggUnit)

                // Create the query
                let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                        quantitySamplePredicate: predicate,
                                                        options: aggOp,
                                                        anchorDate: anchorDate,
                                                        intervalComponents: interval)

                // Set the results handler
                query.initialResultsHandler = { query, results, error in
                    guard error == nil else {
                        log.error("Failed to fetch \(sampleType) statistics: \(error!)")
                        completion(aggregates: .None, error: error)
                        return
                    }
                    completion(aggregates: .Statistics(results?.statistics() ?? []), error: nil)
                }
                healthKitStore.executeQuery(query)
            }

        default:
            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
            completion(aggregates: .None, error: err)
        }
    }

    // Statistics calculation, with a default aggregation operator.
    public func fetchStatisticsOfType(sampleType: HKSampleType,
                                      predicate: NSPredicate? = nil,
                                      aggUnit: NSCalendarUnit = .Day,
                                      completion: HMSampleBlock)
    {
        fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: sampleType.aggregationOptions) {
            self.queryResultAsSamples($0, error: $1, completion: completion)
        }
    }

    // Statistics calculation over a predefined period.
    public func fetchStatisticsOfTypeForPeriod(sampleType: HKSampleType,
                                               period: HealthManagerStatisticsRangeType,
                                               aggOp: HKStatisticsOptions,
                                               completion: HMSampleBlock)
    {
        let (predicate, _, _, aggUnit) = periodAggregation(period)
        fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: aggOp) {
            self.queryResultAsSamples($0, error: $1, completion: completion)
        }
    }

    // Cache-based equivalent of fetchStatisticsOfTypeForPeriod
    public func getStatisticsOfTypeForPeriod(keyPrefix: String,
                                             sampleType: HKSampleType,
                                             period: HealthManagerStatisticsRangeType,
                                             aggOp: HKStatisticsOptions,
                                             completion: HMSampleBlock)
    {
        let (predicate, _, _, aggUnit) = periodAggregation(period)
        let key = getPeriodCacheKey(keyPrefix, aggOp: aggOp, period: period)

        aggregateCache.setObjectForKey(key, cacheBlock: { success, failure in
            self.fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: aggOp) {
                self.queryResultAsAggregates(aggOp, result: $0, error: $1) { (aggregates, error) in
                    guard error == nil else {
                        failure(error)
                        return
                    }
                    log.verbose("Caching aggregates for \(key)")
                    success(MCAggregateArray(aggregates: aggregates), .Date(self.getCacheExpiry(period)))
                }
            }
        }, completion: {object, isLoadedFromCache, error in
            log.verbose("Cache result \(key) \(isLoadedFromCache)")
            if let aggArray = object {
                log.verbose("Cache result \(key) size \(aggArray.aggregates.count)")
                self.queryResultAsSamples(.AggregatedSamples(aggArray.aggregates), error: error, completion: completion)
            } else {
                completion(samples: [], error: error)
            }
        })
    }

    // Statistics calculation over a predefined period.
    // This is similar to the method above, except that it computes a daily average for cumulative metrics
    // when requesting a yearly period.
    public func fetchDailyStatisticsOfTypeForPeriod(sampleType: HKSampleType,
                                                    period: HealthManagerStatisticsRangeType,
                                                    aggOp: HKStatisticsOptions,
                                                    completion: HMSampleBlock)
    {
        let (predicate, startDate, endDate, aggUnit) = periodAggregation(period)
        let byDay = sampleType.aggregationOptions == .CumulativeSum

        fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: byDay ? .Day : aggUnit, aggOp: byDay ? .CumulativeSum : aggOp) {
            if byDay {
                // Compute aggregates at aggUnit granularity by first partially aggregating per day,
                // and then computing final aggregates as daily averages.
                self.finalizePartialAggregationAsSamplesForPeriod(sampleType, startDate: startDate, endDate: endDate,
                                                                  aggUnit: aggUnit, aggOp: aggOp, result: $0, error: $1, completion: completion)
            } else {
                self.queryResultAsSamplesForPeriod(sampleType, startDate: startDate, endDate: endDate,
                                                   aggUnit: aggUnit, aggOp: aggOp, result: $0, error: $1, completion: completion)
            }
        }
    }

    // Cache-based equivalent of fetchDailyStatisticsOfTypeForPeriod
    public func getDailyStatisticsOfTypeForPeriod(keyPrefix: String,
                                                  sampleType: HKSampleType,
                                                  period: HealthManagerStatisticsRangeType,
                                                  aggOp: HKStatisticsOptions,
                                                  completion: HMSampleBlock)
    {
        let (predicate, startDate, endDate, aggUnit) = periodAggregation(period)
        let key = getPeriodCacheKey(keyPrefix, aggOp: aggOp, period: period)

        let byDay = sampleType.aggregationOptions == .CumulativeSum

        aggregateCache.setObjectForKey(key, cacheBlock: { success, failure in
            let doCache : ([MCAggregateSample], NSError?) -> Void = { (aggregates, error) in
                guard error == nil else {
                    failure(error)
                    return
                }
                log.verbose("Caching daily aggregates for \(key)")
                success(MCAggregateArray(aggregates: aggregates), .Date(self.getCacheExpiry(period)))
            }

            self.fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: byDay ? .Day : aggUnit, aggOp: byDay ? .CumulativeSum : aggOp) {
                if byDay {
                    self.finalizePartialAggregationForPeriod(sampleType, startDate: startDate, endDate: endDate,
                                                             aggUnit: aggUnit, aggOp: aggOp, result: $0, error: $1)
                    { doCache($0, $1) }
                } else {
                    self.queryResultAsAggregatesForPeriod(sampleType, startDate: startDate, endDate: endDate,
                                                          aggUnit: aggUnit, aggOp: aggOp, result: $0, error: $1)
                    { doCache($0, $1) }
                }
            }
        }, completion: {object, isLoadedFromCache, error in
            log.verbose("Cache daily result \(key) \(isLoadedFromCache)")
            if let aggArray = object {
                log.verbose("Cache daily result \(key) size \(aggArray.aggregates.count)")
                self.queryResultAsSamples(.AggregatedSamples(aggArray.aggregates), error: error, completion: completion)
            } else {
                completion(samples: [], error: error)
            }
        })
    }

    // Returns the extreme values over a predefined period.
    public func fetchMinMaxOfTypeForPeriod(sampleType: HKSampleType,
                                           period: HealthManagerStatisticsRangeType,
                                           completion: ([MCSample], [MCSample], NSError?) -> Void)
    {
        let (predicate, startDate, endDate, aggUnit) = periodAggregation(period)

        let finalize : (HKStatisticsOptions, MCAggregateSample) -> MCSample = {
            var agg = $1; agg.finalAggregate($0); return agg as MCSample
        }

        fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: [.DiscreteMin, .DiscreteMax]) {
            self.queryResultAsAggregatesForPeriod(sampleType, startDate: startDate, endDate: endDate,
                                                  aggUnit: aggUnit, aggOp: [.DiscreteMin, .DiscreteMax], result: $0, error: $1)
            { (aggregates, error) in
                guard error == nil else {
                    completion([], [], error)
                    return
                }
                completion(aggregates.map { finalize(.DiscreteMin, $0) }, aggregates.map { finalize(.DiscreteMax, $0) }, error)
            }
        }
    }

    // Cache-based equivalent of fetchMinMaxOfTypeForPeriod
    public func getMinMaxOfTypeForPeriod(keyPrefix: String,
                                         sampleType: HKSampleType,
                                         period: HealthManagerStatisticsRangeType,
                                         completion: ([MCSample], [MCSample], NSError?) -> Void)
    {
        let aggOp: HKStatisticsOptions = [.DiscreteMin, .DiscreteMax]
        let (predicate, startDate, endDate, aggUnit) = periodAggregation(period)
        let key = getPeriodCacheKey(keyPrefix, aggOp: aggOp, period: period)

        let finalize : (HKStatisticsOptions, MCAggregateSample) -> MCSample = {
            var agg = $1; agg.finalAggregate($0); return agg as MCSample
        }

        aggregateCache.setObjectForKey(key, cacheBlock: { success, failure in
            self.fetchAggregatesOfType(sampleType, predicate: predicate, aggUnit: aggUnit, aggOp: aggOp) {
                self.queryResultAsAggregatesForPeriod(sampleType, startDate: startDate, endDate: endDate,
                                                      aggUnit: aggUnit, aggOp: aggOp, result: $0, error: $1)
                { (aggregates, error) in
                    guard error == nil else {
                        failure(error)
                        return
                    }
                    log.verbose("Caching minmax aggregates for \(key) ")
                    success(MCAggregateArray(aggregates: aggregates), .Date(self.getCacheExpiry(period)))
                }
            }
        }, completion: {object, isLoadedFromCache, error in
            log.verbose("Cache minmax result \(key) \(isLoadedFromCache)")
            if let aggArray = object {
                log.verbose("Cache minmax result \(key) size \(aggArray.aggregates.count)")
                completion(aggArray.aggregates.map { finalize(.DiscreteMin, $0) }, aggArray.aggregates.map { finalize(.DiscreteMax, $0) }, error)
            } else {
                completion([], [], error)
            }
        })
    }

    // Completion handler is on main queue
    public func correlateStatisticsOfType(type: HKSampleType, withType type2: HKSampleType,
                                          pred1: NSPredicate? = nil, pred2: NSPredicate? = nil, completion: HMCorrelationBlock)
    {
        var results1: [MCSample]?
        var results2: [MCSample]?

        func intersect(arr1: [MCSample], arr2: [MCSample]) -> [(NSDate, MCSample, MCSample)] {
            var output: [(NSDate, MCSample, MCSample)] = []
            var arr1ByDay : [NSDate: MCSample] = [:]
            arr1.forEach { s in
                let start = s.startDate.startOf(.Day)
                arr1ByDay.updateValue(s, forKey: start)
            }

            arr2.forEach { s in
                let start = s.startDate.startOf(.Day)
                if let match = arr1ByDay[start] { output.append((start, match, s)) }
            }
            return output
        }

        let group = dispatch_group_create()
        dispatch_group_enter(group)
        fetchStatisticsOfType(type, predicate: pred1) { (results, error) -> Void in
            guard error == nil else {
                completion([], [], error)
                dispatch_group_leave(group)
                return
            }
            results1 = results
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        fetchStatisticsOfType(type2, predicate: pred2) { (results, error) -> Void in
            guard error == nil else {
                completion([], [], error)
                dispatch_group_leave(group)
                return
            }
            results2 = results
            dispatch_group_leave(group)
        }

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            guard !(results1 == nil || results2 == nil) else {
                let desc = results1 == nil ? (results2 == nil ? "LHS and RHS" : "LHS") : "RHS"
                let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Invalid \(desc) statistics"])
                completion([], [], err)
                return
            }
            var zipped = intersect(results1!, arr2: results2!)
            zipped.sortInPlace { (a,b) in a.1.numeralValue! < b.1.numeralValue! }
            completion(zipped.map { $0.1 }, zipped.map { $0.2 }, nil)
        }
    }


    // MARK: - Circadian event retrieval.

    // Query food diary events stored as prep and recovery workouts in HealthKit
    public func fetchPreparationAndRecoveryWorkout(oldestFirst: Bool, beginDate: NSDate? = nil, completion: HMSampleBlock)
    {
        let predicate = mealsSincePredicate(beginDate)
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: oldestFirst)
        fetchSamplesOfType(HKWorkoutType.workoutType(), predicate: predicate, limit: noLimit, sortDescriptors: [sortDescriptor], completion: completion)
    }

    // Invokes a callback on circadian event intervals.
    // This is an array of event endpoints where an endpoint
    // is a pair of NSDate and metabolic state (i.e.,
    // whether you are eating/fasting/sleeping/exercising).
    //
    // Conceptually, circadian events are intervals with a starting date
    // and ending date. We represent these endpoints (i.e., starting vs ending)
    // as consecutive array elements. For example the following array represents
    // an eating event (as two array elements) following by a sleeping event
    // (also as two array elements):
    //
    // [('2016-01-01 20:00', .Meal), ('2016-01-01 20:45', .Meal), ('2016-01-01 23:00', .Sleep), ('2016-01-02 07:00', .Sleep)]
    //
    public func fetchCircadianEventIntervals(startDate: NSDate = 1.days.ago,
                                             endDate: NSDate = NSDate(),
                                             completion: HMCircadianBlock)
    {
        typealias Event = (NSDate, CircadianEvent)
        typealias IEvent = (Double, CircadianEvent)

        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Fetch HealthKit sleep and workout samples matching the requested data range.
        // Note the workout samples include meal events since we encode these as preparation
        // and recovery workouts.
        // We create event endpoints from the resulting samples.
        fetchSamples(typesAndPredicates) { (events, error) -> Void in
            guard error == nil && !events.isEmpty else {
                completion(intervals: [], error: error)
                return
            }

            // Fetch samples returns a dictionary that map a HKSampleType to an array of HKSamples.
            // We use a flatmap operation to concatenate all samples across different HKSampleTypes.
            //
            // We truncate the start of event intervals to the startDate parameter.
            //
            let extendedEvents = events.flatMap { (ty,vals) -> [Event]? in
                switch ty {
                case is HKWorkoutType:
                    // Workout samples may be meal or exercise events.
                    // We turn each event into an array of two elements, indicating
                    // the start and end of the event.
                    return vals.flatMap { s -> [Event] in
                        let st = s.startDate < startDate ? startDate : s.startDate
                        let en = s.endDate
                        guard let v = s as? HKWorkout else { return [] }
                        switch v.workoutActivityType {
                        case HKWorkoutActivityType.PreparationAndRecovery:
                            // TODO: check for "Meal Type" key in metadata to distinguish from other P&R events
                            // (e.g., added from other apps)
                            return [(st, .Meal), (en, .Meal)]
                        default:
                            return [(st, .Exercise), (en, .Exercise)]
                        }
                    }

                case is HKCategoryType:
                    // Convert sleep samples into event endpoints.
                    guard ty.identifier == HKCategoryTypeIdentifierSleepAnalysis else {
                        return nil
                    }
                    return vals.flatMap { s -> [Event] in
                        let st = s.startDate < startDate ? startDate : s.startDate
                        let en = s.endDate
                        return [(st, .Sleep), (en, .Sleep)]
                    }

                default:
                    log.error("Unexpected type \(ty.identifier) while fetching circadian event intervals")
                    return nil
                }
            }

            // Sort event endpoints by their occurrence time.
            // This sorts across all event types (sleep, eat, exercise).
            let sortedEvents = extendedEvents.flatten().sort { (a,b) in return a.0 < b.0 }

            // Up to this point the endpoint array does not contain any fasting events
            // since these are implicitly any interval where no other meal/sleep/exercise events occurs.
            // The following code creates explicit fasting events, so that the endpoint array
            // fully covers the [startDate, endDate) interval provided as parameters.
            let epsilon = 1.seconds

            // Create a "final" fasting event to cover the time period up to the endDate parameter.
            // This handles if the last sample occurs at exactly the endDate.
            let lastev = sortedEvents.last ?? sortedEvents.first!
            let lst = lastev.0 == endDate ? [] : [(lastev.0, CircadianEvent.Fast), (endDate, CircadianEvent.Fast)]

            // We create explicit fasting endpoints by folding over all meal/sleep/exercise endpoints.
            // The accumulated state is:
            // i. an endpoint array, which is returned as the result of the loop.
            // ii. a boolean indicating whether the current event is the start of an event interval.
            //     Thus (assuming 0-based arrays) even-numbered elements are interval starts, and
            //     odd-numbered elements are interval ends.
            // iii. the previous element in the loop.
            //
            let initialAccumulator : ([Event], Bool, Event!) = ([], true, nil)
            let endpointArray = sortedEvents.reduce(initialAccumulator, combine:
            { (acc, event) in
                let eventEndpointDate = event.0
                let eventMetabolicState = event.1

                let resultArray = acc.0
                let eventIsIntervalStart = acc.1
                let prevEvent = acc.2

                let nextEventAsIntervalStart = !acc.1

                guard prevEvent != nil else {
                    // Skip prefix indicates whether we should add a fasting interval before the first event.
                    let skipPrefix = eventEndpointDate == startDate || startDate == NSDate.distantPast()
                    let newResultArray = (skipPrefix ? [event] : [(startDate, CircadianEvent.Fast), (eventEndpointDate, CircadianEvent.Fast), event])
                    return (newResultArray, nextEventAsIntervalStart, event)
                }

                let prevEventEndpointDate = prevEvent.0

                if (eventIsIntervalStart && prevEventEndpointDate == eventEndpointDate) {
                    // We skip adding any fasting event between back-to-back events.
                    // To do this, we check if the current event starts an interval, and whether
                    // the start date for this interval is the same as the end date of the previous interval.
                    let newResult = resultArray + [(eventEndpointDate + epsilon, eventMetabolicState)]
                    return (newResult, nextEventAsIntervalStart, event)
                } else if eventIsIntervalStart {
                    // This event endpoint is a starting event that has a gap to the previous event.
                    // Thus we fill in a fasting event in between.
                    // We truncate any events that last more than 24 hours to last 24 hours.
                    let fastEventStart = prevEventEndpointDate + epsilon
                    let modifiedEventEndpoint = eventEndpointDate - epsilon
                    let fastEventEnd = modifiedEventEndpoint - 1.days > fastEventStart ? fastEventStart + 1.days : modifiedEventEndpoint
                    let newResult = resultArray + [(fastEventStart, .Fast), (fastEventEnd, .Fast), event]
                    return (newResult, nextEventAsIntervalStart, event)
                } else {
                    // This endpoint is an interval ending event.
                    // Thus we add the endpoint to the result array.
                    return (resultArray + [event], nextEventAsIntervalStart, event)
                }
            }).0 + lst  // Add the final fasting event to the event endpoint array.

            completion(intervals: endpointArray, error: error)
        }
    }

    // A filter-aggregate query template.
    public func fetchAggregatedCircadianEvents<T,U>(predicate: ((NSDate, CircadianEvent) -> Bool)? = nil,
                                                    aggregator: ((T, (NSDate, CircadianEvent)) -> T),
                                                    initialAccum: T, initialResult: U,
                                                    final: (T -> U),
                                                    completion: (U, error: NSError?) -> Void)
    {
        fetchCircadianEventIntervals(NSDate.distantPast()) { (intervals, error) in
            guard error == nil else {
                completion(initialResult, error: error)
                return
            }

            let filtered = predicate == nil ? intervals : intervals.filter(predicate!)
            let accum = filtered.reduce(initialAccum, combine: aggregator)
            completion(final(accum), error: nil)
        }
    }

    // Time-restricted version of the above function.
    public func fetchAggregatedCircadianEvents<T,U>(startDate: NSDate, endDate: NSDate,
                                                    predicate: ((NSDate, CircadianEvent) -> Bool)? = nil,
                                                    aggregator: ((T, (NSDate, CircadianEvent)) -> T),
                                                    initialAccum: T, initialResult: U,
                                                    final: (T -> U),
                                                    completion: (U, error: NSError?) -> Void)
    {
        fetchCircadianEventIntervals(startDate, endDate: endDate) { (intervals, error) in
            guard error == nil else {
                completion(initialResult, error: error)
                return
            }

            let filtered = predicate == nil ? intervals : intervals.filter(predicate!)
            let accum = filtered.reduce(initialAccum, combine: aggregator)
            completion(final(accum), error: nil)
        }
    }

    // Compute total eating times per day by filtering and aggregating over meal events.
    public func fetchEatingTimes(completion: HMCircadianAggregateBlock)
    {
        // Accumulator:
        // i. boolean indicating whether the current endpoint starts an interval.
        // ii. an NSDate indicating when the previous endpoint occurred.
        // iii. a dictionary of accumulated eating times per day.
        typealias Accum = (Bool, NSDate!, [NSDate: Double])

        let aggregator : (Accum, (NSDate, CircadianEvent)) -> Accum = { (acc, e) in
            let startOfInterval = acc.0
            let prevIntervalEndpointDate = acc.1
            let eatingTimesByDay = acc.2
            if !startOfInterval && prevIntervalEndpointDate != nil {
                switch e.1 {
                case .Meal:
                    let day = prevIntervalEndpointDate.startOf(.Day)
                    var nAcc = eatingTimesByDay
                    let nEat = (eatingTimesByDay[day] ?? 0.0) + e.0.timeIntervalSinceDate(prevIntervalEndpointDate!)
                    nAcc.updateValue(nEat, forKey: day)
                    return (!startOfInterval, e.0, nAcc)
                default:
                    return (!startOfInterval, e.0, eatingTimesByDay)
                }
            }
            return (!startOfInterval, e.0, eatingTimesByDay)
        }
        let initial : Accum = (true, nil, [:])
        let final : (Accum -> [(NSDate, Double)]) = { acc in
            let eatingTimesByDay = acc.2
            return eatingTimesByDay.map { return ($0.0, $0.1 / 3600.0) }.sort { (a,b) in return a.0 < b.0 }
        }

        fetchAggregatedCircadianEvents(nil, aggregator: aggregator, initialAccum: initial, initialResult: [], final: final, completion: completion)
    }

    // Compute max fasting times per day by filtering and aggregating over everything other than meal events.
    // This stitches fasting events together if they are sequential (i.e., one ends while the other starts).
    public func fetchMaxFastingTimes(completion: HMCircadianAggregateBlock)
    {
        // Accumulator:
        // i. boolean indicating whether the current endpoint starts an interval.
        // ii. start of this fasting event.
        // iii. the previous event.
        // iv. a dictionary of accumulated fasting intervals.
        typealias Accum = (Bool, NSDate!, NSDate!, [NSDate: Double])

        let predicate : (NSDate, CircadianEvent) -> Bool = {
            switch $0.1 {
            case .Exercise, .Fast, .Sleep:
                return true
            default:
                return false
            }
        }

        let aggregator : (Accum, (NSDate, CircadianEvent)) -> Accum = { (acc, e) in
            var byDay = acc.3
            let (startOfInterval, prevFast, prevEvt) = (acc.0, acc.1, acc.2)
            var nextFast = prevFast
            if startOfInterval && prevFast != nil && prevEvt != nil && e.0 != prevEvt {
                let fastStartDay = prevFast.startOf(.Day)
                let duration = prevEvt.timeIntervalSinceDate(prevFast)
                let currentMax = byDay[fastStartDay] ?? duration
                byDay.updateValue(currentMax >= duration ? currentMax : duration, forKey: fastStartDay)
                nextFast = e.0
            } else if startOfInterval && prevFast == nil {
                nextFast = e.0
            }
            return (!startOfInterval, nextFast, e.0, byDay)
        }

        let initial : Accum = (true, nil, nil, [:])
        let final : Accum -> [(NSDate, Double)] = { acc in
            var byDay = acc.3
            if let finalFast = acc.1, finalEvt = acc.2 {
                if finalFast != finalEvt {
                    let fastStartDay = finalFast.startOf(.Day)
                    let duration = finalEvt.timeIntervalSinceDate(finalFast)
                    let currentMax = byDay[fastStartDay] ?? duration
                    byDay.updateValue(currentMax >= duration ? currentMax : duration, forKey: fastStartDay)
                }
            }
            return byDay.map { return ($0.0, $0.1 / 3600.0) }.sort { (a,b) in return a.0 < b.0 }
        }

        fetchAggregatedCircadianEvents(predicate, aggregator: aggregator, initialAccum: initial, initialResult: [], final: final, completion: completion)
    }

    // Computes the number of days in the last year that have at least one sample, for the given types.
    // TODO: cache invalidation in observer query.
    public func fetchSampleCollectionDays(sampleTypes: [HKSampleType], completion: ([HKSampleType:Int], NSError?) -> Void) {
        var someError: NSError? = nil
        let group = dispatch_group_create()
        var results : [HKSampleType:Int] = [:]

        let period : HealthManagerStatisticsRangeType = .Year
        let (predicate, _, _, _) = periodAggregation(period)

        for sampleType in sampleTypes {
            dispatch_group_enter(group)
            let type = sampleType.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : sampleType.identifier
            let proxyType = sampleType.identifier == type ? sampleType : HKObjectType.quantityTypeForIdentifier(type)!

            if #available(iOS 9.3, *) {
                if type == HKQuantityTypeIdentifierAppleExerciseTime {
                    dispatch_group_leave(group)
                    continue
                }
            }

            let aggOp = proxyType.aggregationOptions
            let keyPrefix = "\(type)_cd"
            let key = getPeriodCacheKey(keyPrefix, aggOp: aggOp, period: period)

            var queryStartTime: NSDate! = nil

            aggregateCache.setObjectForKey(key, cacheBlock: { success, failure in
                // This caches a singleton array by aggregating over all samples for the year.
                let doCache : ([MCSample], NSError?) -> Void = { (samples, error) in
                    guard error == nil else {
                        failure(error)
                        return
                    }
                    log.verbose("Caching sample collection days for \(key)")
                    let agg = self.aggregateSamplesManually(proxyType, aggOp: aggOp, samples: samples)
                    log.info("Finished SCQ for \(key) \(NSDate().timeIntervalSinceDate(queryStartTime!))")
                    success(MCAggregateArray(aggregates: [agg]), .Date(self.getCacheExpiry(period)))
                }

                log.info("Starting SCQ for \(key)")
                queryStartTime = NSDate()

                self.fetchAggregatesOfType(proxyType, predicate: predicate, aggUnit: .Day, aggOp: aggOp) {
                    self.queryResultAsSamples($0, error: $1) { doCache($0, $1) }
                }
            }, completion: {object, isLoadedFromCache, error in
                log.verbose("Cache sample collection days result \(key) \(isLoadedFromCache)")

                guard error == nil else {
                    log.error(error)
                    someError = error
                    results.updateValue(0, forKey: sampleType)
                    dispatch_group_leave(group)
                    return
                }

                if let aggArray = object {
                    log.verbose("Cache sample collection days result \(key) size \(aggArray.aggregates.count)")
                    if aggArray.aggregates.count > 0 {
                        results.updateValue(aggArray.aggregates[0].count(), forKey: sampleType)
                    } else {
                        log.info("No aggregates found for collection days")
                        results.updateValue(0, forKey: sampleType)
                    }
                    dispatch_group_leave(group)
                } else {
                    log.info("No aggregate array found for collection days")
                    results.updateValue(0, forKey: sampleType)
                    dispatch_group_leave(group)
                }
            })
        }

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            completion(results, someError)
        }
    }

    // Fetches summed circadian event durations, grouped according the the given function,
    // and within the specified start and end date.
    public func fetchCircadianDurationsByGroup<G: Hashable>(
                    startDate: NSDate, endDate: NSDate,
                    predicate: ((NSDate, CircadianEvent) -> Bool)? = nil, groupBy: ((NSDate, CircadianEvent) -> G),
                    completion: ([G:Double], NSError?) -> Void)
    {
        // Accumulator:
        // i. boolean indicating whether the current endpoint starts an interval.
        // ii. the previous event.
        // iii. a dictionary of accumulated durations per group.
        typealias Accum = (Bool, NSDate!, [G:Double])

        let aggregator : (Accum, (NSDate, CircadianEvent)) -> Accum = { (acc, e) in
            var partialAgg = acc.2
            let (startOfInterval, prevEvtDate) = (acc.0, acc.1)
            let groupKey = groupBy(e.0, e.1)

            if !startOfInterval && prevEvtDate != nil {
                // Accumulate the interval duration for the current category.
                var nAcc = partialAgg
                let nDur = (partialAgg[groupKey] ?? 0.0) + e.0.timeIntervalSinceDate(prevEvtDate!)
                nAcc.updateValue(nDur, forKey: groupKey)
            }
            return (!startOfInterval, e.0, partialAgg)
        }

        let initial : Accum = (true, nil, [:])
        let final : (Accum -> [G:Double]) = { return $0.2 }

        fetchAggregatedCircadianEvents(startDate, endDate: endDate, predicate: predicate, aggregator: aggregator,
                                       initialAccum: initial, initialResult: [:], final: final, completion: completion)
    }

    // General purpose fasting variability query, aggregating durations according to the given calendar unit.
    // This uses a one-pass variance/stddev calculation to finalize the resulting durations.
    public func fetchFastingVariability(startDate: NSDate, endDate: NSDate, aggUnit: NSCalendarUnit,
                                        completion: (variability: Double, error: NSError?) -> Void)
    {
        let predicate: ((NSDate, CircadianEvent) -> Bool) = {
            switch $0.1 {
            case .Exercise, .Fast, .Sleep:
                return true
            default:
                return false
            }
        }

        let group : (NSDate, CircadianEvent) -> NSDate = { return $0.0.startOf(aggUnit) }

        fetchCircadianDurationsByGroup(startDate, endDate: endDate, predicate: predicate, groupBy: group) {
            (table, error) in
            guard error == nil else {
                completion(variability: 0.0, error: error)
                return
            }
            // One-pass moment calculation.
            // State: [n, oldM, newM, oldS, newS]
            var st : [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
            table.forEach { v in
                st[0] += 1
                if st[0] == 1.0 { st[1] = v.1; st[2] = v.1; st[3] = 0.0; st[4] = 0.0; }
                else {
                    st[2] = st[1] + (v.1 - st[1]) / st[0]
                    st[4] = st[3] + (v.1 - st[1]) * (v.1 - st[2])
                    st[1] = st[2]
                    st[3] = st[4]
                }
            }
            let variance = st[0] > 1.0 ? ( st[4] / (st[0] - 1.0) ) : 0.0
            let stddev = sqrt(variance)
            completion(variability: stddev, error: error)
        }
    }

    public func fetchWeeklyFastingVariability(startDate: NSDate = 1.years.ago, endDate: NSDate = NSDate(),
                                              completion: (variability: Double, error: NSError?) -> Void)
    {
        log.info("Starting WFV query")
        let queryStartTime = NSDate()
        fetchFastingVariability(startDate, endDate: endDate, aggUnit: .WeekOfYear) {
            log.info("Finished WFV query \(NSDate().timeIntervalSinceDate(queryStartTime))")
            completion(variability: $0, error: $1)
        }
    }

    public func fetchDailyFastingVariability(startDate: NSDate = 1.months.ago, endDate: NSDate = NSDate(),
                                             completion: (variability: Double, error: NSError?) -> Void)
    {
        log.info("Starting DFV query")
        let queryStartTime = NSDate()
        fetchFastingVariability(startDate, endDate: endDate, aggUnit: .Day) {
            log.info("Finished DFV query \(NSDate().timeIntervalSinceDate(queryStartTime))")
            completion(variability: $0, error: $1)
        }
    }

    // Returns total time spent fasting and non-fasting in the last week
    public func fetchWeeklyFastState(completion: (fast: Double, nonFast: Double, error: NSError?) -> Void) {
        let group : (NSDate, CircadianEvent) -> Int = { e in
            switch e.1 {
            case .Meal:
                return 0

            case .Exercise, .Sleep, .Fast:
                return 1
            }
        }

        log.info("Starting WF STATE query")
        let queryStartTime = NSDate()
        fetchCircadianDurationsByGroup(1.weeks.ago, endDate: NSDate(), groupBy: group) { (categories, error) in
            log.info("Finished WF STATE query \(NSDate().timeIntervalSinceDate(queryStartTime))")
            guard error == nil else {
                completion(fast: 0.0, nonFast: 0.0, error: error)
                return
            }
            completion(fast: categories[0] ?? 0.0, nonFast: categories[1] ?? 0.0, error: error)
        }
    }

    // Returns total time spent fasting while sleeping and fasting while awake in the last week
    public func fetchWeeklyFastType(completion: (fastSleep: Double, fastAwake: Double, error: NSError?) -> Void) {
        let predicate: ((NSDate, CircadianEvent) -> Bool) = {
            switch $0.1 {
            case .Exercise, .Fast, .Sleep:
                return true
            default:
                return false
            }
        }

        let group : (NSDate, CircadianEvent) -> Int = { e in
            switch e.1 {
            case .Sleep:
                return 0
            case .Exercise, .Fast:
                return 1
            default:
                return 2
            }
        }

        log.info("Starting WF TYPE query")
        let queryStartTime = NSDate()
        fetchCircadianDurationsByGroup(1.weeks.ago, endDate: NSDate(), predicate: predicate, groupBy: group) { (categories, error) in
            log.info("Finished WF TYPE query \(NSDate().timeIntervalSinceDate(queryStartTime))")
            guard error == nil else {
                completion(fastSleep: 0.0, fastAwake: 0.0, error: error)
                return
            }
            completion(fastSleep: categories[0] ?? 0.0, fastAwake: categories[1] ?? 0.0, error: error)
        }
    }

    // Returns total time spent eating and exercising in the last week
    public func fetchWeeklyEatAndExercise(completion: (eatingTime: Double, exerciseTime: Double, error: NSError?) -> Void) {
        let predicate: ((NSDate, CircadianEvent) -> Bool) = {
            switch $0.1 {
            case .Exercise, .Meal:
                return true
            default:
                return false
            }

        }

        let group : (NSDate, CircadianEvent) -> Int = { e in
            switch e.1 {
            case .Meal:
                return 0
            case .Exercise:
                return 1
            default:
                return 2
            }
        }

        log.info("Starting WEE query")
        let queryStartTime = NSDate()
        fetchCircadianDurationsByGroup(1.weeks.ago, endDate: NSDate(), predicate: predicate, groupBy: group) { (categories, error) in
            log.info("Finished WEE query \(NSDate().timeIntervalSinceDate(queryStartTime))")
            guard error == nil else {
                completion(eatingTime: 0.0, exerciseTime: 0.0, error: error)
                return
            }
            completion(eatingTime: categories[0] ?? 0.0, exerciseTime: categories[1] ?? 0.0, error: error)
        }
    }

    public func correlateWithFasting(sortFasting: Bool, type: HKSampleType, predicate: NSPredicate? = nil, completion: HMFastingCorrelationBlock) {
        var results1: [MCSample]?
        var results2: [(NSDate, Double)]?

        func intersect(samples: [MCSample], fasting: [(NSDate, Double)]) -> [(NSDate, Double, MCSample)] {
            var output:[(NSDate, Double, MCSample)] = []
            var byDay: [NSDate: Double] = [:]
            fasting.forEach { f in
                let start = f.0.startOf(.Day)
                byDay.updateValue((byDay[start] ?? 0.0) + f.1, forKey: start)
            }

            samples.forEach { s in
                let start = s.startDate.startOf(.Day)
                if let match = byDay[start] { output.append((start, match, s)) }
            }
            return output
        }

        let group = dispatch_group_create()
        dispatch_group_enter(group)
        fetchStatisticsOfType(type, predicate: predicate) { (results, error) -> Void in
            guard error == nil else {
                completion([], error)
                dispatch_group_leave(group)
                return
            }
            results1 = results
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        fetchMaxFastingTimes { (results, error) -> Void in
            guard error == nil else {
                completion([], error)
                dispatch_group_leave(group)
                return
            }
            results2 = results
            dispatch_group_leave(group)
        }

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            guard !(results1 == nil || results2 == nil) else {
                let desc = results1 == nil ? (results2 == nil ? "LHS and RHS" : "LHS") : "RHS"
                let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Invalid \(desc) statistics"])
                completion([], err)
                return
            }
            var zipped = intersect(results1!, fasting: results2!)
            zipped.sortInPlace { (a,b) in return ( sortFasting ? a.1 < b.1 : a.2.numeralValue! < b.2.numeralValue! ) }
            completion(zipped, nil)
        }
    }


    // MARK: - Writing into HealthKit
    public func saveSample(sample: HKSample, completion: (Bool, NSError?) -> Void)
    {
        healthKitStore.saveObject(sample, withCompletion: completion)
    }

    public func saveSamples(samples: [HKSample], completion: (Bool, NSError?) -> Void)
    {
        healthKitStore.saveObjects(samples, withCompletion: completion)
    }

    public func saveSleep(startDate: NSDate, endDate: NSDate, metadata: NSDictionary, completion: ( (Bool, NSError!) -> Void)!)
    {
        log.debug("Saving sleep \(startDate) \(endDate)")

        let type = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let sample = HKCategorySample(type: type, value: HKCategoryValueSleepAnalysis.Asleep.rawValue, startDate: startDate, endDate: endDate, metadata: metadata as? [String : AnyObject])

        healthKitStore.saveObject(sample, withCompletion: { (success, error) -> Void in
            if( error != nil  ) { completion(success,error) }
            else { completion(success,nil) }
        })
    }

    public func saveWorkout(startDate: NSDate, endDate: NSDate, activityType: HKWorkoutActivityType, distance: Double, distanceUnit: HKUnit, kiloCalories: Double, metadata:NSDictionary, completion: ( (Bool, NSError!) -> Void)!)
    {
        log.debug("Saving workout \(startDate) \(endDate)")

        let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
        let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)

        let workout = HKWorkout(activityType: activityType, startDate: startDate, endDate: endDate, duration: abs(endDate.timeIntervalSinceDate(startDate)), totalEnergyBurned: caloriesQuantity, totalDistance: distanceQuantity, metadata: metadata  as! [String:String])

        healthKitStore.saveObject(workout, withCompletion: { (success, error) -> Void in
            if( error != nil  ) { completion(success,error) }
            else { completion(success,nil) }
        })
    }

    public func saveRunningWorkout(startDate: NSDate, endDate: NSDate, distance:Double, distanceUnit: HKUnit, kiloCalories: Double, metadata: NSDictionary, completion: ( (Bool, NSError!) -> Void)!)
    {
        saveWorkout(startDate, endDate: endDate, activityType: HKWorkoutActivityType.Running, distance: distance, distanceUnit: distanceUnit, kiloCalories: kiloCalories, metadata: metadata, completion: completion)
    }

    public func saveCyclingWorkout(startDate: NSDate, endDate: NSDate, distance:Double, distanceUnit: HKUnit, kiloCalories: Double, metadata: NSDictionary, completion: ( (Bool, NSError!) -> Void)!)
    {
        saveWorkout(startDate, endDate: endDate, activityType: HKWorkoutActivityType.Cycling, distance: distance, distanceUnit: distanceUnit, kiloCalories: kiloCalories, metadata: metadata, completion: completion)
    }

    public func saveSwimmingWorkout(startDate: NSDate, endDate: NSDate, distance:Double, distanceUnit: HKUnit, kiloCalories: Double, metadata: NSDictionary, completion: ( (Bool, NSError!) -> Void)!)
    {
        saveWorkout(startDate, endDate: endDate, activityType: HKWorkoutActivityType.Swimming, distance: distance, distanceUnit: distanceUnit, kiloCalories: kiloCalories, metadata: metadata, completion: completion)
    }

    public func savePreparationAndRecoveryWorkout(startDate: NSDate, endDate: NSDate, distance:Double, distanceUnit: HKUnit, kiloCalories: Double, metadata: NSDictionary, completion: ( (Bool, NSError!) -> Void)!)
    {
        saveWorkout(startDate, endDate: endDate, activityType: HKWorkoutActivityType.PreparationAndRecovery, distance: distance, distanceUnit: distanceUnit, kiloCalories: kiloCalories, metadata: metadata, completion: completion)
    }


    // MARK: - Removing samples from HealthKit

    // Due to HealthKit bug, taken from: https://gist.github.com/bendodson/c0f0a6a1f601dc4573ba
    func deleteSamplesOfType(sampleType: HKSampleType, startDate: NSDate?, endDate: NSDate?, predicate: NSPredicate,
                             withCompletion completion: (success: Bool, count: Int, error: NSError?) -> Void)
    {
        let predWithInterval =
            startDate == nil && endDate == nil ?
                predicate :
                NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate, HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
                ])

        let query = HKSampleQuery(sampleType: sampleType, predicate: predWithInterval, limit: 0, sortDescriptors: nil) { (query, results, error) -> Void in
            if let _ = error {
                completion(success: false, count: 0, error: error)
                return
            }

            if let objects = results {
                if objects.count == 0 {
                    completion(success: true, count: 0, error: nil)
                } else {
                    self.healthKitStore.deleteObjects(objects, withCompletion: { (success, error) -> Void in
                        completion(success: error == nil, count: objects.count, error: error)
                    })
                }
            } else {
                completion(success: true, count: 0, error: nil)
            }

        }
        healthKitStore.executeQuery(query)
    }

    public func deleteSamples(startDate: NSDate? = nil, endDate: NSDate? = nil, typesAndPredicates: [HKSampleType: NSPredicate],
                              completion: (deleted: Int, error: NSError!) -> Void)
    {
        let group = dispatch_group_create()
        var numDeleted = 0

        typesAndPredicates.forEach { (type, predicate) -> () in
            dispatch_group_enter(group)
            self.deleteSamplesOfType(type, startDate: startDate, endDate: endDate, predicate: predicate) {
                (success, count, error) in
                guard success && error == nil else {
                    log.error("Could not delete samples for \(type.displayText)(\(success)): \(error)")
                    dispatch_group_leave(group)
                    return
                }
                numDeleted += count
                dispatch_group_leave(group)
            }
        }

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            // TODO: partial error handling, i.e., when a subset of the desired types fail in their queries.
            completion(deleted: numDeleted, error: nil)
        }
    }

    public func deleteCircadianEvents(startDate: NSDate, endDate: NSDate, completion: NSError? -> Void) {
        let withSourcePredicate: NSPredicate -> NSPredicate = { pred in
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                pred, HKQuery.predicateForObjectsFromSource(HKSource.defaultSource())
            ])
        }

        let mealConjuncts = [
            HKQuery.predicateForWorkoutsWithWorkoutActivityType(.PreparationAndRecovery),
            HKQuery.predicateForObjectsWithMetadataKey("Meal Type")
        ]
        let mealPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: mealConjuncts)

        let circadianEventPredicates: NSPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            mealPredicate,
            HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Running),
            HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Cycling),
            HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Swimming),
        ])

        let sleepType = HKCategoryType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let sleepPredicate = HKQuery.predicateForCategorySamplesWithOperatorType(.EqualToPredicateOperatorType, value: HKCategoryValueSleepAnalysis.Asleep.rawValue)

        let typesAndPredicates: [HKSampleType: NSPredicate] = [
            HKWorkoutType.workoutType(): withSourcePredicate(circadianEventPredicates)
          , sleepType: withSourcePredicate(sleepPredicate)
        ]

        self.deleteSamples(startDate, endDate: endDate, typesAndPredicates: typesAndPredicates) { (deleted, error) in
            if error != nil {
                log.error("Failed to delete samples on the device, HealthKit may potentially diverge from the server.")
                log.error(error)
            }
            completion(error)
        }
    }


    // MARK: - Cache invalidation

    public func invalidateCache(type: HKSampleType) {
        let cacheType = type.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : type.identifier
        let cacheKeyPrefix = cacheType
        let expiredPeriods : [HealthManagerStatisticsRangeType] = [.Week, .Month, .Year]
        var expiredKeys : [String]

        let minMaxKeys = expiredPeriods.map { self.getPeriodCacheKey(cacheKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: $0) }
        let avgKeys = expiredPeriods.map { self.getPeriodCacheKey(cacheKeyPrefix, aggOp: .DiscreteAverage, period: $0) }

        if cacheType == HKQuantityTypeIdentifierHeartRate || cacheType == HKQuantityTypeIdentifierUVExposure {
            expiredKeys = minMaxKeys
        } else if cacheType == HKQuantityTypeIdentifierBloodPressureSystolic {
            let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
            expiredKeys = minMaxKeys
            expiredKeys.appendContentsOf(
                expiredPeriods.map { self.getPeriodCacheKey(diastolicKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: $0) })
        } else {
            expiredKeys = avgKeys
        }
        expiredKeys.forEach {
            log.info("Invalidating aggregate cache for \($0)")
            self.aggregateCache.removeObjectForKey($0)
        }
    }

    // MARK: - Observers
    public func startBackgroundObserverForType(type: HKSampleType, maxResultsPerQuery: Int = Int(HKObjectQueryNoLimit),
                                               getAnchorCallback: HKSampleType -> (Bool, HKQueryAnchor?, NSPredicate?),
                                               anchorQueryCallback: HMAnchorSamplesCBlock) -> Void
    {
        let onBackgroundStarted = {(success: Bool, nsError: NSError?) -> Void in
            guard success else {
                log.error(nsError)
                return
            }
            // Create and execute an observer query that itself issues an anchored query every
            // time new data is added or deleted in HealthKit.
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
                        // We use getOldestSampleForType to initialize the archive span minimums.
                        log.verbose("Registering bulk ingestion availability for: \(tname)")
                        self.getOldestSampleForType(type) { _ in () }
                    }
                }

                self.fetchAnchoredSamplesOfType(type, predicate: predicate, anchor: anchor, maxResults: maxResultsPerQuery, callContinuously: false) {
                    (added, deleted, newAnchor, error) -> Void in

                    // Invalidate caches only if we have actually added or removed data according to the anchor query.
                    if added.count > 0 || deleted.count > 0 {
                        self.invalidateCache(type)
                    }

                    anchorQueryCallback(added: added, deleted: deleted, newAnchor: newAnchor, error: error, completion: completion)
                }
            }
            self.healthKitStore.executeQuery(obsQuery)
        }
        healthKitStore.enableBackgroundDeliveryForType(type, frequency: HKUpdateFrequency.Immediate, withCompletion: onBackgroundStarted)
    }

    // MARK: - Chart queries

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
                    self.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) {
                        if $2 != nil { log.error($2) }
                        dispatch_group_leave(group)
                    }
                } else if type == HKQuantityTypeIdentifierBloodPressureSystolic {
                    // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
                    let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
                    let bloodPressureGroup = dispatch_group_create()

                    dispatch_group_enter(bloodPressureGroup)
                    self.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                        if $2 != nil { log.error($2) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    let diastolicType = HKQuantityTypeIdentifierBloodPressureDiastolic
                    dispatch_group_enter(bloodPressureGroup)
                    self.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                        if $2 != nil { log.error($2) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        dispatch_group_leave(group) //leave main group
                    }

                } else {
                    self.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) {
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
            key = getPeriodCacheKey(keyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: period)
            asMinMax = true
            asBP = type == HKQuantityTypeIdentifierBloodPressureSystolic
        } else {
            key = getPeriodCacheKey(keyPrefix, aggOp: .DiscreteAverage, period: period)
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
                self.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                    if $2 != nil { log.error($2) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_enter(bloodPressureGroup)
                self.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                    if $2 != nil { log.error($2) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let diastolicKey = self.getPeriodCacheKey(diastolicKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: period)

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
                self.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period) { (_, _, error) in
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
            self.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) { (_, error) in
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

// Helper struct for iterating over date ranges.
struct DateRange : SequenceType {

    var calendar: NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!

    var startDate: NSDate
    var endDate: NSDate
    var stepUnits: NSCalendarUnit
    var stepValue: Int

    var currentStep: Int = 0

    init(startDate: NSDate, endDate: NSDate, stepUnits: NSCalendarUnit, stepValue: Int = 1) {
        self.startDate = startDate
        self.endDate = endDate
        self.stepUnits = stepUnits
        self.stepValue = stepValue
    }

    func generate() -> Generator {
        return Generator(range: self)
    }

    struct Generator: GeneratorType {

        var range: DateRange

        mutating func next() -> NSDate? {
            if range.currentStep == 0 { range.currentStep += 1; return range.startDate }
            else {
                if let nextDate = range.calendar.dateByAddingUnit(range.stepUnits, value: range.stepValue, toDate: range.startDate, options: NSCalendarOptions(rawValue: 0)) {
                    range.currentStep += 1
                    if range.endDate <= nextDate {
                        return nil
                    } else {
                        range.startDate = nextDate
                        return nextDate
                    }
                }
                return nil
            }
        }
    }
}