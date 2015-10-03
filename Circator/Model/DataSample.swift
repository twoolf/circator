//
//  DataSample.swift
//  Circator
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit

struct DataSample: CustomStringConvertible {
    
    static let bodyMassFormatter: NSMassFormatter = {
        let formatter = NSMassFormatter()
        formatter.forPersonMassUse = true
        formatter.unitStyle = .Medium
        formatter.numberFormatter = numberFormatter
        return formatter
    }()
    
    static let numberFormatter: NSNumberFormatter = {
        let formatter: NSNumberFormatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static let calorieFormatter: NSEnergyFormatter = {
        let formatter = NSEnergyFormatter()
        formatter.unitStyle = NSFormattingUnitStyle.Medium
        formatter.forFoodEnergyUse = true
        return formatter
    }()
    
    let type: HealthManager.Parameter
    let data: HKQuantity
    
    var description: String {
        switch type {
        case .BodyMass:
            return DataSample.bodyMassFormatter.stringFromKilograms(data.doubleValueForUnit(HKUnit.meterUnit()))
        case .BloodPressure:
            return "\(data.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))"
        case .EnergyIntake:
            return DataSample.calorieFormatter.stringFromJoules(data.doubleValueForUnit(HKUnit.jouleUnit()))
        case .HeartRate:
            return "\(DataSample.numberFormatter.stringFromNumber(data.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())))!) bpm"
        case .Sleep:
            return NSString(format: "%.1f h", data.doubleValueForUnit(HKUnit.hourUnit())) as String
        }
    }
    
    init(type: HealthManager.Parameter, data: HKQuantity) {
        self.type = type
        self.data = data
    }
    
}