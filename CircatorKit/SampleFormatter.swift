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

    public func numberFromResults(results: [Result]) -> Double {
        if var stat = results as? [HKStatistics] {
            guard stat.isEmpty == false else {
                return Double.quietNaN
            }
            return numberFromStatistics(stat.removeLast())
        } else if let samples = results as? [HKSample] {
            return numberFromSamples(samples)
        } else if let derived = results as? [DerivedQuantity] {
            return numberFromDerivedQuantities(derived)
        }
        return Double.quietNaN
    }

    public func stringFromResults(results: [Result]) -> String {
        if var stat = results as? [HKStatistics] {
            guard stat.isEmpty == false else {
                return emptyString
            }
            return stringFromStatistics(stat.removeLast())
        } else if let samples = results as? [HKSample] {
            return stringFromSamples(samples)
        } else if let derived = results as? [DerivedQuantity] {
            return stringFromDerivedQuantities(derived)
        }
        return emptyString
    }

    public func numberFromStatistics(statistics: HKStatistics) -> Double {
        // Guaranteed to be quantity sample here
        // TODO: Need implementation for correlation and sleep
        guard let quantity = statistics.quantity else {
            return Double.quietNaN
        }
        return numberFromQuantity(quantity, type: statistics.quantityType)
    }

    public func stringFromStatistics(statistics: HKStatistics) -> String {
        // Guaranteed to be quantity sample here
        // TODO: Need implementation for correlation and sleep
        guard let quantity = statistics.quantity else {
            return emptyString
        }
        return stringFromQuantity(quantity, type: statistics.quantityType)
    }

    public func numberFromSamples(samples: [HKSample]) -> Double {
        guard samples.isEmpty == false else {
            return Double.quietNaN
        }
        if let type = samples.last!.sampleType as? HKQuantityType {
            return numberFromQuantity((samples.last as! HKQuantitySample).quantity, type: type)
        }
        switch samples.last!.sampleType.identifier {
        case HKWorkoutTypeIdentifier:
            let d = NSDate(timeIntervalSinceReferenceDate: samples.workoutDuration!)
            return Double(d.hour) + (Double(d.minute) / 60.0)

        case HKCategoryTypeIdentifierSleepAnalysis:
            let d = NSDate(timeIntervalSinceReferenceDate: samples.sleepDuration!)
            return Double(d.hour) + (Double(d.minute) / 60.0)

        case HKCorrelationTypeIdentifierBloodPressure:
            // Return the systeolic for blood pressure, since this is the larger number.
            let correlationSample = samples.first as! HKCorrelation
            let systolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!).first as? HKQuantitySample
            guard systolicSample != nil else { return Double.quietNaN }
            return systolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())

        default:
            return Double.quietNaN
        }
    }

    public func stringFromSamples(samples: [HKSample]) -> String {
        guard samples.isEmpty == false else {
            return emptyString
        }
        if let type = samples.last!.sampleType as? HKQuantityType {
            return stringFromQuantity((samples.last as! HKQuantitySample).quantity, type: type)
        }
        switch samples.last!.sampleType.identifier {
        case HKWorkoutTypeIdentifier:
            return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(samples.workoutDuration!)!)"

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

    private func numberFromDerivedQuantities(derived: [DerivedQuantity]) -> Double {
        guard derived.isEmpty == false else {
            return Double.quietNaN
        }
        if let fst      = derived.first as DerivedQuantity?,
               quantity = fst.quantity,
               type     = fst.quantityType
        {
            if let qtype = type as? HKQuantityType {
                return numberFromDerivedQuantity(quantity, type: qtype)
            }

            switch type.identifier {
            case HKCategoryTypeIdentifierSleepAnalysis:
                let d = NSDate(timeIntervalSinceReferenceDate: quantity)
                return Double(d.hour) + (Double(d.minute) / 60.0)

            default:
                return Double.quietNaN
            }
        }
        return Double.quietNaN
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

/*
            case HKCorrelationTypeIdentifierBloodPressure:
                let correlationSample = derived
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
    private func numberFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> Double {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
        case HKQuantityTypeIdentifierHeartRate:
            return quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()))
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return quantity.doubleValueForUnit(HKUnit.jouleUnit())
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return quantity.doubleValueForUnit(HKUnit.mileUnit())
        case HKQuantityTypeIdentifierStepCount:
            return quantity.doubleValueForUnit(HKUnit.countUnit())
        case HKQuantityTypeIdentifierUVExposure:
            return quantity.doubleValueForUnit(HKUnit.countUnit())
        case HKQuantityTypeIdentifierDietaryProtein:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietarySugar:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietarySodium:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())
        default:
            return Double.quietNaN
        }
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
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.mileUnit()))!
        case HKQuantityTypeIdentifierStepCount:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit()))!
        case HKQuantityTypeIdentifierUVExposure:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit()))!
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

    private func numberFromDerivedQuantity(quantity: Double, type: HKQuantityType) -> Double {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            let hkquantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: quantity)
            return hkquantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))

        default:
            return quantity
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

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity, unit: .Kilocalorie)

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) miles"

        case HKQuantityTypeIdentifierStepCount:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) steps"

        case HKQuantityTypeIdentifierUVExposure:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) exposure"

        case HKQuantityTypeIdentifierDietaryProtein:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietarySugar:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietarySodium:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        default:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity) ?? "<nil>"
        }
    }
}