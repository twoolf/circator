//
//  LineChartCollectionCell.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/1/16.
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit
import Charts

class LineChartCollectionCell: BaseChartCollectionCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let lineChart = self.chartView as! LineChartView
        lineChart.dragEnabled = false
        lineChart.pinchZoomEnabled = false
    }
}
