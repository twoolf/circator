//
//  HealthManager_Watch.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

class HealthManager: NSObject {
    
    lazy var healthKitStore: HKHealthStore = HKHealthStore()
    func saveWorkout(workoutService: WorkoutSessionService,
                     completion: (Bool, NSError!) -> Void) {
        guard let start = workoutService.startDate, end = workoutService.endDate else {return}
        
        var metadata = workoutService.configuration.dictionaryRepresentation()
        metadata[HKMetadataKeyIndoorWorkout] = workoutService.configuration.exerciseType.location == .Indoor
        
        let workout = HKWorkout(activityType: workoutService.configuration.exerciseType.workoutType,
                                startDate: start,
                                endDate: end,
                                duration: end.timeIntervalSinceDate(start),
                                totalEnergyBurned: workoutService.energyBurned,
                                totalDistance: workoutService.distance,
                                device: HKDevice.localDevice(),
                                metadata: metadata)
        
        var samples: [HKQuantitySample] = [HKQuantitySample]()
        samples += workoutService.hrData
        samples += workoutService.distanceData
        samples += workoutService.energyData
        
        healthKitStore.saveObject(workout) { success, error in
            if (!success || samples.count == 0) {
                completion(success, error)
                return
            }

            self.healthKitStore.addSamples(samples, toWorkout: workout, completion: { success, error  in
                completion(success, error)
            })
        }
    }
}
