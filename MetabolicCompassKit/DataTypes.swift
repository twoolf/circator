//
//  DataTypes.swift
//  MetabolicCompass
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

public struct MCStatisticSample : MCSample {
    public var statistic    : HKStatistics
    public var numeralValue : Double?

    public var startDate    : NSDate        { return statistic.startDate   }
    public var endDate      : NSDate        { return statistic.endDate     }
    public var defaultUnit  : HKUnit?       { return statistic.defaultUnit }
    public var hkType       : HKSampleType? { return statistic.hkType      }

    public init(statistic: HKStatistics, statsOption: HKStatisticsOptions) {
        self.statistic = statistic
        self.numeralValue = nil
        if ( statsOption.contains(.DiscreteAverage) ) {
            self.numeralValue = statistic.averageQuantity()?.doubleValueForUnit(defaultUnit!)
        }
        if ( statsOption.contains(.DiscreteMin) ) {
            self.numeralValue = statistic.minimumQuantity()?.doubleValueForUnit(defaultUnit!)
        }
        if ( statsOption.contains(.DiscreteMax) ) {
            self.numeralValue = statistic.maximumQuantity()?.doubleValueForUnit(defaultUnit!)
        }
        if ( statsOption.contains(.CumulativeSum) ) {
            self.numeralValue = statistic.sumQuantity()?.doubleValueForUnit(defaultUnit!)
        }
    }
}

/*
 * Generalized aggregation, irrespective of HKSampleType.
 *
 * This relies on the numeralValue field provided by the MCSample protocol to provide
 * a valid numeric representation for all HKSampleTypes.
 *
 * The increment operation provided within can only be applied to samples of a matching type.
 */
public struct MCAggregateSample : MCSample {
    public var startDate    : NSDate
    public var endDate      : NSDate
    public var numeralValue : Double?
    public var defaultUnit  : HKUnit?
    public var hkType       : HKSampleType?
    public var aggOp        : HKStatisticsOptions

    var runningAgg: [Double] = [0.0, 0.0, 0.0]
    var runningCnt: Int = 0

    public init(sample: MCSample, op: HKStatisticsOptions) {
        startDate = sample.startDate
        endDate = sample.endDate
        numeralValue = nil
        defaultUnit = nil
        hkType = sample.hkType
        aggOp = op
        self.incr(sample)
    }

    public init(startDate: NSDate = NSDate(), endDate: NSDate = NSDate(), value: Double?, sampleType: HKSampleType?, op: HKStatisticsOptions) {
        self.startDate = startDate
        self.endDate = endDate
        numeralValue = value
        defaultUnit = sampleType?.defaultUnit
        hkType = sampleType
        aggOp = op
    }

    public init(statistic: HKStatistics, op: HKStatisticsOptions) {
        startDate = statistic.startDate
        endDate = statistic.endDate
        numeralValue = statistic.numeralValue
        defaultUnit = statistic.defaultUnit
        hkType = statistic.hkType
        aggOp = op

        // Initialize internal statistics.
        if let sumQ = statistic.sumQuantity() {
            runningAgg[0] = sumQ.doubleValueForUnit(statistic.defaultUnit!)
        } else if let avgQ = statistic.averageQuantity() {
            runningAgg[0] = avgQ.doubleValueForUnit(statistic.defaultUnit!)
            runningCnt = 1
        }
        if let minQ = statistic.minimumQuantity() {
            runningAgg[1] = minQ.doubleValueForUnit(statistic.defaultUnit!)
        }
        if let maxQ = statistic.maximumQuantity() {
            runningAgg[2] = maxQ.doubleValueForUnit(statistic.defaultUnit!)
        }
    }

    public init(startDate: NSDate, endDate: NSDate, numeralValue: Double?, defaultUnit: HKUnit?,
                hkType: HKSampleType?, aggOp: HKStatisticsOptions, runningAgg: [Double], runningCnt: Int)
    {
        self.startDate = startDate
        self.endDate = endDate
        self.numeralValue = numeralValue
        self.defaultUnit = defaultUnit
        self.hkType = hkType
        self.aggOp = aggOp
        self.runningAgg = runningAgg
        self.runningCnt = runningCnt
    }

