//
//  SampleFormatter.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCCircadianQueries

/**
 Controls the formatting and presentation style of all metrics.  Getting these units right and controlling their display is important for the user experience.  We use Apple's work with units in HealthKit to enable our population expressions to match up with those values from HealthKit

  -note:
  units and conversions are covered in Apple's HealthKit documentation
 
  -remark: 
  stringFromSamples, stringFromDerivedQuantities, etc are all in this location

 */
public class SampleFormatter: NSObject {

    public static let bodyMassFormatter: MassFormatter = {
        let formatter = MassFormatter()
        formatter.isForPersonMassUse = true
        formatter.unitStyle = .medium
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    public static let foodMassFormatter: MassFormatter = {
        let formatter = MassFormatter()
        formatter.unitStyle = .medium
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    public static let chartDateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    public static let numberFormatter: NumberFormatter = {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    public static let integerFormatter: NumberFormatter = {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public static let calorieFormatter: EnergyFormatter = {
        let formatter = EnergyFormatter()
        formatter.numberFormatter = SampleFormatter.numberFormatter
        formatter.unitStyle = Formatter.UnitStyle.medium
        return formatter
    }()

    public static let timeIntervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
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
        guard !samples.isEmpty else { return Double.nan }
        if let _ = samples as? [HKStatistics] {
            var stat = samples.map { $0 as! HKStatistics }
            return numberFromStatistics(statistics: stat.removeLast())
        } else if let _ = samples as? [HKSample] {
            let hksamples = samples.map { $0 as! HKSample }
            return numberFromHKSamples(samples: hksamples)
        } else {
            return numberFromMCSamples(samples: samples)
        }
    }

    public func stringFromSamples(samples: [MCSample]) -> String {
        guard !samples.isEmpty else { return emptyString }
        if let _ = samples as? [HKStatistics] {
            var stat = samples.map { $0 as! HKStatistics }
            return stringFromStatistics(statistics: stat.removeLast())
        } else if let _ = samples as? [HKSample] {
            let hksamples = samples.map { $0 as! HKSample }
            return stringFromHKSamples(samples: hksamples)
        } else  {
            return stringFromMCSamples(samples: samples)
        }
    }

    public func numberFromStatistics(statistics: HKStatistics) -> Double {
        // Guaranteed to be quantity sample here
        guard let quantity = statistics.quantity else {
            return Double.nan
        }
        return numberFromQuantity(quantity: quantity, type: statistics.quantityType)
    }

    public func stringFromStatistics(statistics: HKStatistics) -> String {
        // Cumulative has sumQuantity Discrete has quantity
        let quantity = statistics.sumQuantity() != nil ? statistics.sumQuantity() : statistics.quantity
        // Guaranteed to be quantity sample here
        guard (quantity != nil) else {
            return emptyString
        }
        return stringFromQuantity(quantity: quantity!, type: statistics.quantityType)
    }

    public func numberFromHKSamples(samples: [HKSample]) -> Double {
        guard !samples.isEmpty else { return Double.nan }
        if let type = samples.last!.sampleType as? HKQuantityType {
            return numberFromQuantity(quantity: (samples.last as! HKQuantitySample).quantity, type: type)
        }
        switch samples.last!.sampleType.identifier {
        case HKWorkoutTypeIdentifier:
            let d = Date(timeIntervalSinceReferenceDate: samples.workoutDuration!)
            return Double(d.hour) + (Double(d.minute) / 60.0)

        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            let d = Date(timeIntervalSinceReferenceDate: samples.sleepDuration!)
            return Double(d.hour) + (Double(d.minute) / 60.0)

        case HKCorrelationTypeIdentifier.bloodPressure.rawValue:
            let correlationSample = samples.first as! HKCorrelation
            let systolicSample = correlationSample.objects(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!).first as? HKQuantitySample
            guard systolicSample != nil else { return Double.nan }
            return systolicSample!.quantity.doubleValue(for: HKUnit.millimeterOfMercury())

        default:
            return Double.nan
        }
    }

    public func stringFromHKSamples(samples: [HKSample]) -> String {
        guard !samples.isEmpty else { return emptyString }
        if let type = samples.last!.sampleType as? HKQuantityType {
            return stringFromQuantity(quantity: (samples.last as! HKQuantitySample).quantity, type: type)
        }
        switch samples.last!.sampleType.identifier {
        case HKWorkoutTypeIdentifier:
            return "\(SampleFormatter.timeIntervalFormatter.string(from: samples.workoutDuration!)!)"

        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return "\(SampleFormatter.timeIntervalFormatter.string(from: samples.sleepDuration!)!)"

        case HKCorrelationTypeIdentifier.bloodPressure.rawValue:
            let correlationSample = samples.first as! HKCorrelation
            let diastolicSample = correlationSample.objects(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!).first as? HKQuantitySample
            let systolicSample = correlationSample.objects(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!).first as? HKQuantitySample
            guard diastolicSample != nil && systolicSample != nil else {
                return emptyString
            }
//            let diastolicNumber = SampleFormatter.integerFormatter.stringFromNumber(NSNumber(diastolicSample!.quantity.doubleValue(for: HKUnit.millimeterOfMercuryUnit())))!
//            let systolicNumber = SampleFormatter.integerFormatter.stringFromNumber(NSNumber(systolicSample!.quantity.doubleValue(for: HKUnit.millimeterOfMercuryUnit())))!
            return "\(systolicSample)/\(diastolicSample)"

        default:
            return emptyString
        }
    }

    private func numberFromMCSamples(samples: [MCSample]) -> Double {
        guard !samples.isEmpty else { return Double.nan }

        if let fst = samples.last {
            if let _ = fst.hkType as? HKQuantityType {
                return numberFromMCSample(sample: fst)
            } else if let quantity = fst.numeralValue, let type = fst.hkType {
                switch type.identifier {
                case HKWorkoutTypeIdentifier,
                     HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                     HKCategoryTypeIdentifier.appleStandHour.rawValue:

                    if let mcunit = type.defaultUnit, let userUnit = UserManager.sharedManager.userUnitsForType(type: type) {
                        return HKQuantity(unit: mcunit, doubleValue: quantity).doubleValue(for: userUnit)
                    }
                    return Double.nan

                default:
                    return Double.nan
                }
            }
        }
        return Double.nan
    }

    private func stringFromMCSamples(samples: [MCSample]) -> String {
        guard !samples.isEmpty else { return emptyString }

        if let fst = samples.last {
            if let qType = fst.hkType as? HKQuantityType {
                if qType.identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue
                    || qType.identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue
                {
                    // Check if we have the complementary blood pressure quantity in the array, and if so,
                    // return the composite string. 
                    let checkId = qType.identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue ?
                        HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue : HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue

                    let matches = samples.filter { $0.hkType?.identifier == checkId }
                    if !matches.isEmpty {
                        let systolicFromMatches = checkId == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue
                        let systolicValue = systolicFromMatches ? matches.last!.numeralValue! : fst.numeralValue!
                        let diastolicValue = systolicFromMatches ? fst.numeralValue! : matches.last!.numeralValue!
//                        let systolicNumber = SampleFormatter.integerFormatter.stringFromNumber(NSNumber(systolicValue))!
//                        let diastolicNumber = SampleFormatter.integerFormatter.stringFromNumber(NSNumber(diastolicValue))!
                        return "\(systolicValue)/\(diastolicValue)"
                    }
                }
                return stringFromMCSample(sample: fst)
            } else if let quantity = fst.numeralValue, let type = fst.hkType {
                switch type.identifier {
                case HKWorkoutTypeIdentifier,
                     HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                     HKCategoryTypeIdentifier.appleStandHour.rawValue:

                    if let unit = type.defaultUnit {
                        let secs = HKQuantity(unit: unit, doubleValue: quantity).doubleValue(for: HKUnit.second())
                        return "\(SampleFormatter.timeIntervalFormatter.string(from: secs)!)"
                    }
                    return emptyString

                default:
                    return emptyString
                }
            }
        }
        return emptyString
    }

    private func numberFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> Double {
        if let userUnit = UserManager.sharedManager.userUnitsForType(type: type) {
            return quantity.doubleValue(for: userUnit)
        }
        return Double.nan
    }

    private func stringFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> String {
        if let userUnit = UserManager.sharedManager.userUnitsForType(type: type) {
            let numericValue = quantity.doubleValue(for: userUnit)
//            return stringFromNumberAndType(numericValue: numericValue, type: type)
            return "fix"
        }
        return emptyString
    }

    private func numberFromMCSample(sample: MCSample) -> Double {
        if let type = sample.hkType, let quantity = sample.numeralValue, let userUnit = UserManager.sharedManager.userUnitsForType(type: type) {
            return HKQuantity(unit: type.defaultUnit!, doubleValue: quantity).doubleValue(for: userUnit)
        }
        return Double.nan
    }

    private func stringFromMCSample(sample: MCSample) -> String {
        if let type = sample.hkType, let quantity = sample.numeralValue, let userUnit = UserManager.sharedManager.userUnitsForType(type: type) {
            let convertedQuantity = HKQuantity(unit: type.defaultUnit!, doubleValue: quantity).doubleValue(for: userUnit)
//            return stringFromNumberAndType(numericValue: convertedQuantity, type: type)
            return "fix"
        }
        return emptyString
    }

/*    private func stringFromNumberAndType(numericValue: Double, type: HKSampleType) -> String {
//        if let fmtnum = SampleFormatter.numberFormatter.stringFromNumber(NSNumber(numericValue)) {
        if let fmtnum = SampleFormatter.numberFormatter.string(from: (NSNumber(numericValue)) {
            switch type.identifier {

            case HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
                 HKCategoryTypeIdentifier.appleStandHour.rawValue,
                 HKWorkoutTypeIdentifier.description:

                return fmtnum + " h"

            case HKQuantityTypeIdentifier.basalBodyTemperature.rawValue,
                 HKQuantityTypeIdentifier.bodyTemperature.rawValue:

                return fmtnum + " F"

            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                 HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
                 HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:

                return fmtnum + " kcal"

            case HKCorrelationTypeIdentifier.bloodPressure.rawValue,
                 HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue,
                 HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:

                return fmtnum + " mmHg"

            case HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
                 HKQuantityTypeIdentifier.stepCount.rawValue,
                 HKQuantityTypeIdentifier.uvExposure.rawValue:
                return fmtnum

            case HKQuantityTypeIdentifier.dietaryBiotin.rawValue,
                 HKQuantityTypeIdentifier.dietaryChromium.rawValue,
                 HKQuantityTypeIdentifier.dietaryFolate.rawValue,
                 HKQuantityTypeIdentifier.dietaryIodine.rawValue,
                 HKQuantityTypeIdentifier.dietaryMolybdenum.rawValue,
                 HKQuantityTypeIdentifier.dietarySelenium.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminA.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminB12.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminD.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminK.rawValue:

                 return fmtnum + " mcg"

            case HKQuantityTypeIdentifier.dietaryCaffeine.rawValue,
                 HKQuantityTypeIdentifier.dietaryCalcium.rawValue,
                 HKQuantityTypeIdentifier.dietaryCholesterol.rawValue,
                 HKQuantityTypeIdentifier.dietaryChloride.rawValue,
                 HKQuantityTypeIdentifier.dietaryCopper.rawValue,
                 HKQuantityTypeIdentifier.dietaryIron.rawValue,
                 HKQuantityTypeIdentifier.dietaryMagnesium.rawValue,
                 HKQuantityTypeIdentifier.dietaryManganese.rawValue,
                 HKQuantityTypeIdentifier.dietaryNiacin.rawValue,
                 HKQuantityTypeIdentifier.dietaryPantothenicAcid.rawValue,
                 HKQuantityTypeIdentifier.dietaryPhosphorus.rawValue,
                 HKQuantityTypeIdentifier.dietaryPotassium.rawValue,
                 HKQuantityTypeIdentifier.dietaryRiboflavin.rawValue,
                 HKQuantityTypeIdentifier.dietarySodium.rawValue,
                 HKQuantityTypeIdentifier.dietaryThiamin.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminB6.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminC.rawValue,
                 HKQuantityTypeIdentifier.dietaryVitaminE.rawValue,
                 HKQuantityTypeIdentifier.dietaryZinc.rawValue:

                return fmtnum + " mg"

            case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue,
                 HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue,
                 HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue,
                 HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue,
                 HKQuantityTypeIdentifier.dietaryFatTotal.rawValue,
                 HKQuantityTypeIdentifier.dietaryFiber.rawValue,
                 HKQuantityTypeIdentifier.dietaryProtein.rawValue,
                 HKQuantityTypeIdentifier.dietarySugar.rawValue:

                return fmtnum + " g"

            case HKQuantityTypeIdentifier.dietaryWater.rawValue:
                return fmtnum + " ml"

            case HKQuantityTypeIdentifier.bloodAlcoholContent.rawValue,
                 HKQuantityTypeIdentifier.bodyFatPercentage.rawValue,
                 HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
                 HKQuantityTypeIdentifier.peripheralPerfusionIndex.rawValue:

                return fmtnum + " %"

            case HKQuantityTypeIdentifier.flightsClimbed.rawValue,
                 HKQuantityTypeIdentifier.inhalerUsage.rawValue,
                 HKQuantityTypeIdentifier.nikeFuel.rawValue,
                 HKQuantityTypeIdentifier.numberOfTimesFallen.rawValue,
                 HKQuantityTypeIdentifier.stepCount.rawValue,
                 HKQuantityTypeIdentifier.uvExposure.rawValue:
                
                return fmtnum

            case HKQuantityTypeIdentifier.electrodermalActivity.rawValue:
                return fmtnum + " mcS"

            case HKQuantityTypeIdentifier.forcedExpiratoryVolume1.rawValue,
                 HKQuantityTypeIdentifier.forcedVitalCapacity.rawValue:

                return fmtnum + " L"

            case HKQuantityTypeIdentifier.peakExpiratoryFlowRate.rawValue:
                return fmtnum + " L/min"

            case HKQuantityTypeIdentifier.bloodGlucose.rawValue:
                return fmtnum + " mg/dL"

            case HKQuantityTypeIdentifier.heartRate.rawValue:
                return fmtnum + " bpm"

            case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
                return fmtnum + " brpm"

            case HKQuantityTypeIdentifier.bodyMassIndex.rawValue:
                return fmtnum + " kg/m2"

            case HKQuantityTypeIdentifier.bodyMass.rawValue,
                 HKQuantityTypeIdentifier.leanBodyMass.rawValue,
                 HKQuantityTypeIdentifier.height.rawValue,
                 HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:

                if let userUnit = UserManager.sharedManager.userUnitsForType(type: type) {
                    return fmtnum + " " + userUnit.unitString
                }
                return emptyString

            default:
                return emptyString
            }
        }
        return emptyString
    } */
}

public class MetricSuffixFormatter: NSObject {
    public static let sharedInstance = MetricSuffixFormatter()

    let buckets: [(Double, String)] = [
        (1e3,  "k"),
        (1e6,  "M"),
        (1e9,  "G"),
        (1e12, "T"),
        (1e15, "P"),
        (1e18, "E")
    ]

    public func formatDouble(i: Double) -> String {
        var entry: (Double, String)! = nil
        for j in 0..<buckets.count {
            if i < buckets[j].0 {
                break
            }
            entry = buckets[j]
        }

        if entry == nil {
            return String(format: "%.3g", i)
        } else {
            return "\(String(format: "%.3g", i / entry.0))\(entry.1)"
        }
    }

    public func formatCGFloat(i: CGFloat) -> String {
        return self.formatDouble(i: Double(i))
    }

    public func formatFloat(i: Float) -> String {
        return self.formatDouble(i: Double(i))
    }

    public func formatInt(i: Int) -> String {
        return self.formatDouble(i: Double(i))
    }
}
