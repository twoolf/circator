//
//  DataGenerator.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import Async
import SORandom
import SwiftDate
import FileKit
import SwiftyJSON

public typealias MCSampler = (NSDate, Double, Double?) -> HKSample?

private let filteredTypeIdentifiers = [HKQuantityTypeIdentifierUVExposure, HKQuantityTypeIdentifierDietaryWater, HKCategoryTypeIdentifierSleepAnalysis]

public class DataGenerator : GeneratorType {

    public static let sharedInstance = DataGenerator()

    let generatorTypes : [HKSampleType] = Array(PreviewManager.previewChoices.flatten()).filter { t in
        return !filteredTypeIdentifiers.contains(t.identifier)
    }

    let generatorUnits : [String: HKUnit] = [
        HKCategoryTypeIdentifierSleepAnalysis             : HKUnit.hourUnit(),
        HKCategoryTypeIdentifierAppleStandHour            : HKUnit.hourUnit(),
        HKQuantityTypeIdentifierActiveEnergyBurned        : HKUnit.kilocalorieUnit(),
        HKQuantityTypeIdentifierBodyMass                  : HKUnit.poundUnit(),
        HKQuantityTypeIdentifierBodyMassIndex             : HKUnit.countUnit(),
        HKQuantityTypeIdentifierBloodPressureDiastolic    : HKUnit.millimeterOfMercuryUnit(),
        HKQuantityTypeIdentifierBloodPressureSystolic     : HKUnit.millimeterOfMercuryUnit(),
        HKQuantityTypeIdentifierDietaryCaffeine           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCarbohydrates      : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCholesterol        : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryEnergyConsumed     : HKUnit.kilocalorieUnit(),
        HKQuantityTypeIdentifierDietaryFatMonounsaturated : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryFatSaturated       : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryFatTotal           : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryProtein            : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietarySugar              : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietarySodium             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryWater              : HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierHeartRate                 : HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()),
        HKQuantityTypeIdentifierStepCount                 : HKUnit.countUnit(),
        HKQuantityTypeIdentifierUVExposure                : HKUnit.countUnit()
    ]

    let parameters : [Bool: [String: (Double, Double)]] = [
        true: [
            HKCategoryTypeIdentifierSleepAnalysis             : (6.5,    1.83),
            HKCategoryTypeIdentifierAppleStandHour            : (4.0,    1.0),
            HKQuantityTypeIdentifierActiveEnergyBurned        : (2750.0, 750.0),
            HKQuantityTypeIdentifierBodyMass                  : (215.0,  41.67),
            HKQuantityTypeIdentifierBodyMassIndex             : (25,     5.0),
            HKQuantityTypeIdentifierBloodPressureDiastolic    : (80.0,   10.0),
            HKQuantityTypeIdentifierBloodPressureSystolic     : (120.0,  13.33),
            HKQuantityTypeIdentifierDietaryCaffeine           : (166.4,  55.467),
            HKQuantityTypeIdentifierDietaryCarbohydrates      : (327.0,  69.9),
            HKQuantityTypeIdentifierDietaryCholesterol        : (352.0,  107.147),
            HKQuantityTypeIdentifierDietaryEnergyConsumed     : (2757.0, 526.6),
            HKQuantityTypeIdentifierDietaryFatMonounsaturated : (36.9,   8.493),
            HKQuantityTypeIdentifierDietaryFatPolyunsaturated : (24.3,   6.01),
            HKQuantityTypeIdentifierDietaryFatSaturated       : (33.4,   9.147),
            HKQuantityTypeIdentifierDietaryFatTotal           : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryProtein            : (88.3,   22.2),
            HKQuantityTypeIdentifierDietarySugar              : (143.3,  47.03),
            HKQuantityTypeIdentifierDietarySodium             : (4560.7, 988.493),
            HKQuantityTypeIdentifierDietaryWater              : (5.0,    1.67),
            HKQuantityTypeIdentifierHeartRate                 : (80.0,   13.33),
            HKQuantityTypeIdentifierStepCount                 : (6000.0, 1996.67),
            HKQuantityTypeIdentifierUVExposure                : (6.0,    1.0)
        ],

        false: [
            HKCategoryTypeIdentifierSleepAnalysis             : (6.5,    1.83),
            HKCategoryTypeIdentifierAppleStandHour            : (4.0,    1.0),
            HKQuantityTypeIdentifierActiveEnergyBurned        : (2750.0, 750.0),
            HKQuantityTypeIdentifierBodyMass                  : (215.0,  41.67),
            HKQuantityTypeIdentifierBodyMassIndex             : (25,     5.0),
            HKQuantityTypeIdentifierBloodPressureDiastolic    : (80.0,   10.0),
            HKQuantityTypeIdentifierBloodPressureSystolic     : (120.0,  13.33),
            HKQuantityTypeIdentifierDietaryCaffeine           : (142.7,  47.567),
            HKQuantityTypeIdentifierDietaryCarbohydrates      : (246.3,  43.13),
            HKQuantityTypeIdentifierDietaryCholesterol        : (235.7,  78.57),
            HKQuantityTypeIdentifierDietaryEnergyConsumed     : (1957.0, 315.67),
            HKQuantityTypeIdentifierDietaryFatMonounsaturated : (25.7,   5.1),
            HKQuantityTypeIdentifierDietaryFatPolyunsaturated : (17.4,   3.533),
            HKQuantityTypeIdentifierDietaryFatSaturated       : (23.9,   5.227),
            HKQuantityTypeIdentifierDietaryFatTotal           : (73.1,   13.0),
            HKQuantityTypeIdentifierDietaryProtein            : (71.3,   12.03),
            HKQuantityTypeIdentifierDietarySugar              : (112.0,  28.73),
            HKQuantityTypeIdentifierDietarySodium             : (3187.3, 557.93),
            HKQuantityTypeIdentifierDietaryWater              : (4.7,    1.567),
            HKQuantityTypeIdentifierHeartRate                 : (80.0,   13.33),
            HKQuantityTypeIdentifierStepCount                 : (6000.0, 1996.67),
            HKQuantityTypeIdentifierUVExposure                : (6.0,    1.0)
        ]
    ]

    // 2hr blocks through a day, represented as seconds.
    let timeBlocksInSecs = 0.0.stride(through: 22.0, by: 2.0).map { x in return x * 3600.0 }

    // Probabilities of event occurring in a 2 hour block, e.g., 0-2AM, 2-4AM, etc. We assume uniformity within the block
    let defaultEventTimeDistribution = [0.03, 0.01, 0.01, 0.12, 0.12, 0.11, 0.11, 0.11, 0.12, 0.12, 0.11, 0.03]

    // Type-specific event distributions, e.g., start of sleep is inverted from the above.
    let eventTimeDistributions : [Bool: [String: [Double]]] = [
        true: [
            HKCategoryTypeIdentifierSleepAnalysis : [0.2, 0.1, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.1, 0.5]
        ],
        false: [
            HKCategoryTypeIdentifierSleepAnalysis : [0.2, 0.1, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.1, 0.5]
        ]
    ]

    // Point and bulk generation API.

    func sampleDailyTimestampsWithWeights(date: NSDate, weights: [Double], count: Int) -> [NSDate] {
        let ts = sampleWithWeights(timeBlocksInSecs, weights, count)
        let offsetInBlock = randContUniforms(0.0, 7200.0, count)
        return zip(ts, offsetInBlock).map { (t,o) in return date + Int(ceil(t + o)).seconds }
    }

    func sampleDailyTimestamps(date: NSDate, count: Int) -> [NSDate] {
        return sampleDailyTimestampsWithWeights(date, weights: defaultEventTimeDistribution, count: count)
    }

    public func generatorForType(type: HKSampleType, count: Int, asMale: Bool = true, date: NSDate, completion: MCSampler) -> [HKSample] {
        switch type.identifier
        {
        case HKCategoryTypeIdentifierSleepAnalysis:
            let params = parameters[asMale]![type.identifier]!
            let tparams = eventTimeDistributions[asMale]![type.identifier]!
            let ts = sampleDailyTimestampsWithWeights(date, weights: tparams, count: count)
            return zip(ts, randNormals(params.0, params.1, count)).flatMap { (t,x) in return completion(t, x, nil) }

        case HKCategoryTypeIdentifierAppleStandHour:
            let params = parameters[asMale]![type.identifier]!
            let ts = sampleDailyTimestamps(date, count: count)
            return zip(ts, randNormals(params.0, params.1, count)).flatMap { (t,x) in return completion(t, x, nil) }

        case HKCorrelationTypeIdentifierBloodPressure:
            let ts = sampleDailyTimestamps(date, count: count)
            let dp = parameters[asMale]![HKQuantityTypeIdentifierBloodPressureDiastolic]!
            let sp = parameters[asMale]![HKQuantityTypeIdentifierBloodPressureSystolic]!

            let dv : [Double] = randNormals(dp.0, dp.1, count)
            let sv : [Double] = randNormals(sp.0, sp.1, count)
            return zip(ts, zip(dv, sv)).flatMap { (t,ds) in return completion(t, ds.0, ds.1) }

        default:
            let tparams = eventTimeDistributions[asMale]![type.identifier] ?? defaultEventTimeDistribution
            let ts = sampleDailyTimestampsWithWeights(date, weights: tparams, count: count)

            if let params = parameters[asMale]![type.identifier] {
                return zip(ts, randNormals(params.0, params.1, count)).flatMap { (t,x) in return completion(t, x, nil) }
            }
            return []
        }
    }

    func nextSample(type: HKSampleType, asMale: Bool = true, date: NSDate, x: Double, y: Double?) -> HKSample? {
        switch type.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            let ct = type as! HKCategoryType
            let sleepStart = date
            let sleepEnd = sleepStart + Int(abs(x) * 3600.0).seconds
            return HKCategorySample(type: ct, value: HKCategoryValueSleepAnalysis.Asleep.rawValue, startDate: sleepStart, endDate: sleepEnd)

        case HKCategoryTypeIdentifierAppleStandHour:
            let ct = type as! HKCategoryType
            let standStart = date
            let standEnd = standStart + Int(abs(x) * 60.0).seconds
            return HKCategorySample(type: ct, value: HKCategoryValueAppleStandHour.Stood.rawValue, startDate: standStart, endDate: standEnd)

            // TODO: ensure diastolic is less than systolic
        case HKCorrelationTypeIdentifierBloodPressure:
            let du = self.generatorUnits[HKQuantityTypeIdentifierBloodPressureDiastolic]!
            let su = self.generatorUnits[HKQuantityTypeIdentifierBloodPressureSystolic]!

            let ct = type as! HKCorrelationType
            let dt = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!
            let st = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!
            let ds = HKQuantitySample(type: dt, quantity: HKQuantity(unit: du, doubleValue: x), startDate: date, endDate: date)
            let ss = HKQuantitySample(type: st, quantity: HKQuantity(unit: su, doubleValue: y!), startDate: date, endDate: date)
            let objs : Set = [ds,ss]
            return HKCorrelation(type: ct, startDate: date, endDate: date, objects: objs)

        default:
            if let u = self.generatorUnits[type.identifier] {
                let qt = type as! HKQuantityType
                let q = HKQuantity(unit: u, doubleValue: x)
                return HKQuantitySample(type: qt, quantity: q, startDate: date, endDate: date)
            }
            return nil
        }
    }

    public func generateManyForType(type: HKSampleType, count: Int, asMale: Bool = true, date: NSDate) -> [HKSample] {
        return generatorForType(type, count: count, asMale: asMale, date: date) { (d,x,y) in
            return self.nextSample(type, asMale: asMale, date: d, x: x, y: y)
        }
    }

    public func generateForType(type: HKSampleType, asMale: Bool = true, date: NSDate) -> HKSample? {
        if let params = parameters[asMale]![type.identifier] {
            let x = randNormal(params.0, params.1)
            return nextSample(type, asMale: asMale, date: date, x: x, y: nil)
        }
        return nil
    }

    // Stream/Generator API
    // This returns a set of HealthKit samples per day.
    // Callers must set the 'currentDay' and 'samplesPerDay' parameters appropriately.

    public typealias Element = [HKSample]

    var currentDay : NSDate! = NSDate()

    var samplesPerDay = 10
    var sampleBuffer : [Bool: [String: [HKSample]]] = [true: [:], false: [:]]

    // Generate samples for the next day.
    public func next() -> Element?
    {
        let sleepWeight = 0.99999
        let sleepOrOther = randBinomial(sleepWeight) > 0 ? [HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!] : []

        let maleOrFemale : [Int] = coinTosses(samplesPerDay)
        let typesToSample : [HKSampleType] = sampleWithReplacement(generatorTypes, sleepOrOther.isEmpty ? samplesPerDay : samplesPerDay-1) + sleepOrOther

        let z : [HKSample] = []
        return zip(maleOrFemale, typesToSample).reduce(z, combine: { (var acc, mt) in
            if let s = sampleBuffer[mt.0 > 0]?[mt.1.identifier]?.popLast() {
                let ddiff = Int(floor(currentDay.timeIntervalSinceDate(s.startDate) / 86400)).days
                let ns = ddiff.fromDate(s.startDate)
                let ne = ddiff.fromDate(s.endDate)

                switch s {
                case is HKCategorySample:
                    let cs = s as! HKCategorySample
                    acc.append(HKCategorySample(type: cs.categoryType, value: cs.value, startDate: ns, endDate: ne))

                case is HKCorrelation:
                    let cs = s as! HKCorrelation
                    acc.append(HKCorrelation(type: cs.correlationType, startDate: ns, endDate: ne, objects: cs.objects))

                case is HKQuantitySample:
                    let qs = s as! HKQuantitySample
                    acc.append(HKQuantitySample(type: qs.quantityType, quantity: qs.quantity, startDate: ns, endDate: ne))

                default:
                    acc.append(s)
                }

                return acc

            } else {
                var newSamples = generateManyForType(mt.1, count: samplesPerDay, asMale: mt.0 > 0, date: currentDay)
                if let r = newSamples.popLast() { acc.append(r) }
                sampleBuffer[mt.0 > 0]![mt.1.identifier] = newSamples
                return acc
            }
        })
    }

    // Dataset generation.
    private var samplesSkipped = 0
    private var daysSkipped = 0

    func writeSample(handle: NSFileHandle, sample: HKSample, asFirst: Bool) {
        do {
            let js = try JSON(HealthManager.serializer.dictForSample(sample))
            if let jsstr = js.rawString(),
                   jsdata = ((asFirst ? "" : ",") + jsstr).dataUsingEncoding(NSUTF8StringEncoding)
            {
                handle.writeData(jsdata)
            } else {
                ++samplesSkipped
            }
        } catch {
            log.error(error)
        }
    }

    private func generateDataset(path: String, users: [String], size: Int, startDate: NSDate, endDate: NSDate) {
        let startDateDay = startDate.startOf(.Day, inRegion: Region())
        let days = Int(ceil(endDate.timeIntervalSinceDate(startDate)) / 86400.0)

        samplesPerDay = size / days
        samplesSkipped = 0
        daysSkipped = 0

        let output = TextFile(path: Path.UserHome + "Documents/" + path)

        do {
            if output.exists { try output.delete() }
            try output.create()

            let gpreamble  = "{ users: [".dataUsingEncoding(NSUTF8StringEncoding)!
            let gpostamble = "]}".dataUsingEncoding(NSUTF8StringEncoding)!
            var firstUser = true

            if let outhndl = output.handleForWriting {
                outhndl.writeData(gpreamble)
                users.forEach { userId in
                    log.info("Generating dataset for \(userId)")

                    let upreamble = ((firstUser ? "" : ",") + "{ \"id\": \"\(userId)\", \"samples\": [").dataUsingEncoding(NSUTF8StringEncoding)!
                    let upostamble = "]}".dataUsingEncoding(NSUTF8StringEncoding)!

                    firstUser = false

                    outhndl.writeData(upreamble)
                    (0..<days).forEach { i in
                        autoreleasepool { _ in
                            currentDay = startDateDay + i.days
                            if let samples : [HKSample] = self.next() {
                                if (i % 10) == 0 { log.info("Writing batch \(i) / \(days),  \(samples.count) samples") }
                                var firstSample = true
                                samples.forEach { s in
                                    writeSample(outhndl, sample: s, asFirst: firstSample)
                                    firstSample = false
                                }
                            } else {
                                ++daysSkipped
                            }
                        }
                    }
                    outhndl.writeData(upostamble)
                }
                outhndl.writeData(gpostamble)

                log.info("Created a HealthKit dataset of size \(output.size! / (1024*1024)) MB at: \(output.path)")
                log.info("Skipped \(samplesSkipped) samples, \(daysSkipped) days")
            } else {
                log.error("Could not write dataset to \(output.path)")
            }
        } catch {
            log.error(error)
        }

    }

    public func generateDatasetForUser(path: String, userId: String, size: Int, startDate: NSDate, endDate: NSDate) {
        generateDataset(path, users: [userId], size: size, startDate: startDate, endDate: endDate)
    }

    private func randomUser(length: Int) -> String {
        let charactersString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let charactersArray = Array(charactersString.characters)

        var string = ""
        for _ in 0..<length {
            string.append(charactersArray[Int(arc4random()) % charactersArray.count])
        }
        
        return string
    }

    public func generateDatasetForService(path: String, numUsers: Int, size: Int, startDate: NSDate, endDate: NSDate) {
        let userIdLen = 20
        let users = (0..<numUsers).map { _ in return randomUser(userIdLen) }
        let sizePerUser = Int(ceil(Double(size) / Double(numUsers)))
        generateDataset(path, users: users, size: sizePerUser, startDate: startDate, endDate: endDate)
    }

}