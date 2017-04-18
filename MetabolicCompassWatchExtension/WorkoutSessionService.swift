//
//  WorkoutSessionService.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

protocol WorkoutSessionServiceDelegate: class {
    /// This method is called when an HKWorkoutSession is correctly started
    func workoutSessionService(service: WorkoutSessionService, didStartWorkoutAtDate startDate: Date)
    
    /// This method is called when an HKWorkoutSession is correctly stopped
    func workoutSessionService(service: WorkoutSessionService, didStopWorkoutAtDate endDate: Date)
    
    /// This method is called when a workout is successfully saved
    func workoutSessionServiceDidSave(service: WorkoutSessionService)
    
    /// This method is called when an anchored query receives new heart rate data
    func workoutSessionService(service: WorkoutSessionService, didUpdateHeartrate heartRate:Double)
    
    /// This method is called when an anchored query receives new distance data
    func workoutSessionService(service: WorkoutSessionService, didUpdateDistance distance:Double)
    
    /// This method is called when an anchored query receives new energy data
    func workoutSessionService(service: WorkoutSessionService, didUpdateEnergyBurned energy:Double)
}


class WorkoutSessionService: NSObject {
    let healthService = HealthManager()
    let session: HKWorkoutSession
    let configuration: WorkoutConfiguration
    
    var startDate: Date?
    var endDate: Date?
    
    // ****** Units and Types
    var distanceType: HKQuantityType {
        if self.configuration.exerciseType.workoutType == .cycling {
            return cyclingDistanceType
        } else {
            return runningDistanceType
        }
    }
    
    // ****** Stored Samples and Queries
    var energyData: [HKQuantitySample] = [HKQuantitySample]()
    var hrData: [HKQuantitySample] = [HKQuantitySample]()
    var distanceData: [HKQuantitySample] = [HKQuantitySample]()
    
    // ****** Query Management
    internal var queries: [HKQuery] = [HKQuery]()
    internal var distanceAnchorValue:HKQueryAnchor?
    internal var hrAnchorValue:HKQueryAnchor?
    internal var energyAnchorValue:HKQueryAnchor?
    
    weak var delegate:WorkoutSessionServiceDelegate?
    
    // ****** Current Workout Values
    var energyBurned: HKQuantity
    var distance: HKQuantity
    var heartRate: HKQuantity
    
    init(configuration: WorkoutConfiguration) {
        self.configuration = configuration
        session = HKWorkoutSession(activityType: configuration.exerciseType.workoutType,
                                   locationType: configuration.exerciseType.location)
        
        // Initialize Current Workout Values
        energyBurned = HKQuantity(unit: energyUnit, doubleValue: 0.0)
        distance = HKQuantity(unit: distanceUnit, doubleValue: 0.0)
        heartRate = HKQuantity(unit: hrUnit, doubleValue: 0.0)
        
        super.init()
        
        session.delegate = self
    }
    
    func startSession() {
        healthService.healthKitStore.start(session)
    }
    
    func stopSession() {
        healthService.healthKitStore.end(session)
    }
    
    func saveSession() {
        healthService.saveWorkout(workoutService: self) { success, error in
            if success {
                self.delegate?.workoutSessionServiceDidSave(service: self)
            }
        }
    }
}

extension WorkoutSessionService: HKWorkoutSessionDelegate {
    
    open func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        
        DispatchQueue.main.async() { () -> Void in
            switch toState {
            case .running:
                self.sessionStarted(date: date)
            case .ended:
                self.sessionEnded(date: date)
            default:
                print("Something weird happened. Not a valid state")
            }
        }
    }
    
    open func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        sessionEnded(date: Date())
    }
    
    // MARK: Internal Session Control
    open func sessionStarted(date: Date) {
        
        // Create and Start Queries
        queries.append(distanceQuery(withStartDate: date as Date))
        queries.append(heartRateQuery(withStartDate: date as Date))
        queries.append(energyQuery(withStartDate: date as Date))
        
        for query in queries {
            healthService.healthKitStore.execute(query)
        }
        
        startDate = date
        
        self.delegate?.workoutSessionService(service: self.delegate as! WorkoutSessionService, didStartWorkoutAtDate: startDate!)
//        self.delegate?.workoutSession(service: WorkoutSessionService.init(configuration: configuration), didStartWorkoutAtDate: startDate!)
    }
    
    open func sessionEnded(date: Date) {
        
        // Stop Any Queries
        for query in queries {
            healthService.healthKitStore.stop(query)
        }
        queries.removeAll()        
        endDate = date
        
        // Let the delegate know
        self.delegate?.workoutSessionService(service: self.delegate as! WorkoutSessionService, didStopWorkoutAtDate: endDate!)
    }
}
