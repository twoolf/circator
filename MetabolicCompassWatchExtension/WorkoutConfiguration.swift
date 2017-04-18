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
    var activeTime: TimeInterval
    var restTime: TimeInterval
    
    private let exerciseTypeKey = "com.raywenderlich.config.exerciseType"
    private let activeTimeKey = "com.raywenderlich.config.activeTime"
    private let restTimeKey = "com.raywenderlich.config.restTime"
    
    init(exerciseType: ExerciseType = .Other, activeTime: TimeInterval = 120, restTime: TimeInterval = 30) {
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
        
        if let active = rawDictionary[activeTimeKey] as? TimeInterval {
            self.activeTime = active
        } else {
            self.activeTime = 120
        }
        
        if let rest = rawDictionary[restTimeKey] as? TimeInterval {
            self.restTime = rest
        } else {
            self.restTime = 30
        }
    }
    
    func intervalDuration() -> TimeInterval {
        return activeTime + restTime
    }
    
    func dictionaryRepresentation() -> [String : AnyObject] {
        return [
            exerciseTypeKey : exerciseType.rawValue as AnyObject,
            activeTimeKey : activeTime as AnyObject,
            restTimeKey : restTime as AnyObject,
        ]
    }
}
