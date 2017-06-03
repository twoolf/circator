//
//  SampleDataAnalyzer.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/24/15.   
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import HealthKit
import Charts
import SwiftDate
import MCCircadianQueries

enum PlotSpec {
    case PlotPredicate(String, NSPredicate?)
    case PlotFasting
}

class SampleDataAnalyzer: NSObject {
    static let sampleFormatter = SampleFormatter()
}

/**
 We use this class to put data into the right format for all of the plots.  The exact approach to how the data is input for the charts will depend on the charting library. But, the general need for this type of transformation (reading from the data stores and putting things into the right format) will be needed for any data that is analyzed by the user.
 
 - note: current format is set by our use of the Charts library
 */
class CorrelationDataAnalyzer: SampleDataAnalyzer {
    let labels: [String]
    let samples: [[MCSample]]
    let values: [[(Date, Double)]]
    let zipped: [(Date, Double, MCSample)]
    var dataSetConfigurators: [((LineChartDataSet) -> Void)?] = []

    init?(labels: [String], samples: [[MCSample]]) {
        guard labels.count == 2 && samples.count == 2 else {
            self.labels = []
            self.samples = []
            self.values = []
            self.zipped = []
            super.init()
            return nil
        }
        self.labels = labels
        self.samples = samples
        self.values = []
        self.zipped = []
        super.init()
    }

    init?(labels: [String], values: [[(Date, Double)]]) {
        guard labels.count == 2 && values.count == 2 else {
            self.labels = []
            self.samples = []
            self.values = []
            self.zipped = []
            super.init()
            return nil
        }
        self.labels = labels
        self.samples = []
        self.values = values
        self.zipped = []
        super.init()
    }

    init?(labels: [String], zipped: [(Date, Double, MCSample)]) {
        guard labels.count == 2 else {
            self.labels = []
            self.samples = []
            self.values = []
            self.zipped = []
            super.init()
            return nil
        }
        self.labels = labels
        self.samples = []
        self.values = []
        self.zipped = zipped
        super.init()
    }

    var correlationChartData: LineChartData {
        if !samples.isEmpty {
            let firstParamEntries = samples[0].enumerated().map { (i, stats) -> ChartDataEntry in
                return ChartDataEntry(x: stats.numeralValue!, y: Double(i) )
            }
            let firstParamDataSet = LineChartDataSet(values: firstParamEntries, label: labels[0])
            dataSetConfigurators[0]?(firstParamDataSet)
            let secondParamEntries = samples[1].enumerated().map { (i, stats) -> ChartDataEntry in
                return ChartDataEntry(x: stats.numeralValue!, y: Double(i) )
            }
            let secondParamDataSet = LineChartDataSet(values: secondParamEntries, label: labels[1])
            dataSetConfigurators[1]?(secondParamDataSet)
//            return LineChartData(xVals: Array(0...samples[0].count + 1), dataSets: [firstParamDataSet, secondParamDataSet])
            return LineChartData()
        } else if !values.isEmpty {
            let firstParamEntries = values[0].enumerated().map { (i, s) -> ChartDataEntry in
                return ChartDataEntry(x: s.1, y: Double(i) )
            }
            let firstParamDataSet = LineChartDataSet(values: firstParamEntries, label: labels[0])
            dataSetConfigurators[0]?(firstParamDataSet)
            let secondParamEntries = values[1].enumerated().map { (i, s) -> ChartDataEntry in
                return ChartDataEntry(x: s.1, y: Double(i))
            }
            let secondParamDataSet = LineChartDataSet(values: secondParamEntries, label: labels[1])
            dataSetConfigurators[1]?(secondParamDataSet)
//            return LineChartData(xVals: Array(0...values[0].count + 1), dataSets: [firstParamDataSet, secondParamDataSet])
            return LineChartData()
        } else {
            let firstParamEntries = zipped.enumerated().map { (i, s) -> ChartDataEntry in
                return ChartDataEntry(x: s.1, y: Double(i))
            }
            let firstParamDataSet = LineChartDataSet(values: firstParamEntries, label: labels[0])
            dataSetConfigurators[0]?(firstParamDataSet)
            let secondParamEntries = zipped.enumerated().map { (i, s) -> ChartDataEntry in
                return ChartDataEntry(x: s.2.numeralValue!, y: Double(i))
            }
            let secondParamDataSet = LineChartDataSet(values: secondParamEntries, label: labels[1])
            dataSetConfigurators[1]?(secondParamDataSet)
//            return LineChartData(xVals: Array(0...zipped.count + 1), dataSets: [firstParamDataSet, secondParamDataSet])
            return LineChartData()
        }
    }
}