    public mutating func rsum(sample: MCSample) {
        runningAgg[0] += sample.numeralValue!
        runningCnt += 1
    }

    public mutating func rmin(sample: MCSample) {
        runningAgg[1] = min(runningAgg[1], sample.numeralValue!)
        runningCnt += 1
    }

    public mutating func rmax(sample: MCSample) {
        runningAgg[2] = max(runningAgg[2], sample.numeralValue!)
        runningCnt += 1
    }

    public mutating func incrOp(sample: MCSample) {
        if aggOp.contains(.DiscreteAverage) || aggOp.contains(.CumulativeSum) {
            rsum(sample)
        }
        if aggOp.contains(.DiscreteMin) {
            rmin(sample)
        }
        if aggOp.contains(.DiscreteMax) {
            rmax(sample)
        }
    }

    public mutating func incr(sample: MCSample) {
        if hkType == sample.hkType {
            startDate = min(sample.startDate, startDate)
            endDate = max(sample.endDate, endDate)

            switch hkType! {
            case is HKCategoryType:
                switch hkType!.identifier {
                case HKCategoryTypeIdentifierSleepAnalysis:
                    incrOp(sample)

                default:
                    log.error("Cannot aggregate \(hkType)")
                }

            case is HKCorrelationType:
                switch hkType!.identifier {
                case HKCorrelationTypeIdentifierBloodPressure:
                    incrOp(sample)

                default:
                    log.error("Cannot aggregate \(hkType)")
                }

            case is HKWorkoutType:
                incrOp(sample)

            case is HKQuantityType:
                incrOp(sample)

            default:
                log.error("Cannot aggregate \(hkType)")
            }

        } else {
            log.error("Invalid sample aggregation between \(hkType) and \(sample.hkType)")
        }
    }

    public mutating func final() {
        if aggOp.contains(.CumulativeSum) {
            numeralValue = runningAgg[0]
        } else if aggOp.contains(.DiscreteAverage) {
            numeralValue = runningAgg[0] / Double(runningCnt)
        } else if aggOp.contains(.DiscreteMin) {
            numeralValue = runningAgg[1]
        } else if aggOp.contains(.DiscreteMax) {
            numeralValue = runningAgg[2]
        }
    }

    public mutating func finalAggregate(finalOp: HKStatisticsOptions) {
        if aggOp.contains(.CumulativeSum) && finalOp.contains(.CumulativeSum) {
            numeralValue = runningAgg[0]
        } else if aggOp.contains(.DiscreteAverage) && finalOp.contains(.DiscreteAverage) {
            numeralValue = runningAgg[0] / Double(runningCnt)
        } else if aggOp.contains(.DiscreteMin) && finalOp.contains(.DiscreteMin) {
            numeralValue = runningAgg[1]
        } else if aggOp.contains(.DiscreteMax) && finalOp.contains(.DiscreteMax) {
            numeralValue = runningAgg[2]
        }
    }

    public func query(stats: HKStatisticsOptions) -> Double? {
        if ( stats.contains(.CumulativeSum) && aggOp.contains(.CumulativeSum) ) {
            return runningAgg[0]
        }
        if ( stats.contains(.DiscreteAverage) && aggOp.contains(.DiscreteAverage) ) {
            return runningAgg[0] / Double(runningCnt)
        }
        if ( stats.contains(.DiscreteMin) && aggOp.contains(.DiscreteMin) ) {
            return runningAgg[1]
        }
        if ( stats.contains(.DiscreteMax) && aggOp.contains(.DiscreteMax) ) {
            return runningAgg[2]
        }
        return nil
    }

    public func count() -> Int { return runningCnt }

    // Encoding/decoding.
    public static func encode(aggregate: MCAggregateSample) -> MCAggregateSampleCoding {
        return MCAggregateSampleCoding(aggregate: aggregate)
    }

    public static func decode(aggregateEncoding: MCAggregateSampleCoding) -> MCAggregateSample? {
        return aggregateEncoding.aggregate
    }
}

public extension MCAggregateSample {
    public class MCAggregateSampleCoding: NSObject, NSCoding {
        var aggregate: MCAggregateSample?

