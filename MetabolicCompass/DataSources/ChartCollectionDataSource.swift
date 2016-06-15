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


class ChartCollectionDataSource: NSObject, UICollectionViewDataSource {

    internal var collectionData: [ChartData] = []
    internal var model: BarChartModel?
    internal var data: [String] = []
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: BaseChartCollectionCell
        
        let typeToShow = data[indexPath.row]
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
        cell.updateLeftAxisWith(chartData?.yMin, maxValue: chartData?.yMax)
        cell.chartView.data = chartData
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "segmentHeader", forIndexPath: indexPath)
    }
}