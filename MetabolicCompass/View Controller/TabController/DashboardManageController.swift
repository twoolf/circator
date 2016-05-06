//
//  DashboardManageController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardManageController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    var data: [DashboardMetricsConfigItem] = []
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar
        .titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
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
        cell.leftImageView.image         = appearanceProvider.imageForSampleType(item.type)
        cell.captionLabel.attributedText = appearanceProvider.titleForSampleType(item.type)
        return cell;
    }
}
