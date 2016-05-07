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
import Granola
import Alamofire
import SwiftyJSON
import SwiftyBeaver
import SwiftyUserDefaults
import SwiftDate

public typealias HMAuthorizationBlock  = (success: Bool, error: NSError?) -> Void
public typealias HMSampleBlock         = (samples: [MCSample], error: NSError?) -> Void
public typealias HMTypedSampleBlock    = (samples: [HKSampleType: [MCSample]], error: NSError?) -> Void
public typealias HMCorrelationBlock    = ([MCSample], [MCSample], NSError?) -> Void

public typealias HMCircadianBlock          = (intervals: [(NSDate, CircadianEvent)], error: NSError?) -> Void
public typealias HMCircadianAggregateBlock = (aggregates: [(NSDate, Double)], error: NSError?) -> Void

public typealias HMFastingCorrelationBlock = ([(NSDate, Double, MCSample)], NSError?) -> Void

public typealias HMAnchorQueryBlock    = (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, NSError?) -> Void
public typealias HMAnchorSamplesBlock  = (added: [HKSample], deleted: [HKDeletedObject], newAnchor: HKQueryAnchor?, error: NSError?) -> Void

public let HMErrorDomain                        = "HMErrorDomain"
public let HMSampleTypeIdentifierSleepDuration  = "HMSampleTypeIdentifierSleepDuration"
public let HMDidUpdateRecentSamplesNotification = "HMDidUpdateRecentSamplesNotification"

private let HMAnchorKey      = DefaultsKey<[String: AnyObject]?>("HKClientAnchorKey")
private let HMAnchorTSKey    = DefaultsKey<[String: AnyObject]?>("HKAnchorTSKey")
private let HMHRangeStartKey = DefaultsKey<[String: AnyObject]>("HKHRangeStartKey")
private let HMHRangeEndKey   = DefaultsKey<[String: AnyObject]>("HKHRangeEndKey")
private let HMHRangeMinKey   = DefaultsKey<[String: AnyObject]>("HKHRangeMinKey")

// Constants.
private let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
private let noLimit  = Int(HKObjectQueryNoLimit)
private let noAnchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
private let dateAsc  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
private let dateDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

/**
 This is the main manager of information reads/writes from HealthKit.  We use AnchorQueries to support continued updates.  Please see Apple Docs for syntax on reading/writing
 
 */
public class HealthManager: NSObject, WCSessionDelegate {

    public static let sharedManager = HealthManager()
    public static let serializer = OMHSerializer()

    lazy var healthKitStore: HKHealthStore = HKHealthStore()

    private override init() {
        super.init()
        connectWatch()
    }

    public var mostRecentSamples = [HKSampleType: [MCSample]]() {
        didSet {
            self.updateWatchContext()
        }
    }

    // Not guaranteed to be on main thread
    public func authorizeHealthKit(completion: HMAuthorizationBlock)
    {
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: HMErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this Device"])
            completion(success: false, error:error)
            return
        }