        init(aggregate: MCAggregateSample) {
            self.aggregate = aggregate
            super.init()
        }

        required public init?(coder aDecoder: NSCoder) {
            guard let startDate    = aDecoder.decodeObjectForKey("startDate")    as? NSDate         else { log.error("Failed to rebuild MCAggregateSample startDate"); aggregate = nil; super.init(); return nil }
            guard let endDate      = aDecoder.decodeObjectForKey("endDate")      as? NSDate         else { log.error("Failed to rebuild MCAggregateSample endDate"); aggregate = nil; super.init(); return nil }
            guard let numeralValue = aDecoder.decodeObjectForKey("numeralValue") as? Double?        else { log.error("Failed to rebuild MCAggregateSample numeralValue"); aggregate = nil; super.init(); return nil }
            guard let defaultUnit  = aDecoder.decodeObjectForKey("defaultUnit")  as? HKUnit?        else { log.error("Failed to rebuild MCAggregateSample defaultUnit"); aggregate = nil; super.init(); return nil }
            guard let hkType       = aDecoder.decodeObjectForKey("hkType")       as? HKSampleType?  else { log.error("Failed to rebuild MCAggregateSample hkType"); aggregate = nil; super.init(); return nil }
            guard let aggOp        = aDecoder.decodeObjectForKey("aggOp")        as? UInt           else { log.error("Failed to rebuild MCAggregateSample aggOp"); aggregate = nil; super.init(); return nil }
            guard let runningAgg   = aDecoder.decodeObjectForKey("runningAgg")   as? [Double]       else { log.error("Failed to rebuild MCAggregateSample runningAgg"); aggregate = nil; super.init(); return nil }
            guard let runningCnt   = aDecoder.decodeObjectForKey("runningCnt")   as? Int            else { log.error("Failed to rebuild MCAggregateSample runningCnt"); aggregate = nil; super.init(); return nil }

            aggregate = MCAggregateSample(startDate: startDate, endDate: endDate, numeralValue: numeralValue, defaultUnit: defaultUnit,
                                          hkType: hkType, aggOp: HKStatisticsOptions(rawValue: aggOp), runningAgg: runningAgg, runningCnt: runningCnt)

            super.init()
        }

        public func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeObject(aggregate!.startDate,      forKey: "startDate")
            aCoder.encodeObject(aggregate!.endDate,        forKey: "endDate")
            aCoder.encodeObject(aggregate!.numeralValue,   forKey: "numeralValue")
            aCoder.encodeObject(aggregate!.defaultUnit,    forKey: "defaultUnit")
            aCoder.encodeObject(aggregate!.hkType,         forKey: "hkType")
            aCoder.encodeObject(aggregate!.aggOp.rawValue, forKey: "aggOp")
            aCoder.encodeObject(aggregate!.runningAgg,     forKey: "runningAgg")
            aCoder.encodeObject(aggregate!.runningCnt,     forKey: "runningCnt")
        }
    }
}

public class MCAggregateArray: NSObject, NSCoding {
    public var aggregates : [MCAggregateSample]

    init(aggregates: [MCAggregateSample]) {
        self.aggregates = aggregates
    }

    required public convenience init?(coder aDecoder: NSCoder) {
        guard let aggs = aDecoder.decodeObjectForKey("aggregates") as? [MCAggregateSample.MCAggregateSampleCoding] else { return nil }
        self.init(aggregates: aggs.flatMap({ return MCAggregateSample.decode($0) }))
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(aggregates.map { return MCAggregateSample.encode($0) }, forKey: "aggregates")
    }
}


// MARK: - Categories & Extensions

// Default aggregation for all subtypes of HKSampleType.

public extension HKSampleType {
    var aggregationOptions: HKStatisticsOptions {
        switch self {
        case is HKCategoryType:
            return (self as! HKCategoryType).aggregationOptions

        case is HKCorrelationType:
            return (self as! HKCorrelationType).aggregationOptions

        case is HKWorkoutType:
            return (self as! HKWorkoutType).aggregationOptions

        case is HKQuantityType:
            return (self as! HKQuantityType).aggregationOptions

        default:
            fatalError("Invalid aggregation overy \(self.identifier)")
        }
    }
}

