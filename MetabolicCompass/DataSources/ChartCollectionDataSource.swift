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
    
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: BaseChartCollectionCell
        if (indexPath.row % 3 == 0) {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(barChartCellIdentifier, forIndexPath: indexPath) as! BarChartCollectionCell
        } else if (indexPath.row % 2 == 0){
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(scatterChartCellIdentifier, forIndexPath: indexPath) as! ScatterChartCollectionCell
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier(lineChartCellIdentifier, forIndexPath: indexPath) as! LineChartCollectionCell
        }
        cell.chartView.data = collectionData[indexPath.row]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "segmentHeader", forIndexPath: indexPath)
    }
}