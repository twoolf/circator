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

public typealias HealthManagerAuthorizationBlock = (success: Bool, error: NSError?) -> Void
public typealias HealthManagerFetchSampleBlock = (samples: [HKSample], error: NSError?) -> Void
public typealias HealthManagerStatisticsBlock = (statistics: [HKStatistics], error: NSError?) -> Void
public typealias HealthManagerCorrelationStatisticsBlock = ([HKStatistics], [HKStatistics], NSError?) -> Void

public let HealthManagerErrorDomain = "HealthManagerErrorDomain"
public let HealthManagerSampleTypeIdentifierSleepDuration = "HealthManagerSampleTypeIdentifierSleepDuration"

public let HealthManagerDidUpdateRecentSamplesNotification = "HealthManagerDidUpdateRecentSamplesNotification"

private let HealthManagerAnchorKey = "HKClientAnchorKey"

public class HealthManager: NSObject, WCSessionDelegate {

    public static let sharedManager = HealthManager()

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

    public var mostRecentSamples = [HKSampleType: [Result]]() {
        didSet {
            self.updateWatchContext()
        }
    }

    public var aggregateRefreshDate : NSDate = NSDate()

    public var mostRecentAggregates = [HKSampleType: [Result]]() {
        didSet {
            aggregateRefreshDate = NSDate()
            self.updateWatchContext()
        }
    }

    // Not guaranteed to be on main thread
    public func authorizeHealthKit(completion: HealthManagerAuthorizationBlock)
    {
        let healthKitTypesToRead : Set<HKObjectType>? = [
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
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
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
            HKObjectType.workoutType()
        ]

        let healthKitTypesToWrite : Set<HKSampleType>? = [
            HKQuantityType.workoutType()
        ]

        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: HealthManagerErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this Device"])
            completion(success: false, error:error)
            return
        }

        healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead)
            { (success, error) -> Void in
                completion(success: success, error: error)
        }

    }

    public func fetchMostRecentSample(sampleType: HKSampleType, completion: HealthManagerFetchSampleBlock)
    {
        let mostRecentPredicate: NSPredicate
        let limit: Int

        let aDay = NSDateComponents()
        aDay.day = -1
        let aDayAgo = NSCalendar.currentCalendar().dateByAddingComponents(aDay, toDate: NSDate(), options: NSCalendarOptions())!
        let now = NSDate()
        if sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis {
            mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(aDayAgo, endDate: now, options: .None)
            limit = Int(HKObjectQueryNoLimit)
        } else {
            mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(NSDate.distantPast(), endDate: now, options: .None)
            limit = 1
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                guard error == nil else {
                    completion(samples: [], error: error)
                    return
                }
                completion(samples: results!, error: nil)
        }

        self.healthKitStore.executeQuery(sampleQuery)
    }

    public func fetchMostRecentSamples(ofTypes types: [HKSampleType] = PreviewManager.previewSampleTypes, completion: (samples: [HKSampleType: [Result]], error: NSError?) -> Void) {
        let group = dispatch_group_create()
        var samples = [HKSampleType: [Result]]()
        types.forEach { (type) -> () in
            dispatch_group_enter(group)
            let predicate = HKSampleQuery.predicateForSamplesWithStartDate(NSDate().dateByAddingTimeInterval(-3600 * 96), endDate: nil, options: HKQueryOptions())
            fetchStatisticsOfType(type, predicate: predicate) { (statistics, error) -> Void in
                dispatch_group_leave(group)
                guard error == nil else {
                    return
                }
                guard statistics.isEmpty == false else {
                    return
                }
                samples[type] = statistics
            }
        }
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            // TODO: partial error handling
            self.mostRecentSamples = samples
            completion(samples: samples, error: nil)
        }
    }

    // Completion handler is on background queue
    public func fetchSamplesOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int = Int(HKObjectQueryNoLimit), completion: HealthManagerFetchSampleBlock) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) -> Void in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            completion(samples: samples!, error: nil)
        }
        healthKitStore.executeQuery(query)
    }

    // Completion handler is on background queue
    public func fetchStatisticsOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, completion: HealthManagerStatisticsBlock) {
        if sampleType is HKQuantityType {
            let calendar = NSCalendar.currentCalendar()

            let interval = NSDateComponents()
            interval.day = 1

            // Set the anchor date to midnight today. Should be able to change according to user settings
            let anchorComponents = calendar.components([.Year, .Month, .Day, .Hour], fromDate: NSDate())
            anchorComponents.hour = 0
            let anchorDate = calendar.dateFromComponents(anchorComponents)!

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
                    print("*** An error occurred while calculating the statistics: \(error!.localizedDescription) ***")
                    completion(statistics: [], error: error)
                    return
                }

                completion(statistics: results!.statistics(), error: nil)
            }
            healthKitStore.executeQuery(query)
        } else {
            completion(statistics: [], error: NSError(domain: HealthManagerErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
        }
    }

    // Query food diary events stored as prep and recovery workouts in HealthKit
    public func fetchPreparationAndRecoveryWorkout(completion: (([AnyObject]!, NSError!) -> Void)!) {
        let predicate =  HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                if let queryError = error {
                    print( "There was an error while reading the samples: \(queryError.localizedDescription)")
                }
                completion(results,error)
        }
        healthKitStore.executeQuery(sampleQuery)
    }

    // TODO: pull this from Granola
    // TODO: make this a dictionary with a list value to support multiple fields per sampleType,
    // e.g., blood_pressure needs both systolic and diastolic
    public static let attributeNamesBySampleType : [HKSampleType:(String,String,String?)] =
        PreviewManager.previewChoices.flatten().reduce([:]) { (var dict, sampleType) in
            switch sampleType.identifier {
            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!.identifier:
                dict[sampleType] = ("body_weight", "body_weight", nil)

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!.identifier:
                dict[sampleType] = ("body_mass_index", "body_mass_index", nil)

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!.identifier:
                dict[sampleType] = ("heart_rate", "heart_rate", nil)

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!.identifier:
                dict[sampleType] = ("unit_value", "diastolic_blood_pressure", "HKQuantityTypeIdentifierBloodPressureDiastolic")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!.identifier:
                dict[sampleType] = ("unit_value", "systolic_blood_pressure", "HKQuantityTypeIdentifierBloodPressureSystolic")

            case HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!.identifier:
                dict[sampleType] = ("sleep_duration", "sleep_duration", nil)

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!.identifier:
                dict[sampleType] = ("unit_value", "distance_walkrun", "HKQuantityTypeIdentifierDistanceWalkingRunning")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!.identifier:
                dict[sampleType] = ("unit_value", "energy_consumed", "HKQuantityTypeIdentifierDietaryEnergyConsumed")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!.identifier:
                dict[sampleType] = ("step_count", "step_count", nil)

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!.identifier:
                dict[sampleType] = ("unit_value", "carbs", "HKQuantityTypeIdentifierDietaryCarbohydrates")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!.identifier:
                dict[sampleType] = ("unit_value", "fat_total", "HKQuantityTypeIdentifierDietaryFatTotal")
                
            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!.identifier:
                dict[sampleType] = ("unit_value", "fat_polyunsaturated", "HKQuantityTypeIdentifierDietaryFatPolyunsaturated")
                
            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!.identifier:
                dict[sampleType] = ("unit_value", "fat_monounsaturated", "HKQuantityTypeIdentifierDietaryFatMonounsaturated")
                
            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!.identifier:
                dict[sampleType] = ("unit_value", "fat_saturated", "HKQuantityTypeIdentifierDietaryFatSaturated")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!.identifier:
                dict[sampleType] = ("unit_value", "protein", "HKQuantityTypeIdentifierDietaryProtein")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!.identifier:
                dict[sampleType] = ("unit_value", "sugar", "HKQuantityTypeIdentifierDietarySugar")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!.identifier:
                dict[sampleType] = ("unit_value", "cholesterol", "HKQuantityTypeIdentifierDietaryCholesterol")

            case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!.identifier:
                dict[sampleType] = ("unit_value", "sodium", "HKQuantityTypeIdentifierDietarySodium")

            case HKObjectType.workoutType().identifier:
                print("WORKOUT: " + sampleType.identifier)
                //dict[sampleType] = ("effective_time_frame", "workout", nil)

            default:
                print("Mismatched sample types on: " + sampleType.identifier)
            }
            return dict
        }

    public static let attributesByName : [String: (HKSampleType, String, String?)] =
        attributeNamesBySampleType
            .map { $0 }
            .reduce([:]) { (var dict, kv) in dict[kv.1.1] = (kv.0, kv.1.0, kv.1.2); return dict }
    
    // Retrieve aggregates for all previewed rows.
    public func fetchAggregates() {
        do {
            var attributes    : [String] = []
            var names         : [String] = []
            var predicates    : [String] = []
            var samplesByName : [String:HKSampleType] = [:]

            for hksType in PreviewManager.previewSampleTypes {
                if let (attr, name, predicate) = HealthManager.attributeNamesBySampleType[hksType] {
                    attributes.append(attr)
                    names.append(name)
                    predicates.append(predicate ?? "")
                    samplesByName[name] = hksType
                }
            }

            var params : [String:AnyObject] = ["attributes":attributes, "names":names, "predicates":predicates]
            
            // Add population filter parameters.
            let popQueryIndex = QueryManager.sharedManager.getSelectedQuery()
            let popQueries = QueryManager.sharedManager.getQueries()
            if popQueryIndex >= 0 && popQueryIndex < popQueries.count  {
                switch popQueries[popQueryIndex].1 {
                case Query.UserDefinedQuery(_):
                    print("NYI: UserDefinedQueries")

                case Query.ConjunctiveQuery(let aggpreds):
                    let pfdict : [[String: AnyObject]] = aggpreds.map { (aggr, attr, cmp, val) in
                            var dict : [String: AnyObject] = [:]
                            if let attrspec = HealthManager.attributesByName[attr] {
                                dict = serializeREST((aggr, attrspec.1, cmp, val))
                                dict["name"] = attr
                                if let attrAsPred = attrspec.2 {
                                    dict["predicate"] = attrAsPred
                                }
                            } else {
                                print(HealthManager.attributesByName)
                                print("Internal error: could not find attribute '\(attr)' while building a conjunctive query")
                            }
                            return dict
                        }.filter { dict in !dict.isEmpty }

                    params["popfilter"] = pfdict
                }
            }

            let json = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted)
            let serializedAttrs = try NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions()) as! [String : AnyObject]

            Alamofire.request(MCRouter.AggMeasures(serializedAttrs))
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .responseJSON {_, response, result in
                    print("AGGPOST: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                    guard !result.isSuccess else {
                        self.refreshAggregatesFromMsg(samplesByName, payload: result.value)
                        return
                    }
            }
        } catch {
            debugPrint(error)
        }
    }

    func refreshAggregatesFromMsg(samplesByName: [String:HKSampleType], payload: AnyObject?) {
        var populationAggregates : [HKSampleType: [Result]] = [:]
        if let aggregates = payload as? [[String: AnyObject]] {
            var failed = false
            for kvdict in aggregates {
                if let sampleName = kvdict["key"] as? String,
                       sampleType = samplesByName[sampleName]
                {
                    if let sampleValue = kvdict["value"] as? Double {
                        populationAggregates[sampleType] = [DerivedQuantity(quantity: sampleValue, quantityType: sampleType)]
                    } else {
                        populationAggregates[sampleType] = [DerivedQuantity(quantity: nil, quantityType: nil)]
                    }
                } else {
                    failed = true
                    break
                }
            }
            if ( !failed ) {
                Async.main {
                    self.mostRecentAggregates = populationAggregates
                    NSNotificationCenter.defaultCenter().postNotificationName(HealthManagerDidUpdateRecentSamplesNotification, object: self)
                }
            }
        }
    }
    
    public func fetchMealAggregates() {
        print("Fetching meals")
        Alamofire.request(MCRouter.MealMeasures([:])).responseString {_, response, result in
            print("POST: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
            print(result.value)
        }
    }

    // Completion hander is on main queue
    public func correlateStatisticsOfType(type: HKSampleType, withType type2: HKSampleType, completion: HealthManagerCorrelationStatisticsBlock) {
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
            print ("statistics of type 1, \(stat1?.enumerate())")
        }
        dispatch_group_enter(group)
        fetchStatisticsOfType(type2) { (statistics, error) -> Void in
            dispatch_group_leave(group)
            guard error == nil else {
                completion([], [], error)
                return
            }
            stat2 = statistics
            print ("statistics of type 2, \(stat2?.enumerate())")
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
            print ("statistics of both types, \(stat1),and \(stat2)")
        }
    }

    // MARK: - Observers

    public func registerObservers() {
        authorizeHealthKit { (success, _) -> Void in
            guard success else {
                return
            }
            let serializer = OMHSerializer()
            let types = [
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
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
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
                HKObjectType.workoutType()
            ]
            types.forEach { (type) in
                self.startBackgroundObserverForType(type) { (added, _, _, error) -> Void in
                    guard error == nil else {
                        debugPrint(error)
                        return
                    }
                    do {
                        let jsons = try added.map { (sample) -> [String : AnyObject] in
                            let json = try serializer.jsonForSample(sample)
                            let data = json.dataUsingEncoding(NSUTF8StringEncoding)!
                            let serializedObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String : AnyObject]
                            return serializedObject
                        }
                        jsons.forEach { json -> () in
                            Alamofire.request(MCRouter.UploadHKMeasures(json)).responseString {_, response, result in
                                print("POST: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                                print(result.value)
                            }
                        }
                    } catch {
                        debugPrint(error)
                    }
                }
            }
        }

    }

    public func startBackgroundObserverForType(type: HKSampleType, maxResultsPerQuery: Int = Int(HKObjectQueryNoLimit), anchorQueryCallback: (addedObjects: [HKSample], deletedObjects: [HKDeletedObject], newAnchor: HKQueryAnchor?, error: NSError?) -> Void) -> Void {
        let onBackgroundStarted = {(success: Bool, nsError: NSError?) -> Void in
            guard success else {
                debugPrint(nsError)
                return
            }
            let obsQuery = HKObserverQuery(sampleType: type, predicate: nil) {
                query, completion, obsError in
                guard obsError == nil else {
                    debugPrint(obsError)
                    return
                }
                self.fetchSamplesOfType(type, anchor: self.getAnchorForType(type), maxResults: maxResultsPerQuery, callContinuosly: false) { (added, deleted, newAnchor, error) -> Void in
                    anchorQueryCallback(addedObjects: added, deletedObjects: deleted, newAnchor: newAnchor, error: error)
                    if let anchor = newAnchor {
                        self.setAnchor(anchor, forType: type)
                    }
                    completion()
                }
            }
            self.healthKitStore.executeQuery(obsQuery)
        }
        healthKitStore.enableBackgroundDeliveryForType(type, frequency: HKUpdateFrequency.Immediate, withCompletion: onBackgroundStarted)
    }

    func fetchSamplesOfType(type: HKSampleType, anchor: HKQueryAnchor?, maxResults: Int, callContinuosly: Bool, completion: (added: [HKSample], deleted: [HKDeletedObject], newAnchor: HKQueryAnchor?, error: NSError?) -> Void) {

        let hkAnchor = anchor ?? HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
        let onAnchorQueryResults: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, NSError?) -> Void = {
            (query:HKAnchoredObjectQuery, addedObjects: [HKSample]?, deletedObjects: [HKDeletedObject]?, newAnchor: HKQueryAnchor?, nsError: NSError?) -> Void in
            completion(added: addedObjects ?? [], deleted: deletedObjects ?? [], newAnchor: newAnchor, error: nsError)
        }
        let anchoredQuery = HKAnchoredObjectQuery(type: type, predicate: nil, anchor: hkAnchor, limit: Int(maxResults), resultsHandler: onAnchorQueryResults)
        if callContinuosly {
            anchoredQuery.updateHandler = onAnchorQueryResults
        }
        healthKitStore.executeQuery(anchoredQuery)
    }


    private func getAnchorForType(type: HKSampleType) -> HKQueryAnchor {
        if let anchorDict = NSUserDefaults.standardUserDefaults().objectForKey(HealthManagerAnchorKey) as? [String: NSData] {
            let encodedAnchor = anchorDict[type.identifier]
            guard encodedAnchor != nil else {
                return HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
            }
            return NSKeyedUnarchiver.unarchiveObjectWithData(encodedAnchor!) as! HKQueryAnchor
        } else {
            return HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
        }
    }

    private func setAnchor(anchor: HKQueryAnchor, forType type: HKSampleType) {
        let encodedAnchor: NSData = NSKeyedArchiver.archivedDataWithRootObject(anchor)
        if var anchorDict = NSUserDefaults.standardUserDefaults().objectForKey(HealthManagerAnchorKey) as? [String: NSData] {
            anchorDict[type.identifier] = encodedAnchor
            NSUserDefaults.standardUserDefaults().setValue(anchorDict, forKey: HealthManagerAnchorKey)
        } else {
            let anchorDict = [type.identifier: encodedAnchor]
            NSUserDefaults.standardUserDefaults().setValue(anchorDict, forKey: HealthManagerAnchorKey)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Writing into HealthKit

    public func savePreparationAndRecoveryWorkout(startDate:NSDate , endDate:NSDate , distance:Double, distanceUnit:HKUnit , kiloCalories:Double,
        metadata:NSDictionary, completion: ( (Bool, NSError!) -> Void)!) {
            print("Saving workout")

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
            print(error)
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
            return NSLocalizedString("Heartbeat", comment: "HealthKit data type")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Food calories", comment: "HealthKit data type")
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("Body Mass Index", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return NSLocalizedString("Walking and Running Distance", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Total Step Count", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Total Carbohydrates", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Total Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Monounsaturated Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Polyunsaturated Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Saturated Fat", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Total Protein", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Total Sugar", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Total Cholesterol", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Total Salt", comment: "HealthKit data type")
        case HKWorkoutTypeIdentifier:
            return NSLocalizedString("Workout", comment: "HealthKit data type")
        default:
            return nil
        }
    }
}

public extension HKQuantityType {
    var aggregationOptions: HKStatisticsOptions {
        switch identifier {
        case HKQuantityTypeIdentifierHeartRate:
            fallthrough
        case HKQuantityTypeIdentifierBodyMass:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierBodyMassIndex:
            return .DiscreteAverage
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return .CumulativeSum
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return .CumulativeSum
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
        case HKQuantityTypeIdentifierDietaryCaffeine:
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
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return sumQuantity()
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
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
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
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
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()
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
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
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
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()
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
        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()
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

public extension Array where Element: HKSample {
    public var sleepDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKCategorySample
            return categorySample.sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis && categorySample.value == HKCategoryValueSleepAnalysis.Asleep.rawValue
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
}
