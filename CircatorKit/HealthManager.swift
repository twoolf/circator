//
//  HealthManager.swift
//  Circator
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

public typealias HMAuthorizationBlock         = (success: Bool, error: NSError?) -> Void
public typealias HMFetchSampleBlock           = (samples: [HKSample], error: NSError?) -> Void
public typealias HMFetchManySampleBlock       = (samples: [HKSampleType: [Result]], error: NSError?) -> Void
public typealias HMStatisticsBlock            = (statistics: [HKStatistics], error: NSError?) -> Void
public typealias HMCorrelationStatisticsBlock = ([HKStatistics], [HKStatistics], NSError?) -> Void
public typealias HMAnchorQueryBlock           = (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, NSError?) -> Void
public typealias HMAnchorSamplesBlock         = (added: [HKSample], deleted: [HKDeletedObject], newAnchor: HKQueryAnchor?, error: NSError?) -> Void

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

public class HealthManager: NSObject, WCSessionDelegate {

    public static let sharedManager = HealthManager()
    public static let serializer = OMHSerializer()

    lazy var healthKitStore: HKHealthStore = HKHealthStore()

    private override init() {
        super.init()
        connectWatch()
    }

    public static let previewSampleMeals = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack"
    ]

    public static let previewSampleTimes = [
        NSDate()
    ]

    // Note: keep these in alphabetical order.
    public static let healthKitTypesToRead : Set<HKObjectType>? = [
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
        HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
        HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
        HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCopper)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCalcium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIron)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPotassium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
        HKObjectType.workoutType()
    ]

    public static let healthKitTypesToWrite : Set<HKSampleType>? = [
        HKQuantityType.workoutType()
    ]

    public static let healthKitTypesToObserve : [HKSampleType] = [
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCopper)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCalcium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIron)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPotassium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
        HKObjectType.workoutType()
    ]

    public static let healthKitShortNames : [String: String] = [
        HKCorrelationTypeIdentifierBloodPressure          : "BP",
        HKCategoryTypeIdentifierSleepAnalysis             : "Sleep",
        HKQuantityTypeIdentifierActiveEnergyBurned        : "Cal burned",
        HKQuantityTypeIdentifierBasalEnergyBurned         : "Cal burned(B)",
        HKQuantityTypeIdentifierBloodGlucose              : "Glucose",
        HKQuantityTypeIdentifierBloodPressureDiastolic    : "BP Diastolic",
        HKQuantityTypeIdentifierBloodPressureSystolic     : "BP Systolic",
        HKQuantityTypeIdentifierBodyMass                  : "Weight",
        HKQuantityTypeIdentifierBodyMassIndex             : "BMI",
        HKQuantityTypeIdentifierDietaryEnergyConsumed     : "Net Calories",
        HKQuantityTypeIdentifierDietarySugar              : "Sugar",
        HKQuantityTypeIdentifierDietaryCopper             : "Copper",
        HKQuantityTypeIdentifierDietaryCalcium            : "Calcium",
        HKQuantityTypeIdentifierDietaryCarbohydrates      : "Carbs",
        HKQuantityTypeIdentifierDietaryCholesterol        : "Cholesterol",
        HKQuantityTypeIdentifierDietaryFiber              : "Fiber",
        HKQuantityTypeIdentifierDietaryIron               : "Iron",
        HKQuantityTypeIdentifierDietaryFatMonounsaturated : "Fat(MS)",
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated : "Fat(PS)",
        HKQuantityTypeIdentifierDietaryFatSaturated       : "Fat(S)",
        HKQuantityTypeIdentifierDietaryFatTotal           : "Fat",
        HKQuantityTypeIdentifierDietaryPotassium          : "Potassium",
        HKQuantityTypeIdentifierDietaryProtein            : "Protein",
        HKQuantityTypeIdentifierDietarySodium             : "Salt",
        HKQuantityTypeIdentifierDietaryCaffeine           : "Caffeine",
        HKQuantityTypeIdentifierDietaryWater              : "Water",
        HKQuantityTypeIdentifierDistanceWalkingRunning    : "Distance",
        HKQuantityTypeIdentifierFlightsClimbed            : "Climbed",
        HKQuantityTypeIdentifierHeartRate                 : "Heart rate",
        HKQuantityTypeIdentifierHeight                    : "Height",
        HKQuantityTypeIdentifierStepCount                 : "Steps",
        HKQuantityTypeIdentifierUVExposure                : "Light",
        HKObjectType.workoutType().identifier             : "Workouts/Meals"
   ]

    public var mostRecentSamples = [HKSampleType: [Result]]() {
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

        healthKitStore.requestAuthorizationToShareTypes(HealthManager.healthKitTypesToWrite, readTypes: HealthManager.healthKitTypesToRead)
            { (success, error) -> Void in
                completion(success: success, error: error)
        }

    }

    // MARK: - HealthKit sample retrieval.

    // Fetches HealthKit samples of the given type for the last day, ordered by their collection date.
    public func fetchMostRecentSample(sampleType: HKSampleType, completion: HMFetchSampleBlock)
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

        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [dateDesc])
            { (sampleQuery, results, error ) -> Void in
                guard error == nil else {
                    completion(samples: [], error: error)
                    return
                }
                completion(samples: results!, error: nil)
        }

        self.healthKitStore.executeQuery(sampleQuery)
    }

    // Fetches HealthKit samples for multiple types, using GCD to retrieve each type asynchronously and concurrently.
    public func fetchMostRecentSamples(ofTypes types: [HKSampleType] = PreviewManager.previewSampleTypes, completion: HMFetchManySampleBlock)
    {
        let group = dispatch_group_create()
        var samples = [HKSampleType: [Result]]()

        let updateSamples : (HKSampleType, [Result], NSError?) -> Void = { (type, statistics, error) in
            dispatch_group_leave(group)
            guard error == nil else {
                log.error("Could not fetch recent samples for \(type.displayText): \(error)")
                return
            }
            guard statistics.isEmpty == false else {
                log.warning("No recent samples available for \(type.displayText)")
                return
            }
            samples[type] = statistics
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
            self.fetchPreparationAndRecoveryWorkout(type) { (statistics, error) in
                updateSamples(type, statistics, error)
            }
        }

        types.forEach { (type) -> () in
            dispatch_group_enter(group)
            if ( (type.description != "HKCategoryTypeIdentifierSleepAnalysis")
                    && (type.description != "HKCorrelationTypeIdentifierBloodPressure")
                    && (type.description != "HKWorkoutTypeIdentifier"))
            {
                onStatistic(type)
            } else if (type.description == "HKCategoryTypeIdentifierSleepAnalysis" ) {
                onCatOrCorr(type)
            } else if (type.description == "HKCorrelationTypeIdentifierBloodPressure") {
                onCatOrCorr(type)
            } else if (type.description == "HKWorkoutTypeIdentifier") {
                onWorkout(type)
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            // TODO: partial error handling
            self.mostRecentSamples = samples
            completion(samples: samples, error: nil)
        }
    }

    // Completion handler is on background queue
    public func fetchSamplesOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int = noLimit, completion: HMFetchSampleBlock) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: [dateAsc]) {
            (query, samples, error) -> Void in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            completion(samples: samples!, error: nil)
        }
        healthKitStore.executeQuery(query)
    }

    // Completion handler is on background queue
    public func fetchStatisticsOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, completion: HMStatisticsBlock) {
        if sampleType is HKQuantityType {
            let interval = NSDateComponents()
            interval.day = 1

            // Set the anchor date to midnight today. Should be able to change according to user settings
            let anchorDate = NSDate().startOf(.Day, inRegion: Region())
            let quantityType = HKObjectType.quantityTypeForIdentifier(sampleType.identifier)!

            // Create the query
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: quantityType.aggregationOptions,
                anchorDate: anchorDate,
                intervalComponents: interval)

            // Set the results handler
            query.initialResultsHandler = {
                query, results, error in

                guard error == nil else {
                    log.error("Failed to fetch \(sampleType.displayText) statistics: \(error!)")
                    completion(statistics: [], error: error)
                    return
                }

                completion(statistics: results!.statistics(), error: nil)
            }
            healthKitStore.executeQuery(query)

        } else {
            completion(statistics: [], error: NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
        }
    }

    // Completion handler is on main queue
    public func correlateStatisticsOfType(type: HKSampleType, withType type2: HKSampleType, completion: HMCorrelationStatisticsBlock) {
        var stat1: [HKStatistics]?
        var stat2: [HKStatistics]?

        let group = dispatch_group_create()
        dispatch_group_enter(group)
        fetchStatisticsOfType(type) { (statistics, error) -> Void in
            dispatch_group_leave(group)
            guard error == nil else {
                completion([], [], error)
                return
            }
            stat1 = statistics
        }
        dispatch_group_enter(group)
        fetchStatisticsOfType(type2) { (statistics, error) -> Void in
            dispatch_group_leave(group)
            guard error == nil else {
                completion([], [], error)
                return
            }
            stat2 = statistics
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            guard stat1 != nil && stat2 != nil else {
                return
            }
            stat1 = stat1!.filter { (statistics) -> Bool in
                return stat2!.hasSamplesAtStartDate(statistics.startDate)
            }
            stat2 = stat2!.filter { (statistics) -> Bool in
                return stat1!.hasSamplesAtStartDate(statistics.startDate)
            }
            guard stat1!.isEmpty == false && stat2!.isEmpty == false else {
                completion(stat1!, stat2!, nil)
                return
            }
            for i in 1..<stat1!.count {
                var j = i
                let target = stat1![i]

                while j > 0 && target.quantity!.compare(stat1![j - 1].quantity!) == .OrderedAscending {
                    swap(&stat1![j], &stat1![j - 1])
                    swap(&stat2![j], &stat2![j - 1])
                    j--
                }
                stat1![j] = target
            }
            completion(stat1!, stat2!, nil)
        }
    }

    // MARK: - Meal timing event retrieval.

    public func fetchPreparationAndRecoveryWorkoutCal(completion: (([AnyObject]!, NSError!) -> Void)!) {
        let predicate =  HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                if let queryError = error {
                    log.error("Error reading HK samples: \(queryError.localizedDescription)")
                }
                completion(results,error)
        }
        healthKitStore.executeQuery(sampleQuery)
    }

    // Query food diary events stored as prep and recovery workouts in HealthKit
    public func fetchPreparationAndRecoveryWorkout(sampleType: HKSampleType, completion: (([HKSample]!, NSError!) -> Void)!) {
        let predicate =  HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                if let queryError = error {
                    log.error("Error reading HK samples: \(queryError.localizedDescription)")
                }
                completion(results as [HKSample]!, nil)
                for (index,value) in results!.enumerate() {
                    print("\(index) \(value)")
                }
        }
        healthKitStore.executeQuery(sampleQuery)
    }

    // MARK: - Observers

    public func registerObservers() {
        authorizeHealthKit { (success, _) -> Void in
            guard success else {
                return
            }

            HealthManager.healthKitTypesToObserve.forEach { (type) in
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
                //log.verbose("Anchor for type \(tname): \(anchor) \(anchor == noAnchor)")

                var predicate : NSPredicate? = nil

                // When initializing an anchor query, apply a predicate to limit the initial results.
                // If we already have a historical range, we filter samples to the current timestamp.
                if anchor == noAnchor
                {
                    if let (_, hend) = UserManager.sharedManager.getHistoricalRangeForType(type.identifier) {
                        // We use acquisition times stored in the profile if available rather than the current time,
                        // to grab all data since the last remote upload to the server.
                        if let  lastAcqTS = UserManager.sharedManager.getAcquisitionTimes(),
                            typeTS = lastAcqTS[type.identifier] as? NSTimeInterval
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
                            // This should be used to implement profile-level delta queries with anchors, independently of whether
                            // the local session on the application has been started. Thus, we should also use the profile anchor
                            // to initialize the historical range, to prevent duplicate data from being uploaded to the server.
                            self.pushAcquisition(type)
                        }
                        log.info("\(tname) \(ts) \(nts) \(anchor == noAnchor)")
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

    public func getAnchorTS() -> [String: AnyObject]? { return Defaults[HMAnchorTSKey] }

    // Pushes the anchor timestamps (i.e., last acquisition times) to the user's profile.
    public func syncAnchorTS(sync: Bool = false) {
        if let ts = Defaults[HMAnchorTSKey] {
            UserManager.sharedManager.setAcquisitionTimes(ts, sync: sync)
        }
    }

    public func resetAnchors() {
        HealthManager.healthKitTypesToObserve.forEach { type in
            self.setAnchorForType(noAnchor, forType: type)
            self.setAnchorTSForType(refDate.timeIntervalSinceReferenceDate, forType: type)
        }
    }


    // MARK: - Writing into HealthKit

    public func savePreparationAndRecoveryWorkout(startDate:NSDate , endDate:NSDate , distance:Double, distanceUnit:HKUnit , kiloCalories:Double,
        metadata:NSDictionary, completion: ( (Bool, NSError!) -> Void)!) {
            log.debug("Saving workout \(startDate) \(endDate)")

            // 1. Create quantities for the distance and energy burned
            let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
            let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)

            // 2. Save Preparation and Recovery Workout as surrogate for Eating (Meal)
            let workout = HKWorkout(activityType: HKWorkoutActivityType.PreparationAndRecovery, startDate: startDate, endDate: endDate, duration: abs(endDate.timeIntervalSinceDate(startDate)), totalEnergyBurned: caloriesQuantity, totalDistance: distanceQuantity, metadata: metadata  as! [String:String])

            healthKitStore.saveObject(workout, withCompletion: { (success, error) -> Void in
                if( error != nil  ) {
                    // Error saving the workout
                    completion(success,error)
                }
                else {
                    // Workout saved
                    completion(success,nil)
                }
            })
    }

    // MARK: - Upload helpers.
    func jsonifySample(sample : HKSample) throws -> [String : AnyObject] {
        return try HealthManager.serializer.dictForSample(sample)
    }

    func uploadSample(jsonObj: [String: AnyObject]) -> () {
        Service.string(MCRouter.UploadHKMeasures(jsonObj), statusCode: 200..<300, tag: "UPLOAD") {
            _, response, result in
            log.info("Upload: \(result.value)")
        }
    }

    func uploadSampleBlock(jsonObjBlock: [[String:AnyObject]]) -> () {
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

                self.uploadSamplesForType(type, added: samples)
                UserManager.sharedManager.decrHistoricalRangeStartForType(type.identifier)

                log.info("Uploaded \(tname) to \(dwstart)")
                if let min = UserManager.sharedManager.getHistoricalRangeMinForType(type.identifier) {
                    let dmin = NSDate(timeIntervalSinceReferenceDate: min)
                    if dwstart > dmin {
                        completion(false, (false, dwstart))
                        Async.background(after: 0.5) {
                            self.uploadInitialAnchorForType(type, completion: completion)
                        }
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
                    "value": sampleFormatter.stringFromResults(results)
                ]
            }
            try WCSession.defaultSession().updateApplicationContext(["context": applicationContext])
        } catch {
            log.error(error)
        }
    }
}

// MARK: - Categories & Extensions

@objc public protocol Result {

}

extension HKStatistics: Result { }
extension HKSample: Result { }

public extension HKSampleType {
    public var displayText: String? {
        switch identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heartrate", comment: "HealthKit data type")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Food calories", comment: "HealthKit data type")
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierBloodGlucose:
            return NSLocalizedString("Blood Glucose", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("Body Mass Index", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierFlightsClimbed:
            return NSLocalizedString("Flights Climbed", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return NSLocalizedString("Active Energy Burned", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return NSLocalizedString("Basal Energy Burned", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return NSLocalizedString("Walking and Running Distance", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Step Count", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Carbohydrates", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return NSLocalizedString("Blood Pressure Diastolic", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return NSLocalizedString("Blood Pressure Systolic", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Monounsaturated Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Polyunsaturated Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Saturated Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Protein", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Sugar", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Cholesterol", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryWater:
            return NSLocalizedString("Water", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV Exposure", comment: "HealthKit data type")
        case HKWorkoutTypeIdentifier:
            return NSLocalizedString("Eating Window", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSLocalizedString("Caffeine", comment: "HealthKit data type")
        default:
            return nil
        }
    }
}

public extension HKQuantityType {
    var aggregationOptions: HKStatisticsOptions {
        switch identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierBodyMassIndex:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return .CumulativeSum
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return .DiscreteAverage
        case HKCategoryTypeIdentifierSleepAnalysis:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierHeartRate:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return .CumulativeSum
        case HKQuantityTypeIdentifierFlightsClimbed:
            return .CumulativeSum
        case HKQuantityTypeIdentifierStepCount:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return .CumulativeSum
        case HKCorrelationTypeIdentifierBloodPressure:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierBloodGlucose:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierDietaryProtein:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietarySugar:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietarySodium:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryWater:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return .CumulativeSum
        case HKQuantityTypeIdentifierUVExposure:
            return .DiscreteAverage
        case HKWorkoutTypeIdentifier:
            return .CumulativeSum
        default:
            return .None
        }
    }
}

public extension HKStatistics {
    var quantity: HKQuantity? {
        switch quantityType.identifier {
        case HKQuantityTypeIdentifierHeartRate:
            fallthrough
        case HKQuantityTypeIdentifierBodyMass:
            return averageQuantity()
        case HKQuantityTypeIdentifierBodyMassIndex:
            return averageQuantity()
        case HKCategoryTypeIdentifierSleepAnalysis:
            return averageQuantity()
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return sumQuantity()
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return averageQuantity()
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return sumQuantity()
        case HKQuantityTypeIdentifierStepCount:
            return sumQuantity()
        case HKQuantityTypeIdentifierFlightsClimbed:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return sumQuantity()
        case HKCorrelationTypeIdentifierBloodPressure:
            return sumQuantity()
        case HKQuantityTypeIdentifierBloodGlucose:
            return sumQuantity()
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return sumQuantity()
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryProtein:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietarySugar:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietarySodium:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryWater:
            return sumQuantity()
        case HKQuantityTypeIdentifierUVExposure:
            return sumQuantity()
        case HKWorkoutTypeIdentifier:
            return sumQuantity()
        default:
            print("Invalid quantity type \(quantityType.identifier) for HKStatistics")
            return sumQuantity()
        }
    }

    public var numeralValue: Double? {
        guard defaultUnit != nil && quantity != nil else {
            return nil
        }
        switch quantityType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            fallthrough
        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough
        case HKCategoryTypeIdentifierSleepAnalysis:
            fallthrough
        case HKQuantityTypeIdentifierBloodGlucose:
            fallthrough
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            fallthrough
        case HKQuantityTypeIdentifierStepCount:
            fallthrough
        case HKQuantityTypeIdentifierFlightsClimbed:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
        case HKCorrelationTypeIdentifierBloodPressure:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureSystolic:
           fallthrough
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietarySugar:
            fallthrough
        case HKQuantityTypeIdentifierDietarySodium:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough
        case HKQuantityTypeIdentifierDietaryWater:
            fallthrough
        case HKQuantityTypeIdentifierUVExposure:
            fallthrough
        case HKWorkoutTypeIdentifier:
            fallthrough
        case HKQuantityTypeIdentifierHeartRate:
            return quantity!.doubleValueForUnit(defaultUnit!)
        default:
            return nil
        }
    }

    public var defaultUnit: HKUnit? {
        let isMetric: Bool = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue
        switch quantityType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()
        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return HKUnit.kilocalorieUnit()
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return HKUnit.kilocalorieUnit()
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return HKUnit.mileUnit()
        case HKQuantityTypeIdentifierStepCount:
            return HKUnit.countUnit()
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()
        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return HKUnit.millimeterOfMercuryUnit()
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return HKUnit.millimeterOfMercuryUnit()
        case HKQuantityTypeIdentifierDietaryProtein:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietarySugar:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietarySodium:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierUVExposure:
            return HKUnit.countUnit()
        default:
            return nil
        }
    }
}

public extension HKSample {
    public var numeralValue: Double? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            fallthrough
        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough
        case HKCategoryTypeIdentifierSleepAnalysis:
            fallthrough
        case HKQuantityTypeIdentifierBloodGlucose:
            fallthrough
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            fallthrough
        case HKQuantityTypeIdentifierStepCount:
            fallthrough
        case HKQuantityTypeIdentifierFlightsClimbed:
            fallthrough
        case HKCorrelationTypeIdentifierBloodPressure:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietarySugar:
            fallthrough
        case HKQuantityTypeIdentifierDietarySodium:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough
        case HKQuantityTypeIdentifierDietaryWater:
            fallthrough
        case HKQuantityTypeIdentifierUVExposure:
            fallthrough
        case HKWorkoutTypeIdentifier:
            fallthrough
        case HKQuantityTypeIdentifierHeartRate:
            return (self as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)

        case HKCategoryTypeIdentifierSleepAnalysis:
            let sample = (self as! HKCategorySample)
            let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.endDate.timeIntervalSinceDate(sample.startDate))
            return secs.doubleValueForUnit(defaultUnit!)

        case HKCorrelationTypeIdentifierBloodPressure:
            return ((self as! HKCorrelation).objects.first as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)

        default:
            return nil
        }
    }

    public var allNumeralValues: [Double]? {
        return numeralValue != nil ? [numeralValue!] : nil
    }

    public var defaultUnit: HKUnit? {
        let isMetric: Bool = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue
        switch sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()
        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
        case HKCategoryTypeIdentifierSleepAnalysis:
            return HKUnit.hourUnit()
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return HKUnit.kilocalorieUnit()
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return HKUnit.kilocalorieUnit()
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return HKUnit.mileUnit()
        case HKQuantityTypeIdentifierStepCount:
            return HKUnit.countUnit()
        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()
        case HKQuantityTypeIdentifierDietaryProtein:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietarySugar:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietarySodium:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return HKUnit.gramUnit()
        case HKQuantityTypeIdentifierUVExposure:
            return HKUnit.countUnit()
        case HKWorkoutTypeIdentifier:
            return HKUnit.hourUnit()
        default:
            return nil
        }
    }
}

public extension HKCorrelation {
    public override var allNumeralValues: [Double]? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKCorrelationTypeIdentifierBloodPressure:
            return objects.map { (sample) -> Double in
                (sample as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
            }
        default:
            return nil
        }
    }
}

public extension Array where Element: HKStatistics {
    public func hasSamplesAtStartDate(startDate: NSDate) -> Bool  {
        for statistics in self {
            if startDate.compare(statistics.startDate) == .OrderedSame && statistics.quantity != nil {
                return true
            }
        }
        return false
    }
}

public func <(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedAscending
}

public func ==(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedSame
}

public extension Array where Element: HKSample {
    public var sleepDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKCategorySample
            return categorySample.sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis && categorySample.value == HKCategoryValueSleepAnalysis.Asleep.rawValue
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
    public var workoutDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKWorkout
            return categorySample.sampleType.identifier == HKWorkoutTypeIdentifier
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
//    public var workoutDuration: NSDate? {
//        return filter { (sample) -> Bool in
//            let categorySample = sample as! HKWorkout
//            let now = NSDate()
//            return categorySample.sampleType.identifier == HKWorkoutTypeIdentifier && categorySample.startDate < now
//
//        }
//    }
}
