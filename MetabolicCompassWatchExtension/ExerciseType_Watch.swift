//
//  ExerciseType_Watch.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

extension ExerciseType {
    var location: HKWorkoutSessionLocationType {
        switch self {
        case .Cycling:                    return HKWorkoutSessionLocationType.Outdoor
        case .StationaryBike:             return HKWorkoutSessionLocationType.Indoor
        case .Elliptical:                 return HKWorkoutSessionLocationType.Indoor
        case .FunctionalStrengthTraining: return HKWorkoutSessionLocationType.Indoor
        case .Rowing:                     return HKWorkoutSessionLocationType.Outdoor
        case .RowingMachine:              return HKWorkoutSessionLocationType.Indoor
        case .Running:                    return HKWorkoutSessionLocationType.Outdoor
        case .Treadmill:                  return HKWorkoutSessionLocationType.Indoor
        case .StairClimbing:              return HKWorkoutSessionLocationType.Indoor
        case .Swimming:                   return HKWorkoutSessionLocationType.Indoor
        case .Stretching:                 return HKWorkoutSessionLocationType.Unknown
        case .Walking:                    return HKWorkoutSessionLocationType.Outdoor
        case .Other:                      return HKWorkoutSessionLocationType.Unknown
        }
    }
    
    var locationName: String {
        switch self.location {
        case .Indoor:  return "Indoor Exercise"
        case .Outdoor: return "Outdoor Exercise"
        case .Unknown: return "General Exercise"
        }
    }
}
