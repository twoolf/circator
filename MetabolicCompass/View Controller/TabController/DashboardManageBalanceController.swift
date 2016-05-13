//
//  DashboardManageBalanceController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import Async

class DashboardManageBalanceController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var data: [DashboardMetricsConfigItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        self.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationBar.barStyle = UIBarStyle.Black;
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        
        self.refreshContent()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contentDidChange), name: PMDidUpdateBalanceSampleTypesNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func refreshContent () {
        
        self.data = []
        
        for type in PreviewManager.balanceSampleTypes {
            self.data.append(DashboardMetricsConfigItem(type: type.identifier, active: true, object: type))
        }
        
        self.tableView.reloadData()
    }
    
    func contentDidChange() {
        
        Async.main {
            self.refreshContent()
        }
        
    }
    
    func save() {
        
//        var samples = [HKSampleType]()
//        
//        for item in self.data {
//            if (item.active) {
//                samples.append(item.object)
//            }
//        }
//        
//        PreviewManager.updatePreviewSampleTypes(samples)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        save()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    private let cellIdentifier = "DashboardManageCell"
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ManageBalanceCell
        let item = self.data[indexPath.row]
        cell.leftImage.image = appearanceProvider.imageForSampleType(item.type, active: true)
        cell.titleLabel.text = appearanceProvider.titleForSampleType(item.type, active: true).string
        cell.data = item
        return cell;
    }
}
