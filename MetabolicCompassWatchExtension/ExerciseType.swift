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
        case .Cycling:                    return HKWorkoutActivityType.Cycling
        case .StationaryBike:             return HKWorkoutActivityType.Cycling
        case .Elliptical:                 return HKWorkoutActivityType.Elliptical
        case .FunctionalStrengthTraining: return HKWorkoutActivityType.FunctionalStrengthTraining
        case .Rowing:                     return HKWorkoutActivityType.Rowing
        case .RowingMachine:              return HKWorkoutActivityType.Rowing
        case .Running:                    return HKWorkoutActivityType.Running
        case .Treadmill:                  return HKWorkoutActivityType.Running
        case .StairClimbing:              return HKWorkoutActivityType.StairClimbing
        case .Swimming:                   return HKWorkoutActivityType.Swimming
        case .Stretching:                 return HKWorkoutActivityType.Other
        case .Walking:                    return HKWorkoutActivityType.Walking
        case .Other:                      return HKWorkoutActivityType.Other
        }
    }

}
