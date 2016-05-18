//
//  MetabolicDailyProgressChartView.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Charts

class MetabolicDailyPorgressChartView : HorizontalBarChartView {
    
    class var exerciseColor: UIColor {
        return UIColor.colorWithHexString("#009A00", alpha: 0.7)!
    }
    
    class var eatingColor: UIColor {
        return UIColor.colorWithHexString("#E4442D", alpha: 0.7)!
    }
    
    class var sleepColor: UIColor {
        return UIColor.colorWithHexString("#008BFF", alpha: 0.7)!
    }
    
    class var fastingColor: UIColor {
        return UIColor.colorWithHexString("#001844", alpha: 0.7)!
    }
    
    private let dailyChartModel = DailyChartModel()
    
    func prepareChart () {
        
//        dailyChartModel.getLastSevenDays()
        
        self.drawValueAboveBarEnabled = true
        self.drawBarShadowEnabled = false
        self.maxVisibleValueCount = 24
        
        let xAxis = self.xAxis;
        xAxis.labelPosition = .Bottom;
        xAxis.labelTextColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)!
        xAxis.labelFont = UIFont.systemFontOfSize(10)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.gridLineWidth = 0;
        
        let leftAxis = self.leftAxis;
        leftAxis.enabled = false
        leftAxis.axisMinValue = 0.0
        leftAxis.axisMaxValue = 24.0
        
        self.legend.formSize = 0;
        self.legend.font = UIFont.systemFontOfSize(0)
//        self.contentView.legend.xEntrySpace = 1.0;
        self.updateChartData()
    }
    
    private func updateChartData () {
        let exerciseColor = UIColor.greenColor()
        let eatColor = UIColor.redColor()
        let sleepColor = UIColor.blueColor()
        let fastingColor = UIColor.clearColor()
        //days
        let days = ["", "", "", "", "", "", ""]
//        var colors:[UIColor] = []
        var entriesArray: [BarChartDataEntry] = []
        let valuesArr = [[2.0, 3.0, 4.0, 3.0, 2.0, 0.2, 0.7],
                         [3.0, 5.0, 3.6, 2.0, 1.0, 0.2, 0.7],
                         [1.0, 2.0, 6.0, 4.0, 1.5, 0.2, 0.7],
                         [4.0, 3.2, 4.4, 3.0, 2.0, 0.2, 0.7],
                         [0.0, 3.0, 4.0, 3.1, 2.2, 0.2, 0.7],
                         [1.2, 2.1, 4.3, 3.4, 2.0, 0.2, 0.7],
                         [2.9, 3.3, 4.6, 3.7, 2.8, 0.9, 0.7]]
        
        for (index, values) in valuesArr.enumerate() {
            let entry = BarChartDataEntry.init(values: values, xIndex: index)
            entriesArray.append(entry)
        }
        
        let set = BarChartDataSet.init(yVals: entriesArray, label: nil)
        set.barSpace = 0.3
        set.drawValuesEnabled = false
        set.colors = [fastingColor, exerciseColor, sleepColor, eatColor]
        
        let data = BarChartData.init(xVals: days, dataSets: [set])
        self.data = data
        
        let formatter = NSNumberFormatter()
        formatter.positiveFormat = "#"
        formatter.locale = NSLocale.currentLocale()
        
        let rightAxis = self.rightAxis
        rightAxis.axisMinValue = max(0.0, self.data!.yMin - 1.0)
        rightAxis.axisMaxValue = min(23.0, self.data!.yMax + 1.0)
        rightAxis.labelCount = Int(rightAxis.axisMaxValue - rightAxis.axisMinValue)
        rightAxis.labelTextColor = UIColor.colorWithHexString("#ffffff", alpha: 0.3)!
        rightAxis.labelFont = UIFont.systemFontOfSize(12)
        rightAxis.drawAxisLineEnabled = true
        rightAxis.drawGridLinesEnabled = true
        rightAxis.valueFormatter = formatter
        rightAxis.axisMinValue = 0.0
        rightAxis.axisMaxValue = 24.0
        rightAxis.gridLineWidth = 1
        rightAxis.gridLineDashPhase = 1
        rightAxis.gridLineDashLengths = [3.0]
    }
}