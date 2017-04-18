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
        
        var accumulatedQuantity: Double = self.doubleValue(for: unit)
        for quantity in quantities {
            let newQuantityValue = quantity.doubleValue(for: unit)
            accumulatedQuantity += newQuantityValue
        }
        return HKQuantity(unit: unit, doubleValue: accumulatedQuantity)
    }
    
    func addSamples(samples: [HKQuantitySample]?, unit: HKUnit) -> HKQuantity {
        guard let samples = samples else {return self}
        
        return addQuantities(quantities: samples.map { (sample) -> HKQuantity in
            return sample.quantity
            }, unit: unit)
    }
    
}

/*public extension HKQuantityType {
    override var aggregationOptions: HKStatisticsOptions {
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return .discreteAverage
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierBloodGlucose:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierBodyMass:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryProtein:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietarySodium:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietarySugar:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDietaryWater:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierFlightsClimbed:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierHeartRate:
            return .discreteAverage
            
        case HKQuantityTypeIdentifierStepCount:
            return .cumulativeSum
            
        case HKQuantityTypeIdentifierUVExposure:
            return .discreteAverage
            
        case HKWorkoutTypeIdentifier:
            return .cumulativeSum
            
        default:
            return .None
        }
    } 
 } */
