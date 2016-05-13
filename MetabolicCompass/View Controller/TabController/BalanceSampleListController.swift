//
//  BalanceSampleListController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import Async

class BalanceSampleListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var selectdType: HKSampleType!
    weak var parentCell: UITableViewCell!
    var completionBlock: (Void -> Void)?
    
    var data: [DashboardMetricsConfigItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        
        self.refreshContent()
        
       
        
    }
    
    func refreshContent () {
        self.data = []
        
        for type in PreviewManager.supportedTypes {
            let contains = PreviewManager.balanceSampleTypes.contains(type)
            
            if (contains && type != self.selectdType) {
                continue
            }
            
            self.data.append(DashboardMetricsConfigItem(type: type.identifier, active: type == self.selectdType, object: type))
        }
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
        cell.showsReorderControl         = false
        
        cell.leftImageView.image = appearanceProvider.imageForSampleType(item.type, active: false)
        cell.captionLabel.text   = appearanceProvider.titleForSampleType(item.type, active: false).string
        cell.button.selected     = item.active
        return cell;
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let obj = tableView.cellForRowAtIndexPath(indexPath) as? ManageDashboardCell
        guard let cell = obj else {
            return
        }
        
        var index = 0
        for item in data {
            
            item.active = false
            if let otherCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? ManageDashboardCell {
                otherCell.button.selected = false
            }
            
            index += 1
        }
        
        let item = self.data[indexPath.row]
        item.active = true
        cell.button.selected = true
        
        Async.main(after: 0.1) {
            self.parentCell.resignFirstResponder()
            var samples = PreviewManager.balanceSampleTypes
            let index   = PreviewManager.balanceSampleTypes.indexOf(self.selectdType)!
            samples[index] = item.object
            PreviewManager.updateBalanceSampleTypes(samples)
        }
        
        guard let block = self.completionBlock else {return}
        block()
    }

}
