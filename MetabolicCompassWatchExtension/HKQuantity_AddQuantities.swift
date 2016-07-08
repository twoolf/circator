//
//  HKQuantity_AddQuantities.swift
//  MetabolicCompass
//
//  Created by twoolf on 5/18/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

extension HKQuantity {
    
    func addQuantities(quantities: [HKQuantity]?, unit: HKUnit) -> HKQuantity {
        guard let quantities = quantities else {return self}
        
        var accumulatedQuantity: Double = self.doubleValueForUnit(unit)
        for quantity in quantities {
            let newQuantityValue = quantity.doubleValueForUnit(unit)
            accumulatedQuantity += newQuantityValue
        }
        return HKQuantity(unit: unit, doubleValue: accumulatedQuantity)
    }
    
    func addSamples(samples: [HKQuantitySample]?, unit: HKUnit) -> HKQuantity {
        guard let samples = samples else {return self}
        
        return addQuantities(samples.map { (sample) -> HKQuantity in
            return sample.quantity
            }, unit: unit)
    }
    
}

public extension HKQuantityType {
    var aggregationOptions: HKStatisticsOptions {
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return .DiscreteAverage
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierBloodGlucose:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierBodyMass:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryProtein:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietarySodium:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietarySugar:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDietaryWater:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierFlightsClimbed:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierHeartRate:
            return .DiscreteAverage
            
        case HKQuantityTypeIdentifierStepCount:
            return .CumulativeSum
            
        case HKQuantityTypeIdentifierUVExposure:
            return .DiscreteAverage
            
        case HKWorkoutTypeIdentifier:
            return .CumulativeSum
            
        default:
            return .None
        }
    }
}
