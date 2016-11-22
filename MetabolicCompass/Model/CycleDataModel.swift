//
//  CycleDataModel.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 11/18/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Charts
import SwiftDate

// Accumulator:
// i. boolean indicating whether the current endpoint starts an interval.
// ii. the previous event timestamp.
// iii. a disjoint window dictionary of the max count, the total AUC and the number of level changes.
public typealias CycleWindows = [NSDate: [(Int, Double, Int)]]
public typealias CycleAccum = (Bool, NSDate!, CycleWindows)

public class CycleDataModel : NSObject {

    public var cycleSegments : [(NSDate, ChartDataEntry)] = []
    public var cycleColors: [NSUIColor] = []

    // Window size in seconds.
    public let cycleWindowSize: Int = 900

    public var measureSegments: [HKSampleType: [(NSDate, ChartDataEntry)]] = [:]
    public var measureColors: [HKSampleType: [NSUIColor]] = [:]

    public var segmentIndex = 0

    public func updateData(completion: NSError? -> Void) {
        let end = NSDate().endOf(.Day)
        let start = (end - 1.months).startOf(.Day)

        var someError: [NSError?] = []
        let group = dispatch_group_create()

        let initAcc: CycleAccum = (true, nil, [:])
        let finalizer: CycleAccum -> CycleWindows = { $0.2 }

        let initWinAcc = [(0, 0.0, 0), (0, 0.0, 0), (0, 0.0, 0)]

        let eventIndex: CircadianEvent -> Int = { e in
            switch e {
            case .Sleep:
                return 0
            case .Meal(_):
                return 1
            case .Exercise(_):
                return 2
            default:
                return -1
            }
        }

        let activityAggregator : (CycleAccum, (NSDate, CircadianEvent)) -> CycleAccum = { (acc, e) in
            var (startOfInterval, eStart, windows) = acc
            if !startOfInterval && eStart != nil {
                let evtIndex = eventIndex(e.1)

                if evtIndex >= 0 {
                    // Loop over windows spanned by the event, adding the contribution of the event to each window.
                    var eWindow = floorDate(eStart, granularity: Double(self.cycleWindowSize))
                    var firstStep = true

                    while eWindow < e.0 {
                        let st = firstStep ? eStart : eWindow
                        let nextWindow = eWindow + self.cycleWindowSize.seconds
                        let length = nextWindow < end ? nextWindow.timeIntervalSinceDate(st) : end.timeIntervalSinceDate(st)

                        let groupIndex = start + eWindow.hour.hours + eWindow.minute.minutes + eWindow.second.seconds

                        var windowAcc: [(Int, Double, Int)]! = windows[groupIndex]
                        if windowAcc != nil {
                            let (rmax, rsum, rcnt) = windowAcc[evtIndex]
                            windowAcc[evtIndex] = (max(rmax, rcnt + 1), rsum + length, rcnt + 1)
                        } else {
                            windowAcc = initWinAcc
                            windowAcc[evtIndex] = (1, length, 1)
                        }
                        windows.updateValue(windowAcc, forKey: groupIndex)

                        eWindow = eWindow + self.cycleWindowSize.seconds
                        firstStep = false
                    }
                }
            }
            return (!startOfInterval, e.0, windows)
        }

        dispatch_group_enter(group)
        MCHealthManager.sharedManager.fetchAggregatedCircadianEvents(
            start, endDate: end, aggregator: activityAggregator, initialAccum: initAcc, initialResult: [:], final: finalizer)
        {
            (result, error) in
            guard error == nil else {
                log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            
            self.refreshChartActivityEntries(start, endDate: end, windows: result)
            dispatch_group_leave(group)
        }

        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: end, options: .None)
        let interval = NSDateComponents()
        interval.minute = 15

        dispatch_group_enter(group)
        let hrType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        let hrQuery = HKStatisticsCollectionQuery(quantityType: hrType, quantitySamplePredicate: predicate, options: .DiscreteAverage, anchorDate: start, intervalComponents: interval)

        hrQuery.initialResultsHandler = { query, results, error in
            guard error == nil else {
                log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            self.refreshChartMeasureEntries(start, endDate: end, sampleType: hrType, statistics: results?.statistics() ?? [])
            dispatch_group_leave(group)
        }
        MCHealthManager.sharedManager.healthKitStore.executeQuery(hrQuery)

        dispatch_group_enter(group)
        let scType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        let scQuery = HKStatisticsCollectionQuery(quantityType: scType, quantitySamplePredicate: predicate, options: .CumulativeSum, anchorDate: start, intervalComponents: interval)

        scQuery.initialResultsHandler = { query, results, error in
            guard error == nil else {
                log.error(error)
                someError.append(error)
                dispatch_group_leave(group)
                return
            }
            self.refreshChartMeasureEntries(start, endDate: end, sampleType: scType, statistics: results?.statistics() ?? [])
            dispatch_group_leave(group)
        }
        MCHealthManager.sharedManager.healthKitStore.executeQuery(scQuery)
        

        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            guard someError.count == 0 else {
                completion(someError[0])
                return
            }
            completion(nil)
        }

    }

