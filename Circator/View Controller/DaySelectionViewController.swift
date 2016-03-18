//
//  DaySelectionViewController.swift
//  Circator
//
//  Created by Sihao Lu on 2/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DaySelectionViewController: UITableViewController {
    
    var selectedIndices: Set<Int> = []
    
    var selectionUpdateHandler: ((Set<Int>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.format()
        navigationItem.title = "Days"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
        selectionUpdateHandler?(selectedIndices)
    }
    
    // MARK: - Table View Formatting
    
    func format() {
        
        tableView.scrollEnabled = false
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return view.bounds.height - navigationController!.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.size.height - 44.0*8
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.lightGrayColor()
        return view
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.lightGrayColor()
        return view
    }
    
    

    // MARK: - Table view data source
    
    private static let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dayCell", forIndexPath: indexPath)
        cell.textLabel?.text = self.dynamicType.dayNames[indexPath.row]
        cell.accessoryType = selectedIndices.contains(indexPath.row) ? .Checkmark : .None
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if selectedIndices.contains(indexPath.row) {
            selectedIndices.remove(indexPath.row)
        } else {
            selectedIndices.insert(indexPath.row)
        }
        cell.accessoryType = selectedIndices.contains(indexPath.row) ? .Checkmark : .None
        selectionUpdateHandler?(selectedIndices)
    }

}
