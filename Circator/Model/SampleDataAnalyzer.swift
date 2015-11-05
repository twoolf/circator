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

class SampleDataAnalyzer: NSObject {
    
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
            let dataSet = LineChartDataSet(yVals: entries)
            dataSetConfigurator?(dataSet)
            let summaryData : [Double] = samples.map { (sample) -> Double in
                return sample.numeralValue!
            }

            return LineChartData(xVals: xVals, dataSet: dataSet)
        } else {
            let xVals: [String] = samples.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
            }
            var index = 0
            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
            }
            let dataSet = LineChartDataSet(yVals: entries)
            dataSetConfigurator?(dataSet)
            let summaryData : [Double] = samples.map { (sample) -> Double in
                return sample.numeralValue!
            }

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

            let sortedDataLength = summaryDataSorted.count
            var xVals = ["Min"]
            var size = summaryDataSorted[0]
//            BubbleChartDataEntry(
            dataEntries.append(BubbleChartDataEntry(xIndex: 0, value: summaryDataSorted[0], size: CGFloat(summaryDataSorted[0]) ))
// 1st fifth
            var sum = 0.0
            var ave = 0.0
            var count = 0.0
            let oneFifth = summaryDataSorted.count/5
            for i in 0..<oneFifth {
                sum = sum + summaryDataSorted[i]
                count = count + 1.0
                }
            ave = sum/count
            xVals.append("1st")
            dataEntries.append(BubbleChartDataEntry(xIndex: 1, value: ave, size: CGFloat(ave) ))
// 2nd fifth
            sum = 0.0
            ave = 0.0
            count = 0.0
            let twoFifths = 2*(summaryDataSorted.count/5)
            for i in oneFifth..<twoFifths {
                sum = sum + summaryDataSorted[i]
                count = count + 1.0
            }
            ave = sum/count
            xVals.append("2nd")
            dataEntries.append(BubbleChartDataEntry(xIndex: 2, value: ave, size: CGFloat(ave) ))
// 3rd fifth
            sum = 0.0
            ave = 0.0
            count = 0.0
            let threeFifths = 3*(summaryDataSorted.count/5)
            for i in twoFifths..<threeFifths {
                sum = sum + summaryDataSorted[i]
                count = count + 1.0
            }
            ave = sum/count
            xVals.append("3rd")
            dataEntries.append(BubbleChartDataEntry(xIndex: 3, value: ave, size: CGFloat(ave) ))
// 4th fifth
            sum = 0.0
            ave = 0.0
            count = 0.0
            let fourFifths = 4*(summaryDataSorted.count/5)
            for i in threeFifths..<fourFifths {
                sum = sum + summaryDataSorted[i]
                count = count + 1.0
            }
            ave = sum/count
            xVals.append("4th")
            dataEntries.append(BubbleChartDataEntry(xIndex: 4, value: ave, size: CGFloat(ave) ))
// last third
            sum = 0.0
            ave = 0.0
            count = 0.0
            for i in fourFifths..<summaryDataSorted.count {
                sum = sum + summaryDataSorted[i]
                count = count + 1.0
            }
            ave = sum/count
            xVals.append("last fifth")
            dataEntries.append(BubbleChartDataEntry(xIndex: 5, value: ave, size: CGFloat(ave) ))
            xVals.append("max")
            dataEntries.append(BubbleChartDataEntry(xIndex: 6, value: summaryDataSorted.last!, size: CGFloat(summaryDataSorted.last!) ))
            let dataSet = BubbleChartDataSet(yVals: dataEntries)
            dataSetConfiguratorBubbleChart?(dataSet)
            return BubbleChartData(xVals: xVals, dataSet: dataSet)
        } else {
            let xVals: [String] = samples.map { (sample) -> String in
                return SampleFormatter.chartDateFormatter.stringFromDate(sample.startDate)
            }
            var index = 0
            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
                return ChartDataEntry(value: sample.numeralValue!, xIndex: index++)
            }
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
//        let summaryDataMax = summaryData.sort().last
    }
}
