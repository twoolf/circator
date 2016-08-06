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
//import CocoaLumberjack
import SwiftyUserDefaults
import SwiftDate
import AwesomeCache
import MCcircadianQueries
import SwiftyBeaver


// Constants.
private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noLimit  = Int(HKObjectQueryNoLimit)
private let dateAsc  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
private let dateDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
private let lastChartsDataCacheKey = "lastChartsDataCacheKey"

public typealias HMAuthorizationBlock  = (success: Bool, error: NSError?) -> Void
public typealias HMSampleBlock         = (samples: [MCSample], error: NSError?) -> Void
public typealias HMTypedSampleBlock    = (samples: [HKSampleType: [MCSample]], error: NSError?) -> Void
public typealias HMAggregateBlock      = (aggregates: MCcircadianQueries.AggregateQueryResult, error: NSError?) -> Void
public typealias HMCorrelationBlock    = ([MCSample], [MCSample], NSError?) -> Void

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

    private let log = SwiftyBeaver.self
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
                self.log.error("Could not fetch recent samples for \(type.displayText): \(error)")
                dispatch_group_leave(group)
                return
            }
            guard statistics.isEmpty == false else {
                self.log.warning("No recent samples available for \(type.displayText)")
                dispatch_group_leave(group)
                return
            }
            samples[type] = statistics
            dispatch_group_leave(group)
        }

        let onStatistic : HKSampleType -> Void = { type in
            let predicate = HKSampleQuery.predicateForSamplesWithStartDate(4.days.ago, endDate: nil, options: HKQueryOptions())
            MCcircadianQueries.sharedManager.fetchStatisticsOfType(type, predicate: predicate) { (statistics, error) in
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
                    self.log.error("Could not fetch recent samples for \(type.displayText): \(error)")
                    dispatch_group_leave(group)
                    return
                }
                guard samples.isEmpty == false else {
                    self.log.warning("No recent samples available for \(type.displayText)")
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
                self.log.error("Could not get oldest sample for: \(tname)")
                return
            }
            let minDate = samples.isEmpty ? NSDate() : samples[0].startDate
            UserManager.sharedManager.setHistoricalRangeMinForType(type.identifier, min: minDate, sync: true)
            self.log.info("Lower bound date for \(tname): \(minDate)")
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

    private func finalizePartialAggregation(aggUnit: NSCalendarUnit,
                                            aggOp: HKStatisticsOptions,
                                            result: MCcircadianQueries.AggregateQueryResult,
                                            error: NSError?,
                                            completion: (([MCAggregateSample], NSError?) -> Void))
    {
        MCcircadianQueries.sharedManager.queryResultAsSamples(result, error: error) { (samples, error) in
            guard error == nil else {
                completion([], error)
                return
            }
            let byPeriod = MCcircadianQueries.sharedManager.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            completion(byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }, nil)
        }
    }

    private func finalizePartialAggregationAsSamples(aggUnit: NSCalendarUnit,
                                                     aggOp: HKStatisticsOptions,
                                                     result: MCcircadianQueries.AggregateQueryResult,
                                                     error: NSError?,
                                                     completion: HMSampleBlock)
    {
        MCcircadianQueries.sharedManager.queryResultAsSamples(result, error: error) { (samples, error) in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            let byPeriod = MCcircadianQueries.sharedManager.aggregateByPeriod(aggUnit, aggOp: aggOp, samples: samples)
            completion(samples: byPeriod.sort({ (a,b) in return a.0 < b.0 }).map { $0.1 }, error: nil)
        }
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
        MCcircadianQueries.sharedManager.fetchStatisticsOfType(type, predicate: pred1) { (results, error) -> Void in
            guard error == nil else {
                completion([], [], error)
                dispatch_group_leave(group)
                return
            }
            results1 = results
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchStatisticsOfType(type2, predicate: pred2) { (results, error) -> Void in
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
                    self.log.error("Could not delete samples for \(type.displayText)(\(success)): \(error)")
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
                self.log.error("Failed to delete samples on the device, HealthKit may potentially diverge from the server.")
                self.log.error(error as! String)
            }
            completion(error)
        }
    }


    // MARK: - Cache invalidation

    public func invalidateCache(type: HKSampleType) {
        let cacheType = type.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : type.identifier
        let cacheKeyPrefix = cacheType
        let expiredPeriods : [MCcircadianQueries.HealthManagerStatisticsRangeType] = [.Week, .Month, .Year]
        var expiredKeys : [String]

        let minMaxKeys = expiredPeriods.map { MCcircadianQueries.sharedManager.getPeriodCacheKey(cacheKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: $0) }
        let avgKeys = expiredPeriods.map { MCcircadianQueries.sharedManager.getPeriodCacheKey(cacheKeyPrefix, aggOp: .DiscreteAverage, period: $0) }

        if cacheType == HKQuantityTypeIdentifierHeartRate || cacheType == HKQuantityTypeIdentifierUVExposure {
            expiredKeys = minMaxKeys
        } else if cacheType == HKQuantityTypeIdentifierBloodPressureSystolic {
            let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
            expiredKeys = minMaxKeys
            expiredKeys.appendContentsOf(
                expiredPeriods.map { MCcircadianQueries.sharedManager.getPeriodCacheKey(diastolicKeyPrefix, aggOp: [.DiscreteMin, .DiscreteMax], period: $0) })
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
                self.log.error(nsError as! String)
                return
            }
            // Create and execute an observer query that itself issues an anchored query every
            // time new data is added or deleted in HealthKit.
            let obsQuery = HKObserverQuery(sampleType: type, predicate: nil) {
                query, completion, obsError in
                guard obsError == nil else {
                    self.log.error(obsError as! String)
                    return
                }

                let tname = type.displayText ?? type.identifier
                let (needsOldestSamples, anchor, predicate) = getAnchorCallback(type)
                if needsOldestSamples {
                    Async.background(after: 0.5) {
                        // We use getOldestSampleForType to initialize the archive span minimums.
                        self.log.verbose("Registering bulk ingestion availability for: \(tname)")
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

        let periods: [MCcircadianQueries.HealthManagerStatisticsRangeType] = [
            MCcircadianQueries.HealthManagerStatisticsRangeType.Week
            , MCcircadianQueries.HealthManagerStatisticsRangeType.Month
            , MCcircadianQueries.HealthManagerStatisticsRangeType.Year
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
                        if $2 != nil { self.log.error($2 as! String) }
                        dispatch_group_leave(group)
                    }
                } else if type == HKQuantityTypeIdentifierBloodPressureSystolic {
                    // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
                    let diastolicKeyPrefix = HKQuantityTypeIdentifierBloodPressureDiastolic
                    let bloodPressureGroup = dispatch_group_create()

                    dispatch_group_enter(bloodPressureGroup)
                    MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(keyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(type)!, period: period) {
                        if $2 != nil { self.log.error($2 as! String) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    let diastolicType = HKQuantityTypeIdentifierBloodPressureDiastolic
                    dispatch_group_enter(bloodPressureGroup)
                    MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                        if $2 != nil { self.log.error($2 as! String) }
                        dispatch_group_leave(bloodPressureGroup)
                    }

                    dispatch_group_notify(bloodPressureGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        dispatch_group_leave(group) //leave main group
                    }

                } else {
                    MCcircadianQueries.sharedManager.getDailyStatisticsOfTypeForPeriod(keyPrefix, sampleType: sampleType, period: period, aggOp: .DiscreteAverage) {
                        if $1 != nil { self.log.error($1 as! String) }
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

    public func getChartDataForQuantity(sampleType: HKSampleType, inPeriod period: MCcircadianQueries.HealthManagerStatisticsRangeType, completion: AnyObject -> Void) {
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
                    if $2 != nil { self.log.error($2 as! String) }
                    dispatch_group_leave(bloodPressureGroup)
                }

                dispatch_group_enter(bloodPressureGroup)
                MCcircadianQueries.sharedManager.getMinMaxOfTypeForPeriod(diastolicKeyPrefix, sampleType: HKObjectType.quantityTypeForIdentifier(diastolicType)!, period: period) {
                    if $2 != nil { self.log.error($2 as! String) }
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
            log.error(error as! String)
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