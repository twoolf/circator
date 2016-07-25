//
//  BaseChartCollectionCell.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/1/16.
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit
import Charts

class BaseChartCollectionCell: UICollectionViewCell {
    @IBOutlet weak var chartTitleLabel: UILabel!
    @IBOutlet weak var chartMinValueLabel: UILabel!
    @IBOutlet weak var chartMaxValueLabel: UILabel!
    @IBOutlet weak var chartBackgroundImage: UIImageView!
    @IBOutlet weak var chartView: BarLineChartViewBase!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        chartMinValueLabel.text = ""
        chartMaxValueLabel.text = ""
        chartBackgroundImage.layer.cornerRadius = 5.0
        chartBackgroundImage.layer.masksToBounds = true
        chartBackgroundImage.layer.borderWidth = 1.5
        chartBackgroundImage.layer.borderColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0).CGColor
        
        baseChartPreperation(self.chartView)
        
        self.backgroundColor = UIColor.clearColor()
        self.contentView.userInteractionEnabled = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        chartMinValueLabel.text = ""
        chartMaxValueLabel.text = ""
    }
    
    func baseChartPreperation (chart: BarLineChartViewBase){
        let xAxis = chart.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.spaceBetweenLabels = 2
        xAxis.axisLineDashLengths = [3.0]
        xAxis.gridLineDashPhase = 1
        xAxis.labelPosition = .Bottom
        xAxis.labelTextColor = UIColor.colorWithHexString("#ffffff", alpha: 0.4)!
        xAxis.axisLineColor = UIColor.colorWithHexString("#ffffff", alpha: 0.4)!
        
        let leftAxis = chart.leftAxis
        
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawLabelsEnabled = false
        
        let rightAxis = chart.rightAxis
        rightAxis.enabled = false
        
        chart.descriptionText = ""
        chart.noDataText = "No data available"
        chart.infoFont = ScreenManager.appFontOfSize(15)
        chart.infoTextColor = UIColor.colorWithHexString("#ffffff", alpha: 0.7)
        chart.legend.enabled = false
        chart.legend.formSize = 0
        
        let marker:BalloonMarker = getChartMarker()
        chart.marker = marker
        chart.drawMarkers = true

        chart.scaleXEnabled = false
        chart.scaleYEnabled = false
    }
    
    func updateLeftAxisWith(minValue: Double?, maxValue: Double?) {        
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
            
            chartMinValueLabel.text = String(format:"%.0f", leftAxis.axisMinValue)
            chartMaxValueLabel.text = String(format:"%.0f", leftAxis.axisMaxValue)
        }
    }
    
    func getChartMarker() -> BalloonMarker {
        let marker:BalloonMarker = BalloonMarker(color: UIColor.whiteColor(),
                                                 font: UIFont.systemFontOfSize(10),
                                                 insets: UIEdgeInsets(top: 5.0, left: 2.0, bottom: 0.0, right: 2.0))
        marker.minimumSize = CGSizeMake(37.0, 29.0)
        return marker
    }
}