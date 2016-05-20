//
//  MetabolicDailyProgressChartView.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Charts

class MetabolicDailyPorgressChartView : HorizontalBarChartView, DailyChartModelProtocol {
    
    class var exerciseColor: UIColor {
        return UIColor.colorWithHexString("#20990b", alpha: 0.7)!
    }
    
    class var eatingColor: UIColor {
        return UIColor.colorWithHexString("#e84c2c", alpha: 0.7)!
    }
    
    class var sleepColor: UIColor {
        return UIColor.colorWithHexString("#338aff", alpha: 0.7)!
    }
    
    class var fastingColor: UIColor {
        return UIColor.colorWithHexString("#021e45", alpha: 0.7)!
    }
    
    func prepareChart () {
        self.descriptionText = ""
        self.drawValueAboveBarEnabled = true
        self.drawBarShadowEnabled = false
        self.maxVisibleValueCount = 24
        let xAxis = self.xAxis;
        xAxis.labelPosition = .Bottom;
        xAxis.labelTextColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)!
        xAxis.labelFont = ScreenManager.appFontOfSize(12.0)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.gridLineWidth = 0;
        
        let leftAxis = self.leftAxis;
        leftAxis.enabled = false
        leftAxis.axisMinValue = 0.0
        leftAxis.axisMaxValue = 24.0
        
        let formatter = NSNumberFormatter()
        formatter.positiveFormat = "#"
        formatter.locale = NSLocale.currentLocale()
        
        let rightAxis = self.rightAxis
        rightAxis.labelTextColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)!
        rightAxis.labelFont = ScreenManager.appFontOfSize(12.0)
        rightAxis.drawAxisLineEnabled = true
        rightAxis.drawGridLinesEnabled = true
        rightAxis.valueFormatter = formatter
        rightAxis.axisMinValue = 0.0
        rightAxis.axisMaxValue = 24.0
        rightAxis.gridLineWidth = 1
        rightAxis.gridLineDashPhase = 1
        rightAxis.gridLineDashLengths = [3.0]
        
        self.legend.formSize = 0;
        self.legend.font = UIFont.systemFontOfSize(0)
    }
    
    func updateChartData (valuesArr: [[Double]], chartColorsArray: [[UIColor]]) {
        //days
        let days = ["", "", "", "", "", "", ""]
        var dataSetArray: [BarChartDataSet] = []
        for (index, values) in valuesArr.enumerate() {
            let entry = BarChartDataEntry.init(values: values, xIndex: index)
            let set = BarChartDataSet.init(yVals: [entry], label: nil)
            set.barSpace = 55
            set.drawValuesEnabled = false
            set.colors = chartColorsArray[index]
            dataSetArray.append(set)
        }
        let data = BarChartData.init(xVals: days, dataSets: dataSetArray)
        data.groupSpace = 75
        self.data = data
        
        let rightAxis = self.rightAxis
        rightAxis.axisMinValue = max(0.0, self.data!.yMin - 1.0)
        rightAxis.axisMaxValue = min(24.0, self.data!.yMax + 1.0)
        rightAxis.labelCount = Int(rightAxis.axisMaxValue - rightAxis.axisMinValue)
        self.animate(yAxisDuration: 1.0)
    }
}