//
//  WorkoutSessionService_Queries.swift
//  MetabolicCompass
//
//  Created by twoolf on 5/18/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

extension WorkoutSessionService {
    
    internal func heartRateQuery(withStartDate start: NSDate) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: nil, options: .None)
        
        let query:HKAnchoredObjectQuery = HKAnchoredObjectQuery(type: hrType,
                                                                predicate: predicate,
                                                                anchor: hrAnchorValue,
                                                                limit: Int(HKObjectQueryNoLimit)) {
                                                                    (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                                                                    
                                                                    self.hrAnchorValue = newAnchor
                                                                    self.newHRSamples(sampleObjects)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.hrAnchorValue = newAnchor
            self.newHRSamples(samples)
        }
        
        return query
    }
    
    private func newHRSamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample] where samples.count > 0 else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.hrData += samples
            if let hr = samples.last?.quantity {
                self.heartRate = hr
                self.delegate?.workoutSessionService(self, didUpdateHeartrate: hr.doubleValueForUnit(hrUnit))
            }
        }
    }
    
    internal func distanceQuery(withStartDate start: NSDate) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: nil, options: .None)
        
        let query = HKAnchoredObjectQuery(type: distanceType,
                                          predicate: predicate,
                                          anchor: distanceAnchorValue,
                                          limit: Int(HKObjectQueryNoLimit)) {
                                            (query, samples, deleteObjects, anchor, error) -> Void in
                                            
                                            self.distanceAnchorValue = anchor
                                            self.newDistanceSamples(samples)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.distanceAnchorValue = newAnchor
            self.newDistanceSamples(samples)
        }
        return query
    }
    
    internal func newDistanceSamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample] where samples.count > 0 else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.distance = self.distance.addSamples(samples, unit: distanceUnit)
            self.distanceData += samples
            
            self.delegate?.workoutSessionService(self, didUpdateDistance: self.distance.doubleValueForUnit(distanceUnit))
        }
    }
    
    internal func energyQuery(withStartDate start: NSDate) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: nil, options: .None)
        
        let query = HKAnchoredObjectQuery(type: energyType,
                                          predicate: predicate,
                                          anchor: energyAnchorValue,
                                          limit: 0) {
                                            (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                                            
                                            self.energyAnchorValue = newAnchor
                                            self.newEnergySamples(sampleObjects)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.energyAnchorValue = newAnchor
            self.newEnergySamples(samples)
        }
        
        return query
    }
    
    internal func newEnergySamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample] where samples.count > 0 else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.energyBurned = self.energyBurned.addSamples(samples, unit: energyUnit)
            self.energyData += samples
            
            self.delegate?.workoutSessionService(self, didUpdateEnergyBurned: self.energyBurned.doubleValueForUnit(energyUnit))
        }
    }
}
