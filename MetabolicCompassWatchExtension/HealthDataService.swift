//
//  HealthDataService.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

// ****** Units and Types
let energyUnit = HKUnit.kilocalorieUnit()
let energyFormatterUnit: NSEnergyFormatterUnit = {
    return HKUnit.energyFormatterUnitFromUnit(energyUnit)
} ()

let distanceUnit: HKUnit = {
    let locale = NSLocale.currentLocale()
    let isMetric: Bool = (locale.objectForKey(NSLocaleUsesMetricSystem)?.boolValue)!
    
    if isMetric {
        return HKUnit.meterUnit()
    } else {
        return HKUnit.mileUnit()
    }
} ()
let distanceFormatterUnit: NSLengthFormatterUnit = {
    return HKUnit.lengthFormatterUnitFromUnit(distanceUnit)
} ()


let hrUnit = HKUnit(fromString: "count/min")

let energyType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
let hrType:HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
let cyclingDistanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceCycling)!
let runningDistanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!

class HealthDataService {
    
    internal let healthKitStore:HKHealthStore = HKHealthStore()
    
    init() {}
    
    func authorizeHealthKitAccess(completion: ((success:Bool, error:NSError!) -> Void)!) {
        let typesToShare = Set(
            [HKObjectType.workoutType(),
                energyType,
                cyclingDistanceType,
                runningDistanceType,
                hrType
            ])
        let typesToSave = Set([
            energyType,
            cyclingDistanceType,
            runningDistanceType,
            hrType
            ])
        
        healthKitStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToSave) { success, error in
            completion(success: success, error: error)
        }
    }
    
    func readWorkouts(completion: (success: Bool, workouts:[HKWorkout], error: NSError!) -> Void) {

        let sourcePredicate = HKQuery.predicateForObjectsFromSource(HKSource.defaultSource())
        
        let workoutsPredicate = HKQuery.predicateForWorkoutsWithOperatorType(.GreaterThanPredicateOperatorType, duration: 0)
        
        let predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [sourcePredicate, workoutsPredicate])
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        
        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            
            guard let samples = results as? [HKWorkout] else {
                completion(success: false, workouts: [HKWorkout](), error: error)
                return
            }
            
            completion(success:error == nil, workouts:samples, error:error)
        }
        healthKitStore.executeQuery(sampleQuery)
    }
    
    func samplesForWorkout(workout: HKWorkout,
                           intervalStart: NSDate,
                           intervalEnd: NSDate,
                           type: HKQuantityType,
                           completion: (samples: [HKSample], error: NSError!) -> Void) {
        
        let workoutPredicate = HKQuery.predicateForObjectsFromWorkout(workout)
        
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(intervalStart, endDate: intervalEnd, options: .None)
        
        let predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [workoutPredicate, datePredicate])
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) { (query, samples, error) -> Void in
            completion(samples: samples!, error: error)
        }
        healthKitStore.executeQuery(query)
    }
    
    func statisticsForWorkout(workout: HKWorkout,
                              intervalStart: NSDate,
                              intervalEnd: NSDate,
                              type: HKQuantityType,
                              options: HKStatisticsOptions,
                              completion: (statistics: HKStatistics, error: NSError!) -> Void) {
        
        let workoutPredicate = HKQuery.predicateForObjectsFromWorkout(workout)
        
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(intervalStart, endDate: intervalEnd, options: .None)
        
        let predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [workoutPredicate, datePredicate])
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { (query, stats, error) -> Void in
            completion(statistics: stats!, error: error)
        }
        healthKitStore.executeQuery(query)
    }
}
