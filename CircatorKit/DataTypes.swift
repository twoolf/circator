//
//  DataTypes.swift
//  Circator
//
//  Created by Yanif Ahmad on 3/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

public enum CircadianEvent {
    case Meal
    case Fast
    case Sleep
    case Exercise
}

/*
 * A protocol for unifying common metadata across HKSample and HKStatistic
 */
public protocol MCSample {
    var startDate    : NSDate        { get }
    var endDate      : NSDate        { get }
    var numeralValue : Double?       { get }
    var defaultUnit  : HKUnit?       { get }
    var hkType       : HKSampleType? { get }
}

/*
 * An aggregated or derived sample, providing an increment function to merge multiple samples.
 * The increment can only be applied to samples of a matching type.
 */
public struct MCAggregateSample : MCSample {
    public var startDate    : NSDate
    public var endDate      : NSDate
    public var numeralValue : Double?
    public var defaultUnit  : HKUnit?
    public var hkType       : HKSampleType?

    var avgTotal: Double = 0.0
    var avgCount: Int = 0

    public init(sample: MCSample) {
        startDate = sample.startDate
        endDate = sample.endDate
        numeralValue = nil
        defaultUnit = nil
        hkType = sample.hkType
        self.incr(sample)
    }

    public init(value: Double?, sampleType: HKSampleType?) {
        startDate = NSDate()
        endDate = NSDate()
        numeralValue = value
        defaultUnit = sampleType?.defaultUnit
        hkType = sampleType
    }

    public mutating func incr(sample: MCSample) {
        if hkType == sample.hkType {
            startDate = min(sample.startDate, startDate)
            endDate = max(sample.endDate, endDate)

            switch hkType!.identifier {
            case HKCategoryTypeIdentifierSleepAnalysis:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKCorrelationTypeIdentifierBloodPressure:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierActiveEnergyBurned:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierBasalEnergyBurned:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierBloodGlucose:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierBloodPressureSystolic:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierBloodPressureDiastolic:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierBodyMass:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierBodyMassIndex:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierDietaryCaffeine:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryCarbohydrates:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryCholesterol:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryEnergyConsumed:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryFatSaturated:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryFatTotal:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryProtein:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietarySodium:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietarySugar:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDietaryWater:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierDistanceWalkingRunning:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierFlightsClimbed:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierHeartRate:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKQuantityTypeIdentifierStepCount:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            case HKQuantityTypeIdentifierUVExposure:
                avgTotal += sample.numeralValue!
                avgCount += 1

            case HKWorkoutTypeIdentifier:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!

            default:
                log.error("Cannot aggregate \(hkType)")
            }

        } else {
            log.error("Invalid sample aggregation between \(hkType) and \(sample.hkType)")
        }
    }

    public mutating func final() {
        switch hkType!.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            numeralValue = avgTotal / Double(avgCount)

        case HKCorrelationTypeIdentifierBloodPressure:
            numeralValue = avgTotal / Double(avgCount)

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            numeralValue = avgTotal / Double(avgCount)

        case HKQuantityTypeIdentifierBloodGlucose:
            numeralValue = avgTotal / Double(avgCount)

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            numeralValue = avgTotal / Double(avgCount)

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBodyMass:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierHeartRate:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierUVExposure:
            numeralValue = avgTotal / Double(avgCount)
            
        default:
            ()
        }
    }
}

// MARK: - Categories & Extensions

extension HKStatistics: MCSample { }
extension HKSample: MCSample { }

