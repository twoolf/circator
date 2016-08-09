//
//  FastingDataModel.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCcircadianQueries

public enum SamplesCollectedIndex {
    case HKType(HKSampleType)
    case Other
}

public class FastingDataModel : NSObject {
    public var samplesCollected: [HKSampleType: Int] = [:]
    
    public var fastSleep: Double = 0.0
    public var fastAwake: Double = 0.0
    
    public var fastEat: Double = 0.0
    public var fastExercise: Double = 0.0
    
    public var cumulativeWeeklyFasting: Double = 0.0
    public var cumulativeWeeklyNonFast: Double = 0.0
    public var weeklyFastingVariability: Double = 0.0
    
    public var maxEntries: Int = 10
    public var collectedAsOtherThreshold: Double = 0.01
    
    override public init() {
        super.init()
    }
    
    public func updateData(completion: NSError? -> Void) {
        var someError: [NSError?] = []
        let group = dispatch_group_create()
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyFastState { (cFast, cNonFast, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.cumulativeWeeklyFasting = cFast
            self.cumulativeWeeklyNonFast = cNonFast
            MetricsStore.sharedInstance.cumulativeWeeklyFasting = String(self.cumulativeWeeklyFasting)
            MetricsStore.sharedInstance.cumulativeWeeklyNonFast = String(self.cumulativeWeeklyNonFast)
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyFastingVariability { (variability, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.weeklyFastingVariability = variability
            MetricsStore.sharedInstance.weeklyFastingVariability = String(self.weeklyFastingVariability)
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyFastType { (fSleep, fAwake, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.fastSleep = fSleep
            self.fastAwake = fAwake
            MetricsStore.sharedInstance.fastSleep = String(self.fastSleep)
            MetricsStore.sharedInstance.fastAwake = String(self.fastAwake)
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCcircadianQueries.sharedManager.fetchWeeklyEatAndExercise { (tEat, tExercise, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.fastEat = tEat
            self.fastExercise = tExercise
            MetricsStore.sharedInstance.fastEat = String(self.fastEat)
            MetricsStore.sharedInstance.fastExercise = String(self.fastExercise)
            dispatch_group_leave(group)
        }
        
    }
}









