//
//  DefaultEventPeriodSelectorViewController.swift
//  Circator
//
//  Created by Edwin L. Whitman on 2/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import CircatorKit
import UIKit
import Async
import Former
import HTPressableButton
import Crashlytics
import SwiftDate

enum TimeOfDayInterval {
    case start
    case end
}

enum TimeDuration {
    case hours
    case minutes
    case seconds
}

/*
//minutes of hour when user awakens and goes to sleep
var wakeMinute = 0
var sleepMinute = 0

//hour of day when user awakens and goes to sleep
var wakeHour = 8
var sleepHour = 22


//specific date for time when user awakens and goes to sleep
let wakeTime = (wakeHour.hours + wakeMinute.minutes).fromDate(NSCalendar.currentCalendar().startOfDayForDate(NSDate()))
let sleepTime = (sleepHour.hours + sleepMinute.minutes).fromDate(NSCalendar.currentCalendar().startOfDayForDate(NSDate()))

//offset hours and minutes of lunch and dinner start times, note: breakfast is just awake to lunch
var lunchOffsetMinute = 0
var dinnerOffsetMinute = 0

var lunchOffsetHour = 11
var dinnerOffsetHour = 18
*/

var AwakeInterval: TimeOfDayInterval?
var AsleepInterval: TimeOfDayInterval?

var BreakfastInterval: TimeOfDayInterval?
var LunchInterval: TimeOfDayInterval?
var DinnerInterval: TimeOfDayInterval?

let sections : [String: [String: Int]] = ["Circadian Rhythmn": ["Awake": 1, "Asleep": 2], "Meal Periods": ["Breakfast": 3, "Lunch": 4, "Dinner": 5]]


class DefaultEventPeriodSelectorViewController : UITableViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Defaults"
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "defaultIntervalSettingsCell")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let keys = [String](sections.keys)
        return section < sections.count ? sections[keys[section]]!.count : 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keys = [String](sections.keys)
        return section < sections.count ? keys[section] : ""
    }
    
    func getSubviewTitle(section : Int, row: Int) -> String {
        let keys = [String](sections[([String](sections.keys))[section]]!.keys)
        return keys[row]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("defaultIntervalSettingsCell", forIndexPath: indexPath)
        cell.preservesSuperviewLayoutMargins = false
        //cell.separatorInset = UIEdgeInsetsZero
        //cell.layoutMargins = UIEdgeInsetsZero
        
        let subview = FormLabelCell()
        subview.formTextLabel()?.text = getSubviewTitle(indexPath.section, row: indexPath.row)
        cell.contentView.addSubview(subview)

        let timeInterval : [Int] = [1, 2]
        let timeIntervalText = FormLabelCell()
        let timeIntervalTextLabel = timeIntervalText.formTextLabel()
        timeIntervalTextLabel?.text = "\(timeInterval[0])" + " to " + "\(timeInterval[1])"
        timeIntervalTextLabel?.textAlignment = .Right
        cell.contentView.addSubview(timeIntervalText)
        
        cell.imageView?.image = nil
        cell.accessoryType = .DisclosureIndicator
        return cell
    }
}