public extension HKSampleType {
    public var displayText: String? {
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "HealthKit data type")

        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return NSLocalizedString("Active Energy Burned", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return NSLocalizedString("Basal Energy Burned", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBloodGlucose:
            return NSLocalizedString("Blood Glucose", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return NSLocalizedString("Blood Pressure Diastolic", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return NSLocalizedString("Blood Pressure Systolic", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("Body Mass Index", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSLocalizedString("Caffeine", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Carbohydrates", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Cholesterol", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Food calories", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Monounsaturated Fat", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Polyunsaturated Fat", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Saturated Fat", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Fat", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Protein", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Sugar", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryWater:
            return NSLocalizedString("Water", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return NSLocalizedString("Walking and Running Distance", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierFlightsClimbed:
            return NSLocalizedString("Flights Climbed", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heartrate", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Step Count", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV Exposure", comment: "HealthKit data type")

        case HKWorkoutTypeIdentifier:
            return NSLocalizedString("Workouts/Meals", comment: "HealthKit data type")

        default:
            return nil
        }
    }

    public var defaultUnit: HKUnit? {
        let isMetric: Bool = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return HKUnit.hourUnit()

        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierBloodGlucose:
            return HKUnit.gramUnitWithMetricPrefix(.Milli).unitDividedByUnit(HKUnit.literUnitWithMetricPrefix(.Deci))

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()

        case HKQuantityTypeIdentifierBodyMassIndex:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryProtein:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietarySodium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietarySugar:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryWater:
            return HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return HKUnit.mileUnit()

        case HKQuantityTypeIdentifierFlightsClimbed:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())

        case HKQuantityTypeIdentifierStepCount:
            return HKUnit.countUnit()
            
        case HKQuantityTypeIdentifierUVExposure:
            return HKUnit.countUnit()
            
        case HKWorkoutTypeIdentifier:
            return HKUnit.hourUnit()
            
        default:
            return nil
        }
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

public extension HKStatistics {
    var quantity: HKQuantity? {
        switch quantityType.identifier {

        case HKCategoryTypeIdentifierSleepAnalysis:
            return averageQuantity()

        case HKCorrelationTypeIdentifierBloodPressure:
            return sumQuantity()

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return sumQuantity()

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return averageQuantity()

        case HKQuantityTypeIdentifierBodyMass:
            return averageQuantity()

        case HKQuantityTypeIdentifierBodyMassIndex:
            return averageQuantity()

        case HKQuantityTypeIdentifierBloodGlucose:
            return sumQuantity()

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return sumQuantity()

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryProtein:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietarySodium:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietarySugar:
            return sumQuantity()

        case HKQuantityTypeIdentifierDietaryWater:
            return sumQuantity()

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return sumQuantity()

        case HKQuantityTypeIdentifierFlightsClimbed:
            return sumQuantity()

        case HKQuantityTypeIdentifierHeartRate:
            return averageQuantity()

        case HKQuantityTypeIdentifierStepCount:
            return sumQuantity()

        case HKQuantityTypeIdentifierUVExposure:
            return sumQuantity()

        case HKWorkoutTypeIdentifier:
            return sumQuantity()

        default:
            log.warning("Invalid quantity type \(quantityType.identifier) for HKStatistics")
            return sumQuantity()
        }
    }

    public var numeralValue: Double? {
        guard defaultUnit != nil && quantity != nil else {
            return nil
        }
        switch quantityType.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            fallthrough
        case HKCorrelationTypeIdentifierBloodPressure:
            fallthrough
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBloodGlucose:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            fallthrough
        case HKQuantityTypeIdentifierBodyMass:
            fallthrough
        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCholesterol:
            fallthrough
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough
        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough
        case HKQuantityTypeIdentifierDietarySodium:
            fallthrough
        case HKQuantityTypeIdentifierDietarySugar:
            fallthrough
        case HKQuantityTypeIdentifierDietaryWater:
            fallthrough
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            fallthrough
        case HKQuantityTypeIdentifierFlightsClimbed:
            fallthrough
        case HKQuantityTypeIdentifierHeartRate:
            fallthrough
        case HKQuantityTypeIdentifierStepCount:
            fallthrough
        case HKQuantityTypeIdentifierUVExposure:
            fallthrough
        case HKWorkoutTypeIdentifier:
            return quantity!.doubleValueForUnit(defaultUnit!)
        default:
            return nil
        }
    }

    public var defaultUnit: HKUnit? { return quantityType.defaultUnit }

    public var hkType: HKSampleType? { return quantityType }
}

public extension HKSample {
    public var numeralValue: Double? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            let sample = (self as! HKCategorySample)
            let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.endDate.timeIntervalSinceDate(sample.startDate))
            return secs.doubleValueForUnit(defaultUnit!)

        case HKCorrelationTypeIdentifierBloodPressure:
            return ((self as! HKCorrelation).objects.first as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            fallthrough

        case HKQuantityTypeIdentifierBloodGlucose:
            fallthrough

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            fallthrough

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough

        case HKQuantityTypeIdentifierBodyMass:
            fallthrough

        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough

        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough

        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough

        case HKQuantityTypeIdentifierDietarySugar:
            fallthrough

        case HKQuantityTypeIdentifierDietarySodium:
            fallthrough

        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough

        case HKQuantityTypeIdentifierDietaryWater:
            fallthrough

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            fallthrough

        case HKQuantityTypeIdentifierFlightsClimbed:
            fallthrough

        case HKQuantityTypeIdentifierHeartRate:
            fallthrough

        case HKQuantityTypeIdentifierStepCount:
            fallthrough

        case HKQuantityTypeIdentifierUVExposure:
            return (self as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)

        case HKWorkoutTypeIdentifier:
            let sample = (self as! HKWorkout)
            let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.duration)
            return secs.doubleValueForUnit(defaultUnit!)

        default:
            return nil
        }
    }

    public var allNumeralValues: [Double]? {
        return numeralValue != nil ? [numeralValue!] : nil
    }

    public var defaultUnit: HKUnit? { return sampleType.defaultUnit }

    public var hkType: HKSampleType? { return sampleType }
}

public extension HKCorrelation {
    public override var allNumeralValues: [Double]? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKCorrelationTypeIdentifierBloodPressure:
            return objects.map { (sample) -> Double in
                (sample as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
            }
        default:
            return nil
        }
    }
}

public extension Array where Element: HKSample {
    public var sleepDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKCategorySample
            return categorySample.sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis
                && categorySample.value == HKCategoryValueSleepAnalysis.Asleep.rawValue
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
    
    public var workoutDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKWorkout
            return categorySample.sampleType.identifier == HKWorkoutTypeIdentifier
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
}
