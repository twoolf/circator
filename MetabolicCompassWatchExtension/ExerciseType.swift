//
//  ExerciseType.swift
//  MetabolicCompass
//
//  Created by twoolf on 5/18/16.
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
    
    var quote: String {
        switch self {
        case .StationaryBike:
            return "\"She who succeeds in gaining the mastery of the bicycle will gain the mastery of life.\" – Susan B. Anthony"
        case .Cycling:
            return "\"When you ride hard on a mountain bike, sometimes you fall, otherwise you’re not riding hard.\" – George W. Bush"
        case .Elliptical:
            return "\"I was never a natural athlete, but I paid my dues in sweat and concentration, and took the time necessary to learn karate and became a world champion.\" – Chuck Norris"
        case .FunctionalStrengthTraining:
            return "\"I just use my muscles as a conversation piece, like someone walking a cheetah down 42nd Street.\" – Arnold Schwarzenegger"
        case .Rowing:
            return "\"It’s a great art, is rowing. It’s the finest art there is. It’s a symphony of motion and when you’re rowing well, why it’s nearing perfection. You’re touching the divine. It touches the you of you’s, which is your soul.\" – George Pocock"
        case .RowingMachine:
            return "\"The less effort, the faster and more powerful you will be.\" – Bruce Lee"
        case .Running:
            return "\"It's factual to say I am a bilateral-below-the-knee amputee. I think it's subjective opinion as to whether or not I am disabled because of that. That's just me.\" – Aimee Mullins"
        case .Treadmill:
            return "\"I run to see who has the most guts.\" – Steve Prefontaine"
        case .StairClimbing:
            return "\"This is one small step for a man, one giant leap for mankind.\" – Neil Armstrong"
        case .Swimming:
            return "\"The water doesn't know how old you are.\" – Dara Torres"
        case .Stretching:
            return "\"Other people may not have had high expectations for me... but I had high expectations for myself.\" – Shannon Miller"
        case .Walking:
            return "\"People sacrifice the present for the future. But life is available only in the present. That is why we should walk in such a way that every step can bring us to the here and the now.\" – Thich Nhat Hanh"
        case .Other:
            return "\"I am building a fire, and everyday I train, I add more fuel. At just the right moment, I light the match.\" – Mia Hamm"
        }
    }
}
