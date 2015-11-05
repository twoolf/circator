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
    var dataSetConfiguratorBarChart: ((BarChartDataSet) -> Void)?
    
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
    
    var barChartData: BarChartData {
        guard samples.isEmpty == false else {
            return BarChartData(xVals: [""])
        }
        if dataGroupingMode == .ByDate {
            var dataEntries: [BarChartDataEntry] = []
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
            let summaryData : [Double] = samples.map { (sample) -> Double in
                return sample.numeralValue!
            }
            let summaryDataSorted = summaryData.sort()
//            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
//                let components = calendar.components(.Day, fromDate: samples.first!.startDate, toDate: sample.startDate, options: NSCalendarOptions())
//            }
//            switch summaryDataSorted.count {
//            case 0:
//                dataEntries.append(BarChartDataEntry(value: 0.0, xIndex: 0))
//            case 1:
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[0], xIndex: 0))
//            case 2:
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[0], xIndex: 0))
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[1], xIndex: 1))
//            case 3:
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[0], xIndex: 0))
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[1], xIndex: 1))
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[2], xIndex: 2))
//            case 4:
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[0], xIndex: 0))
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[1], xIndex: 1))
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[2], xIndex: 2))
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[3], xIndex: 3))
//            case 5:
//                for i in 0..<summaryDataSorted.count {
//                    let dataEntry = BarChartDataEntry(value: summaryDataSorted[i], xIndex: i)
//                    dataEntries.append(dataEntry)
//                }
//            case _ where summaryDataSorted.count > 5:
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[0], xIndex: 0))
//                dataEntries.append(BarChartDataEntry(value: 0.0, xIndex: 1))
//                for i in 2..<(summaryDataSorted.count-1) {
//                    let dataEntry = BarChartDataEntry(value: summaryDataSorted[i], xIndex: i)
//                    dataEntries.append(dataEntry)
//                }
//                dataEntries.append(BarChartDataEntry(value: summaryDataSorted[summaryDataSorted.count], xIndex: summaryDataSorted.count))
//            default:
//                dataEntries.append(BarChartDataEntry(value: 0.0, xIndex: 0))
//            }
            let sortedDataLength = summaryDataSorted.count
            dataEntries.append(BarChartDataEntry(value: summaryDataSorted[0], xIndex: 0))
            dataEntries.append(BarChartDataEntry(value: 0.0, xIndex: 1))
            for i in 0..<(summaryDataSorted.count) {
                let j=i+2
                let dataEntry = BarChartDataEntry(value: summaryDataSorted[i], xIndex: j)
                dataEntries.append(dataEntry)
                }
            dataEntries.append(BarChartDataEntry(value: 120.0, xIndex: summaryDataSorted.count+1 ))
//            dataEntries.append(BarChartDataEntry(value: summaryDataSorted[sortedDataLength], xIndex: summaryDataSorted.count+1 ))
//            dataEntries.append(BarChartDataEntry(value: summaryDataSorted[summaryDataSorted.count], xIndex: summaryDataSorted.count))
            
//            default:
//                dataEntries.append(BarChartDataEntry(value: 0.0, xIndex: 0))
//            for i in 0..<summaryDataSorted.count {
//                let dataEntry = BarChartDataEntry(value: summaryDataSorted[i], xIndex: i)
//                dataEntries.append(dataEntry)
//            }
//            let entries: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
//                let components = calendar.components(.Day, fromDate: samples.first!.startDate, toDate: sample.startDate, options: NSCalendarOptions())
//                return ChartDataEntry(value: sample.numeralValue!, xIndex: components.day + 1)
//            }
//            let summaryData: [ChartDataEntry] = samples.map { (sample) -> ChartDataEntry in
//                let components = calendar.components(.Day, fromDate: samples.first!.startDate, toDate: sample.startDate, options: NSCalendarOptions())
//                return ChartDataEntry(value: sample.numeralValue!, xIndex: components.day + 1)
//            }
            let dataSet = BarChartDataSet(yVals: dataEntries)
            dataSetConfiguratorBarChart?(dataSet)
            return BarChartData(xVals: xVals, dataSet: dataSet)
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
            let dataSet = BarChartDataSet(yVals: summaryData)
            dataSetConfiguratorBarChart?(dataSet)
            
            return BarChartData(xVals: xVals, dataSet: dataSet)
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
