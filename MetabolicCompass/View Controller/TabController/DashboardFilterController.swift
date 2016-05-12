//
//  DashboardFilterController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardFilterController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var data: [DashboardFilterItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    
    @IBAction func onClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.navigationController?.navigationBar.barStyle = .Black;
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        // fake data
        
        self.data = [DashboardFilterItem(title: "Weight",
            items: [DashboardFilterCellData(title: "Under 50", selected: false, filterType: 0),
                    DashboardFilterCellData(title: "Between 50-100", selected: false, filterType: 0),
                    DashboardFilterCellData(title: "Between 100-150", selected: true, filterType: 0),
                    DashboardFilterCellData(title: "More than 200", selected: true, filterType: 0)]),
        
                     DashboardFilterItem(title: "Body Mass Index",
                        items: [DashboardFilterCellData(title: "Under 18(underweight)", selected: true, filterType: 0),
                            DashboardFilterCellData(title: "Between 18-25(standard)", selected: false, filterType: 0),
                            DashboardFilterCellData(title: "Between 25-30(overweight)", selected: true, filterType: 0),
                            DashboardFilterCellData(title: "More than 30(obese)", selected: true, filterType: 0)])]
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].items.count
    }
    
    private let dashboardFilterCellIdentifier = "DashboardFilterCell"
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell  = tableView.dequeueReusableCellWithIdentifier(dashboardFilterCellIdentifier, forIndexPath: indexPath) as! DashboardFilterCell
        cell.data = self.data[indexPath.section].items[indexPath.row]
        
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("DashboardHeaderCell") as! DashboardFilterHeaderCell
        cell.captionLabel.text = self.data[section].title
        return cell;
    }
    
    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? DashboardFilterCell
        cell?.didPressButton(self)
        
        var selectedCount = 0
        for item in self.data[indexPath.section].items {
            if (item.selected) {
                selectedCount += 1;
            }
        }
        
        if (selectedCount == 0) {
            cell?.didPressButton(self)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }

}
