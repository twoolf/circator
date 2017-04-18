//
//  HealthManager_Watch.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

// This extension adds support for saving an HKWorkoutSession from Watch
class HealthManager: NSObject {
    
    lazy var healthKitStore: HKHealthStore = HKHealthStore()
    /// This function saves a workout from a WorkoutSessionService and its HKWorkoutSession
    func saveWorkout(workoutService: WorkoutSessionService,
                     completion: @escaping (Bool, NSError?) -> Void) {
        guard let start = workoutService.startDate, let end = workoutService.endDate else {return}
        
        // Create some metadata to save the interval timer details.
        var metadata = workoutService.configuration.dictionaryRepresentation()
        metadata[HKMetadataKeyIndoorWorkout] = workoutService.configuration.exerciseType.location as AnyObject?
        
        let workout = HKWorkout(activityType: workoutService.configuration.exerciseType.workoutType,
                                start: start as Date,
                                end: end as Date,
                                duration: end.timeIntervalSince(start as Date),
                                totalEnergyBurned: workoutService.energyBurned,
                                totalDistance: workoutService.distance,
                                device: HKDevice.local(),
                                metadata: metadata)
        
        // Collect the sampled data
        var samples: [HKQuantitySample] = [HKQuantitySample]()
        samples += workoutService.hrData
        samples += workoutService.distanceData
        samples += workoutService.energyData
        
        // Save the workout
        healthKitStore.save(workout) { success, error in
            if (!success || samples.count == 0) {
                completion(success, error as NSError?)
                return
            }
            
            // If there are samples to save, add them to the workout
            self.healthKitStore.add(samples, to: workout, completion: { success, error  in
                completion(success, error as NSError?)
            })
        }
    }
}
