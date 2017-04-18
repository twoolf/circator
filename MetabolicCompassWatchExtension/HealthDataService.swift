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
let energyUnit = HKUnit.kilocalorie()
let energyFormatterUnit: EnergyFormatter.Unit = {
    return HKUnit.energyFormatterUnit(from: energyUnit)
} ()

let distanceUnit: HKUnit = {
    let locale = NSLocale.current
    let isMetric: Bool = true
//    let isMetric: Bool = (locale.objectForKey(NSLocaleUsesMetricSystem)?.boolValue)!
//    let isMetric: Bool = (locale.objectForKey(NSLocale.Key.usesMetricSystem)?.boolValue)!
//    let isMetric: Bool = (locale(objectForKey:NSLocale.Key).usesMetricSystem)?.boolValue)!

    if isMetric {
        return HKUnit.meter()
    } else {
        return HKUnit.mile()
    }
} ()
let distanceFormatterUnit: LengthFormatter.Unit = {
    return HKUnit.lengthFormatterUnit(from: distanceUnit)
} ()


let hrUnit = HKUnit(from: "count/min")

let energyType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
let hrType:HKQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
let cyclingDistanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling)!
let runningDistanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!

class HealthDataService {
    
    internal let healthKitStore:HKHealthStore = HKHealthStore()
    
    init() {}
    
    /// This function asks HealthKit for authorization to read and write to the health store
    func authorizeHealthKitAccess(completion: @escaping ((_ success:Bool, _ error:NSError?) -> Void)) {
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
        
        healthKitStore.requestAuthorization(toShare: typesToShare, read: typesToSave) { success, error in
            completion(success, error as NSError?)
        }
    }
    
    /// This function gets HKWorkouts from the Health Store that were created by this app
    func readWorkouts(completion: @escaping (_ success: Bool, _ workouts:[HKWorkout], _ error: NSError?) -> Void) {
        
        // Predicate indicating "this app"
        let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
        
        // Get workouts that took some amount of time
        let workoutsPredicate = HKQuery.predicateForWorkouts(with: .greaterThan, duration: 0)
        
        // AND the two predicates together
        let predicate = NSCompoundPredicate(type: .and, subpredicates: [sourcePredicate, workoutsPredicate])
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        
        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            
            guard let samples = results as? [HKWorkout] else {
                completion(false, [HKWorkout](), error as NSError?)
                return
            }
            
            completion(error == nil, samples, error as NSError?)
        }
        healthKitStore.execute(sampleQuery)
    }
    
    /// This function gets samples of a certain type from the workout passed in
    func samplesForWorkout(workout: HKWorkout,
                           intervalStart: Date,
                           intervalEnd: Date,
                           type: HKQuantityType,
                           completion: @escaping (_ samples: [HKSample], _ error: NSError?) -> Void) {
        
        // Start with the workout
        let workoutPredicate = HKQuery.predicateForObjects(from: workout)
        
        // Just get samples within the timeframe of a certain interval
        let datePredicate = HKQuery.predicateForSamples(withStart: intervalStart as Date, end: intervalEnd as Date, options: [])
        
        // AND the two predicates
        let predicate = NSCompoundPredicate(type: .and, subpredicates: [workoutPredicate, datePredicate])
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) { (query, samples, error) -> Void in
            completion(samples!, error as NSError?)
        }
        healthKitStore.execute(query)
    }
    
    /// This function gets statistics of a certain type from the workout passed in
    func statisticsForWorkout(workout: HKWorkout,
                              intervalStart: Date,
                              intervalEnd: Date,
                              type: HKQuantityType,
                              options: HKStatisticsOptions,
                              completion: @escaping (_ statistics: HKStatistics, _ error: NSError?) -> Void) {
        
        // Start with the workout
        let workoutPredicate = HKQuery.predicateForObjects(from: workout)
        
        // Just get stats within the timeframe of a certain interval
        let datePredicate = HKQuery.predicateForSamples(withStart: intervalStart as Date, end: intervalEnd as Date, options: [])
        
        // AND the two predicates
        let predicate = NSCompoundPredicate(type: .and, subpredicates: [workoutPredicate, datePredicate])
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { (query, stats, error) -> Void in
            completion(stats!, error as NSError?)
        }
        healthKitStore.execute(query)
    }
}
