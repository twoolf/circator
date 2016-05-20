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
