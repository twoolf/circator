
//
// Created by Artem Usachov on 5/31/16.
// Copyright (c) 2016 SROST. All rights reserved.
//

import Foundation
import Charts
import SwiftDate
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries

enum ChartType {
    case BarChart
    case LineChart
    case ScatterChart
}

class BarChartModel : NSObject {

    var rangeType: HealthManagerStatisticsRangeType = HealthManagerStatisticsRangeType.week
    private var typesChartDataQueue = DispatchQueue(label: "BarChartModel.typesChartDataQueue")
    private var _typesChartData: [String: ChartData] = [:]
    
    var typesChartData: [String: ChartData] {
        get { return typesChartDataQueue.sync {  _typesChartData } }
        set { typesChartDataQueue.sync {  _typesChartData = newValue } }
    }
    
    private func createQueue() -> OperationQueue {
        let operationQueue = OperationQueue()
        return operationQueue
    }
    
    var _chartDataOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        return operationQueue
    }()
    
    private var chartTypeToQuantityType: [String: ChartType] = [HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.basalEnergyBurned.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.stepCount.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.activeEnergyBurned.rawValue : .BarChart,
                                                                HKCategoryTypeIdentifier.sleepAnalysis.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryProtein.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatTotal.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFiber.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietarySugar.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietarySodium.rawValue : .BarChart, //salt
                                                                HKQuantityTypeIdentifier.dietaryCaffeine.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryCholesterol.rawValue: .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryWater.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.bodyMassIndex.rawValue : .LineChart,
                                                                HKQuantityTypeIdentifier.bodyMass.rawValue : .LineChart,
                                                                HKQuantityTypeIdentifier.heartRate.rawValue : .ScatterChart,
                                                                HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : .ScatterChart,
                                                                HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue : .ScatterChart,
                                                                HKQuantityTypeIdentifier.uvExposure.rawValue : .ScatterChart]


    func colorsForSet(entries: [ChartDataEntry]) -> [UIColor] {
        let array = entries.map { $0.y == 0 ? UIColor.clear : UIColor.green}
        return array
    }

    //MARK: Prepare chart data
    func convertStatisticsValues(stisticsValues: [Double],
                                 forRange range: HealthManagerStatisticsRangeType,
                                           type: ChartType,
                                         create: ((Double, Double, ChartType) -> ChartDataEntry)) -> [ChartDataEntry] {
        var yVals: [ChartDataEntry] = []
        for (index, value) in stisticsValues.enumerated() {
            let entry = create(Double(index), value, type)
            switch type {
            case .LineChart:
                if value != 0 {
                    yVals.append(entry)
                }
            case .BarChart, .ScatterChart:
                yVals.append(entry)
            }
        }
        return yVals
    }

    func getChartDataForRange(range: HealthManagerStatisticsRangeType, type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        let xVals: [String]
        let yVals: [ChartDataEntry]
        switch range {
        case .week:
            xVals = getWeekTitles()
        case .month:
            xVals = getMonthTitles()
        case .year:
            xVals = getYearTitles()
        }

        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: range)
        } else {
            yVals = convertStatisticsValues(stisticsValues: values, forRange: range, type: type, create: {x, y, type in
                switch type {
                case .BarChart:
                    return BarChartDataEntry(x: x, y: y, data: xVals as AnyObject)
                case .LineChart:
                    return ChartDataEntry(x: x, y: y)
                case .ScatterChart:
                    return ChartDataEntry(x: x, y: y)
                }
            })
        }
        let noZeroFormatter = NumberFormatter()
        noZeroFormatter.zeroSymbol = ""
        switch type {
        case .LineChart:
            let lineSet = LineChartDataSet(values: yVals, label: "Check")
            lineSet.setColor(.red)
            lineSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
            return LineChartData(dataSet: lineSet)
        case .ScatterChart:
            let scatterSet = ScatterChartDataSet(values: yVals, label: "Check")
            let colors = colorsForSet(entries: yVals)
            scatterSet.colors = colors
            scatterSet.setScatterShape(.circle)
            scatterSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
            return ScatterChartData(dataSet: scatterSet)
        case .BarChart:
            let barSet = BarChartDataSet(values: yVals, label: "Check")
            barSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
            barSet.setColor(UIColor.orange)
            return BarChartData(dataSet: barSet)
        }
    }

    func getYValuesForScatterChart (minValues: [Double], maxValues: [Double], period: HealthManagerStatisticsRangeType) -> [ChartDataEntry] {
        let xVals: [String]
        switch period {
        case .week:
            xVals = getWeekTitles()
        case .month:
            xVals = getMonthTitles()
        case .year:
            xVals = getYearTitles()
        }
        var yVals: [ChartDataEntry] = []
        for (index, minValue) in minValues.enumerated() {
            let maxValue = maxValues[index]
            if maxValue > 0 && minValue > 0 {
                yVals.append(ChartDataEntry(x: Double(index), y: minValue, data: xVals as AnyObject))
            } else if maxValue > 0 {
                yVals.append(ChartDataEntry(x: Double(index), y: maxValue, data: xVals as AnyObject))
            }
        }
        return yVals
    }

    func getBloodPressureChartData(range: HealthManagerStatisticsRangeType,
                             systolicMax: [Double],
                             systolicMin: [Double],
                            diastolicMax: [Double],
                            diastolicMin: [Double]) -> ScatterChartData {
        let systolicWeekData = getYValuesForScatterChart(minValues: systolicMin, maxValues: systolicMax, period: range)
        let diastolicWeekData = getYValuesForScatterChart(minValues: diastolicMin, maxValues: diastolicMax, period: range)
        let systolicSet = ScatterChartDataSet(values: systolicWeekData, label: "check3")
        let diastolicSet = ScatterChartDataSet(values: diastolicWeekData, label: "check3")
        systolicSet.setScatterShape(.circle)
        diastolicSet.setScatterShape(.circle)

        var array = [ScatterChartDataSet]()
        array.append(systolicSet)
        array.append(diastolicSet)
        return ScatterChartData(dataSets: array)
    }

    func getAllDataForCurrentPeriodForSample(qType : HKSampleType,  _chartType: ChartType?, completion: @escaping (Bool) -> Void) {
        
        let type = qType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : qType.identifier
        let chartType = _chartType == nil ? chartTypeForQuantityTypeIdentifier(qType: type) : _chartType
        let key = type + "\(self.rangeType.rawValue)"
        
//        log.warning("Getting chart data for \(type)")
        
        switch type {
        case HKQuantityTypeIdentifier.heartRate.rawValue, HKQuantityTypeIdentifier.uvExposure.rawValue:
            // We should get max and min values. because for this type we are using scatter chart
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                let array = values.map {$0.map {$0.isNaN ? 0.0 : $0} }
                if array.count > 0 {
                    let data = self.getChartDataForRange(range: self.rangeType, type: chartType!, values: array[0], minValues: array[1])
                    self.typesChartData[key] = data
                }
                completion(array.count > 0)
            }
        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:
            // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: type))!, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                let array = values.map {$0.map {$0.isNaN ? 0.0 : $0} }
                if array.count > 0 {
                    let data = self.getBloodPressureChartData(range: self.rangeType,
                                                              systolicMax: array[0],
                                                              systolicMin: array[1],
                                                              diastolicMax: array[2],
                                                              diastolicMin: array[3])
                    self.typesChartData[key] = data
                }
                completion(array.count > 0)
            }
        default:
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [Double]
                let arrray = values.map {$0.isNaN ? 0.0 : $0}
                let condition = (arrray.count > 0)
                if condition {
                    let data = self.getChartDataForRange(range: self.rangeType, type: chartType!, values: arrray, minValues: nil)
                    self.typesChartData[key] = data
                }
                completion(condition)
            }
        }
    }
    
    func gettAllDataForSpecifiedType(chartType: ChartType, completion: @escaping () -> Void) {
        resetOperation()
        let chartGroup = DispatchGroup()
        for qType in PreviewManager.chartsSampleTypes {
            chartGroup.enter()
            _chartDataOperationQueue.addOperation({
                self.getAllDataForCurrentPeriodForSample(qType: qType, _chartType: chartType) { _ in
                    chartGroup.leave()
                }
            })
        }
        chartGroup.notify(qos: DispatchQoS.background, queue: DispatchQueue.main) {
            self.addCompletionForOperationQueue(completion: completion)
        }
    }
    
    func getAllDataForCurrentPeriod(completion: @escaping () -> Void) {
        //always reset current operation queue before start new one
        resetOperation()
        let chartGroup = DispatchGroup()

        for qType in PreviewManager.chartsSampleTypes {
            _chartDataOperationQueue.addOperation({
                chartGroup.enter()
                self.getAllDataForCurrentPeriodForSample(qType: qType, _chartType: nil) { _ in
                    chartGroup.leave()
                }
            })
        }
        chartGroup.notify(qos: DispatchQoS.background, queue: DispatchQueue.main) {
            self.addCompletionForOperationQueue(completion: completion)
        }
    }

    // MARK :- Chart titles for X

    func getWeekTitles () -> [String] {
        let currentDate = Date()
        let weekAgoDate = currentDate - 7.days
        var weekTitles: [String] = []
        var prevMonthDates: [Date] = []
        var currentMonthDates: [Date] = []

        for index in 1...7 {
            let day = weekAgoDate + index.days
            if day.month < currentDate.month {
                prevMonthDates.append(day)
            } else {
                currentMonthDates.append(day)
            }
        }

        for (index, date) in prevMonthDates.enumerated() {
            weekTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }

        for (index, date) in currentMonthDates.enumerated() {
            weekTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }

        return weekTitles
    }

    func getMonthTitles () -> [String] {
        let dateMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let calendar = Calendar.current
        let currentDate = Date()
        let interval = calendar.dateInterval(of: .month, for: dateMonthAgo!)
        let numOfDays = calendar.dateComponents([.day], from: (interval?.start)!, to: (interval?.end)!).day!
        var monthTitles: [String] = []
        let monthAgoDate = currentDate - numOfDays.days
        var prevMonthDates: [Date] = []
        var currentMonthDates: [Date] = []
        for index in 1...numOfDays {
            let day = monthAgoDate + index.days
            if day.month < currentDate.month {
                prevMonthDates.append(day)
            } else {
                currentMonthDates.append(day)
            }
        }
        for (index, date) in prevMonthDates.enumerated() {
            monthTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }
        for (index, date) in currentMonthDates.enumerated() {
            monthTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }
        return monthTitles
    }

    func getYearTitles() -> [String] {
        let calendar = Calendar.current
        let date = Date()
        let interval = calendar.dateInterval(of: .year, for: date)!
        let numOfDays = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        let currentDate = Date()

       let endDate = currentDate.startOf(component: .month) + 1.months

        let dateYearAgo = endDate - numOfDays.days
        var prevYearDays: [Date] = []
        var currentYearDays: [Date] = []
        var yearTitles: [String] = []
            for index in 0...(numOfDays - 1) {
                let date = dateYearAgo + index.days
                    date.year < endDate.year ? prevYearDays.append(date) : currentYearDays.append(date)
                }
                for (index, date) in prevYearDays.enumerated() {
                    yearTitles.append(convertDateToYearString(date: date, forIndex: index))
                }
                for (index, date) in currentYearDays.enumerated() {
                    yearTitles.append(convertDateToYearString(date: date, forIndex: index))
                }
        return yearTitles
    }

    //MARK: Help
    func chartTypeForQuantityTypeIdentifier(qType: String) -> ChartType {
        if let chartType = chartTypeToQuantityType[qType] {
            return chartType
        }
        return .BarChart
    }

    func convertDateToYearString(date: Date, forIndex index: Int) -> String {
        let month =  String(date.monthName.prefix(3))
        if index == 0 {
            return month + String(date.year)
        }
        return month
    }

    func convertDateToWeekString(date: Date, forIndex index: Int) -> String {
        if date.day == 1 {
            let month = String(date.monthName.prefix(3))
            return String(date.day) + month
        }
        return "\(date.day)"
    }
    
    func addCompletionForOperationQueue(completion: @escaping () -> Void) {
        _chartDataOperationQueue.operations.onFinish(block: {
            OperationQueue.main.addOperation({
                completion()
            })
        })
    }
    
    func resetOperation() {
        _chartDataOperationQueue.cancelAllOperations()
        _chartDataOperationQueue = createQueue()
    }

    func titlesFor(range: HealthManagerStatisticsRangeType) -> [String] {
        switch range {
        case .week:
            return getWeekTitles()
        case .month:
            return getMonthTitles()
        case .year:
            return getYearTitles()
        }
    }
}
