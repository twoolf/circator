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

    var rangeType: HealthManagerStatisticsRangeType = HealthManagerStatisticsRangeType.Week
    var typesChartData: [String: ChartData] = [:]
    var _chartDataOperationQueue: NSOperationQueue = NSOperationQueue()
    
    private var chartTypeToQuantityType: [String: ChartType] = [HKQuantityTypeIdentifierDietaryEnergyConsumed : .BarChart,
                                                                HKQuantityTypeIdentifierBasalEnergyBurned : .BarChart,
                                                                HKQuantityTypeIdentifierStepCount : .BarChart,
                                                                HKQuantityTypeIdentifierActiveEnergyBurned : .BarChart,
                                                                HKCategoryTypeIdentifierSleepAnalysis : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryProtein : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryFatTotal : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryCarbohydrates : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryFiber : .BarChart,
                                                                HKQuantityTypeIdentifierDietarySugar : .BarChart,
                                                                HKQuantityTypeIdentifierDietarySodium : .BarChart, //salt
                                                                HKQuantityTypeIdentifierDietaryCaffeine : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryCholesterol: .BarChart,
                                                                HKQuantityTypeIdentifierDietaryFatPolyunsaturated : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryFatSaturated : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryFatMonounsaturated : .BarChart,
                                                                HKQuantityTypeIdentifierDietaryWater : .BarChart,
                                                                HKQuantityTypeIdentifierBodyMassIndex : .LineChart,
                                                                HKQuantityTypeIdentifierBodyMass : .LineChart,
                                                                HKQuantityTypeIdentifierHeartRate : .ScatterChart,
                                                                HKQuantityTypeIdentifierBloodPressureSystolic : .ScatterChart,
                                                                HKQuantityTypeIdentifierBloodPressureDiastolic : .ScatterChart,
                                                                HKQuantityTypeIdentifierUVExposure : .ScatterChart]

    //MARK: Data for YEAR
    func getChartDataForYear(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {

        let xVals = getYearTitles()
        var yVals: [ChartDataEntry] = []
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues, maxValues: values, period: .Year)
        } else {
            yVals = convertStatisticsValues(values, forRange: .Year)
        }

        return getChartDataFor(xVals, yVals: yVals, type: type)
    }

    //MARK: Data for MONTH
    func getChartDataForMonth(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        let xVals = getMonthTitles()
        var yVals = convertStatisticsValues(values, forRange: .Month)
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues, maxValues: values, period: .Month)
        }

        return getChartDataFor(xVals, yVals: yVals, type: type)
    }

    //MARK: Data for WEEK
    func getChartDataForWeek(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        let xVals = getWeekTitles()
        var yVals = convertStatisticsValues(values, forRange: .Week)
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues, maxValues: values, period: .Week)
        }

        return getChartDataFor(xVals, yVals: yVals, type: type)
    }

    //MARK: Prepate chart data
    func convertStatisticsValues(stisticsValues: [Double], forRange range: HealthManagerStatisticsRangeType) -> [ChartDataEntry] {
        let indexIncrement = range == .Month || range == .Year ? 2 : 1;//For year and Month we add 2 for index because we ahve empty values on left and right to make a gap for xAxis
        //for week we have only one empty value left and right on xAxis
        var yVals: [ChartDataEntry] = []

        for (index, value) in stisticsValues.enumerate() {
            if value > 0.0 {
                yVals.append(BarChartDataEntry(value: value, xIndex: index+indexIncrement))
            }
        }
        return yVals
    }

    func getChartDataForRange(range: HealthManagerStatisticsRangeType, type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        switch range {
            case .Week:
                return self.getChartDataForWeek(type, values: values, minValues: minValues)
            case .Month:
                return self.getChartDataForMonth(type, values: values, minValues: minValues)
            case .Year:
                return self.getChartDataForYear(type, values: values, minValues: minValues)
        }
    }

    func getYValuesForScatterChart (minValues: [Double], maxValues: [Double], period: HealthManagerStatisticsRangeType) -> [ChartDataEntry] {
        var yVals: [ChartDataEntry] = []
        let indexIncrement = period == .Month || period == .Year ? 2 : 1;
        for (index, minValue) in minValues.enumerate() {
            let maxValue = maxValues[index]
            if maxValue > 0 && minValue > 0 {
                yVals.append(BarChartDataEntry(values: [minValue, maxValue] , xIndex: index+indexIncrement))
            } else if maxValue > 0 {
                yVals.append(BarChartDataEntry(values: [maxValue] , xIndex: index+indexIncrement))
            }
        }
        return yVals
    }

    func getChartDataFor(xVals: [String], yVals: [ChartDataEntry], type: ChartType) -> ChartData {
        switch type {
            case .BarChart:
                return barChartDataWith(xVals, yVals: yVals)
            case .LineChart:
                return lineChartDataWith(xVals, yVals: yVals)
            case .ScatterChart:
                return scatterChartDataWith(xVals, yVals: yVals)
        }
    }

    func getBloodPressureChartData(range: HealthManagerStatisticsRangeType, systolicMax: [Double], systolicMin: [Double], diastolicMax: [Double], diastolicMin: [Double]) -> ChartData{
        let systolicWeekData = getYValuesForScatterChart(systolicMin, maxValues: systolicMax, period: range)
        let diastolicWeekData = getYValuesForScatterChart(diastolicMin, maxValues: diastolicMax, period: range)
        var xVals: [String] = []
        switch range {
            case .Week:
                xVals = getWeekTitles()
            case .Month:
                xVals = getMonthTitles()
            case .Year:
                xVals = getYearTitles()

        }
        return scatterChartDataWith(xVals, yVals1: systolicWeekData, yVals2: diastolicWeekData)
    }

    private func barChartDataWith(xVals: [String], yVals: [ChartDataEntry]) -> BarChartData {
        let daysDataSet = BarChartDataSet(yVals: yVals, label: "")
        daysDataSet.barSpace = 0.9
        daysDataSet.colors = [UIColor.colorWithHexString("#ffffff", alpha: 0.8)!]
        daysDataSet.drawValuesEnabled = false

        let barChartData = BarChartData(xVals: xVals, dataSets: [daysDataSet])
        return barChartData
    }

    private func lineChartDataWith(xVals: [String], yVals: [ChartDataEntry]) -> LineChartData {
        let lineChartDataSet = LineChartDataSet(yVals: yVals, label: "")
        lineChartDataSet.colors = [UIColor.whiteColor().colorWithAlphaComponent(0.3)]
        lineChartDataSet.circleRadius = 3.0
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.circleHoleRadius = 1.5
        lineChartDataSet.circleHoleColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        lineChartDataSet.circleColors = [UIColor.whiteColor()]
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.drawVerticalHighlightIndicatorEnabled = false

        let lineChartData = LineChartData(xVals: xVals, dataSets: [lineChartDataSet])
        return lineChartData
    }

    private func scatterChartDataWith(xVals: [String], yVals:[ChartDataEntry], dataSetType: DataSetType = DataSetType.HeartRate) -> ScatterChartData {

        let dataSet = MCScatterChartDataSet(yVals: yVals, label: "")
        dataSet.dataSetType = dataSetType
        dataSet.colors = [UIColor.whiteColor()]
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.drawVerticalHighlightIndicatorEnabled = false

        let chartData = ScatterChartData(xVals: xVals, dataSets: [dataSet])
        return chartData
    }

    private func scatterChartDataWith(xVals: [String], yVals1:[ChartDataEntry], yVals2:[ChartDataEntry]) -> ScatterChartData {

        let dataSet1 = MCScatterChartDataSet(yVals: yVals1, label: "")
        dataSet1.dataSetType = .BloodPressureTop
        dataSet1.colors = [UIColor.whiteColor()]
        dataSet1.drawValuesEnabled = false
        dataSet1.drawHorizontalHighlightIndicatorEnabled = false
        dataSet1.drawVerticalHighlightIndicatorEnabled = false

        let dataSet2 = MCScatterChartDataSet(yVals: yVals2, label: "")
        dataSet2.dataSetType = .BloodPressureBottom
        dataSet2.colors = [UIColor.whiteColor()]
        dataSet2.drawValuesEnabled = false
        dataSet2.drawHorizontalHighlightIndicatorEnabled = false
        dataSet2.drawVerticalHighlightIndicatorEnabled = false

        let chartData = ScatterChartData(xVals: xVals, dataSets: [dataSet1, dataSet2])
        return chartData
    }
    //TODO: Maybe we should remove this function
    //Don't know for what this function exists. Can't find usage in the project.
    func scatterChartDataWithMultipleEntries(xVals: [String], yVals:[[ChartDataEntry]], types: [DataSetType?]) -> ScatterChartData {
        
        assert(xVals.count != yVals.count, "Data input is invalid, x and y value arrays count should be equal")

        var dataSets = [MCScatterChartDataSet]()
        
        var i = 0
        while i <= yVals.count {
            let dataSet1 = MCScatterChartDataSet(yVals: yVals[i], label: "")
            dataSet1.colors = i % 2 == 0 ? [UIColor.whiteColor()] : [UIColor.redColor()]
            if types[i] != nil { dataSet1.dataSetType = types[i]! }
            dataSet1.drawValuesEnabled = false
            dataSets.append(dataSet1)
            i += 1
        }
        
        let chartData = ScatterChartData(xVals: xVals, dataSets: dataSets)
        return chartData
    }
    
    
    func scatterChartDataWithMultipleDataSets(xVals: [String?], dataSets:[IChartDataSet]) -> ScatterChartData? {
        
        var xValues : [String] = Array()
        //dataSets[0] yAxis
        //dataSets[1] xAxis
        let finalDataSet = MCScatterChartDataSet()
        finalDataSet.dataSetType = .HeartRate
        finalDataSet.colors = [UIColor.whiteColor()]
        finalDataSet.drawValuesEnabled = false
        finalDataSet.drawHorizontalHighlightIndicatorEnabled = false
        finalDataSet.drawVerticalHighlightIndicatorEnabled = false
        
        //create xAxis labels
        if let dSet1 = dataSets[0] as? ChartDataSet, let dSet2 = dataSets[1] as? ChartDataSet {
            //cleanup data sets if one of the dataset has empty values
            let iterateDataSet = dSet2.yVals.count > dSet1.yVals.count ? dSet2 : dSet1
            //interate over dataSet that has beggest count of values
            //if they are equal no metter on which dataset we will make iteration
            for yVal in iterateDataSet.yVals {
                //first we should get values for current index of yVal
                let currentYValueFirstDataSet = dSet1.yValForXIndex(yVal.xIndex)
                let currentYValueSecondDataSet = dSet2.yValForXIndex(yVal.xIndex)
                //then we check if any of these values are NaN (so the values for given index doesn't exists)
                if currentYValueFirstDataSet.isNaN || currentYValueSecondDataSet.isNaN {
                    //get entries for indexes
                    //we should check that index of the entry is equal to the yVal index
                    //see entryForXIndex for explaantion
                    //finaly we removing entry from dataset that has no pair
                    let firstSetEntry = dSet1.entryForXIndex(yVal.xIndex)!
                    if firstSetEntry.xIndex == yVal.xIndex {
                        dSet1.removeEntry(firstSetEntry)
                    }
                    let secondSetEntry = dSet2.entryForXIndex(yVal.xIndex)!
                    if secondSetEntry.xIndex == yVal.xIndex {
                        dSet2.removeEntry(secondSetEntry)
                    }
                }
            }
            //sort values in the right way
            dSet2.yVals.sortInPlace({ (firstEntry, secondEntry) -> Bool in
                firstEntry.value < secondEntry.value
            })
            //prepare xAxis labels
            for yValue in dSet2.yVals {
                let currentYValue = dataSets[0].yValForXIndex(yValue.xIndex)
                if (currentYValue != Double.NaN) {
                    //chek is number decimal or not
                    let numberIsDecimal = yValue.value - floor(yValue.value) > 0.001
                    let label: String
                    if !numberIsDecimal {
                        label = "\(Int(yValue.value))";
                    } else {
                        label = "\(yValue.value)"
                    }
                    if !xValues.contains(label) {//skip repeated values
                        //they shouldn't be added to the xAxis labels beaceuse they will be grouped into one BarChartEntry
                        xValues.append(label)
                    }
                }
            }
            var repeadetValuesIndexes: [Int] = []
            var countOfrepeatedValues: Int = 0
            for (index, yValue) in dSet2.yVals.enumerate() {//iterate over second dataset and find repeated values
                let newIndex = index + 1 - countOfrepeatedValues
                let chartEntryAlreadyAdded = repeadetValuesIndexes.contains(yValue.xIndex)
                if chartEntryAlreadyAdded {//check if we already added this value
                    //works only for repeated values
                    continue
                }
                var entriesArray: [Double] = []
                var finalChartEntry: BarChartDataEntry?
                //try to find values that are repeated
                let filteredYValues = dSet2.yVals.filter({ (entry) -> Bool in
                    return entry.value == yValue.value
                })
                if filteredYValues.count > 1 {//we found values that are repeated
                    for chartEntry in filteredYValues {
                        repeadetValuesIndexes.append(chartEntry.xIndex)
                        let currentYValue = dataSets[0].yValForXIndex(chartEntry.xIndex)
                        entriesArray.append(currentYValue)
                    }
                    //we need this hack because of calculating x indexes
                    /*
                     For example we have three repeated values. So we should skip two indexes
                     That's why we rounding number of repated values to the closest Int value
                     */
                    countOfrepeatedValues = Int (ceil(Double(entriesArray.count)/2))
                    finalChartEntry = BarChartDataEntry(values: entriesArray, xIndex: newIndex)
                } else {//we didn't find any repeated values
                    let currentYValue = dataSets[0].yValForXIndex(yValue.xIndex)
                    finalChartEntry = BarChartDataEntry(values: [currentYValue], xIndex: newIndex)
                }
                finalDataSet.addEntry(finalChartEntry!)
            }
        }
        
        var newValues : [String] = Array()
        newValues.append("")//gap from the left side
        newValues += xValues
        newValues.append("")//gap from the right side
        let chartData = ScatterChartData(xVals: newValues, dataSets: [finalDataSet])
        return chartData
    }
    
    func lineChartWithMultipleDataSets(xVals: [String?], dataSets:[IChartDataSet]) -> LineChartData? {
        var i = 0
        for dataSet1 in dataSets {
            if let dSet = dataSet1 as? ChartBaseDataSet {
                dSet.colors = i % 2 == 0 ? [UIColor.whiteColor()] : [UIColor.redColor()]
            }
            i += 1
        }
        let chartData = LineChartData(xVals: xVals, dataSets: dataSets)
        return chartData
    }

    // MARK :- Get all data for type
    
    func getAllDataForCurrentPeriodForSamlpe(qType : HKSampleType,  _chartType: ChartType?) {

        if #available(iOS 9.3, *) {
            if qType.identifier == HKQuantityTypeIdentifierAppleExerciseTime {
                return
            }
        }
        
        let type = qType.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : qType.identifier
        let chartType = _chartType == nil ? chartTypeForQuantityTypeIdentifier(type) : _chartType
        let key = type + "\(self.rangeType.rawValue)"
        
        log.warning("Getting chart data for \(type)")
        
        if type == HKQuantityTypeIdentifierHeartRate || type == HKQuantityTypeIdentifierUVExposure {
            // We should get max and min values. because for this type we are using scatter chart
            HealthManager.sharedManager.getChartDataForQuantity(qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                if values.count > 0 {
                    self.typesChartData[key] = self.getChartDataForRange(self.rangeType, type: chartType!, values: values[0], minValues: values[1])
                }
            }
        } else if type == HKQuantityTypeIdentifierBloodPressureSystolic {
            // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
            HealthManager.sharedManager.getChartDataForQuantity(HKObjectType.quantityTypeForIdentifier(type)!, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                if values.count > 0 {
                    self.typesChartData[key] = self.getBloodPressureChartData(self.rangeType,
                                                                              systolicMax: values[0], systolicMin: values[1],
                                                                              diastolicMax: values[2], diastolicMin: values[3])
                }
            }
        } else {
            HealthManager.sharedManager.getChartDataForQuantity(qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [Double]
                self.typesChartData[key] = self.getChartDataForRange(self.rangeType, type: chartType!, values: values, minValues: nil)
            }
        }
    }
    
    func gettAllDataForSpecifiedType(chartType: ChartType, completion: () -> Void) {
        resetOperation()
        for qType in PreviewManager.chartsSampleTypes {
            _chartDataOperationQueue.addOperationWithBlock({
                self.getAllDataForCurrentPeriodForSamlpe(qType, _chartType: chartType)
            })
        }
        addCompletionForOperationQueue(completion)
    }
    
    func getAllDataForCurrentPeriod(completion: () -> Void) {
        //always reset current operation queue before start new one
        resetOperation()
        for qType in PreviewManager.chartsSampleTypes {
            _chartDataOperationQueue.addOperationWithBlock({ 
                self.getAllDataForCurrentPeriodForSamlpe(qType, _chartType: nil)
            })
        }
        addCompletionForOperationQueue(completion)
    }

    // MARK :- Chart titles for X

    func getWeekTitles () -> [String] {
        let currentDate = NSDate()
        let weekAgoDate = currentDate - 7.days
        var weekTitles: [String] = []
        var prevMonthDates: [NSDate] = []
        var currentMonthDates: [NSDate] = []

        weekTitles.append("")//create a gap for the left side

        for index in 1...7 {
            let day = weekAgoDate + index.days
            if day.month < currentDate.month {
                prevMonthDates.append(day)
            } else {
                currentMonthDates.append(day)
            }
        }

        for (index, date) in prevMonthDates.enumerate() {
            weekTitles.append(convertDateToWeekString(date, forIndex: index))
        }

        for (index, date) in currentMonthDates.enumerate() {
            weekTitles.append(convertDateToWeekString(date, forIndex: index))
        }

        weekTitles.append("")//create a gap for the right side
        return weekTitles
    }

    func getMonthTitles () -> [String] {
        var monthTitles: [String] = []
        let currentDate = NSDate()
        let numberOfDays = 31//max number of days in one month
        let monthAgoDate = currentDate - numberOfDays.days
        var prevMonthDates: [NSDate] = []
        var currentMonthDates: [NSDate] = []

        //empty labels for left gap
        monthTitles.append("")
        monthTitles.append("")
        monthTitles.append("")

        for index in 1...numberOfDays {
            let day = monthAgoDate + index.days
            if day.month < currentDate.month {
                prevMonthDates.append(day)
            } else {
                currentMonthDates.append(day)
            }
        }

        for (index, date) in prevMonthDates.enumerate() {
            monthTitles.append(convertDateToWeekString(date, forIndex: index))
        }

        for (index, date) in currentMonthDates.enumerate() {
            monthTitles.append(convertDateToWeekString(date, forIndex: index))
        }

        //empty labels for right gap
        monthTitles.append("")
        monthTitles.append("")
        monthTitles.append("")

        return monthTitles
    }

    func getYearTitles () -> [String] {
        let numOfMonth = 13
        let currentDate = NSDate()
        let dateYearAgo = currentDate - 1.years
        var prevYearMonthes: [NSDate] = []
        var currentYearMonthes: [NSDate] = []
        var yearTitles: [String] = []

        yearTitles.append(" ")//space for gap

        for index in 0...(numOfMonth-1) {
            let date = dateYearAgo + index.months
            date.year < currentDate.year ? prevYearMonthes.append(date) : currentYearMonthes.append(date)
        }

        for (index, date) in prevYearMonthes.enumerate() {
            yearTitles.append(convertDateToYearString(date, forIndex: index))
        }

        for (index, date) in currentYearMonthes.enumerate() {
            yearTitles.append(convertDateToYearString(date, forIndex: index))
        }

        yearTitles.append(" ")//space for gap

        return yearTitles
    }

    //MARK: Help
    func chartTypeForQuantityTypeIdentifier(qType: String) -> ChartType {
        if let chartType = chartTypeToQuantityType[qType] {
            return chartType
        }
        return .BarChart
    }

    func convertDateToYearString (date: NSDate, forIndex index: Int) -> String {
        let month = date.monthName
        let cutRange = month.startIndex ..< month.startIndex.advancedBy(3)
        let monthName = month.length > 3 ? month.substringWithRange(cutRange) : month

        if index == 0 {
            return monthName + " \(date.year)"
        }

        return monthName
    }

    func convertDateToWeekString (date: NSDate, forIndex index: Int) -> String {
        if index == 0 {
            let month = date.monthName
            let cutRange = month.startIndex ..< month.startIndex.advancedBy(3)
            let monthName = month.length > 3 ? month.substringWithRange(cutRange) : month
            return monthName + " \(date.day)"
        }
        return "\(date.day)"
    }
    
    func addCompletionForOperationQueue(completion: () -> Void) {
        _chartDataOperationQueue.operations.onFinish({
            NSOperationQueue.mainQueue().addOperationWithBlock({
                completion()
            })
        })
    }
    
    func resetOperation () {
        _chartDataOperationQueue.cancelAllOperations()
        _chartDataOperationQueue = NSOperationQueue()
    }
}
