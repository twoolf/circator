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
    func workoutSessionService(service: WorkoutSessionService, didStartWorkoutAtDate startDate: NSDate)
    
    /// This method is called when an HKWorkoutSession is correctly stopped
    func workoutSessionService(service: WorkoutSessionService, didStopWorkoutAtDate endDate: NSDate)
    
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
    private let healthService = HealthManager()
    let session: HKWorkoutSession
    let configuration: WorkoutConfiguration
    
    var startDate: NSDate?
    var endDate: NSDate?
    
    // ****** Units and Types
    var distanceType: HKQuantityType {
        if self.configuration.exerciseType.workoutType == .Cycling {
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
    private var queries: [HKQuery] = [HKQuery]()
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
        healthService.healthKitStore.startWorkoutSession(session)
    }
    
    func stopSession() {
        healthService.healthKitStore.endWorkoutSession(session)
    }
    
    func saveSession() {
        healthService.saveWorkout(self) { success, error in
            if success {
                self.delegate?.workoutSessionServiceDidSave(self)
            }
        }
    }
}

extension WorkoutSessionService: HKWorkoutSessionDelegate {
    
    func workoutSession(workoutSession: HKWorkoutSession,
                        didChangeToState toState: HKWorkoutSessionState,
                                         fromState: HKWorkoutSessionState, date: NSDate) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            switch toState {
            case .Running:
                self.sessionStarted(date)
            case .Ended:
                self.sessionEnded(date)
            default:
                print("Something weird happened. Not a valid state")
            }
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession,
                        didFailWithError error: NSError) {
        sessionEnded(NSDate())
    }
    
    // MARK: Internal Session Control
    private func sessionStarted(date: NSDate) {
        
        // Create and Start Queries
        queries.append(distanceQuery(withStartDate: date))
        queries.append(heartRateQuery(withStartDate: date))
        queries.append(energyQuery(withStartDate: date))
        
        for query in queries {
            healthService.healthKitStore.executeQuery(query)
        }
        
        startDate = date
        
        // Let the delegate know
        delegate?.workoutSessionService(self, didStartWorkoutAtDate: date)
    }
    
    private func sessionEnded(date: NSDate) {
        
        // Stop Any Queries
        for query in queries {
            healthService.healthKitStore.stopQuery(query)
        }
        queries.removeAll()
        
        endDate = date
        
        // Let the delegate know
        self.delegate?.workoutSessionService(self, didStopWorkoutAtDate: date)
    }
}
