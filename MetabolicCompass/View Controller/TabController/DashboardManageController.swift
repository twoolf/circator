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
            //self.tableView.reloadData()
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appNavBarTextColor(),
                                                  NSFontAttributeName : ScreenManager.appNavBarFont()]
        self.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationBar.barStyle = UIBarStyle.Black;
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        self.tableView.allowsSelectionDuringEditing = true
        
        self.data = []
        
        for type in PreviewManager.supportedTypes {
            let active = PreviewManager.previewSampleTypes.contains(type)
            self.data.append(DashboardMetricsConfigItem(type: type.identifier, active: active, object: type))
        }
        
        self.tableView.editing = true
    }
    
    func save() {
        
        var samples = [HKSampleType]()
        
        for item in self.data {
            if (item.active) {
                samples.append(item.object)
            }
        }
        
        PreviewManager.updatePreviewSampleTypes(samples)
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
        
         let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ManageDashboardCell
        
        let item = self.data[indexPath.row]
        cell.showsReorderControl = false
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
