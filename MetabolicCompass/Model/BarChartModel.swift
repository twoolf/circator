//
// Created by Artem Usachov on 5/31/16.
// Copyright (c) 2016 SROST. All rights reserved.
//

import Foundation
import Charts
import SwiftDate

enum ChartType {
    case BarChart
    case LineChart
    case ScatterChart
}

class BarChartModel {
    //MARK: Data for YEAR
        
    func getYValuesForYear (maxRange:UInt32 = 39) -> [BarChartDataEntry] {
        let numOfMonth = 12
        var yVals: [BarChartDataEntry] = []
        var range = maxRange
        
        for index in 1...numOfMonth {
            range += 1
            let value = Double(arc4random_uniform(range))
            yVals.append(BarChartDataEntry(value: max(value, 10.0), xIndex: index))
        }
        return yVals
    }
    
    func getChartDataForYear(type: ChartType) -> ChartData {
        
        let xValsArr = getYearTitles()
        let yValsTop = getYValuesForYear()
        let yValsBottom = getYValuesForYear(UInt32(10))

        switch type {
            case .BarChart:
                return barChartDataWith(xValsArr, yVals: yValsTop)
            case .LineChart:
                return lineChartDataWith(xValsArr, yVals: yValsTop)
            case .ScatterChart:
                return scatterChartDataWith(xValsArr, yVals1: yValsTop, yVals2: yValsBottom)
        }
    }
    
    //MARK: Data for MONTH
    
    func getYValuesForMonth(maxRange:UInt32 = 20) -> [ChartDataEntry] {
        let numberOfDays = 31
        var yVals: [ChartDataEntry] = []
        var range = maxRange
        
        for index in 2...numberOfDays+2 {
            range += 1
            let value = Double(arc4random_uniform(range))
            yVals.append(BarChartDataEntry(value: max(value, 10.0), xIndex: index))
        }
        return yVals
    }

    func getChartDataForMonth(type: ChartType) -> ChartData {
        let xValsArr = getMonthTitles()
        let yValsTop = getYValuesForMonth()
        let yValsBottom = getYValuesForMonth(UInt32(10))

        switch type {
            case .BarChart:
                return barChartDataWith(xValsArr, yVals: yValsTop)
            case .LineChart:
                return lineChartDataWith(xValsArr, yVals: yValsTop)
            case .ScatterChart:
                return scatterChartDataWith(xValsArr, yVals1: yValsTop, yVals2: yValsBottom)
        }
    }
    
    //MARK: Data for WEEK
    
    func getYValuesForWeek(maxRange:UInt32 = 39)-> [ChartDataEntry] {
        var yVals: [ChartDataEntry] = []
        var range: UInt32 = maxRange
        
        for index in 1...7 {
            range += 1
            let value = Double(arc4random_uniform(range))
            yVals.append(BarChartDataEntry(value: max(value, 10.0), xIndex: index))
        }
        
        return yVals
    }
    
    func getValuesForWeekScatterChart () -> [ChartDataEntry]{
        var yVals: [ChartDataEntry] = []
        var range: UInt32 = 39
        
        for index in 1...7 {
            range += 1
            let value = Double(arc4random_uniform(range))
            yVals.append(BarChartDataEntry(values: [min(value, 4.0), value] , xIndex: index))
        }
        
        return yVals
    }
    
    func getChartDataForWeek(type: ChartType) -> ChartData {
        let xVals = getWeekTitles()
        let yValsTop = ChartType.ScatterChart == type ? getValuesForWeekScatterChart () : getYValuesForWeek()
//        let yValsBottom = getYValuesForWeek(UInt32(10))

        switch type {
            case .BarChart:
                return barChartDataWith(xVals, yVals: yValsTop)
            case .LineChart:
                return lineChartDataWith(xVals, yVals: yValsTop)
            case .ScatterChart:
                return scatterChartDataWith(xVals, yVals1: yValsTop, yVals2: [])
        }
    }
    
    //MARK: Prepate chart data

    private func barChartDataWith(xVals: [String], yVals: [ChartDataEntry]) -> BarChartData {
        let daysDataSet = BarChartDataSet(yVals: yVals, label: "")
        daysDataSet.barSpace = 0.9
        daysDataSet.colors = [UIColor .whiteColor()]
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
        let lineChartData = LineChartData(xVals: xVals, dataSets: [lineChartDataSet])

        return lineChartData
    }
    
    private func scatterChartDataWith(xVals: [String], yVals1:[ChartDataEntry], yVals2:[ChartDataEntry]) -> ScatterChartData {
        
        let topDataSet = MCScatterChartDataSet(yVals: yVals2, label: "")
        topDataSet.dataSetType = DataSetType.BloodPressureTop
        topDataSet.colors = [UIColor.whiteColor()]
        topDataSet.drawValuesEnabled = false
        
        let bottomDataSet = MCScatterChartDataSet(yVals: yVals1, label: "")
        bottomDataSet.dataSetType = DataSetType.HartRate
        bottomDataSet.colors = [UIColor.whiteColor()]
        bottomDataSet.drawValuesEnabled = false
        
        let chartData = ScatterChartData(xVals: xVals, dataSets: [topDataSet, bottomDataSet])
        return chartData
    }
    
    //MARK: Week titles
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
    
    //MARK: Month titles
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
    
    func getYearTitles () -> [String]{
        let numOfMonth = 12
        let currentDate = NSDate()
        let dateYearAgo = currentDate - numOfMonth.months
        var prevYearMonthes: [NSDate] = []
        var currentYearMonthes: [NSDate] = []
        var yearTitles: [String] = []
        
        yearTitles.append(" ")//space for gap
        
        for index in 1...numOfMonth {
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
}
