//
//  ExerciseType.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

enum ExerciseType: Int {
    case Cycling = 1
    case StationaryBike
    case Elliptical
    case FunctionalStrengthTraining
    case Rowing
    case RowingMachine
    case Running
    case Treadmill
    case StairClimbing
    case Swimming
    case Stretching
    case Walking
    case Other
    
    static let allValues = [Cycling, StationaryBike, Elliptical, FunctionalStrengthTraining, Rowing, RowingMachine, Running, Treadmill, StairClimbing, Swimming, Stretching, Walking, Other]
    
    var title: String {
        switch self {
        case .Cycling:                    return "Cycling"
        case .StationaryBike:             return "Stationary Bike"
        case .Elliptical:                 return "Elliptical"
        case .FunctionalStrengthTraining: return "Weights"
        case .Rowing:                     return "Rowing"
        case .RowingMachine:              return "Ergometer"
        case .Running:                    return "Running"
        case .Treadmill:                  return "Treadmill"
        case .StairClimbing:              return "Stairs"
        case .Swimming:                   return "Swimming"
        case .Stretching:                 return "Stretching"
        case .Walking:                    return "Walking"
        case .Other:                      return "Other"
        }
    }
    
    var workoutType: HKWorkoutActivityType {
        switch self {
        case .Cycling:                    return HKWorkoutActivityType.cycling
        case .StationaryBike:             return HKWorkoutActivityType.cycling
        case .Elliptical:                 return HKWorkoutActivityType.elliptical
        case .FunctionalStrengthTraining: return HKWorkoutActivityType.functionalStrengthTraining
        case .Rowing:                     return HKWorkoutActivityType.rowing
        case .RowingMachine:              return HKWorkoutActivityType.rowing
        case .Running:                    return HKWorkoutActivityType.running
        case .Treadmill:                  return HKWorkoutActivityType.running
        case .StairClimbing:              return HKWorkoutActivityType.stairClimbing
        case .Swimming:                   return HKWorkoutActivityType.swimming
        case .Stretching:                 return HKWorkoutActivityType.other
        case .Walking:                    return HKWorkoutActivityType.walking
        case .Other:                      return HKWorkoutActivityType.other
        }
    }

}
