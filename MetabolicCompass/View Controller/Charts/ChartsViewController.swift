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
import MCCircadianQueries
import SwiftDate
import Crashlytics

enum DataRangeType : Int {
    case Week = 0
    case Month
    case Year
}

class ChartsViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var rangeType = DataRangeType.Week
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"
    private let chartCollectionDataSource = ChartCollectionDataSource()
    private let chartCollectionDelegate = ChartCollectionDelegate()
    private let chartsModel = BarChartModel()
    private var segmentControl: UISegmentedControl? = nil

    // MARK :- View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateNavigationBar()
        registerCells()
//        chartCollectionDataSource.model = chartsModel
        collectionView.delegate = chartCollectionDelegate
//        collectionView.dataSource = chartCollectionDataSource
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateChartDataWithClean), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateChartsData), name: NSNotification.Name(rawValue: HMDidUpdatedChartsData), object: nil)
        chartCollectionDataSource.updateData()
        updateChartsData()
        logContentView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logContentView(asAppear: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentView(withName: "Charts",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
                                       contentId: Date().intervalString(toDate: Date()),
                                       customAttributes: ["range": rangeType.rawValue])
    }

    // MARK :- Base preparation
    func updateChartDataWithClean() {
//        chartsModel.typesChartData = [:]
        IOSHealthManager.sharedManager.cleanCache()
        IOSHealthManager.sharedManager.collectDataForCharts()
        activityIndicator.startAnimating()
    }
    
    func updateChartsData () {
        if !activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }
//        chartsModel.getAllDataForCurrentPeriod(completion: {
//        chartsModel(updateChartsData()) {
//            self.updateChartsData {
//            self.activityIndicator.stopAnimating()
//            self.collectionView.reloadData()
//        })
        chartsModel.getAllDataForCurrentPeriod(completion: {
            self.activityIndicator.stopAnimating()
            self.collectionView.reloadData()
        })
    }

    func registerCells () {
        let barChartCellNib = UINib(nibName: "BarChartCollectionCell", bundle: nil)
        collectionView.register(barChartCellNib, forCellWithReuseIdentifier: barChartCellIdentifier)
//        collectionView?.register(barChartCellNib, forCellWithReuseIdentifier: barChartCellIdentifier)

        let lineChartCellNib = UINib(nibName: "LineChartCollectionCell", bundle: nil)
        collectionView?.register(lineChartCellNib, forCellWithReuseIdentifier: lineChartCellIdentifier)

        let scatterChartCellNib = UINib(nibName: "ScatterChartCollectionCell", bundle: nil)
        collectionView.register(scatterChartCellNib, forCellWithReuseIdentifier: scatterChartCellIdentifier)
    }

    func updateNavigationBar () {
        let manageButton = ScreenManager.sharedInstance.appNavButtonWithTitle(title: "Manage")
        manageButton.addTarget(self, action: #selector(manageCharts), for: .touchUpInside)
        let manageBarButton = UIBarButtonItem(customView: manageButton)
        self.navigationItem.leftBarButtonItem = manageBarButton
        self.navigationItem.title = NSLocalizedString("CHART", comment: "chart screen title")
        
//        let correlateButton = ScreenManager.sharedInstance.appNavButtonWithTitle("Correlate")
//        correlateButton.addTarget(self, action: #selector(correlateChart), forControlEvents: .TouchUpInside)
//        let corrButton = UIBarButtonItem(customView: correlateButton)
//        self.navigationItem.rightBarButtonItem = corrButton
    }

    @IBAction func rangeChanged(_ sender: UISegmentedControl) {
        self.segmentControl = sender
//        var showCorrelate = false
//        let correlateSegment = sender.numberOfSegments-1
        switch sender.selectedSegmentIndex {
            case HealthManagerStatisticsRangeType.month.rawValue: break
//                chartsModel.rangeType = .month
            case HealthManagerStatisticsRangeType.year.rawValue:
//                chartsModel.rangeType = .year
                break
            default: break
//                chartsModel.rangeType = .week
        }
        logContentView()
        updateChartsData()
    }

    func manageCharts () {
        let manageController = UIStoryboard(name: "TabScreens", bundle: nil).instantiateViewController(withIdentifier: "manageCharts")
        self.present(manageController, animated: true) {}
    }

//    func correlateChart () {
//        if let correlateController = UIStoryboard(name: "TabScreens", bundle: nil).instantiateViewControllerWithIdentifier("correlatePlaceholder") as? UIViewController {
//            let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .Plain, target: self, action: #selector(dismissCorrelateChart))
//
//            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
//            self.navigationController?.pushViewController(correlateController, animated: true)
//            
//        }
//    }
//
//    func dismissCorrelateChart() {
//        dismissViewControllerAnimated(true) { _ in
//            if let sc = self.segmentControl {
//                sc.selectedSegmentIndex = 0
//                self.rangeChanged(sc)
//            }
//        }
//    }

}
