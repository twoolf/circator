//
//  DashboardManageController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

class DashboardManageController: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        self.tableView.allowsSelectionDuringEditing = true
        
        // TODO: read/save data from storage
        self.data = [
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierBodyMass, active: true),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierHeartRate, active: false),
            DashboardMetricsConfigItem(type: HKCategoryTypeIdentifierSleepAnalysis, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierBodyMassIndex, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryCaffeine, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietarySugar, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryCholesterol, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryProtein, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryFatTotal, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryCarbohydrates, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryFatPolyunsaturated, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryFatSaturated, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryFatMonounsaturated, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryWater, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierDietaryEnergyConsumed, active: false),
            DashboardMetricsConfigItem(type: HKCorrelationTypeIdentifierBloodPressure, active: false),
            DashboardMetricsConfigItem(type: HKQuantityTypeIdentifierStepCount, active: false),]
        
        self.tableView.editing = true
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
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    private let cellIdentifier = "DashboardManageCell"
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
         let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ManageDashboardCell
        
        let item = self.data[indexPath.row]
        cell.showsReorderControl         = false
        cell.updateSelectionStatus(item.active, appearanceProvider: appearanceProvider, itemType: item.type)
        return cell;
    }
    
    func  selectedItemsCount() -> Int {
        var selected = 0
        
        for item in self.data {
            if (item.active) {
                selected += 1
            }
        }
        
        return selected
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let obj = tableView.cellForRowAtIndexPath(indexPath) as? ManageDashboardCell
        guard let cell = obj else {
            return
        }

        let item = self.data[indexPath.row]
        
        if (item.active && self.selectedItemsCount() == 1) {
            return
        }
        
        item.active = !item.active
        cell.updateSelectionStatus(item.active, appearanceProvider: appearanceProvider, itemType: item.type)
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let itemToMove = self.data[fromIndexPath.row]
        self.data.removeAtIndex(fromIndexPath.row)
        self.data.insert(itemToMove, atIndex: toIndexPath.row)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.showsReorderControl = false
    }
}
