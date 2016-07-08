//
//  WorkoutConfiguration.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

class WorkoutConfiguration {
    
    let exerciseType: ExerciseType
    var activeTime: NSTimeInterval
    var restTime: NSTimeInterval
    
    private let exerciseTypeKey = "com.raywenderlich.config.exerciseType"
    private let activeTimeKey = "com.raywenderlich.config.activeTime"
    private let restTimeKey = "com.raywenderlich.config.restTime"
    
    init(exerciseType: ExerciseType = .Other, activeTime: NSTimeInterval = 120, restTime: NSTimeInterval = 30) {
        self.exerciseType = exerciseType
        self.activeTime = activeTime
        self.restTime = restTime
    }
    
    init(withDictionary rawDictionary:[String : AnyObject]) {
        if let type = rawDictionary[exerciseTypeKey] as? Int {
            self.exerciseType = ExerciseType(rawValue: type)!
        } else {
            self.exerciseType = ExerciseType.Other
        }
        
        if let active = rawDictionary[activeTimeKey] as? NSTimeInterval {
            self.activeTime = active
        } else {
            self.activeTime = 120
        }
        
        if let rest = rawDictionary[restTimeKey] as? NSTimeInterval {
            self.restTime = rest
        } else {
            self.restTime = 30
        }
    }
    
    func intervalDuration() -> NSTimeInterval {
        return activeTime + restTime
    }
    
    func dictionaryRepresentation() -> [String : AnyObject] {
        return [
            exerciseTypeKey : exerciseType.rawValue,
            activeTimeKey : activeTime,
            restTimeKey : restTime,
        ]
    }
}
