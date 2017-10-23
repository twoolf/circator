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
        case .Cycling:                    return HKWorkoutSessionLocationType.outdoor
        case .StationaryBike:             return HKWorkoutSessionLocationType.indoor
        case .Elliptical:                 return HKWorkoutSessionLocationType.indoor
        case .FunctionalStrengthTraining: return HKWorkoutSessionLocationType.indoor
        case .Rowing:                     return HKWorkoutSessionLocationType.outdoor
        case .RowingMachine:              return HKWorkoutSessionLocationType.indoor
        case .Running:                    return HKWorkoutSessionLocationType.outdoor
        case .Treadmill:                  return HKWorkoutSessionLocationType.indoor
        case .StairClimbing:              return HKWorkoutSessionLocationType.indoor
        case .Swimming:                   return HKWorkoutSessionLocationType.indoor
        case .Stretching:                 return HKWorkoutSessionLocationType.unknown
        case .Walking:                    return HKWorkoutSessionLocationType.outdoor
        case .Other:                      return HKWorkoutSessionLocationType.unknown
        }
    }
    
    var locationName: String {
        switch self.location {
        case .indoor:  return "Indoor Exercise"
        case .outdoor: return "Outdoor Exercise"
        case .unknown: return "General Exercise"
        }
    }
}