        healthKitStore.requestAuthorizationToShareTypes(HMConstants.sharedInstance.healthKitTypesToWrite, readTypes: HMConstants.sharedInstance.healthKitTypesToRead)
            { (success, error) -> Void in
                completion(success: success, error: error)
        }
    }

    // MARK: - Predicate construction

    public func mealsSincePredicate(startDate: NSDate? = nil, endDate: NSDate = NSDate()) -> NSPredicate? {
        var predicate : NSPredicate? = nil
        if let st = startDate {
            let conjuncts = [
                HKQuery.predicateForSamplesWithStartDate(st, endDate: endDate, options: .None),
                HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
            ]
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: conjuncts)
        } else {
            predicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
        }
        return predicate
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

    // MARK: - HealthKit sample retrieval.

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

    // Fetch samples, aggregating per day.
    public func fetchAggregatedSamplesOfType(sampleType: HKSampleType, aggregateUnit: NSCalendarUnit = .Day, predicate: NSPredicate? = nil,
                                             limit: Int = noLimit, sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        fetchSamplesOfType(sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { samples, error in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            var byDay: [NSDate: MCAggregateSample] = [:]
            samples.forEach { sample in
                let day = sample.startDate.startOf(aggregateUnit, inRegion: Region())
                if var agg = byDay[day] {
                    agg.incr(sample)
                    byDay[day] = agg
                } else {
                    byDay[day] = MCAggregateSample(sample: sample)
                }
            }

            let doFinal: ((NSDate, MCAggregateSample) -> MCSample) = { (_,var agg) in agg.final(); return agg as MCSample }
            completion(samples: byDay.sort({ (a,b) in return a.0 < b.0 }).map(doFinal), error: nil)
        }
    }

    // Completion handler is on background queue
    public func fetchStatisticsOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, completion: HMSampleBlock) {
        switch sampleType {
        case is HKCategoryType:
            fallthrough

        case is HKCorrelationType:
            fallthrough

        case is HKWorkoutType:
            fetchAggregatedSamplesOfType(sampleType, predicate: predicate, completion: completion)

        case is HKQuantityType:
            let interval = NSDateComponents()
            interval.day = 1

            // Set the anchor date to midnight today.
            let anchorDate = NSDate().startOf(.Day, inRegion: Region())
            let quantityType = HKObjectType.quantityTypeForIdentifier(sampleType.identifier)!

            // Create the query
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: quantityType.aggregationOptions,
                anchorDate: anchorDate,
                intervalComponents: interval)

            // Set the results handler
            query.initialResultsHandler = { query, results, error in
                guard error == nil else {
                    log.error("Failed to fetch \(sampleType.displayText) statistics: \(error!)")
                    completion(samples: [], error: error)
                    return
                }
                completion(samples: results?.statistics().map { $0 as MCSample } ?? [], error: nil)
            }
            healthKitStore.executeQuery(query)

        default:
            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
            completion(samples: [], error: err)
        }
    }

    // Completion handler is on main queue
    public func correlateStatisticsOfType(type: HKSampleType, withType type2: HKSampleType, pred1: NSPredicate? = nil, pred2: NSPredicate? = nil, completion: HMCorrelationBlock) {
        var results1: [MCSample]?
        var results2: [MCSample]?

        func intersect(arr1: [MCSample], arr2: [MCSample]) -> [(NSDate, MCSample, MCSample)] {
            var output: [(NSDate, MCSample, MCSample)] = []
            var arr1ByDay : [NSDate: MCSample] = [:]
            arr1.forEach { s in
                let start = s.startDate.startOf(.Day, inRegion: Region())
                arr1ByDay.updateValue(s, forKey: start)
            }

            arr2.forEach { s in
                let start = s.startDate.startOf(.Day, inRegion: Region())
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

        dispatch_group_notify(group, dispatch_get_main_queue()) {
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

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            // TODO: partial error handling, i.e., when a subset of the desired types fail in their queries.
            completion(samples: samplesByType, error: nil)
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
                let eventEndpointDate = e.0
                let eventMetabolicState = e.1

                let resultArray = acc.0
                let eventIsIntervalStart = acc.1
                let prevEvent = acc.2

                let nextEventAsIntervalStart = !acc.1

                guard prevEvent != nil else {
                    // Skip prefix indicates whether we should add a fasting interval before the first event.
                    let skipPrefix = eventEndpointDate == startDate || startDate == NSDate.distantPast()
                    let newResultArray = (skipPrefix ? [event] : [(startDate, CircadianEvent.Fast), (eventEndpointDate, CircadianEvent.Fast), eventEndpointDate])
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
    public func fetchAggregatedCircadianEvents<T>(predicate: ((NSDate, CircadianEvent) -> Bool)? = nil,
                                                  aggregator: ((T, (NSDate, CircadianEvent)) -> T), initial: T, final: (T -> [(NSDate, Double)]),
                                                  completion: HMCircadianAggregateBlock)
    {
        fetchCircadianEventIntervals(NSDate.distantPast()) { (intervals, error) in
            guard error == nil else {
                completion(aggregates: [], error: error)
                return
            }

            let filtered = predicate == nil ? intervals : intervals.filter(predicate!)
            let accum = filtered.reduce(initial, combine: aggregator)
            completion(aggregates: final(accum), error: nil)
        }
    }

    // Compute total eating times per day by filtering and aggregating over meal events.
    public func fetchEatingTimes(completion: HMCircadianAggregateBlock) {
        typealias Accum = (Bool, NSDate!, [NSDate: Double])
        let aggregator : (Accum, (NSDate, CircadianEvent)) -> Accum = { (acc, e) in
            if !acc.0 && acc.1 != nil {
                switch e.1 {
                case .Meal:
                    let day = acc.1.startOf(.Day, inRegion: Region())
                    var nacc = acc.2
                    nacc.updateValue((acc.2[day] ?? 0.0) + e.0.timeIntervalSinceDate(acc.1!), forKey: day)
                    return (!acc.0, e.0, nacc)
                default:
                    return (!acc.0, e.0, acc.2)
                }
            }
            return (!acc.0, e.0, acc.2)
        }
        let initial : Accum = (true, nil, [:])
        let final : (Accum -> [(NSDate, Double)]) = { acc in
            return acc.2.map { return ($0.0, $0.1 / 3600.0) }.sort { (a,b) in return a.0 < b.0 }
        }

        fetchAggregatedCircadianEvents(nil, aggregator: aggregator, initial: initial, final: final, completion: completion)
    }

    // Compute max fasting times per day by filtering and aggregating over everything other than meal events.
    // This stitches fasting events together if they are sequential (i.e., one ends while the other starts).
    public func fetchMaxFastingTimes(completion: HMCircadianAggregateBlock)
    {
        // Accumulator:
        // i. boolean indicating event start.
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
            let (iStart, prevFast, prevEvt) = (acc.0, acc.1, acc.2)
            var nextFast = prevFast
            if iStart && prevFast != nil && prevEvt != nil && e.0 != prevEvt {
                let fastStartDay = prevFast.startOf(.Day, inRegion: Region())
                let duration = prevEvt.timeIntervalSinceDate(prevFast)
                let currentMax = byDay[fastStartDay] ?? duration
                byDay.updateValue(currentMax >= duration ? currentMax : duration, forKey: fastStartDay)
                nextFast = e.0
            } else if iStart && prevFast == nil {
                nextFast = e.0
            }
            return (!acc.0, nextFast, e.0, byDay)
        }

        let initial : Accum = (true, nil, nil, [:])
        let final : Accum -> [(NSDate, Double)] = { acc in
            var byDay = acc.3
            if let finalFast = acc.1, finalEvt = acc.2 {
                if finalFast != finalEvt {
                    let fastStartDay = finalFast.startOf(.Day, inRegion: Region())
                    let duration = finalEvt.timeIntervalSinceDate(finalFast)
                    let currentMax = byDay[fastStartDay] ?? duration
                    byDay.updateValue(currentMax >= duration ? currentMax : duration, forKey: fastStartDay)
                }
            }
            return byDay.map { return ($0.0, $0.1 / 3600.0) }.sort { (a,b) in return a.0 < b.0 }
        }

        fetchAggregatedCircadianEvents(predicate, aggregator: aggregator, initial: initial, final: final, completion: completion)
    }

    public func correlateWithFasting(sortFasting: Bool, type: HKSampleType, predicate: NSPredicate? = nil, completion: HMFastingCorrelationBlock) {
        var results1: [MCSample]?
        var results2: [(NSDate, Double)]?

        func intersect(samples: [MCSample], fasting: [(NSDate, Double)]) -> [(NSDate, Double, MCSample)] {
            var output:[(NSDate, Double, MCSample)] = []
            var byDay: [NSDate: Double] = [:]
            fasting.forEach { f in
                let start = f.0.startOf(.Day, inRegion: Region())
                byDay.updateValue((byDay[start] ?? 0.0) + f.1, forKey: start)
            }

            samples.forEach { s in
                let start = s.startDate.startOf(.Day, inRegion: Region())
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

        dispatch_group_notify(group, dispatch_get_main_queue()) {
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


    // MARK: - Observers

    public func registerObservers() {
        authorizeHealthKit { (success, _) -> Void in
            guard success else {
                return
            }

            HMConstants.sharedInstance.healthKitTypesToObserve.forEach { (type) in
                self.startBackgroundObserverForType(type) { (added, _, _, error) -> Void in
                    guard error == nil else {
                        log.error("Failed to register observers: \(error)")
                        return
                    }
                    self.uploadSamplesForType(type, added: added)
                }
            }
        }

    }

    public func startBackgroundObserverForType(type: HKSampleType, maxResultsPerQuery: Int = noLimit, anchorQueryCallback: HMAnchorSamplesBlock)
                -> Void
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

                let anchor = self.getAnchorForType(type)
                let tname = type.displayText ?? type.identifier

                var predicate : NSPredicate? = nil

                // When initializing an anchor query, apply a predicate to limit the initial results.
                // If we already have a historical range, we filter samples to the current timestamp.
                if anchor == noAnchor
                {
                    if let (_, hend) = UserManager.sharedManager.getHistoricalRangeForType(type.identifier) {
                        // We use acquisition times stored in the profile if available rather than the current time,
                        // to grab all data since the last remote upload to the server.
                        if let  lastAcqTS = UserManager.sharedManager.getAcquisitionTimes(),
                                acqK = UserManager.sharedManager.shortId(type.identifier),
                                typeTS = lastAcqTS[acqK] as? NSTimeInterval
                        {
                            let importStart = NSDate(timeIntervalSinceReferenceDate: typeTS)
                            predicate = HKQuery.predicateForSamplesWithStartDate(importStart, endDate: NSDate(), options: .None)
                            log.info("Data import since \(importStart): \(tname)")
                        } else {
                            let nearFuture = 1.minutes.fromNow
                            let pstart = NSDate(timeIntervalSinceReferenceDate: hend)
                            predicate = HKQuery.predicateForSamplesWithStartDate(pstart, endDate: nearFuture, options: .None)
                            log.info("Data import from \(pstart) \(nearFuture): \(tname)")
                        }
                    } else {
                        let (start, end) = UserManager.sharedManager.initializeHistoricalRangeForType(type.identifier, sync: true)
                        let (dstart, dend) = (NSDate(timeIntervalSinceReferenceDate: start), NSDate(timeIntervalSinceReferenceDate: end))
                        predicate = HKQuery.predicateForSamplesWithStartDate(dstart, endDate: dend, options: .None)

                        Async.background(after: 0.5) {
                            log.verbose("Registering bulk ingestion availability for: \(tname)")
                            self.getOldestSampleForType(type) { _ in () }
                        }
                    }
                }

                self.fetchAnchoredSamplesOfType(type, predicate: predicate, anchor: anchor, maxResults: maxResultsPerQuery, callContinuously: false) {
                    (added, deleted, newAnchor, error) -> Void in
                    anchorQueryCallback(added: added, deleted: deleted, newAnchor: newAnchor, error: error)
                    if let anchor = newAnchor {
                        self.setAnchorForType(anchor, forType: type)

                        // Refresh the latest acquisition timestamp for this measure.
                        let ts  = self.getAnchorTSForType(type)
                        let nts = added.reduce(ts, combine: { (acc,x) in return max(acc, x.startDate.timeIntervalSinceReferenceDate) })
                        if nts > ts {
                            self.setAnchorTSForType(nts, forType: type)

                            // Push acquisition times into profile, and subsequently Stormpath.
                            self.pushAcquisition(type)
                        }
                    }
                    completion()
                }
            }
            self.healthKitStore.executeQuery(obsQuery)
        }
        healthKitStore.enableBackgroundDeliveryForType(type, frequency: HKUpdateFrequency.Immediate, withCompletion: onBackgroundStarted)
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

    // Note: the UserManager batches timestamps based on cancelling a deferred synchronization timer.
    private func pushAcquisition(type: HKSampleType) {
        syncAnchorTS(true)
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

    // Setter and getter for anchor timestamps (i.e., the date associated with the anchor as the acquisition time).
    public func getAnchorTSForType(type: HKSampleType) -> NSTimeInterval {
        return Defaults[HMAnchorTSKey]?[type.identifier] as? NSTimeInterval ?? refDate.timeIntervalSinceReferenceDate
    }

    public func setAnchorTSForType(ts: NSTimeInterval, forType type: HKSampleType) {
        if !Defaults.hasKey(HMAnchorTSKey) {
            Defaults[HMAnchorTSKey] = [type.identifier: ts]
        } else {
            Defaults[HMAnchorTSKey]![type.identifier] = ts
        }
        Defaults.synchronize()
    }

    // Pushes the anchor timestamps (i.e., last acquisition times) to the user's profile.
    public func syncAnchorTS(sync: Bool = false) {
        if let ts = Defaults[HMAnchorTSKey] {
            let mappedTS = Dictionary(pairs: ts.flatMap { (kv) -> (String, AnyObject)? in
                if let sk = UserManager.sharedManager.shortId(kv.0) { return (sk, kv.1) }
                return nil
            })
            UserManager.sharedManager.setAcquisitionTimes(mappedTS, sync: sync)
        }
    }

    public func resetAnchors() {
        HMConstants.sharedInstance.healthKitTypesToObserve.forEach { type in
            self.setAnchorForType(noAnchor, forType: type)
            self.setAnchorTSForType(refDate.timeIntervalSinceReferenceDate, forType: type)
        }
    }

    // Get both the anchor object and its timestamp.
    public func getAnchorAndTSForType(type: HKSampleType) -> (HKQueryAnchor, NSTimeInterval) {
        if let anchorDict = Defaults[HMAnchorKey], tsDict = Defaults[HMAnchorTSKey] {
            if let encodedAnchor = anchorDict[type.identifier] as? NSData,
                ts = tsDict[type.identifier] as? NSTimeInterval
            {
                return (NSKeyedUnarchiver.unarchiveObjectWithData(encodedAnchor) as! HKQueryAnchor, ts)
            }
        }
        return (noAnchor, refDate.timeIntervalSinceReferenceDate)
    }

    // Return acquisition times for all measures.
    public func getAnchorTS() -> [String: AnyObject]? { return Defaults[HMAnchorTSKey] }


    // MARK: - Writing into HealthKit

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

    // MARK: - Upload helpers.
    public func jsonifySample(sample : HKSample) throws -> [String : AnyObject] {
        return try HealthManager.serializer.dictForSample(sample)
    }

    func uploadSample(jsonObj: [String: AnyObject]) -> () {
        Service.string(MCRouter.UploadHKMeasures(jsonObj), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.info("Upload: \(result.value)")
        }
    }

    public func uploadSampleBlock(jsonObjBlock: [[String:AnyObject]]) -> () {
        Service.string(MCRouter.UploadHKMeasures(["block":jsonObjBlock]), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.info("Upload: \(result.value)")
        }
    }

    func uploadSamplesForType(type: HKSampleType, added: [HKSample]) {
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
                            self.uploadSampleBlock(jsonObjs)
                        } catch {
                            log.error(error)
                        }
                    }
                }
            } else {
                let jsons = try added.map(self.jsonifySample)
                jsons.forEach(self.uploadSample)
            }
        } catch {
            log.error(error)
        }
    }

    private func uploadInitialAnchorForType(type: HKSampleType, completion: (Bool, (Bool, NSDate)?) -> Void) {
        let tname = type.displayText ?? type.identifier
        if let wend = UserManager.sharedManager.getHistoricalRangeStartForType(type.identifier) {
            let dwend = NSDate(timeIntervalSinceReferenceDate: wend)
            let dwstart = UserManager.sharedManager.decrAnchorDate(dwend)
            let pred = HKQuery.predicateForSamplesWithStartDate(dwstart, endDate: dwend, options: .None)
            fetchSamplesOfType(type, predicate: pred, limit: noLimit) { (samples, error) in
                guard error == nil else {
                    log.error("Could not get initial anchor samples for: \(tname) \(dwstart) \(dwend)")
                    return
                }

                let hksamples = samples as! [HKSample]
                self.uploadSamplesForType(type, added: hksamples)
                UserManager.sharedManager.decrHistoricalRangeStartForType(type.identifier)

                log.info("Uploaded \(tname) to \(dwstart)")
                if let min = UserManager.sharedManager.getHistoricalRangeMinForType(type.identifier) {
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

    private func getOldestSampleForType(type: HKSampleType, completion: HKSampleType -> ()) {
        let tname = type.displayText ?? type.identifier
        fetchSamplesOfType(type, predicate: nil, limit: 1) { (samples, error) in
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

    private func backgroundUploadForType(type: HKSampleType, completion: (Bool, (Bool, NSDate)?) -> Void) {
        let tname = type.displayText ?? type.identifier
        if let _ = UserManager.sharedManager.getHistoricalRangeForType(type.identifier),
               _ = UserManager.sharedManager.getHistoricalRangeMinForType(type.identifier)
        {
            self.uploadInitialAnchorForType(type, completion: completion)
        } else {
            log.warning("No historical range found for \(tname)")
            completion(true, nil)
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

