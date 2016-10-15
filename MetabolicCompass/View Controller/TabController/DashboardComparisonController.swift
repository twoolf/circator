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

class DashboardComparisonController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let dashboardComparisonCellIdentifier = "ComparisonCell"
    @IBOutlet weak var tableView: UITableView!

    var activityIndicator: NVActivityIndicatorView! = nil
    var activityCnt: Int = 0
    var activityAsync: Async! = nil

    var comparisonTips: [Int:TapTip] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource      = self
        self.tableView.delegate        = self
        self.tableView.allowsSelection = false

        let sz: CGFloat = 25
        let screenSize = UIScreen.mainScreen().bounds.size
        let hOffset: CGFloat = screenSize.height < 569 ? 40.0 : 75.0

        let activityFrame = CGRectMake((screenSize.width - sz) / 2, (screenSize.height - (hOffset+sz)) / 2, sz, sz)
        self.activityIndicator = NVActivityIndicatorView(frame: activityFrame, type: .LineScale, color: UIColor.lightGrayColor())
        self.view.addSubview(self.activityIndicator)

        AccountManager.shared.loginAndInitialize(false)
    }
    
    func contentDidUpdate (notification: NSNotification) {
        self.tableView.reloadData()
        self.stopActivityIndicator()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.startActivityIndicator()
        AccountManager.shared.contentManager.initializeBackgroundWork()

        self.tableView.reloadData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contentDidUpdate), name: HMDidUpdateRecentSamplesNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateContent), name: UIApplicationDidBecomeActiveNotification, object: nil)
        logContentView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopActivityIndicator(true)
        AccountManager.shared.contentManager.stopBackgroundWork()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        logContentView(false)
    }

    func startActivityIndicator() {
        activityIndicator.startAnimating()
        activityCnt += 2

        if activityAsync != nil { activityAsync.cancel() }
        activityAsync = Async.main(after: 20.0) {
            self.activityCnt = 0
            if self.activityCnt == 0 && self.activityIndicator.animating { self.activityIndicator.stopAnimating() }
        }
    }

    func stopActivityIndicator(force: Bool = false) {
        activityCnt = force ? 0 : max(activityCnt - 1, 0)
        if (force || activityCnt == 0) && activityIndicator.animating { activityIndicator.stopAnimating() }
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentViewWithName("Population",
                                       contentType: asAppear ? "Appear" : "Disappear",
                                       contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
                                       customAttributes: nil)
    }

    func updateContent() {
        self.startActivityIndicator()
        AccountManager.shared.contentManager.resetBackgroundWork()
    }

    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewManager.previewSampleTypes.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(dashboardComparisonCellIdentifier, forIndexPath: indexPath) as! DashboardComparisonCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType

        let active = QueryManager.sharedManager.isQueriedType(sampleType)
        cell.setPopulationFiltering(active)

        let timeSinceRefresh = NSDate().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate)
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
        let stale = timeSinceRefresh > Double(refreshPeriod)
        
        cell.setUserData(MCHealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: PopulationHealthManager.sharedManager.mostRecentAggregates[sampleType] ?? [],
                         stalePopulation: stale)

        if indexPath.section == 0 && comparisonTips[indexPath.row] == nil {
            let targetView = cell

            let desc = "This table helps you compare your personal health stats (left column) to our study population's stats (right column). We show values older than 24 hours in yellow. You can pick measures to display with the Manage button."

            let tipAsTop = PreviewManager.previewSampleTypes.count > 6 && indexPath.row > PreviewManager.previewSampleTypes.count - 4
            comparisonTips[indexPath.row] = TapTip(forView: targetView, withinView: tableView, text: desc, width: 350, numTaps: 2, numTouches: 1, asTop: tipAsTop)
            targetView.addGestureRecognizer(comparisonTips[indexPath.row]!.tapRecognizer)
            targetView.userInteractionEnabled = true
        }

        return cell
    }

}
