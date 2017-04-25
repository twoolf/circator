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
import AwesomeCache
import SwiftDate

private let WCActivityKey = "Circ"
private let WCHeartRateKey = HKQuantityTypeIdentifier.heartRate
private let WCStepCountKey = "HKQuantityTypeIdentifierStepCount"

public let CDMNeedsRefresh = "CDMNeedsRefresh"

// Accumulator:
// i. boolean indicating whether the current endpoint starts an interval.
// ii. the previous event timestamp.
// iii. a disjoint window dictionary of the max count, the total AUC and the number of level changes.
public typealias CycleWindows = [Date: [(Int, Double, Int)]]
public typealias CycleAccum = (Bool, Date?, CycleWindows)

class CycleWindowInfo : NSObject, NSCoding {
    static var winValuesKey  = "winValues"
    static var winMetaPKey   = "winMetaP"
    static var winMetaVKey   = "winMetaV"
    static var winColorsKey  = "winColors"

    internal var winEntries: [Double] = []
    internal var winMetadata: [AnyObject?] = []
    internal var winColors: [NSUIColor] = []

    init(entries: [Double], metadata: [AnyObject?], colors: [NSUIColor]) {
        self.winEntries = entries
        self.winMetadata = metadata
        self.winColors = colors
    }

    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let entries = aDecoder.decodeObject(forKey: CycleWindowInfo.winValuesKey) as? [Double] else { return nil }
        guard let colors = aDecoder.decodeObject(forKey: CycleWindowInfo.winColorsKey) as? [NSUIColor] else { return nil }
        guard let mpos = aDecoder.decodeObject(forKey: CycleWindowInfo.winMetaPKey) as? [Bool] else { return nil }
        guard let mval = aDecoder.decodeObject(forKey: CycleWindowInfo.winMetaVKey) as? [AnyObject] else { return nil }

        var i: Int = 0
        let metadata: [AnyObject?] = mpos.map { if $0 { return nil } else { i += 1; return mval[i-1] } }

        self.init(entries: entries, metadata: metadata, colors: colors)
    }

    internal func encodeWithCoder(aCoder: NSCoder) {
        let mpos : [Bool] = winMetadata.map { $0 == nil }
        let mval : [AnyObject] = winMetadata.flatMap { $0 }

        aCoder.encode(winEntries, forKey: CycleWindowInfo.winValuesKey)
        aCoder.encode(winColors, forKey: CycleWindowInfo.winColorsKey)
        aCoder.encode(mpos, forKey: CycleWindowInfo.winMetaPKey)
        aCoder.encode(mval, forKey: CycleWindowInfo.winMetaVKey)
    }
}

typealias MCCycleWindowCache = Cache<CycleWindowInfo>

public class CycleDataModel : NSObject {

    public var cycleSegments : [(Date, ChartDataEntry)] = []
    public var cycleColors: [NSUIColor] = []

    // Window size in seconds.
    public let cycleWindowSize: Int = 900

    public var measureSegments: [HKSampleType: [(Date, ChartDataEntry)]] = [:]
    public var measureColors: [HKSampleType: [NSUIColor]] = [:]

    public var segmentIndex = 0

    var cachedWindows: MCCycleWindowCache
    let cacheDuration: Double = 300.0

