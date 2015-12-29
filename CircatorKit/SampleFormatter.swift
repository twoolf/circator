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
    
    public static let foodMassFormatter: NSMassFormatter = {
        let formatter = NSMassFormatter()
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
        formatter.numberFormatter = SampleFormatter.numberFormatter
        formatter.unitStyle = NSFormattingUnitStyle.Medium
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

    public func stringFromResults(results: [Result]) -> String {
        if let stat = results as? [HKStatistics] {
            guard stat.isEmpty == false else {
                return emptyString
            }
            return stringFromStatistics(stat[0])
        } else if let samples = results as? [HKSample] {
            return stringFromSamples(samples)
        } else if let derived = results as? [DerivedQuantity] {
            return stringFromDerivedQuantities(derived)
        }
        return emptyString
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

    private func stringFromDerivedQuantities(derived: [DerivedQuantity]) -> String {
        guard derived.isEmpty == false else {
            return emptyString
        }
        if let fst      = derived.first as DerivedQuantity?,
               quantity = fst.quantity,
               type     = fst.quantityType
        {
            if let qtype = type as? HKQuantityType {
                return stringFromDerivedQuantity(quantity, type: qtype)
            }
            
            switch type.identifier {
            case HKCategoryTypeIdentifierSleepAnalysis:
                return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(quantity)!)"

            /* TODO: both systolic and diastolic.
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
            */
            default:
                return emptyString
            }
        }
        return emptyString
    }

    // TODO: handle other quantities.
    private func stringFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)))
        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())))!) bpm"
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return SampleFormatter.calorieFormatter.stringFromJoules(quantity.doubleValueForUnit(HKUnit.jouleUnit()))
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietaryProtein:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietarySugar:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietarySodium:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
        default:
            return emptyString
        }
    }

    private func stringFromDerivedQuantity(quantity: Double, type: HKQuantityType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            let hkquantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: quantity)
            let kilos = hkquantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(kilos)

        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) bpm"

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity, unit: .Kilocalorie)
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietaryProtein:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietarySugar:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietarySodium:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) gms"

        default:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity) ?? "<nil>"
        }
    }
}