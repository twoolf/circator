//
//  ChartsViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts

enum DataRangeType : Int {
    case Week = 0
    case Month
    case Year
}

class ChartsViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"
    private let chartCollectionDataSource = ChartCollectionDataSource()
    private let chartCollectionDelegate = ChartCollectionDelegate()
    private let chartsModel = BarChartModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barChartCellNib = UINib(nibName: "BarChartCollectionCell", bundle: nil)
        collectionView?.registerNib(barChartCellNib, forCellWithReuseIdentifier: barChartCellIdentifier)
        
        let lineChartCellNib = UINib(nibName: "LineChartCollectionCell", bundle: nil)
        collectionView?.registerNib(lineChartCellNib, forCellWithReuseIdentifier: lineChartCellIdentifier)
        
        let scatterChartCellNib = UINib(nibName: "ScatterChartCollectionCell", bundle: nil)
        collectionView.registerNib(scatterChartCellNib, forCellWithReuseIdentifier: scatterChartCellIdentifier)
        
        collectionView.delegate = chartCollectionDelegate
        collectionView.dataSource = chartCollectionDataSource
        
        getSampleCollectionData(DataRangeType.Week)
    }
    
    @IBAction func rangeChnaged(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case DataRangeType.Month.rawValue:
            getSampleCollectionData(DataRangeType.Month)
        case DataRangeType.Year.rawValue:
            getSampleCollectionData(DataRangeType.Year)
        default:
            getSampleCollectionData(DataRangeType.Week)
        }
    }
    
    func getSampleCollectionData (range: DataRangeType) {
        let iterations = 3
        var chartData:[ChartData] = []
        switch range {
        case .Month:
            for index in 0...iterations {
                if (index % 3 == 0) {
                    chartData.append(chartsModel.getChartDataForMonth(ChartType.BarChart))
                } else if (index % 2 == 0) {
                    chartData.append(chartsModel.getChartDataForMonth(ChartType.ScatterChart))
                } else {
                    chartData.append(chartsModel.getChartDataForMonth(ChartType.LineChart))
                }
            }
        case .Year:
            for index in 0...iterations {
                if (index % 3 == 0) {
                    chartData.append(chartsModel.getChartDataForYear(ChartType.BarChart))
                } else if (index % 2 == 0) {
                    chartData.append(chartsModel.getChartDataForYear(ChartType.ScatterChart))
                } else {
                    chartData.append(chartsModel.getChartDataForYear(ChartType.LineChart))
                }
            }
        default:
            for index in 0...iterations {
                if (index % 3 == 0) {
                    chartData.append(chartsModel.getChartDataForWeek(ChartType.BarChart))
                } else if (index % 2 == 0) {
                    chartData.append(chartsModel.getChartDataForWeek(ChartType.ScatterChart))
                } else {
                    chartData.append(chartsModel.getChartDataForWeek(ChartType.LineChart))
                }
            }
        }
        
        chartCollectionDataSource.collectionData = chartData
        collectionView.reloadData()
    }

}
