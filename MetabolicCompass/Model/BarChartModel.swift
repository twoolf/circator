
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
import Stormpath

enum ChartType {
    case BarChart
    case LineChart
    case ScatterChart
}

class BarChartModel : NSObject {

    var rangeType: HealthManagerStatisticsRangeType = HealthManagerStatisticsRangeType.week
    var typesChartData: [String: ChartData] = [:]
    var _chartDataOperationQueue: OperationQueue = OperationQueue()
    
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

    //MARK: Data for YEAR
    func getChartDataForYear(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {

        let xVals = getYearTitles()
        var yVals: [ChartDataEntry] = []
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: .year)
        } else {
            yVals = convertStatisticsValues(stisticsValues: values, forRange: .year, type: type, create: {x, y, type in
                return BarChartDataEntry.init(x: x, y: y)
            })
        }
        return getChartDataFor(xVals: xVals, yVals: yVals, type: type) as! ChartData
    }

    //MARK: Data for MONTH
    func getChartDataForMonth(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        let xVals = getMonthTitles()
        var yVals = convertStatisticsValues(stisticsValues: values, forRange: .month, type: type, create: {x, y, type in
            return BarChartDataEntry.init(x: x, y: y)
        })
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: .month)
        }
        return getChartDataFor(xVals: xVals, yVals: yVals, type: type) as! ChartData
    }

    func colorsForSet(entries: [ChartDataEntry]) -> [UIColor] {
       var array = [UIColor] ()
        for entry in entries {
            if entry.y == 0 {
                array.append(UIColor.clear)
            } else {
                array.append(UIColor.green)
            }
        }
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

        var xVals = [String] ()
        switch range {
        case .week:
            xVals = getWeekTitles()
        case .month:
            xVals = getMonthTitles()
        case .year:
            xVals = getYearTitles()
        }

        var yVals = convertStatisticsValues(stisticsValues: values, forRange: range, type: type, create: {x, y, type in
            switch type {
            case .BarChart:
                return BarChartDataEntry.init(x: x, y: y, data: xVals as AnyObject)
            case .LineChart:
                return ChartDataEntry.init(x: x, y: y)
            case .ScatterChart:
                return ChartDataEntry.init(x: x, y: y)
            }
        })

        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: range)
        }
        let noZeroFormatter = NumberFormatter()
        noZeroFormatter.zeroSymbol = ""
        switch type {
        case .LineChart:
            let lineSet = LineChartDataSet.init(values: yVals, label: "Check")
            lineSet.setColor(UIColor.red)
            lineSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
            return LineChartData(dataSet: lineSet)
        case .ScatterChart:
            let scatterSet = ScatterChartDataSet.init(values: yVals, label: "Check")
            let colors = colorsForSet(entries: yVals)
            scatterSet.colors = colors
            scatterSet.setScatterShape(.circle)
            scatterSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
            return ScatterChartData.init(dataSet: scatterSet)
        case .BarChart:
            let barSet = BarChartDataSet.init(values: yVals, label: "Check")
            barSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
            barSet.setColor(UIColor.orange)
            return BarChartData.init(dataSet: barSet)
        }
    }

    func getYValuesForScatterChart (minValues: [Double], maxValues: [Double], period: HealthManagerStatisticsRangeType) -> [ChartDataEntry] {
        var xVals = [String] ()
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
    
    func getChartDataFor(xVals: [String], yVals: [ChartDataEntry], type: ChartType) -> AnyObject {
        switch type {
            case .BarChart:
                return BarChartDataSet.init(values: yVals, label: "MyCheck")
            case .LineChart:
                return LineChartDataSet.init(values: yVals, label: "MyCheck")
            case .ScatterChart:
                return ScatterChartDataSet.init(values: yVals, label: "MyCheck")
        }
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
        var array = [ScatterChartDataSet]()
        array.append(systolicSet)
        array.append(diastolicSet)
        return ScatterChartData.init(dataSets: array)
    }

    func getAllDataForCurrentPeriodForSample(qType : HKSampleType,  _chartType: ChartType?, completion: @escaping (Bool) -> Void) {
        
        let type = qType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : qType.identifier
        let chartType = _chartType == nil ? chartTypeForQuantityTypeIdentifier(qType: type) : _chartType
        let key = type + "\(self.rangeType.rawValue)"
        
        log.warning("Getting chart data for \(type)")
        
        if type == HKQuantityTypeIdentifier.heartRate.rawValue || type == HKQuantityTypeIdentifier.uvExposure.rawValue {
            // We should get max and min values. because for this type we are using scatter chart
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                let array = values.map {$0.map {$0.isNaN ? 0.0 : $0} }
                if array.count > 0 {
                    self.typesChartData[key] = self.getChartDataForRange(range: self.rangeType, type: chartType!, values: array[0], minValues: array[1])
                }
                completion(array.count > 0)
            }
        } else if type == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
            // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: type))!, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                let array = values.map {$0.map {$0.isNaN ? 0.0 : $0} }
                if array.count > 0 {
                    self.typesChartData[key] = self.getBloodPressureChartData(range: self.rangeType,
                                                                   systolicMax: array[0],
                                                                   systolicMin: array[1],
                                                                  diastolicMax: array[2],
                                                                  diastolicMin: array[3])
                }
                completion(array.count > 0)
            }
        } else {
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: qType, inPeriod: self.rangeType) { obj in
                var values = obj as! [Double]
                if self.rangeType == .month && values.count > 0 {
                    values.remove(at: 0)
                }
                let arrray = values.map {$0.isNaN ? 0.0 : $0}
                if arrray.count > 0 {
                    self.typesChartData[key] = self.getChartDataForRange(range: self.rangeType, type: chartType!, values: arrray, minValues: nil)
                }
                completion(arrray.count > 0)
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
        let stepType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let weightType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let heartType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let bloodType = HKSampleType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!
        let sleepType = HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let energyType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let polisaturatedType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)
        let dietaryFatType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)
        let proteinType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)

        for qType in PreviewManager.chartsSampleTypes {
            if qType == heartType {
            chartGroup.enter()
            _chartDataOperationQueue.addOperation({ 
                self.getAllDataForCurrentPeriodForSample(qType: qType, _chartType: nil) { _ in
                    chartGroup.leave()
                }
            })

            }
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
        var monthTitles: [String] = []
        let currentDate = Date()
        let numberOfDays = 32
        let monthAgoDate = currentDate - numberOfDays.days
        var prevMonthDates: [Date] = []
        var currentMonthDates: [Date] = []
        for index in 1...numberOfDays {
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
     //   monthTitles.append("")
        return monthTitles
    }

    func getYearTitles() -> [String] {
        let calendar = Calendar.current
        let date = Date()
        let interval = calendar.dateInterval(of: .year, for: date)!
        let numOfDays = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        let currentDate = Date()
        let dateYearAgo = currentDate - 1.years
        var prevYearDays: [Date] = []
        var currentYearDays: [Date] = []
        var yearTitles: [String] = []
            for index in 0...(numOfDays - 1) {
                let date = dateYearAgo + index.days
                    date.year < currentDate.year ? prevYearDays.append(date) : currentYearDays.append(date)
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

        let month =  String(date.monthName.characters.prefix(3))
         if index == 0 {
            return month + String(date.year)
        }

        return month
    }

    func convertDateToWeekString(date: Date, forIndex index: Int) -> String {
        if date.day == 1 {
            let month = String(date.monthName.characters.prefix(3))
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
        _chartDataOperationQueue = OperationQueue()
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
