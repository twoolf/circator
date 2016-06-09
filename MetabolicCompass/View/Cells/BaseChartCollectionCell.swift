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
    
    @IBOutlet weak var chartBackgroundImage: UIImageView!
    @IBOutlet weak var chartView: BarLineChartViewBase!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        chartBackgroundImage.layer.cornerRadius = 5.0
        chartBackgroundImage.layer.masksToBounds = true
        chartBackgroundImage.layer.borderWidth = 1.5
        chartBackgroundImage.layer.borderColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0).CGColor
        
        baseChartPreperation(self.chartView)
        
        self.backgroundColor = UIColor.clearColor()
        self.userInteractionEnabled = false
    }
    
    func baseChartPreperation (chart: BarLineChartViewBase){
        let xAxis = chart.xAxis
        xAxis.drawGridLinesEnabled = false
        xAxis.spaceBetweenLabels = 2
        xAxis.axisLineDashLengths = [3.0]
        xAxis.gridLineDashPhase = 1
        xAxis.labelPosition = .Bottom
        xAxis.labelTextColor = UIColor.whiteColor()
        xAxis.axisLineColor = UIColor.whiteColor()
        
        let topLimit = ChartLimitLine(limit:50)
        topLimit.lineWidth = 1
        topLimit.lineDashLengths = [3.0, 3.0]
        topLimit.lineColor = UIColor.whiteColor()
        
        let leftAxis = chart.leftAxis
        leftAxis.addLimitLine(topLimit)
        leftAxis.axisMaxValue = 50.0
        leftAxis.axisMinValue = 0.0
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawGridLinesEnabled = false
        leftAxis.drawLabelsEnabled = false
        
        let rightAxis = chart.rightAxis
        rightAxis.enabled = false
        
        chart.descriptionText = ""
        chart.legend.enabled = false
        chart.legend.formSize = 0
        let marker:BalloonMarker = getChartMarker()
        chart.marker = marker
        chart.drawMarkers = true
        chart.scaleXEnabled = false
        chart.scaleYEnabled = false
    }
    
    func getChartMarker() -> BalloonMarker {
        let marker:BalloonMarker = BalloonMarker(color: UIColor.whiteColor(),
                                                 font: UIFont.systemFontOfSize(10),
                                                 insets: UIEdgeInsets(top: 5.0, left: 8.0, bottom: 0.0, right: 8.0))
        marker.minimumSize = CGSizeMake(37.0, 29.0)
        return marker
    }
}