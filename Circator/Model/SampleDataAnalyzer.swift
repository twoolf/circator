//
//  SampleDataAnalyzer.swift
//  Circator
//
//  Created by Sihao Lu on 10/24/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import CircatorKit
import HealthKit
import Charts
import SwiftDate

class CorrelationDataAnalyzer: SampleDataAnalyzer {
    let sampleTypes: [HKSampleType]
    let statistics: [[HKStatistics]]
    var dataSetConfigurators: [((LineChartDataSet) -> Void)?] = []

    init?(sampleTypes: [HKSampleType], statistics: [[HKStatistics]]) {
        guard sampleTypes.count == 2 && statistics.count == 2 else {
            self.sampleTypes = []
            self.statistics = []
            super.init()
            return nil
        }
        self.sampleTypes = sampleTypes
        self.statistics = statistics
        super.init()
    }

    var correlationChartData: LineChartData {
        let firstParamEntries = statistics[0].enumerate().map { (i, stats) -> ChartDataEntry in
            return ChartDataEntry(value: stats.numeralValue!, xIndex: i + 1)
        }
        let firstParamDataSet = LineChartDataSet(yVals: firstParamEntries, label: sampleTypes[0].displayText)
        dataSetConfigurators[0]?(firstParamDataSet)
        let secondParamEntries = statistics[1].enumerate().map { (i, stats) -> ChartDataEntry in
            return ChartDataEntry(value: stats.numeralValue!, xIndex: i + 1)
        }
        let secondParamDataSet = LineChartDataSet(yVals: secondParamEntries, label: sampleTypes[1].displayText)
        dataSetConfigurators[1]?(secondParamDataSet)
        return LineChartData(xVals: Array(0...statistics[0].count + 1), dataSets: [firstParamDataSet, secondParamDataSet])
    }
}

class PlotDataAnalyzer: SampleDataAnalyzer {
    let samples: [HKSample]
    let statistics: [HKStatistics]
    let sampleType: HKSampleType

    init(sampleType: HKSampleType, statistics: [HKStatistics]) {
        self.sampleType = sampleType
        self.statistics = statistics
        self.samples = []
        super.init()
    }

    init(sampleType: HKSampleType, samples: [HKSample]) {
        self.sampleType = sampleType
        self.samples = samples
        self.statistics = []
        super.init()
    }

    enum DataGroupingMode {
        case ByInstance
        case ByDate
    }

    var dataGroupingMode: DataGroupingMode = .ByDate
    var dataSetConfigurator: ((LineChartDataSet) -> Void)?
    var dataSetConfiguratorBubbleChart: ((BubbleChartDataSet) -> Void)?

    var lineChartData: LineChartData {
        guard !(statistics.isEmpty && samples.isEmpty) else {
            return LineChartData(xVals: [""])
        }
        if dataGroupingMode == .ByDate {
            // Offset final date by one and first date by negative one
            let firstDate = statistics.isEmpty ? samples.first!.startDate : statistics.first!.startDate
            let lastDate = statistics.isEmpty ? samples.last!.startDate : statistics.last!.startDate
            let zeroDate = firstDate.startOf(.Day, inRegion: Region()) - 1.days
            let finalDate = lastDate.startOf(.Day, inRegion: Region()) + 1.days
            var currentDate = zeroDate
            var dates: [NSDate] = []
            while currentDate <= finalDate {
                currentDate = currentDate + 1.days
                dates.append(currentDate)
            }

            let xVals: [String] = dates.map { (date) -> String in
                SampleFormatter.chartDateFormatter.stringFromDate(date)
            }

            var entries: [ChartDataEntry] = []

            if !statistics.isEmpty {
                entries = statistics.map { (sample) -> ChartDataEntry in
                    let dayDiff = zeroDate.difference(sample.startDate.startOf(.Day, inRegion: Region()), unitFlags: .Day)
                    let val = sample.numeralValue ?? 0.0
                    return ChartDataEntry(value: val, xIndex: dayDiff!.day)
                }
            } else if !samples.isEmpty {
                switch sampleType.identifier {
                case HKCategoryTypeIdentifierSleepAnalysis:
                    var acc : [Int: Double] = [:]
                    samples.forEach { sample in
                        let day = zeroDate.difference(sample.startDate.startOf(.Day, inRegion: Region()), unitFlags: .Day)!.day
                        let val = sample.numeralValue ?? 0.0
                        acc.updateValue(val + (acc[day] ?? 0.0), forKey: day)
                    }
                    entries = acc.sort({ (a,b) in return a.0 < b.0 })
                                 .map { (day, val) -> ChartDataEntry in return ChartDataEntry(value: val, xIndex: day) }

                case HKCorrelationTypeIdentifierBloodPressure:
                    var acc : [Int: (Int, Double)] = [:]
                    samples.forEach { sample in
                        let day = zeroDate.difference(sample.startDate.startOf(.Day, inRegion: Region()), unitFlags: .Day)!.day
                        let val = sample.numeralValue ?? 0.0
                        let eacc = acc[day] ?? (0, 0.0)
                        acc.updateValue((eacc.0 + 1, val + eacc.1), forKey: day)
                    }
                    entries = acc.sort({ (a,b) in return a.0 < b.0 })
                                 .map { (day, countsum) -> ChartDataEntry in return ChartDataEntry(value: countsum.1 / Double(countsum.0), xIndex: day) }

                default:
                    log.error("Cannot plot samples for \(sampleType.identifier)")
                }
            } else {
                log.warning("No samples or statistics found for plotting")
            }

            let dataSet = LineChartDataSet(yVals: entries, label: "")
            dataSetConfigurator?(dataSet)
            return LineChartData(xVals: xVals, dataSet: dataSet)
        } else {
            var xVals: [String] = []
            var index = 0
            var entries: [ChartDataEntry] = []

            if !statistics.isEmpty {
                xVals = statistics.map { (sample) -> String in
                    return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
                }
                entries = statistics.map { (sample) -> ChartDataEntry in
                    return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
                }
            } else if !samples.isEmpty {
                xVals = samples.map { (sample) -> String in
                    return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
                }
                entries = samples.map { (sample) -> ChartDataEntry in
                    return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
                }
            }

            let dataSet = LineChartDataSet(yVals: entries, label: "")
            dataSetConfigurator?(dataSet)
            return LineChartData(xVals: xVals, dataSet: dataSet)
        }
    }

