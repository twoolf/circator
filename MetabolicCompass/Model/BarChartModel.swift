//
// Created by Artem Usachov on 5/31/16.
// Copyright (c) 2016 SROST. All rights reserved.
//

import Foundation
import Charts

enum ChartType {
    case BarChart
    case LineChart
    case ScatterChart
}

class BarChartModel {
    //MARK: Data for YEAR
    
    func getXValuesForYear () -> [String] {
        var xValsArr: [String] = []
        let numOfMonth = 12
        
        xValsArr.append(" ")//space for gap
        
        for index in 1...numOfMonth {
            let monthString = String(index)
            xValsArr.append(monthString)
        }
        
        xValsArr.append(" ")//space for gap
        
        return xValsArr
    }
    
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
        
        let xValsArr = getXValuesForYear()
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
    
    func getXValuesForMonth() -> [String] {
        var xValsArr: [String] = []
        let numberOfDays = 31
        
        //empty labels for gap
        xValsArr.append("")
        xValsArr.append("")
        xValsArr.append("")
        
        for index in 1...numberOfDays {
            let dayString = String(index)
            if index == 19 {
                xValsArr.append("May " + dayString)
            } else {
                xValsArr.append(dayString)
            }
        }
        //empty labels for gap
        xValsArr.append("")
        xValsArr.append("")
        xValsArr.append("")
        
        return xValsArr
    }
    
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
        let xValsArr = getXValuesForMonth()
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
        let xVals = ["", "10", "11", "12", "13", "14", "15", "16", ""]
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
}
