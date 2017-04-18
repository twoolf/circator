//
//  WorkoutSessionService_Queries.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

extension WorkoutSessionService {
    
    internal func heartRateQuery(withStartDate start: Date) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamples(withStart: start as Date, end: nil, options: [])
        
        let query:HKAnchoredObjectQuery = HKAnchoredObjectQuery(type: hrType,
                                                                predicate: predicate,
                                                                anchor: hrAnchorValue,
                                                                limit: Int(HKObjectQueryNoLimit)) {
                                                                    (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                                                                    
                                                                    self.hrAnchorValue = newAnchor
                                                                    self.newHRSamples(samples: sampleObjects)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.hrAnchorValue = newAnchor
            self.newHRSamples(samples: samples)
        }
        
        return query
    }
    
    private func newHRSamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample], samples.count > 0 else {
            return
        }
        
        DispatchQueue.main.async() {
            self.hrData += samples
            if let hr = samples.last?.quantity {
                self.heartRate = hr
                self.delegate?.workoutSessionService(service: self.delegate as! WorkoutSessionService, didUpdateHeartrate: hr.doubleValue(for: hrUnit))
//                self.delegate?.workoutSessionService(self, didUpdateHeartrate: hr.doubleValue(for: hrUnit))
            }
        }
    }
    
    internal func distanceQuery(withStartDate start: Date) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamples(withStart: start as Date, end: nil, options: [])
        
        let query = HKAnchoredObjectQuery(type: distanceType,
                                          predicate: predicate,
                                          anchor: distanceAnchorValue,
                                          limit: Int(HKObjectQueryNoLimit)) {
                                            (query, samples, deleteObjects, anchor, error) -> Void in
                                            
                                            self.distanceAnchorValue = anchor
                                            self.newDistanceSamples(samples: samples)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.distanceAnchorValue = newAnchor
            self.newDistanceSamples(samples: samples)
        }
        return query
    }
    
    internal func newDistanceSamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample], samples.count > 0 else {
            return
        }
        
        DispatchQueue.main.async() {
            self.distance = self.distance.addSamples(samples: samples, unit: distanceUnit)
            self.distanceData += samples
            self.delegate?.workoutSessionService(service: self.delegate as! WorkoutSessionService, didUpdateDistance: self.distance.doubleValue(for: distanceUnit))
//            self.delegate?.workoutSessionService(self, didUpdateDistance: self.distance.doubleValue(for: distanceUnit))
        }
    }
    
    internal func energyQuery(withStartDate start: Date) -> HKQuery {
        // Query all samples from the beginning of the workout session
        let predicate = HKQuery.predicateForSamples(withStart: start as Date, end: nil, options: [])
        
        let query = HKAnchoredObjectQuery(type: energyType,
                                          predicate: predicate,
                                          anchor: energyAnchorValue,
                                          limit: 0) {
                                            (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
                                            
                                            self.energyAnchorValue = newAnchor
                                            self.newEnergySamples(samples: sampleObjects)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.energyAnchorValue = newAnchor
            self.newEnergySamples(samples: samples)
        }
        
        return query
    }
    
    internal func newEnergySamples(samples: [HKSample]?) {
        // Abort if the data isn't right
        guard let samples = samples as? [HKQuantitySample], samples.count > 0 else {
            return
        }
        
        DispatchQueue.main.async() {
            self.energyBurned = self.energyBurned.addSamples(samples: samples, unit: energyUnit)
            self.energyData += samples
            self.delegate?.workoutSessionService(service: self.delegate as! WorkoutSessionService, didUpdateEnergyBurned: self.energyBurned.doubleValue(for: energyUnit))
//            self.delegate?.workoutSessionService(service: self, didUpdateEnergyBurned: self.energyBurned.doubleValue(for: energyUnit))
            
//            self.delegate?.workoutSession(self, didUpdateEnergyBurned: self.energyBurned.doubleValue(for: energyUnit))
        }
    }
}
