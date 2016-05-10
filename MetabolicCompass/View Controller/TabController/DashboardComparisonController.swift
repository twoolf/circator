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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchRecentSamples()
    }
    
    func withHKCalAuth(completion: Void -> Void) {
        
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                UINotifications.noHealthKit(self)
                return
            }
        
            EventManager.sharedManager.checkCalendarAuthorizationStatus(completion)
        }
    }
    
    func fetchRecentSamples() {
        withHKCalAuth {
            HealthManager.sharedManager.fetchMostRecentSamples() { (samples, error) -> Void in
                guard error == nil else { return }
                NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
                self.tableView.reloadData()
            }
        }
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
