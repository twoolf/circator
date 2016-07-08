//
//  ChartCollectionDataSource.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/1/16.
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit
import Charts
import HealthKit

class ChartCollectionDataSource: NSObject, UICollectionViewDataSource {

    internal var collectionData: [ChartData] = []
    internal var model: BarChartModel?
    internal var data: [String] = []
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: BaseChartCollectionCell
        
        let typeToShow = data[indexPath.row] == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : data[indexPath.row]
        let chartType: ChartType = (model?.chartTypeForQuantityTypeIdentifier(typeToShow))!
        let key = typeToShow + "\((model?.rangeType.rawValue)!)"
        let chartData = model?.typesChartData[key]
        if(chartType == ChartType.BarChart) {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(barChartCellIdentifier, forIndexPath: indexPath) as! BarChartCollectionCell
        } else if (chartType == ChartType.LineChart) {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(lineChartCellIdentifier, forIndexPath: indexPath) as! LineChartCollectionCell
        } else {//Scatter chart
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(scatterChartCellIdentifier, forIndexPath: indexPath) as! ScatterChartCollectionCell
        }
        cell.chartView.data = nil
        if let yMax = chartData?.yMax, yMin = chartData?.yMin where yMax > 0 || yMin > 0 {
            cell.updateLeftAxisWith(chartData?.yMin, maxValue: chartData?.yMax)
            cell.chartView.data = chartData
        }
        cell.chartTitleLabel.text = appearanceProvider.stringForSampleType(typeToShow == HKQuantityTypeIdentifierBloodPressureSystolic ? HKCorrelationTypeIdentifierBloodPressure : typeToShow)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "segmentHeader", forIndexPath: indexPath)
    }
}