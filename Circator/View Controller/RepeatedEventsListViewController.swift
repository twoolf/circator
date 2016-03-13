//
//  RepeatedEventsListViewController.swift
//  Circator
//
//  Created by Edwin L. Whitman on 3/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import CircatorKit
import Async
import Dodo
import HTPressableButton
import ResearchKit
import Pages
import Charts
import SwiftDate
import Former

class RepeatedEventsListViewController: UIViewController {
    
    // MARK: - Weekday Selector
    
    lazy var sundayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100))
        //button.titleLabel?.text = NSLocalizedString("Su", comment: "Sunday")
        button.setTitle("Su", forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var mondayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100))
        button.titleLabel?.text = NSLocalizedString("M", comment: "Monday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var tuesdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100))
        button.titleLabel?.text = NSLocalizedString("Tu", comment: "Tuesday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var wednesdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(110, 300, 100, 100))
        button.titleLabel?.text = NSLocalizedString("W", comment: "Wednesday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var thursdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(110, 300, 100, 100))
        button.titleLabel?.text = NSLocalizedString("Th", comment: "Thursday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var fridayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(110, 300, 100, 100))
        button.titleLabel?.text = NSLocalizedString("F", comment: "Friday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var saturdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(110, 300, 100, 100))
        button.titleLabel?.text = NSLocalizedString("Sa", comment: "Saturday")
        button.titleLabel?.textAlignment = .Center
        button.titleLabel?.textColor = UIColor.blackColor()
        return button
    }()
    
    lazy var weekdayRowSelector : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.sundayButton, self.mondayButton, self.tuesdayButton, self.wednesdayButton, self.thursdayButton, self.fridayButton, self.saturdayButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()
    
    // MARK: - Event Item, Cell and Table View
    
    class EventsListTableViewController : UITableViewController {
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            /*
            // Set table view header as row of weekdays
            let tableViewHeader = weekdayRowSelector // as! UITableViewCell
            tableViewHeader.frame = CGRectMake(0, 0, self.tableView.bounds.width, 100)
            tableViewHeader.backgroundColor = UIColor.blueColor()
            self.tableView.tableHeaderView = tableViewHeader
            */
            
            tableView.registerClass(EventItemTableViewCell.self, forCellReuseIdentifier: "EventItemTableViewCell")
        }
        
        override func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
            tableView.reloadData()
        }
        
        //Set section of table
        override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }
        
        //Set table to have one cell for every 30 mins within day
        override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 48
        }
        
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("EventItemTableViewCell") as! EventItemTableViewCell
            
            let subview = FormLabelCell()
            subview.formTextLabel()?.text = "time"
            cell.contentView.addSubview(subview)
            return cell
        }
        
        /*
        override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            return "Today"
        }
        
        override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
            view.tintColor = UIColor(red: 170/255.0, green: 131/255.0, blue: 224/255.0, alpha: 1.0)
            if let header = view as? UITableViewHeaderFooterView {
                header.textLabel!.font = UIFont(name: "HelveticaNeue-Thin", size: 14.0)
                header.textLabel!.textColor = UIColor.whiteColor()
            }
        }
        */
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViews()
        
    }
    
    private func configureViews() {
        
        
        //adding weekday selector view
        weekdayRowSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weekdayRowSelector)
        
        let weekdayRowSelectorConstraints: [NSLayoutConstraint] = [
            weekdayRowSelector.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            weekdayRowSelector.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            weekdayRowSelector.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor)
        ]
        
        view.addConstraints(weekdayRowSelectorConstraints)
        
        let eventsList = EventsListTableViewController()
        let eventsListView = eventsList.view
        eventsListView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(eventsList)
        view.addSubview(eventsListView)
        let eventsListViewConstraints: [NSLayoutConstraint] = [
            eventsListView.topAnchor.constraintEqualToAnchor(weekdayRowSelector.bottomAnchor),
            eventsListView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor),
            //eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            eventsListView.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventsListView.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor),
            eventsListView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
        ]
        view.addConstraints(eventsListViewConstraints)
        
        //view.addSubview(weekdayRowSelector)
        // Set frame coordinates for weekday header selector
        //var yHeaderPosition : CGFloat = 0.0
        /*
        if let nav = self.navigationController {
            yHeaderPosition = nav.navigationBar.frame.origin.y + nav.navigationBar.frame.size.height
        }
        */
        
        /*
        weekdayHeader.frame = CGRectMake(0, yHeaderPosition, self.view.frame.size.width, 100)
        weekdayHeader.backgroundColor = UIColor.orangeColor()
        */
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Repeated Events"
        
    }
    

}