/**
 To prepare data for plots (1st button on left)
 
 - note: format set by Charts library; summary statistics are in BubbleChart
 */
class PlotDataAnalyzer: SampleDataAnalyzer {
    let sampleType: HKSampleType
    let samples: [MCSample]
    let values: [(Date, Double)]

    init(sampleType: HKSampleType, samples: [MCSample]) {
        self.sampleType = sampleType
        self.samples = samples
        self.values = []
        super.init()
    }

    init(sampleType: HKSampleType, values: [(Date, Double)]) {
        self.sampleType = sampleType
        self.samples = []
        self.values = values
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
        guard !(samples.isEmpty && values.isEmpty) else {
//            return LineChartData(xVals: [""])
//            return LineChartData(dataSets: [""])
            return LineChartData()
        }
        if dataGroupingMode == .ByDate {
            var xVals: [String] = []
            var entries: [ChartDataEntry] = []

            if !samples.isEmpty {
                (xVals, entries) = lineFromSamples()
            } else {
                (xVals, entries) = lineFromValues()
            }

            let dataSet = LineChartDataSet(values: entries, label: "")
            dataSetConfigurator?(dataSet)
//            return LineChartData(xVals: xVals, dataSet: dataSet)
//            return LineChartData(dataSets: dataSet)
        } else if !samples.isEmpty {
            let _: [String] = samples.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.string(from: sample.startDate)
            }

            var index = 0
            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                index += 1
                return ChartDataEntry(x: sample.numeralValue!, y: Double(index-1))
            }

            let dataSet = LineChartDataSet(values: entries, label: "")
            dataSetConfigurator?(dataSet)
//            return LineChartData(x: xVals, YAxis: dataSet)
//            return LineChartData(dataSets: dataSet)
//            return LineChartData(dataSets: []?)
            return LineChartData()
        } else {
            let xVals: [String] = values.map {
                return SampleFormatter.chartDateFormatter.string(from: $0.0)
            }

            var index = 0
            let entries: [ChartDataEntry] = values.map {_,_ in 
                index += 1
//                let XvalsInSet = $0.1
//                let XvalsInSet = []
//                return ChartDataEntry(x: XvalsInSet, y: index)
                return ChartDataEntry()
            }

            let dataSet = LineChartDataSet(values: entries, label: "")
            dataSetConfigurator?(dataSet)
//            return LineChartData(xVals: xVals, dataSet: dataSet)
//            return LineChartData(dataSets: []?) 
            return LineChartData()
        }
        return LineChartData()
    }

    /// for summary data -- in sets of 20% ordered from min to max --
    var bubbleChartData: BubbleChartData {
        guard !(samples.isEmpty && values.isEmpty) else {
//            return BubbleChartData(labels: [""])
            return BubbleChartData()
        }
        if dataGroupingMode == .ByDate {
            var dataEntries: [BubbleChartDataEntry] = []
            let summaryData: [Double] = !samples.isEmpty ? samples.map { return $0.numeralValue ?? 0.0 } : values.map { return $0.1 }

            let summaryDataSorted = summaryData.sorted()
            guard !summaryData.isEmpty else {
//                return BubbleChartDataEntry(xVals: [String](), dataSet: nil)
                return BubbleChartData()
            }
            _ = ["Min", "1st", "2nd", "3rd", "4th", "Last 5th", "Max"]
            dataEntries.append(BubbleChartDataEntry(x: 0, y: summaryDataSorted[0], size: CGFloat(summaryDataSorted[0])))
            for partition in 1...5 {
                let prevFifth = summaryDataSorted.count / 5 * (partition - 1)
                let fifth = summaryDataSorted.count / 5 * partition
                let sum = summaryDataSorted[prevFifth..<fifth].reduce(0) { $0 + $1 }
                guard sum > 0 else {
                    continue
                }
                let average = sum / Double(fifth - prevFifth)
                dataEntries.append(BubbleChartDataEntry(x: Double(partition), y: average, size: CGFloat(average)))
            }
            dataEntries.append(BubbleChartDataEntry(x: 6, y: summaryDataSorted.last!, size: CGFloat(summaryDataSorted.last!)))
            let dataSet = BubbleChartDataSet(values: dataEntries)
            dataSetConfiguratorBubbleChart?(dataSet)
//            return BubbleChartData(xVals: xVals, dataSet: dataSet)
            return BubbleChartData()
        }
        else if !samples.isEmpty {
            let xVals : [String] = samples.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.string(from: sample.startDate)
            }

            var index = 0
            let summaryData : [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                index += 1
                return ChartDataEntry(x: sample.numeralValue!, y: Double(index-1))
            }

            let dataSet = BubbleChartDataSet(values: summaryData)
            dataSetConfiguratorBubbleChart?(dataSet)
//            return BubbleChartData(xVals: xVals, dataSet: dataSet)
            return BubbleChartData()
        }
        else {
            let xVals : [String] = values.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.string(from: sample.0)
            }

            var index = 0
            let summaryData : [ChartDataEntry] = values.map { (sample) -> ChartDataEntry in
                index += 1
                return ChartDataEntry(x: sample.1, y: Double(index-1))
            }

            let dataSet = BubbleChartDataSet(values: summaryData)
            dataSetConfiguratorBubbleChart?(dataSet)