public extension HKCategoryType {
    override var aggregationOptions: HKStatisticsOptions { return .DiscreteAverage }
}

public extension HKCorrelationType {
    override var aggregationOptions: HKStatisticsOptions { return .DiscreteAverage }
}

public extension HKWorkoutType {
    override var aggregationOptions: HKStatisticsOptions { return .CumulativeSum }
}

public extension HKQuantityType {
    override var aggregationOptions: HKStatisticsOptions {
        switch aggregationStyle {
        case .Discrete:
            return .DiscreteAverage
        case .Cumulative:
            return .CumulativeSum
        }
    }
}

// Duration aggregate for HKSample arrays.
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

/*
 * MCSample extensions for HKStatistics.
 */
extension HKStatistics: MCSample { }

public extension HKStatistics {
    var quantity: HKQuantity? {
        switch quantityType.aggregationStyle {
        case .Discrete:
            return averageQuantity()
        case .Cumulative:
            return sumQuantity()
        }
    }

    public var numeralValue: Double? {
        guard defaultUnit != nil && quantity != nil else {
            return nil
        }
        return quantity!.doubleValueForUnit(defaultUnit!)
    }

    public var defaultUnit: HKUnit? { return quantityType.defaultUnit }

    public var hkType: HKSampleType? { return quantityType }
}

/*
 * MCSample extensions for HKSample.
 */

extension HKSample: MCSample { }

public extension HKSampleType {

    public var defaultUnit: HKUnit? {
        let isMetric: Bool = UserManager.sharedManager.useMetricUnits() ??
                                NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue

        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return HKUnit.hourUnit()

        case HKCategoryTypeIdentifierAppleStandHour:
            return HKUnit.hourUnit()

        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierBasalBodyTemperature:
            return HKUnit.degreeFahrenheitUnit()

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierBloodAlcoholContent:
            return HKUnit.percentUnit()

        case HKQuantityTypeIdentifierBloodGlucose:
            return HKUnit.gramUnitWithMetricPrefix(.Milli).unitDividedByUnit(HKUnit.literUnitWithMetricPrefix(.Deci))

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierBodyFatPercentage:
            return HKUnit.percentUnit()

        case HKQuantityTypeIdentifierBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()

        case HKQuantityTypeIdentifierBodyMassIndex:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierBodyTemperature:
            return HKUnit.degreeFahrenheitUnit()

        case HKQuantityTypeIdentifierDietaryBiotin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryCalcium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryChloride:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryChromium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryCopper:
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

        case HKQuantityTypeIdentifierDietaryFiber:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryFolate:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryIodine:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryIron:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryMagnesium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryManganese:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryMolybdenum:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryNiacin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryPantothenicAcid:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryPhosphorus:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryPotassium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryProtein:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryRiboflavin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietarySelenium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietarySodium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietarySugar:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryThiamin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminA:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryVitaminB12:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryVitaminB6:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminC:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminD:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryVitaminE:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminK:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryWater:
            return HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryZinc:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return isMetric ? HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo) : HKUnit.mileUnit()

        case HKQuantityTypeIdentifierElectrodermalActivity:
            return HKUnit.siemenUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierFlightsClimbed:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierForcedExpiratoryVolume1:
            return HKUnit.literUnit()

        case HKQuantityTypeIdentifierForcedVitalCapacity:
            return HKUnit.literUnit()