    var bubbleChartData: BubbleChartData {
        guard !(statistics.isEmpty && samples.isEmpty) else {
            return BubbleChartData(xVals: [""])
        }
        if dataGroupingMode == .ByDate {
            var dataEntries: [BubbleChartDataEntry] = []
            var summaryData: [Double] = []

            if !statistics.isEmpty {
                summaryData = statistics.map { s in return s.numeralValue ?? 0.0 }
            }
            else if !samples.isEmpty {
                let zeroDate = samples.first!.startDate.startOf(.Day, inRegion: Region()) - 1.days
                switch sampleType.identifier {
                case HKCategoryTypeIdentifierSleepAnalysis:
                    var acc : [Int: Double] = [:]
                    samples.forEach { sample in
                        let day = zeroDate.difference(sample.startDate.startOf(.Day, inRegion: Region()), unitFlags: .Day)!.day
                        let val = sample.numeralValue ?? 0.0
                        acc.updateValue(val + (acc[day] ?? 0.0), forKey: day)
                    }
                    summaryData = acc.map { (_, val) -> Double in return val }

                case HKCorrelationTypeIdentifierBloodPressure:
                    var acc : [Int: (Int, Double)] = [:]
                    samples.forEach { sample in
                        let day = zeroDate.difference(sample.startDate.startOf(.Day, inRegion: Region()), unitFlags: .Day)!.day
                        let val = sample.numeralValue ?? 0.0
                        let eacc = acc[day] ?? (0, 0.0)
                        acc.updateValue((eacc.0 + 1, val + eacc.1), forKey: day)

                    }
                    summaryData = acc.map { (_, countsum) -> Double in return countsum.1 / Double(countsum.0) }

                default:
                    log.error("Cannot plot quartiles for \(sampleType.identifier)")
                }
            }

            let summaryDataSorted = summaryData.sort()
            guard !summaryData.isEmpty else {
                return BubbleChartData(xVals: [String](), dataSet: nil)
            }
            let xVals = ["Min", "1st", "2nd", "3rd", "4th", "Last 5th", "Max"]
            dataEntries.append(BubbleChartDataEntry(xIndex: 0, value: summaryDataSorted[0], size: CGFloat(summaryDataSorted[0])))
            for partition in 1...5 {
                let prevFifth = summaryDataSorted.count / 5 * (partition - 1)
                let fifth = summaryDataSorted.count / 5 * partition
                let sum = summaryDataSorted[prevFifth..<fifth].reduce(0) { $0 + $1 }
                guard sum > 0 else {
                    continue
                }
                let average = sum / Double(fifth - prevFifth)
                dataEntries.append(BubbleChartDataEntry(xIndex: partition, value: average, size: CGFloat(average)))
            }
            dataEntries.append(BubbleChartDataEntry(xIndex: 6, value: summaryDataSorted.last!, size: CGFloat(summaryDataSorted.last!)))
            let dataSet = BubbleChartDataSet(yVals: dataEntries)
            dataSetConfiguratorBubbleChart?(dataSet)
            return BubbleChartData(xVals: xVals, dataSet: dataSet)
        }
        else {
            var xVals: [String] = []
            var summaryData: [ChartDataEntry] = []
            var index = 0

            if !statistics.isEmpty {
                xVals = statistics.map { (sample) -> String in
                    return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
                }
                summaryData = statistics.map { (sample) -> ChartDataEntry in
                    return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
                }
            } else if !samples.isEmpty {
                xVals = samples.map { (sample) -> String in
                    return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
                }
                summaryData = samples.map { (sample) -> ChartDataEntry in
                    return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
                }
            }

            let dataSet = BubbleChartDataSet(yVals: summaryData)
            dataSetConfiguratorBubbleChart?(dataSet)
            return BubbleChartData(xVals: xVals, dataSet: dataSet)
        }
    }

    var summaryData: Double  {
        guard !(statistics.isEmpty && samples.isEmpty) else {
            return 0.0
        }

        let summaryData : [Double] = statistics.isEmpty ?
            samples.map { (sample) -> Double in return sample.numeralValue! } :
            statistics.map { (sample) -> Double in return sample.numeralValue! }

        return summaryData.sort().first!
    }
}

class SampleDataAnalyzer: NSObject {
    static let sampleFormatter = SampleFormatter()
}
