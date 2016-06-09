//
//  ScatterChartCollectionCell.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/1/16.
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit
import Charts

class ScatterChartCollectionCell: BaseChartCollectionCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        let scatterChart = self.chartView as! ScatterChartView
        scatterChart.renderer = MCScatterChartRenderer(dataProvider: scatterChart, animator: scatterChart.chartAnimator, viewPortHandler: scatterChart.viewPortHandler)
    }
}