        case HKQuantityTypeIdentifierHeight:
            return isMetric ? HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Centi) : HKUnit.footUnit()

        case HKQuantityTypeIdentifierInhalerUsage:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierLeanBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()

        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())

        case HKQuantityTypeIdentifierNikeFuel:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierNumberOfTimesFallen:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierOxygenSaturation:
            return HKUnit.percentUnit()

        case HKQuantityTypeIdentifierPeakExpiratoryFlowRate:
            return HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())

        case HKQuantityTypeIdentifierPeripheralPerfusionIndex:
            return HKUnit.percentUnit()

        case HKQuantityTypeIdentifierRespiratoryRate:
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

    // Units used by the MC webservice.
    public var serviceUnit: HKUnit? {
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return HKUnit.secondUnit()

        case HKCategoryTypeIdentifierAppleStandHour:
            return HKUnit.secondUnit()

        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierBasalBodyTemperature:
            return HKUnit.degreeFahrenheitUnit()

        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return HKUnit.kilocalorieUnit()

        case HKQuantityTypeIdentifierBloodAlcoholContent:
            return HKUnit.percentUnit()

        case HKQuantityTypeIdentifierBloodGlucose:
            return HKUnit.gramUnitWithMetricPrefix(.Milli).unitDividedByUnit(HKUnit.literUnitWithMetricPrefix(.Deci))

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return HKUnit.millimeterOfMercuryUnit()

        case HKQuantityTypeIdentifierBodyFatPercentage:
            return HKUnit.percentUnit()

        case HKQuantityTypeIdentifierBodyMass:
            return HKUnit.gramUnitWithMetricPrefix(.Kilo)

        case HKQuantityTypeIdentifierBodyMassIndex:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierBodyTemperature:
            return HKUnit.degreeFahrenheitUnit()

        case HKQuantityTypeIdentifierDietaryBiotin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryCalcium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryChloride:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryChromium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryCopper:
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

        case HKQuantityTypeIdentifierDietaryFiber:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryFolate:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryIodine:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryIron:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryMagnesium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryManganese:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryMolybdenum:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryNiacin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryPantothenicAcid:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryPhosphorus:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryPotassium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryProtein:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryRiboflavin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietarySelenium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietarySodium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietarySugar:
            return HKUnit.gramUnit()

        case HKQuantityTypeIdentifierDietaryThiamin:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminA:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryVitaminB12:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryVitaminB6:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminC:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminD:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryVitaminE:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryVitaminK:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierDietaryWater:
            return HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDietaryZinc:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return HKUnit.meterUnit()

        case HKQuantityTypeIdentifierElectrodermalActivity:
            return HKUnit.siemenUnitWithMetricPrefix(HKMetricPrefix.Micro)

        case HKQuantityTypeIdentifierFlightsClimbed:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierForcedExpiratoryVolume1:
            return HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierForcedVitalCapacity:
            return HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli)

        case HKQuantityTypeIdentifierHeight:
            return HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Centi)

        case HKQuantityTypeIdentifierInhalerUsage:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierLeanBodyMass:
            return HKUnit.gramUnitWithMetricPrefix(.Kilo)

        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())

        case HKQuantityTypeIdentifierNikeFuel:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierNumberOfTimesFallen:
            return HKUnit.countUnit()

        case HKQuantityTypeIdentifierOxygenSaturation:
            return HKUnit.percentUnit()
            
        case HKQuantityTypeIdentifierPeakExpiratoryFlowRate:
            return HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit())
            
        case HKQuantityTypeIdentifierPeripheralPerfusionIndex:
            return HKUnit.percentUnit()
            
        case HKQuantityTypeIdentifierRespiratoryRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
            
        case HKQuantityTypeIdentifierStepCount:
            return HKUnit.countUnit()
            
        case HKQuantityTypeIdentifierUVExposure:
            return HKUnit.countUnit()
            
        case HKWorkoutTypeIdentifier:
            return HKUnit.secondUnit()
            
        default:
            return nil
        }
    }
}

public extension HKSample {
    public var numeralValue: Double? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType {
        case is HKCategoryType:
            switch sampleType.identifier {
            case HKCategoryTypeIdentifierSleepAnalysis:
                let sample = (self as! HKCategorySample)
                let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.endDate.timeIntervalSinceDate(sample.startDate))
                return secs.doubleValueForUnit(defaultUnit!)
            default:
                return nil
            }

        case is HKCorrelationType:
            switch sampleType.identifier {
            case HKCorrelationTypeIdentifierBloodPressure:
                return ((self as! HKCorrelation).objects.first as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
            default:
                return nil
            }

        case is HKWorkoutType:
            let sample = (self as! HKWorkout)
            let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.duration)
            return secs.doubleValueForUnit(defaultUnit!)

        case is HKQuantityType:
            return (self as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)

