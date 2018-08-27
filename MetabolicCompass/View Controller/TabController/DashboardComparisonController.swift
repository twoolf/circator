//
//  DashboardComparisonController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import NVActivityIndicatorView

class DashboardComparisonController: UIViewController, UITableViewDelegate, UITableViewDataSource, AppActivityIndicatorContainer {
    private let dashboardComparisonCellIdentifier = "ComparisonCell"
    @IBOutlet weak var tableView: UITableView!

    private(set) var activityIndicator: AppActivityIndicator?
    var activityCnt: Int = 0
    var activityAsync: Async? = nil

    var comparisonTips: [Int:TapTip] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator = AppActivityIndicator.forView(container: view)

        self.tableView.dataSource      = self
        self.tableView.delegate        = self
        self.tableView.allowsSelection = false
        
    }

    @objc func contentDidUpdate (_ notification: NSNotification) {
        self.tableView.reloadData()
        self.stopActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(self.contentDidUpdate), name: NSNotification.Name(rawValue: HMDidUpdateRecentSamplesNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshData), name: NSNotification.Name(rawValue: HMDidUpdateAnyMeasures), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateContent), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
//        self.updateContent()

        self.tableView.reloadData()
        logContentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
        self.stopActivityIndicator(true)
        AccountManager.shared.contentManager.stopBackgroundWork()
        logContentView(false)
    }

    func startActivityIndicator() {
        showActivity()
        activityCnt += 1

        activityAsync?.cancel()
        activityAsync = nil
        activityAsync = Async.main(after: 20.0) { [weak self] in
            self?.stopActivityIndicator(true)
        }
    }

    func stopActivityIndicator(_ force: Bool = false) {
        activityCnt = force ? 0 : max(activityCnt - 1, 0)
        if (force || activityCnt == 0) && isInProgress() {
            activityCnt = 0
            activityAsync?.cancel()
            activityAsync = nil
            hideActivity()
        }
    }

    func logContentView(_ asAppear: Bool = true) {
        Answers.logContentView(withName: "Population",
                                       contentType: asAppear ? "Appear" : "Disappear",
                                       contentId: Date().weekdayName,
                                       customAttributes: nil)
    }

    @objc func updateContent() {
        self.startActivityIndicator()
        AccountManager.shared.contentManager.initializeBackgroundWork()
    }

    @objc func refreshData() {
        ComparisonDataModel.sharedManager.updateIndividualData(types: PreviewManager.previewSampleTypes) { _ in () }
    }

    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewManager.previewSampleTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: dashboardComparisonCellIdentifier, for: indexPath as IndexPath) as! DashboardComparisonCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType

        let active = QueryManager.sharedManager.isQueriedType(sample: sampleType)
        cell.setPopulationFiltering(active: active)

//        let timeSinceRefresh = DateInterval(start: Date.distantPast, end: PopulationHealthManager.sharedManager.aggregateRefreshDate)
//        let timeSinceRefresh = DateInterval().intersection(with: PopulationHealthManager.sharedManager.aggregateRefreshDate ?? Date.distantPast())
//        let timeSinceRefresh = Date().addingTimeInterval(PopulationHealthManager.sharedManager.aggregateRefreshDate ?? Date.distantPast())
//        let timeSinceRefresh = DateInterval().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate ?? Date.distantPast())
//        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency()
//        let stale = timeSinceRefresh > DateInterval(start: Date(), duration: TimeInterval(refreshPeriod))
        let stale = true

        let individualSamples = ComparisonDataModel.sharedManager.recentSamples[sampleType] ?? [HKSample]()
        let populationSamples = ComparisonDataModel.sharedManager.recentAggregates[sampleType] ?? []
        cell.setUserData(individualSamples, populationAverageData: populationSamples, stalePopulation: stale)

        if indexPath.section == 0 && comparisonTips[indexPath.row] == nil {
            let targetView = cell

            let desc = "This table helps you compare your personal health stats (left column) to our study population's stats (right column). We show values older than 24 hours in yellow. You can pick measures to display with the Manage button."

            let tipAsTop = PreviewManager.previewSampleTypes.count > 6 && indexPath.row > PreviewManager.previewSampleTypes.count - 4
            comparisonTips[indexPath.row] = TapTip(forView: targetView, withinView: tableView, text: desc, width: 350, numTaps: 2, numTouches: 1, asTop: tipAsTop)
            targetView.addGestureRecognizer(comparisonTips[indexPath.row]!.tapRecognizer)
            targetView.isUserInteractionEnabled = true
        }

        return cell
    }

}
