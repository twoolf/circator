//
//  FastingDataModel.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCCircadianQueries

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
    
    public var collectError: NSError?
    
    override public init() {
        super.init()
        updateData()
    }
    
    public func updateData() {
        var someError: [NSError?] = []
        let group = dispatch_group_create()
        
        dispatch_group_enter(group)
        MCHealthManager.sharedManager.fetchWeeklyFastState { (cFast, cNonFast, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.cumulativeWeeklyFasting = cFast
            self.cumulativeWeeklyNonFast = cNonFast
            MetricsStore.sharedInstance.cumulativeWeeklyFasting = String(format: "%.1f h", (self.cumulativeWeeklyFasting / 3600.0))
            MetricsStore.sharedInstance.cumulativeWeeklyNonFast = String(format: "%.1f h", (self.cumulativeWeeklyNonFast / 3600.0))
            
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCHealthManager.sharedManager.fetchWeeklyFastingVariability { (variability, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.weeklyFastingVariability = variability
            MetricsStore.sharedInstance.weeklyFastingVariability = String(format: "%.1f h", (self.weeklyFastingVariability / 3600.0))
            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCHealthManager.sharedManager.fetchWeeklyFastType { (fSleep, fAwake, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.fastSleep = fSleep
            self.fastAwake = fAwake
            MetricsStore.sharedInstance.fastSleep = String(format: "%.1f h", (self.fastSleep / 3600.0))
            MetricsStore.sharedInstance.fastAwake = String(format: "%.1f h", (self.fastSleep / 3600.0))

            dispatch_group_leave(group)
        }
        
        dispatch_group_enter(group)
        MCHealthManager.sharedManager.fetchWeeklyEatAndExercise { (tEat, tExercise, error) in
            guard error == nil else {
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.fastEat = tEat
            self.fastExercise = tExercise
            MetricsStore.sharedInstance.fastEat = String(format: "%.1f h", (self.fastEat / 3600.0))
            MetricsStore.sharedInstance.fastExercise = String(format: "%.1f h", (self.fastExercise / 3600.0))

            dispatch_group_leave(group)
        }
        
    }
}

