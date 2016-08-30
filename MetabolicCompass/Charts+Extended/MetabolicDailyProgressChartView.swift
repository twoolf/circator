//
//  MetabolicDailyProgressChartView.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Charts

class MetabolicDailyProgressChartView : HorizontalBarChartView, DailyChartModelProtocol {

    var tip: TapTip! = nil
    var tipDummyLabel: UILabel! = nil

    var changeColorRecognizer: UITapGestureRecognizer! = nil
    var changeColorCompletion: (Void -> Void)? = nil

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

    class var mutedExerciseColor: UIColor {
        return UIColor.colorWithHexString("#021e46", alpha: 0.7)!
    }

    class var mutedEatingColor: UIColor {
        return UIColor.colorWithHexString("#021e47", alpha: 0.7)!
    }

    class var mutedSleepColor: UIColor {
        return UIColor.colorWithHexString("#021e48", alpha: 0.7)!
    }

    class var highlightFastingColor: UIColor {
        return UIColor.colorWithHexString("#ffca00", alpha: 0.7)!
    }
    
    func prepareChart () {
        self.descriptionText = ""
        self.drawValueAboveBarEnabled = true
        self.drawBarShadowEnabled = false
        self.scaleYEnabled = false
        self.highlightPerTapEnabled = false
        self.highlightPerDragEnabled = false
        self.highlightFullBarEnabled = false
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
        rightAxis.granularityEnabled = true
        rightAxis.granularity = 1.0
        
        self.legend.formSize = 0;
        self.legend.font = UIFont.systemFontOfSize(0)

        // Tip setup.
        tipDummyLabel = UILabel()
        tipDummyLabel.userInteractionEnabled = false
        tipDummyLabel.enabled = false
        tipDummyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tipDummyLabel)
        addConstraints([
            centerXAnchor.constraintEqualToAnchor(tipDummyLabel.centerXAnchor),
            centerYAnchor.constraintEqualToAnchor(tipDummyLabel.centerYAnchor),
            tipDummyLabel.widthAnchor.constraintEqualToConstant(1),
            tipDummyLabel.heightAnchor.constraintEqualToConstant(1),
        ])

        let desc = "Your Body Clock shows the times you slept, ate, exercised and fasted over the last week. You can pinch to zoom in on your activities, or double-tap to highlight fasting periods."
        self.tip = TapTip(forView: tipDummyLabel, withinView: self, text: desc, width: 350, numTaps: 2, numTouches: 2, asTop: false)
        self.addGestureRecognizer(tip.tapRecognizer)

        changeColorRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleColors))
        changeColorRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(changeColorRecognizer)

        self.userInteractionEnabled = true
    }

    func updateChartData (animate: Bool = true, valuesArr: [[Double]], chartColorsArray: [[UIColor]]) {
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

        let labelsInHours: Int = 2
        let maxZoomWidthInHours: CGFloat = 2.0
        let zoomFactor: CGFloat = 24.0 / maxZoomWidthInHours

        let rightAxis = self.rightAxis
        rightAxis.axisMinValue = max(0.0, self.data!.yMin - 1.0)
        rightAxis.axisMaxValue = min(24.0, self.data!.yMax + 1.0)
        rightAxis.labelCount = Int(rightAxis.axisMaxValue - rightAxis.axisMinValue) / labelsInHours
        if animate { self.animate(yAxisDuration: 1.0) }

        self.setVisibleXRange(minXRange: CGFloat(self.xAxis.axisRange) / zoomFactor, maxXRange: CGFloat(self.xAxis.axisRange))
    }

    func toggleColors() {
        changeColorCompletion?()
    }

}