//
//  DaySelectionViewController.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 2/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

/**
 Supporting events that repeat: structued by days/times for meals, exercise, sleep
 
 - note: works with RepeatedEventsController
 */
class DaySelectionViewController: UITableViewController {
    
    var selectedIndices: Set<Int> = []
    
    var selectionUpdateHandler: ((Set<Int>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Days"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
        selectionUpdateHandler?(selectedIndices)
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
