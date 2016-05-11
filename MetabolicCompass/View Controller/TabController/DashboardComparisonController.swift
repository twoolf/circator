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

class DashboardComparisonController:
    UIViewController,
    UITableViewDelegate,
    UITableViewDataSource
{

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource      = self
        self.tableView.delegate        = self
        self.tableView.allowsSelection = false
        
        AccountManager.shared.loginAndInitialize()
    }
    
    func contenteDidUpdate (notification: NSNotification) {
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contenteDidUpdate),
                                                         name: ContentManager.ContentDidUpdateNotification,
                                                         object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewManager.previewSampleTypes.count
    }
    
    private let dashboardComparisonCellIdentifier = "ComparisonCell"
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(dashboardComparisonCellIdentifier, forIndexPath: indexPath) as! DashboardComparisonCell
        
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType
        let timeSinceRefresh = NSDate().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate)
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
        let stale = timeSinceRefresh > Double(refreshPeriod)
        
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: PopulationHealthManager.sharedManager.mostRecentAggregates[sampleType] ?? [],
                         stalePopulation: stale)
        return cell
    }

}