        default:
            return nil
        }
    }

    public var defaultUnit: HKUnit? { return sampleType.defaultUnit }

    public var hkType: HKSampleType? { return sampleType }
}

// Readable type description.
public extension HKSampleType {
    public var displayText: String? {
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "HealthKit data type")

        case HKCategoryTypeIdentifierAppleStandHour:
            return NSLocalizedString("Hours Standing", comment: "HealthKit data type")

        case HKCharacteristicTypeIdentifierBloodType:
            return NSLocalizedString("Blood Type", comment: "HealthKit data type")

        case HKCharacteristicTypeIdentifierBiologicalSex:
            return NSLocalizedString("Gender", comment: "HealthKit data type")

        case HKCharacteristicTypeIdentifierFitzpatrickSkinType:
            return NSLocalizedString("Skin Type", comment: "HealthKit data type")

        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood Pressure", comment: "HealthKit data type")

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
            return NSLocalizedString("Heart Rate", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Step Count", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV Exposure", comment: "HealthKit data type")

        case HKWorkoutTypeIdentifier:
            return NSLocalizedString("Workouts/Meals", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBasalBodyTemperature:
            return NSLocalizedString("Basal Body Temperature", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBloodAlcoholContent:
            return NSLocalizedString("Blood Alcohol", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBodyFatPercentage:
            return NSLocalizedString("", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierBodyTemperature:
            return NSLocalizedString("Body Temperature", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryBiotin:
            return NSLocalizedString("Biotin", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryCalcium:
            return NSLocalizedString("Calcium", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryChloride:
            return NSLocalizedString("Chloride", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryChromium:
            return NSLocalizedString("Chromium", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryCopper:
            return NSLocalizedString("Copper", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryFiber:
            return NSLocalizedString("Fiber", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryFolate:
            return NSLocalizedString("Folate", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryIodine:
            return NSLocalizedString("Iodine", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryIron:
            return NSLocalizedString("Iron", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryMagnesium:
            return NSLocalizedString("Magnesium", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryManganese:
            return NSLocalizedString("Manganese", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryMolybdenum:
            return NSLocalizedString("Molybdenum", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryNiacin:
            return NSLocalizedString("Niacin", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryPantothenicAcid:
            return NSLocalizedString("Pantothenic Acid", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryPhosphorus:
            return NSLocalizedString("Phosphorus", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryPotassium:
            return NSLocalizedString("Potassium", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryRiboflavin:
            return NSLocalizedString("Riboflavin", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietarySelenium:
            return NSLocalizedString("Selenium", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryThiamin:
            return NSLocalizedString("Thiamin", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminA:
            return NSLocalizedString("Vitamin A", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminB12:
            return NSLocalizedString("Vitamin B12", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminB6:
            return NSLocalizedString("Vitamin B6", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminC:
            return NSLocalizedString("Vitamin C", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminD:
            return NSLocalizedString("Vitamin D", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminE:
            return NSLocalizedString("Vitamin E", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryVitaminK:
            return NSLocalizedString("Vitamin K", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierDietaryZinc:
            return NSLocalizedString("Zinc", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierElectrodermalActivity:
            return NSLocalizedString("Electrodermal Activity", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierForcedExpiratoryVolume1:
            return NSLocalizedString("FEV1", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierForcedVitalCapacity:
            return NSLocalizedString("FVC", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierHeight:
            return NSLocalizedString("Height", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierInhalerUsage:
            return NSLocalizedString("Inhaler Usage", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierLeanBodyMass:
            return NSLocalizedString("Lean Body Mass", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierNikeFuel:
            return NSLocalizedString("Nike Fuel", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierNumberOfTimesFallen:
            return NSLocalizedString("Times Fallen", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierOxygenSaturation:
            return NSLocalizedString("Blood Oxygen Saturation", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierPeakExpiratoryFlowRate:
            return NSLocalizedString("PEF", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierPeripheralPerfusionIndex:
            return NSLocalizedString("PPI", comment: "HealthKit data type")

        case HKQuantityTypeIdentifierRespiratoryRate:
            return NSLocalizedString("RR", comment: "HealthKit data type")

        default:
            return nil
        }
    }
}
