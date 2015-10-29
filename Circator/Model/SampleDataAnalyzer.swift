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
            return LineChartData(xVals: xVals, dataSet: dataSet)
        }
    }
}
