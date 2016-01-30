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
    let sampleType: HKSampleType
    
    init(sampleType: HKSampleType, samples: [HKSample]) {
        self.sampleType = sampleType
        self.samples = samples
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
        guard samples.isEmpty == false else {
            return LineChartData(xVals: [""])
        }
        if dataGroupingMode == .ByDate {
            let calendar = NSCalendar.currentCalendar()
            var finalDate = samples.last!.startDate
            // Offset final date by one
            finalDate = calendar.dateByAddingUnit(.Day, value: 1, toDate: finalDate, options: NSCalendarOptions())!
            // Offset first date by negative one
            var currentDate = calendar.dateByAddingUnit(.Day, value: -1, toDate: samples.first!.startDate, options: NSCalendarOptions())!
            var dates: [NSDate] = []
            while currentDate.compare(finalDate) != NSComparisonResult.OrderedDescending {
                currentDate = calendar.dateByAddingUnit(.Day, value: 1, toDate: currentDate, options: NSCalendarOptions())!
                dates.append(currentDate)
            }
            let xVals: [String] = dates.map { (date) -> String in
                SampleFormatter.chartDateFormatter.stringFromDate(date)
            }
            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                let components = calendar.components(.Day, fromDate: samples.first!.startDate, toDate: sample.startDate, options: NSCalendarOptions())
                return ChartDataEntry(value: sample.numeralValue!, xIndex: components.day + 1)
            }
            let dataSet = LineChartDataSet(yVals: entries, label: "")
            dataSetConfigurator?(dataSet)
            return LineChartData(xVals: xVals, dataSet: dataSet)
        } else {
            let xVals: [String] = samples.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
            }
            var index = 0
            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
            }
            let dataSet = LineChartDataSet(yVals: entries, label: "")
            dataSetConfigurator?(dataSet)
            return LineChartData(xVals: xVals, dataSet: dataSet)
        }
    }
    
    var bubbleChartData: BubbleChartData {
        guard samples.isEmpty == false else {
            return BubbleChartData(xVals: [""])
        }
        if dataGroupingMode == .ByDate {
            var dataEntries: [BubbleChartDataEntry] = []

            let summaryData : [Double] = samples.map { (sample) -> Double in
                return sample.numeralValue!
            }
            let summaryDataSorted = summaryData.sort()
            guard summaryData.isEmpty == false else {
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
        } else {
            let xVals: [String] = samples.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
            }
            var index = 0
            let summaryData: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
            }
            let dataSet = BubbleChartDataSet(yVals: summaryData)
            dataSetConfiguratorBubbleChart?(dataSet)
            
            return BubbleChartData(xVals: xVals, dataSet: dataSet)
        }
    }
    
    
    var summaryData: Double  {
        guard samples.isEmpty == false else {
            return 0.0
        }
        let summaryData : [Double] = samples.map { (sample) -> Double in
            return sample.numeralValue! }
        return summaryData.sort().first!

    }
}

class SampleDataAnalyzer: NSObject {
    static let sampleFormatter = SampleFormatter()
}
