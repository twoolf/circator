//
//  DashboardComparisonController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

class DashboardComparisonController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let dashboardComparisonCellIdentifier = "ComparisonCell"
    @IBOutlet weak var tableView: UITableView!

    var comparisonTips: [Int:TapTip] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource      = self
        self.tableView.delegate        = self
        self.tableView.allowsSelection = false

        AccountManager.shared.loginAndInitialize(false)
    }
    
    func contentDidUpdate (notification: NSNotification) {
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        AccountManager.shared.contentManager.initializeBackgroundWork()
        self.tableView.reloadData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contentDidUpdate), name: HMDidUpdateRecentSamplesNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateContent), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func updateContent() {
        AccountManager.shared.contentManager.resetBackgroundWork()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        AccountManager.shared.contentManager.stopBackgroundWork()
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: PopulationHealthManager.sharedManager.mostRecentAggregates[sampleType] ?? [],
                         stalePopulation: stale)

        if indexPath.section == 0 && indexPath.row < 3 && comparisonTips[indexPath.row] == nil {
            let targetView = cell

            let desc = "This table helps you compare your personal health stats (left column) to our study population's stats (right column). We show values older than 24 hours in yellow. You can pick which measures to display with the Manage button, and change the population compared with the Filter button."

            comparisonTips[indexPath.row] = TapTip(forView: targetView, text: desc, width: 350, numTaps: 2, numTouches: 2, asTop: false)
            targetView.addGestureRecognizer(comparisonTips[indexPath.row]!.tapRecognizer)
            targetView.userInteractionEnabled = true
        }

        return cell
    }

}
