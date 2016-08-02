//
//  CorrelationLineChartCell.swift
//  MetabolicCompass
//
//  Created by rost srost on 8/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts

class TwoLineCorrelcationCell: LineChartCollectionCell {

    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var secondaryChartMinValueLabel: UILabel!
    @IBOutlet weak var secondaryChartMaxValueLabel: UILabel!
    
    func updateRightAxisWith(minValue: Double?, maxValue: Double?) {
        let leftAxis = chartView.leftAxis
        leftAxis.removeAllLimitLines()
        if let maxValue = maxValue, let minValue = minValue {
            let topLimitMax = maxValue + (maxValue/3)
            let topLimit = ChartLimitLine(limit:topLimitMax)
            topLimit.lineWidth = 1
            topLimit.lineDashLengths = [3.0, 3.0]
            topLimit.lineColor = UIColor.colorWithHexString("#338aff", alpha: 0.4)!
            leftAxis.axisMaxValue = topLimitMax
            leftAxis.axisMinValue = minValue - (minValue/3)
            leftAxis.addLimitLine(topLimit)
            
            secondaryChartMinValueLabel.text = String(format:"%.0f", leftAxis.axisMinValue)
            secondaryChartMaxValueLabel.text = String(format:"%.0f", leftAxis.axisMaxValue)
        }
    }
    
    func updateMinMaxTitlesWithValues(minValue:String, maxValue:String) {
        secondaryChartMinValueLabel.text = minValue
        secondaryChartMaxValueLabel.text = maxValue
    }

}