    // Create colors by composing each event type color component, normalized to window length * max count
    func refreshChartActivityEntries(startDate: NSDate, endDate: NSDate, windows: CycleWindows) {
        let secsPerDay = Double(24 * 60 * 60)
        let maxCounts = windows.reduce([1, 1, 1], combine: { acc in acc.0.enumerate().map { max($0.1, acc.1.1[$0.0].2) } }).map { CGFloat($0) }

        var i = 0
        var t = startDate
        let end = startDate + 24.hours

        cycleSegments = []
        cycleColors = []

        let colorComponents: UIColor -> [CGFloat] = { color in
            var red : CGFloat = 0.0
            var green : CGFloat = 0.0
            var blue : CGFloat = 0.0
            var alpha : CGFloat = 0.0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [red, green, blue, alpha]
        }

        // Returns the component scaled by a logistic function applied to the factor
        let colorFactor: CGFloat -> CGFloat = { factor in
            return 0.08 + (0.92 / (1 + exp(-8 * (factor - 0.4))))
        }

        let activityComponents = [colorComponents(MetabolicDailyProgressChartView.eatingColor),
                                  colorComponents(MetabolicDailyProgressChartView.sleepColor),
                                  colorComponents(MetabolicDailyProgressChartView.exerciseColor)]

        while t < end {
            var entryData: [Int]? = nil
            if let windowAcc = windows[t] {
                let (_, sr, cr) = windowAcc[1]
                let (_, sg, cg) = windowAcc[2]
                let (_, sb, cb) = windowAcc[0]

                let ef = cr <= 0 ? 0.0 : CGFloat(sr) / (CGFloat(self.cycleWindowSize) * maxCounts[1])
                let xf = cg <= 0 ? 0.0 : CGFloat(sg) / (CGFloat(self.cycleWindowSize) * maxCounts[2])
                let sf = cb <= 0 ? 0.0 : CGFloat(sb) / (CGFloat(self.cycleWindowSize) * maxCounts[0])

                let lef = colorFactor(ef)
                let lxf = colorFactor(xf)
                let lsf = colorFactor(sf)

                let scaleColors = zip([lef, lsf, lxf], activityComponents)

                let r = scaleColors.reduce(0.0, combine: { max($0, $1.0 * $1.1[0]) })
                let g = scaleColors.reduce(0.0, combine: { max($0, $1.0 * $1.1[1]) })
                let b = scaleColors.reduce(0.0, combine: { max($0, $1.0 * $1.1[2]) })

                let wColor = NSUIColor(red: r, green: g, blue: b, alpha: 1.0)
                cycleColors.append(wColor)

                entryData = [cb, cr, cg]

            } else {
                cycleColors.append(MetabolicDailyProgressChartView.fastingColor)
            }

            cycleSegments.append((t, ChartDataEntry(value: Double(self.cycleWindowSize) / secsPerDay, xIndex: i, data: entryData)))

            i += 1
            t = t + self.cycleWindowSize.seconds
        }
    }

    func refreshChartMeasureEntries(startDate: NSDate, endDate: NSDate, sampleType: HKSampleType, statistics: [HKStatistics]) {
        let secsPerDay = Double(24 * 60 * 60)
        var windows: [NSDate: Double] = [:]
        var minMeasure: Double = 1000.0
        var maxMeasure: Double = 0.0

        statistics.forEach { stats in
            let groupIndex = startDate + stats.startDate.hour.hours + stats.startDate.minute.minutes + stats.startDate.second.seconds

            let measure = (sampleType.aggregationOptions == .CumulativeSum ?
                stats.sumQuantity()?.doubleValueForUnit(sampleType.defaultUnit!)
                : stats.averageQuantity()?.doubleValueForUnit(sampleType.defaultUnit!)) ?? 0.0

            minMeasure = min(minMeasure, measure)
            maxMeasure = max(maxMeasure, measure)

            if let windowAcc = windows[groupIndex] {
                windows.updateValue(max(windowAcc, measure), forKey: groupIndex)
            } else {
                windows.updateValue(measure, forKey: groupIndex)
            }
        }

        minMeasure = min(minMeasure, maxMeasure)
        let measureRange = maxMeasure - minMeasure

        var i = 0
        var j = 0
        var t = startDate
        let end = startDate + 24.hours

        measureSegments[sampleType] = []
        measureColors[sampleType] = []

        while t < end {
            var entryData: Double? = nil
            if let windowAcc = windows[t] {
                j += 1
                let alpha = CGFloat(measureRange > 0.0 ? ((windowAcc - minMeasure) / (maxMeasure - minMeasure)) : 1.0)
                entryData = windowAcc

                let wColor = typeColor(sampleType)
                measureColors[sampleType]!.append(wColor.colorWithAlphaComponent(alpha))
            } else {
                measureColors[sampleType]!.append(MetabolicDailyProgressChartView.fastingColor)
            }

            measureSegments[sampleType]!.append((t, ChartDataEntry(value: Double(self.cycleWindowSize) / secsPerDay, xIndex: i, data: entryData)))
            
            i += 1
            t = t + self.cycleWindowSize.seconds
        }
    }

    func typeColor(sampleType: HKSampleType) -> UIColor {
        return sampleType.identifier == HKQuantityTypeIdentifierStepCount ?
            MetabolicDailyProgressChartView.exerciseColor : MetabolicDailyProgressChartView.eatingColor
    }

    func segmentColor() -> UIColor {
        switch segmentIndex {
        case 0:
            return MetabolicDailyProgressChartView.sleepColor

        case 1:
            return MetabolicDailyProgressChartView.eatingColor

        default:
            return MetabolicDailyProgressChartView.exerciseColor
        }
    }
}
