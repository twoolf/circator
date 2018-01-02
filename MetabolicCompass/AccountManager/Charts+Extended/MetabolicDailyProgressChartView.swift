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
    var changeColorCompletion: (() -> Void)? = nil
    
    class var exerciseColor: UIColor {
        return UIColor.colorWithHex(hex6: 0x20990b, alpha: 0.7)
    }
    
    class var eatingColor: UIColor {
        return UIColor.colorWithHex(hex6: 0xe84c2c, alpha: 0.7)
    }
    
    class var sleepColor: UIColor {
        return UIColor.colorWithHex(hex6: 0x338aff, alpha: 0.7)
    }
    
    class var fastingColor: UIColor {
        return UIColor.colorWithHex(hex6: 0x021e45, alpha: 0.7)
    }
    
    class var mutedExerciseColor: UIColor {
        return UIColor.colorWithHex(hex6: 0x021e46, alpha: 0.7)
    }
    
    class var mutedEatingColor: UIColor {
        return UIColor.colorWithHex(hex6: 0x021e47, alpha: 0.7)
    }
    
    class var mutedSleepColor: UIColor {
        return UIColor.colorWithHex(hex6: 0x021e48, alpha: 0.7)
    }
    
    class var highlightFastingColor: UIColor {
        return UIColor.colorWithHex(hex6: 0xffca00, alpha: 0.7)
    }
    
    func prepareChart () {
        self.chartDescription?.text = ""
        self.drawValueAboveBarEnabled = true
        self.drawBarShadowEnabled = false
        self.scaleYEnabled = false
        self.highlightPerTapEnabled = false
        self.highlightPerDragEnabled = false
        self.highlightFullBarEnabled = false
        let xAxis = self.xAxis;
        xAxis.labelPosition = .bottom;
        xAxis.labelTextColor = UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!
        xAxis.labelFont = ScreenManager.appFontOfSize(size: 12.0)
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = true
        xAxis.gridLineWidth = 0;
        
        let leftAxis = self.leftAxis;
        leftAxis.enabled = false
        leftAxis.axisMinimum = 0.0
        leftAxis.axisMaximum = 24.0
        
        let formatter = NumberFormatter()
        formatter.positiveFormat = "#"
        formatter.locale = NSLocale.current
        
        let rightAxis = self.rightAxis
        rightAxis.labelTextColor = UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!
        rightAxis.labelFont = ScreenManager.appFontOfSize(size: 12.0)
        rightAxis.drawAxisLineEnabled = true
        rightAxis.drawGridLinesEnabled = true
        rightAxis.valueFormatter = formatter as? IAxisValueFormatter
        rightAxis.axisMinimum = 0.0
        rightAxis.axisMaximum = 24.0
        rightAxis.gridLineWidth = 1
        rightAxis.gridLineDashPhase = 1
        rightAxis.gridLineDashLengths = [3.0]
        rightAxis.granularityEnabled = true
        rightAxis.granularity = 1.0
        
        self.legend.formSize = 0;
        self.legend.font = UIFont.systemFont(ofSize: 0)
        
        // Tip setup.
        tipDummyLabel = UILabel()
        tipDummyLabel.isUserInteractionEnabled = false
        tipDummyLabel.isEnabled = false
        tipDummyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tipDummyLabel)
        addConstraints([
            centerXAnchor.constraint(equalTo: tipDummyLabel.centerXAnchor),
            centerYAnchor.constraint(equalTo: tipDummyLabel.centerYAnchor),
            tipDummyLabel.widthAnchor.constraint(equalToConstant: 1),
            tipDummyLabel.heightAnchor.constraint(equalToConstant: 1),
            ])
        
        let desc = "Your Body Clock shows the times you slept, ate, exercised and fasted over the last week. You can pinch to zoom in on your activities, or double-tap to highlight fasting periods."
        self.tip = TapTip(forView: tipDummyLabel, withinView: self, text: desc, width: 350, numTaps: 2, numTouches: 2, asTop: false)
        self.addGestureRecognizer(tip.tapRecognizer)
        
        changeColorRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleColors))
        changeColorRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(changeColorRecognizer)
        
        self.isUserInteractionEnabled = true
    }
    
    func updateChartData (animate: Bool = true, valuesAndColors: [Date: [(Double, UIColor)]]) {
        
        var dataSetArray: [BarChartDataSet] = []
        var i = 0
        valuesAndColors.forEach { date, tuples in
            i = i+1
            var values: [Double] = []
            var colors: [UIColor] = []
            
            tuples.forEach { value, color in
                values.append(value)
                colors.append(color)
            }
            var entries: [BarChartDataEntry] = []
            for (index, value) in values.enumerated(){
                let entry = BarChartDataEntry.init(x: Double(i), y: value)
                entries.append(entry)
            }
            let set = BarChartDataSet.init(values: entries, label: "")
            set.drawValuesEnabled = false
            set.colors = colors
            dataSetArray.append(set)
        }
        let data = BarChartData.init(dataSets: dataSetArray)
        self.data = data
        
        let labelsInHours: Int = 2
        let maxZoomWidthInHours: CGFloat = 2.0
        let zoomFactor: Double = Double (24.0 / maxZoomWidthInHours)
        
        let rightAxis = self.rightAxis
        rightAxis.axisMinimum = max(0.0, self.data!.yMin - 1.0)
        rightAxis.axisMaximum = min(24.0, self.data!.yMax + 1.0)
        rightAxis.labelCount = Int(rightAxis.axisMaximum - rightAxis.axisMinimum) / labelsInHours
        if animate { self.animate(yAxisDuration: 1.0) }
        self.setVisibleXRange(minXRange: Double (self.xAxis.axisRange/zoomFactor), maxXRange: Double(self.xAxis.axisRange))
    }
    
    @objc func toggleColors() {
        changeColorCompletion?()
    }
}
