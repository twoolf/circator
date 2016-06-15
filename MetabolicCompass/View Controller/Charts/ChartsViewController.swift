//
//  ChartsViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts
import HealthKit
import MetabolicCompassKit

enum DataRangeType : Int {
    case Week = 0
    case Month
    case Year
}

class ChartsViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    private var rangeType = DataRangeType.Week
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"
    private let chartCollectionDataSource = ChartCollectionDataSource()
    private let chartCollectionDelegate = ChartCollectionDelegate()
    private let chartsModel = BarChartModel()
    
    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        upateNavigationBar()
        registerCells()
        chartCollectionDataSource.model = chartsModel
        collectionView.delegate = chartCollectionDelegate
        collectionView.dataSource = chartCollectionDataSource
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getChartsData()
    }
    
    //MARK: Base preparation
    
    func getChartsData () {
        
        let group = dispatch_group_create()
        for qType in PreviewManager.supportedTypes {
            if qType.identifier == HKCategoryTypeIdentifierSleepAnalysis {
                continue
            }
            if #available(iOS 9.3, *) {
                if qType.identifier == HKQuantityTypeIdentifierAppleExerciseTime {
                    continue
                }
            } else {
                // Fallback on earlier versions
            }
            chartCollectionDataSource.data.append(qType.identifier)
            dispatch_group_enter(group)
            chartsModel.getAllRangesDataForType(qType.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : qType.identifier) {
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }
    
    func registerCells () {
        let barChartCellNib = UINib(nibName: "BarChartCollectionCell", bundle: nil)
        collectionView?.registerNib(barChartCellNib, forCellWithReuseIdentifier: barChartCellIdentifier)
        
        let lineChartCellNib = UINib(nibName: "LineChartCollectionCell", bundle: nil)
        collectionView?.registerNib(lineChartCellNib, forCellWithReuseIdentifier: lineChartCellIdentifier)
        
        let scatterChartCellNib = UINib(nibName: "ScatterChartCollectionCell", bundle: nil)
        collectionView.registerNib(scatterChartCellNib, forCellWithReuseIdentifier: scatterChartCellIdentifier)
    }
    
    func upateNavigationBar () {
        let manageButton = ScreenManager.sharedInstance.appNavButtonWithTitle("Manage")
        manageButton.addTarget(self, action: #selector(manageCharts), forControlEvents: .TouchUpInside)
        let manageBarButton = UIBarButtonItem(customView: manageButton)
        self.navigationItem.leftBarButtonItem = manageBarButton
        self.navigationItem.title = NSLocalizedString("CHART", comment: "chart screen title")
    }
    
    @IBAction func rangeChnaged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case HealthManagerStatisticsRangeType.Month.rawValue:
                chartsModel.rangeType = .Month
            case HealthManagerStatisticsRangeType.Year.rawValue:
                chartsModel.rangeType = .Year
            default:
                chartsModel.rangeType = .Week
        }
        collectionView.reloadData()
    }
    
    func manageCharts () {
        print ("manageCharts")
    }

}