//            return BubbleChartData(xVals: xVals, dataSet: dataSet)
            return BubbleChartData()
        }
    }

    var summaryData: Double  {
        guard !(samples.isEmpty && values.isEmpty) else {
            return 0.0
        }

        let summaryData : [Double] = !samples.isEmpty ? samples.map { return $0.numeralValue! } : values.map { return $0.1 }
        return summaryData.sorted().first!
    }

    func enumerateDates(startDate: Date, endDate: Date) -> [Date] {
//        let zeroDate = startDate.startOf(.Day, inRegion: Region()) - 1.days
        let zeroDate = endDate.startOfDay - 1.days
//        let finalDate = endDate.startOf(.Day, inRegion: Region()) + 1.days
        let finalDate = endDate.startOfDay + 1.days
        var currentDate = zeroDate
        var dates: [Date] = []
        while currentDate <= finalDate {
            currentDate = currentDate + 1.days
            dates.append(currentDate)
        }
        return dates
    }

    func datesFromSamples() -> [Date] {
        let firstDate = samples.first!.startDate
        let lastDate = samples.last!.startDate
        return enumerateDates(startDate: firstDate, endDate: lastDate)
    }

    func datesFromValues() -> [Date] {
        let firstDate = values.first!.0
        let lastDate = values.last!.0
        return enumerateDates(startDate: firstDate, endDate: lastDate)
    }

    func lineFromSamples() -> ([String], [ChartDataEntry]) {
        let dates = datesFromSamples()
        let zeroDate = dates.first!

        let xVals: [String] = dates.map { (date) -> String in
            SampleFormatter.chartDateFormatter.string(from: date)
        }

        let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
//            let dayDiff = zeroDate.difference(sample.startDate.startOf(.Day, inRegion: Region()), unitFlags: .Day)
//            let dayDiff = zeroDate.startOf(component: sample.startDate.startOf(component: .day)) 
            let dayDiff = DateInterval(start: Date(), end: Date().addHours(hoursToAdd: 20))
            let val = sample.numeralValue ?? 0.0
            return ChartDataEntry(x: val, y: dayDiff.duration)
        }
        return (xVals, entries)
    }

    func lineFromValues() -> ([String], [ChartDataEntry]) {
        let dates = datesFromValues()
        _ = dates.first!

        let xVals: [String] = dates.map { (date) -> String in
            SampleFormatter.chartDateFormatter.string(from: date)
        }

        let entries: [ChartDataEntry] = values.map { (sample) -> ChartDataEntry in
//            let dayDiff = zeroDate.difference(sample.0.startOf(.Day, inRegion: Region()), unitFlags: .Day)
//            let dayDiff = zeroDate.startOf(component: sample.0.startOf(component: .day))
//            let dayDiff = zeroDate.startOf(component: sample.0.addHours(hoursToAdd: 12))
//            let dayDiff = zeroDate.startOf(component: sample.0.timeIntervalSinceNow)
            let dayDiff = Date()
//            return ChartDataEntry(x: sample.1, y: dayDiff)
            return ChartDataEntry()
        }
        return (xVals, entries)
    }

}
