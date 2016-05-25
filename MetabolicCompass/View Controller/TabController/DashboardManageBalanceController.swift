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
    
    let selectController: BalanceSampleListController = {
        let storyboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("BalanceSampleListController") as! BalanceSampleListController
        controller.modalPresentationStyle = .OverCurrentContext
        return controller
    }()
    
    var data: [DashboardMetricsConfigItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    private let cellIdentifier = "DashboardManageCell"
    
    //MARK: View life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appNavBarTextColor(),
                                                  NSFontAttributeName : ScreenManager.appNavBarFont()]
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
    
    //MARK: Working with content
    
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
    
    //MARK: controller methods
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    //MARK: Actions
    @IBAction func onClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        save()
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ManageBalanceCell
        let item = self.data[indexPath.row]
        cell.leftImage.image = appearanceProvider.imageForSampleType(item.type, active: true)
        cell.titleLabel.text = appearanceProvider.titleForSampleType(item.type, active: true).string
        cell.sampleTypesIndex = indexPath.row
        cell.data = item
        return cell;
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! ManageBalanceCell
        self.selectController.selectdType = selectedCell.data.object
        self.selectController.parentCell  = selectedCell
        self.presentViewController(self.selectController, animated: true, completion: nil)
    }
}