    override init() {
        do {
            self.cachedWindows = try MCCycleWindowCache(name: "MCCycleWindowCache")
        } catch _ {
            fatalError("Unable to create CycleDataModel window cache.")
        }
        super.init()
        NotificationCenter.defaultCenter.addObserver(self, selector: #selector(invalidateActivityEntries), name: HMDidUpdateCircadianEvents, object: nil)
        MCHealthManager.sharedManager.measureInvalidationsByType.forEach {
            NotificationCenter.defaultCenter().addObserver(self, selector: #selector(invalidateMeasureEntries), name: HMDidUpdateMeasuresPfx + $0, object: nil)
        }
    }

    public func updateData(completion: (NSError?) -> Void) {
        let end = Date().endOf(component: .Day)
        let start = (end - 1.months).startOf(.Day)

        var someError: [NSError?] = []
        let group = DispatchGroup()

        let initAcc: CycleAccum = (true, nil, [:])
        let finalizer: (CycleAccum) -> CycleWindows = { $0.2 }

        let initWinAcc = [(0, 0.0, 0), (0, 0.0, 0), (0, 0.0, 0)]

        let eventIndex: (CircadianEvent) -> Int = { e in
            switch e {
            case .sleep:
                return 0
            case .meal(_):
                return 1
            case .exercise(_):
                return 2
            default:
                return -1
            }
        }

        let activityAggregator : (CycleAccum, (Date, CircadianEvent)) -> CycleAccum = { (acc, e) in
            var (startOfInterval, eStart, windows) = acc
            if !startOfInterval && eStart != nil {
                let evtIndex = eventIndex(e.1)

                if evtIndex >= 0 {
                    // Loop over windows spanned by the event, adding the contribution of the event to each window.
                    var eWindow = floorDate(date: eStart, granularity: Double(self.cycleWindowSize))
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

        // Retrieve activity entries from the cache.
        group.enter()
        cachedWindows.setObjectForKey(WCActivityKey, cacheBlock: {
            (success, failure) in
            MCHealthManager.sharedManager.fetchAggregatedCircadianEvents(
                start, endDate: end, aggregator: activityAggregator, initialAccum: initAcc, initialResult: [:], final: finalizer)
            {
                (result, error) in
                guard error == nil else {
                    failure(error)
                    return
                }
                let (winEntries, winMeta, winColors) = self.getChartActivityEntries(start, endDate: end, windows: result)
                success(CycleWindowInfo(entries: winEntries, metadata: winMeta, colors: winColors), .Seconds(self.cacheDuration))
            }
            }, completion: { (cachedVal, cacheHit, error) in
                guard error == nil else {
                    log.error(error!.localizedDescription)
                    someError.append(error)
                    dispatch_group_leave(group)
                    return
                }
                if let windows = cachedVal {
                    self.cycleSegments = zip(windows.winEntries, windows.winMetadata).enumerate().map {
                        let entry = ChartDataEntry(value: $0.1.0, xIndex: $0.0, data: $0.1.1)
                        return (start + ($0.0 * self.cycleWindowSize).seconds, entry)
                    }
                    self.cycleColors = windows.winColors
                }
                dispatch_group_leave(group)
        })

        // Retrieve measure entries from the cache.
        let hrType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifierHeartRate)!
        let scType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifierStepCount)!

        let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate: end, options: .None)
        var interval = DateComponents()
        interval.minute = 15

        let measureQueries : [(HKQuantityType, HKStatisticsOptions, String)] = [(hrType, .DiscreteAverage, WCHeartRateKey.rawValue), (scType, .CumulativeSum, WCStepCountKey)]

        measureQueries.forEach { (sampleType, aggOp, cacheKey) in
            group.enter()

            cachedWindows.setObject(forKey: cacheKey, cacheBlock: { (success, failure) in
                let query = HKStatisticsCollectionQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: aggOp, anchorDate: start, intervalComponents: interval)

                query.initialResultsHandler = { query, results, error in
                    guard error == nil else {
                        failure(error)
                        return
                    }
                    let (winEntries, winMeta, winColors) = self.getChartMeasureEntries(start, endDate: end, sampleType: sampleType, statistics: results?.statistics() ?? [])
                    success(CycleWindowInfo(entries: winEntries, metadata: winMeta, colors: winColors), .Seconds(self.cacheDuration))
                }
                MCHealthManager.sharedManager.healthKitStore.executeQuery(query)
                }, completion: { (cachedVal, cacheHit, error) in
                    guard error == nil else {
                        log.error(error!.localizedDescription)
                        someError.append(error)
                        dispatch_group_leave(group)
                        return
                    }
                    if let windows = cachedVal {
                        self.measureSegments[sampleType] = zip(windows.winEntries, windows.winMetadata).enumerate().map {
                            let entry = ChartDataEntry(value: $0.1.0, xIndex: $0.0, data: $0.1.1)
                            return (start + ($0.0 * self.cycleWindowSize).seconds, entry)
                        }
                        self.measureColors[sampleType] = windows.winColors
                    }
                    dispatch_group_leave(group)
            })
        }

        dispatch_group_notify(group, DispatchQueue.global(DispatchQueue.GlobalQueuePriority.background, 0)) {
            guard someError.count == 0 else {
                completion(someError[0])
                return
            }
            completion(nil)
        }
    }

    // Create colors by composing each event type color component, normalized to window length * max count
    func getChartActivityEntries(startDate: Date, endDate: Date, windows: CycleWindows) -> ([Double], [AnyObject?], [NSUIColor]) {
        let secsPerDay = Double(24 * 60 * 60)
        let maxCounts = windows.reduce([1, 1, 1], combine: { acc in acc.0.enumerate().map { max($0.1, acc.1.1[$0.0].2) } }).map { CGFloat($0) }

        var i = 0
        var t = startDate
        let end = startDate + 24.hours

        var resultEntries : [Double] = []
        var resultMeta : [AnyObject?] = []
        var resultColors : [NSUIColor] = []

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
                resultColors.append(wColor)

                entryData = [cb, cr, cg]

            } else {
                resultColors.append(MetabolicDailyProgressChartView.fastingColor)
            }

            resultEntries.append(Double(self.cycleWindowSize) / secsPerDay)
            resultMeta.append(entryData)

            i += 1
            t = t + self.cycleWindowSize.seconds
        }
        return (resultEntries, resultMeta, resultColors)
    }

    func getChartMeasureEntries(startDate: Date, endDate: Date, sampleType: HKSampleType, statistics: [HKStatistics]) -> ([Double], [AnyObject?], [NSUIColor]) {
        let secsPerDay = Double(24 * 60 * 60)
        var windows: [Date: Double] = [:]
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

        var resultEntries : [Double] = []
        var resultMeta : [AnyObject?] = []
        var resultColors : [NSUIColor] = []

        while t < end {
            var entryData: Double? = nil
            if let windowAcc = windows[t] {
                j += 1
                let alpha = CGFloat(measureRange > 0.0 ? ((windowAcc - minMeasure) / (maxMeasure - minMeasure)) : 1.0)
                entryData = windowAcc

                let wColor = typeColor(sampleType)
                resultColors.append(wColor.colorWithAlphaComponent(alpha))
            } else {
                resultColors.append(MetabolicDailyProgressChartView.fastingColor)
            }

            resultEntries.append(Double(self.cycleWindowSize) / secsPerDay)
            resultMeta.append(entryData)
            
            i += 1
            t = t + self.cycleWindowSize.seconds
        }
        return (resultEntries, resultMeta, resultColors)
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

    // MARK :- cache invalidation

    func invalidateActivityEntries(note: NSNotification) {
        log.info("Invalidating cycle window cache for circadian activities")
        cachedWindows.removeObjectForKey(WCActivityKey)
        NSNotificationCenter.defaultCenter().postNotificationName(CDMNeedsRefresh, object: self, userInfo: ["type": WCActivityKey])
    }

    func invalidateMeasureEntries(note: NSNotification) {
        if let info = note.userInfo, let sampleTypeId = info["type"] as? String {
            log.info("Invalidating cycle window cache for \(sampleTypeId)")
            cachedWindows.removeObjectForKey(sampleTypeId)
            NSNotificationCenter.defaultCenter().postNotificationName(CDMNeedsRefresh, object: self, userInfo: ["type": sampleTypeId])
        }
    }
}
