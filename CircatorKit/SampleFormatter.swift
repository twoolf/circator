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

    public func numberFromSamples(samples: [MCSample]) -> Double {
        if var stat = samples as? [HKStatistics] {
            guard stat.isEmpty == false else {
                return Double.quietNaN
            }
            return numberFromStatistics(stat.removeLast())
        } else if let samples = samples as? [HKSample] {
            return numberFromHKSamples(samples)
        } else {
            return numberFromMCSamples(samples)
        }
    }

    public func stringFromSamples(samples: [MCSample]) -> String {
        if var stat = samples as? [HKStatistics] {
            guard stat.isEmpty == false else {
                return emptyString
            }
            return stringFromStatistics(stat.removeLast())
        } else if let samples = samples as? [HKSample] {
            return stringFromHKSamples(samples)
        } else  {
            return stringFromMCSamples(samples)
        }
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

    public func numberFromHKSamples(samples: [HKSample]) -> Double {
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
            // Return the systolic for blood pressure, since this is the larger number.
            let correlationSample = samples.first as! HKCorrelation
            let systolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!).first as? HKQuantitySample
            guard systolicSample != nil else { return Double.quietNaN }
            return systolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())

        default:
            return Double.quietNaN
        }
    }

    public func stringFromHKSamples(samples: [HKSample]) -> String {
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

    private func numberFromMCSamples(samples: [MCSample]) -> Double {
        guard !samples.isEmpty else { return Double.quietNaN }

        if let fst      = samples.first,
               quantity = fst.numeralValue,
               type     = fst.hkType
        {
            if let qtype = type as? HKQuantityType {
                return numberFromMCSample(quantity, type: qtype)
            }

            switch type.identifier {
            case HKWorkoutTypeIdentifier:
                let d = NSDate(timeIntervalSinceReferenceDate: quantity)
                return Double(d.hour) + (Double(d.minute) / 60.0)

            case HKCategoryTypeIdentifierSleepAnalysis:
                log.info("Sleep MC \(quantity)")
                let d = NSDate(timeIntervalSinceReferenceDate: quantity)
                return Double(d.hour) + (Double(d.minute) / 60.0)

            default:
                return Double.quietNaN
            }
        }
        return Double.quietNaN
    }

    private func stringFromMCSamples(samples: [MCSample]) -> String {
        guard !samples.isEmpty else { return emptyString }

        if let fst      = samples.first,
               quantity = fst.numeralValue,
               type     = fst.hkType
        {
            if let qtype = type as? HKQuantityType {
                return stringFromMCSample(quantity, type: qtype)
            }

            switch type.identifier {
            case HKWorkoutTypeIdentifier:
                return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(quantity)!)"

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

    private func numberFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> Double {
        switch type.identifier {
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return quantity.doubleValueForUnit(HKUnit.kilocalorieUnit())

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())
            
        case HKQuantityTypeIdentifierBodyMass:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))

        case HKQuantityTypeIdentifierBodyMassIndex:
            return quantity.doubleValueForUnit(HKUnit.countUnit())

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return quantity.doubleValueForUnit(HKUnit.kilocalorieUnit())

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryProtein:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietarySodium:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierDietarySugar:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return quantity.doubleValueForUnit(HKUnit.mileUnit())

        case HKQuantityTypeIdentifierDietaryWater:
            return quantity.doubleValueForUnit(HKUnit.literUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierHeartRate:
            return quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()))

        case HKQuantityTypeIdentifierStepCount:
            return quantity.doubleValueForUnit(HKUnit.countUnit())

        case HKQuantityTypeIdentifierUVExposure:
            return quantity.doubleValueForUnit(HKUnit.countUnit())
            
        default:
            return Double.quietNaN
        }
    }

    private func stringFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.kilocalorieUnit()), unit: .Kilocalorie)

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!

        case HKQuantityTypeIdentifierBodyMass:
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)))

        case HKQuantityTypeIdentifierBodyMassIndex:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit()))!

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli)), unit: .Gram)

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli)), unit: .Gram)

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.kilocalorieUnit()), unit: .Kilocalorie)

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDietaryProtein:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDietarySodium:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli)), unit: .Gram)

        case HKQuantityTypeIdentifierDietarySugar:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.mileUnit()))!

        case HKQuantityTypeIdentifierDietaryWater:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.literUnitWithMetricPrefix(.Milli)))!

        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())))!) bpm"

        case HKQuantityTypeIdentifierStepCount:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit()))!

        case HKQuantityTypeIdentifierUVExposure:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit()))!

        default:
            return emptyString
        }
    }

    private func numberFromMCSample(quantity: Double, type: HKSampleType) -> Double {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            let hkquantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: quantity)
            return hkquantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))

        default:
            return quantity
        }
    }

    private func stringFromMCSample(quantity: Double, type: HKSampleType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity, unit: .Kilocalorie)

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity)!

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity)!

        case HKQuantityTypeIdentifierBodyMass:
            let hkquantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: quantity)
            let kilos = hkquantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(kilos)

        case HKQuantityTypeIdentifierBodyMassIndex:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity)!

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) mg"

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) mg"

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity, unit: .Kilocalorie)

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietaryProtein:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDietarySodium:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) mg"

        case HKQuantityTypeIdentifierDietarySugar:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) miles"

        case HKQuantityTypeIdentifierDietaryWater:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) ml"

        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) bpm"

        case HKQuantityTypeIdentifierStepCount:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) steps"

        case HKQuantityTypeIdentifierUVExposure:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) hours"
            
        default:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity) ?? "<nil>"
        }
    }
}