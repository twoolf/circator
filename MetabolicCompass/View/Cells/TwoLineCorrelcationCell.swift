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

    func updateRightAxisWith(minValue: Double?, maxValue: Double?, minOffsetFactor: Double? = nil, maxOffsetFactor: Double? = nil) {
        let rightAxis = chartView.rightAxis
        rightAxis.removeAllLimitLines()
        if let maxValue = maxValue, let minValue = minValue {
            let maxMultiplier = maxOffsetFactor ?? 1/3
            let topLimitMax = maxValue + (maxMultiplier == 0 ? 0.0 : maxValue * maxMultiplier)
            let topLimit = ChartLimitLine(limit:topLimitMax)
            topLimit.lineWidth = 1
            topLimit.lineDashLengths = [3.0, 3.0]
            topLimit.lineColor = UIColor.colorWithHexString(rgb: "#338aff", alpha: 0.4)!
            rightAxis.axisMaxValue = topLimitMax
            let minMultiplier = minOffsetFactor ?? 1.3
            rightAxis.axisMinValue = minValue - (minMultiplier == 0 ? 0.0 : minValue * minMultiplier)
            rightAxis.addLimitLine(topLimit)

            secondaryChartMinValueLabel.text = String(format:"%.0f", rightAxis.axisMinValue)
            secondaryChartMaxValueLabel.text = String(format:"%.0f", rightAxis.axisMaxValue)
        }
    }

    func updateMinMaxTitlesWithValues(minValue:String, maxValue:String) {
        secondaryChartMinValueLabel.text = minValue
        secondaryChartMaxValueLabel.text = maxValue
    }

}
