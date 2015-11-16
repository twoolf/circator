//
//  SampleFormatter.swift
//  Circator
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit

public class SampleFormatter: NSObject {
    
    public static let bodyMassFormatter: NSMassFormatter = {
        let formatter = NSMassFormatter()
        formatter.forPersonMassUse = true
        formatter.unitStyle = .Medium
        formatter.numberFormatter = numberFormatter
        return formatter
    }()
    
    public static let chartDateFormatter: NSDateFormatter = {
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    
    public static let numberFormatter: NSNumberFormatter = {
        let formatter: NSNumberFormatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    public static let integerFormatter: NSNumberFormatter = {
        let formatter: NSNumberFormatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.NoStyle
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public static let calorieFormatter: NSEnergyFormatter = {
        let formatter = NSEnergyFormatter()
        formatter.unitStyle = NSFormattingUnitStyle.Medium
        formatter.forFoodEnergyUse = true
        return formatter
    }()
    
    public static let timeIntervalFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Abbreviated
        formatter.allowedUnits = [.Hour, .Minute]
        return formatter
    }()
    
    private let emptyString: String
    
    public convenience override init() {
        self.init(emptyString: "--")
    }
    
    public init(emptyString: String) {
        self.emptyString = emptyString
        super.init()
    }
    
    public func stringFromStatistics(statistics: HKStatistics) -> String {
        // Guaranteed to be quantity sample here
        // TODO: Need implementation for correlation and sleep
        guard let quantity = statistics.quantity else {
            return emptyString
        }
        return stringFromQuantity(quantity, type: statistics.quantityType)
    }
    
    public func stringFromSamples(samples: [HKSample]) -> String {
        guard samples.isEmpty == false else {
            return emptyString
        }
        if let type = samples.first!.sampleType as? HKQuantityType {
            return stringFromQuantity((samples.first as! HKQuantitySample).quantity, type: type)
        }
        switch samples.first!.sampleType.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(samples.sleepDuration!)!)"
        case HKCorrelationTypeIdentifierBloodPressure:
            let correlationSample = samples.first as! HKCorrelation
            let diastolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!).first as? HKQuantitySample
            let systolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!).first as? HKQuantitySample
            guard diastolicSample != nil && systolicSample != nil else {
                return emptyString
            }
            let diastolicNumber = SampleFormatter.integerFormatter.stringFromNumber(diastolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!
            let systolicNumber = SampleFormatter.integerFormatter.stringFromNumber(systolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!
            return "\(systolicNumber)/\(diastolicNumber)"
        default:
            return emptyString
        }
    }
    
    private func stringFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)))
        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())))!) bpm"
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return SampleFormatter.calorieFormatter.stringFromJoules(quantity.doubleValueForUnit(HKUnit.jouleUnit()))
        default:
            return emptyString
        }
    }
    
}