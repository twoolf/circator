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
    
    //TODO: fix bug: left edge of button cuts off right edge of adjacent button
    
    lazy var sundayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        //button.titleLabel?.text = NSLocalizedString("Su", comment: "Sunday")
        button.setTitle("Su", forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var mondayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        button.titleLabel?.text = NSLocalizedString("M", comment: "Monday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var tuesdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        button.titleLabel?.text = NSLocalizedString("Tu", comment: "Tuesday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var wednesdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        button.titleLabel?.text = NSLocalizedString("W", comment: "Wednesday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var thursdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        button.titleLabel?.text = NSLocalizedString("Th", comment: "Thursday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var fridayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        button.titleLabel?.text = NSLocalizedString("F", comment: "Friday")
        button.titleLabel?.textAlignment = .Center
        return button
    }()
    
    lazy var saturdayButton: UIButton = {
        let button = HTPressableButton(frame: CGRectMake(0, 0, 100, 100), buttonStyle: .Circular)
        button.shadowHeight = 0.0
        button.titleLabel?.text = NSLocalizedString("Sa", comment: "Saturday")
        button.titleLabel?.textAlignment = .Center
        button.titleLabel?.textColor = UIColor.blackColor()
        return button
    }()
    
    lazy var weekdayRowSelector : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.sundayButton, self.mondayButton, self.tuesdayButton, self.wednesdayButton, self.thursdayButton, self.fridayButton, self.saturdayButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillProportionally
        stackView.alignment = UIStackViewAlignment.Center
        stackView.spacing = 0
        return stackView
    }()
    
    var eventsList : EventsListTableViewController?
    
    // MARK: - Event Item, Cell and Table View
    
    class EventsListTableViewController : UITableViewController {
        
        let hours : [String] = ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM", "7 AM", "8 AM", "9 AM", "10 AM", "11 AM", "Noon", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", "6 PM", "7 PM", "8 PM", "9 PM", "10 PM", "11 PM", "12 AM"]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.estimatedRowHeight = 44.0
            tableView.rowHeight = UITableViewAutomaticDimension
            /*
            // Set table view header as row of weekdays
            let tableViewHeader = weekdayRowSelector // as! UITableViewCell
            tableViewHeader.frame = CGRectMake(0, 0, self.tableView.bounds.width, 100)
            tableViewHeader.backgroundColor = UIColor.blueColor()
            self.tableView.tableHeaderView = tableViewHeader
            */
            
            //EventItemTableViewCell.self
            tableView.registerClass(EventItemTableViewCell.self, forCellReuseIdentifier: "EventItemTableViewCell")
            tableView.registerClass(EventListTimeSeperatorTableViewCell.self, forCellReuseIdentifier: "EventListTimeSeperatorTableViewCell")
            //self.tableView.contentInset = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
            
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
            
            return 24 * 2 + 24 + 1
        }
        
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            if indexPath.row % 3 == 0 || indexPath.row == 73 {
                return 11.0
            } else {
                return 44.0
            }
        }
        
        override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return UITableViewAutomaticDimension
        }
        
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            var cell : UITableViewCell
            //Initialize and clear cell for input
            if indexPath.row % 3 != 0 && indexPath.row != 73 {
                cell = tableView.dequeueReusableCellWithIdentifier("EventItemTableViewCell", forIndexPath: indexPath) as! EventItemTableViewCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("EventListTimeSeperatorTableViewCell", forIndexPath: indexPath) as! EventListTimeSeperatorTableViewCell
            }
            
            //clears subviews previously rendered to cell
            for view in cell.contentView.subviews {
                view.removeFromSuperview()
            }
            
            //sets cell to be filled with event item cell
            if indexPath.row % 3 != 0 && indexPath.row != 73 {
                let subview = FormLabelCell()
                subview.formTextLabel()?.text = "\(indexPath.row)"
                cell.contentView.addSubview(subview)
            //sets cell to filled with time seperator
            } else {
                let timeLabel = UILabel()
                timeLabel.translatesAutoresizingMaskIntoConstraints = false
                timeLabel.text = hours[indexPath.row/3]
                timeLabel.font = UIFont.systemFontOfSize(11, weight: UIFontWeightSemibold)
                timeLabel.backgroundColor = UIColor.grayColor()

                cell.contentView.addSubview(timeLabel)
                
                let timeLabelConstraints : [NSLayoutConstraint] = [
                    timeLabel.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    timeLabel.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor),
                    timeLabel.leftAnchor.constraintEqualToAnchor(cell.contentView.leftAnchor, constant: 30)
                ]
                
                cell.contentView.addConstraints(timeLabelConstraints)
                
                let seperatorLine = UIView(frame: CGRectMake(0,0,1,1))
                seperatorLine.translatesAutoresizingMaskIntoConstraints = false
                seperatorLine.backgroundColor = UIColor.redColor()
                                
                cell.contentView.addSubview(seperatorLine)
                
                let seperatorLineConstraints : [NSLayoutConstraint] = [
                    seperatorLine.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    seperatorLine.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor),
                    //seperatorLine.widthAnchor.constraintEqualToAnchor(cell.widthAnchor),
                    seperatorLine.leftAnchor.constraintEqualToAnchor(timeLabel.rightAnchor, constant: 15),
                    seperatorLine.rightAnchor.constraintEqualToAnchor(cell.contentView.rightAnchor)
                ]
                
                cell.contentView.addConstraints(seperatorLineConstraints)
            }

            
            return cell
        }
        
        
        override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
            return false
        }
        
        override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
            return 0
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
        self.configureView()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Repeated Events"
        self.eventsList!.tableView.reloadData()
    }
    
    private func format() {
        
    }
    
    //Sets configuration of view controller
    private func configureView() {
        
        //Sets format options
        self.format()
        
        //adding weekday selector view
        weekdayRowSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weekdayRowSelector)
        
        let weekdayRowSelectorConstraints: [NSLayoutConstraint] = [
            weekdayRowSelector.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 15),
            weekdayRowSelector.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor),
            weekdayRowSelector.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            weekdayRowSelector.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor),
            NSLayoutConstraint(item: weekdayRowSelector, attribute: .Height, relatedBy: .Equal, toItem: view.layoutMarginsGuide, attribute: .Width, multiplier: 0.1428571429, constant: 0),
        ]
        
        //weekdayRowSelector.frame.size.height = (weekdayRowSelector.frame.size.width * 0.1428571429)
        
        view.addConstraints(weekdayRowSelectorConstraints)
        
        eventsList = EventsListTableViewController()
        eventsList!.automaticallyAdjustsScrollViewInsets = false
        let eventsListView = self.eventsList!.view
        eventsListView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(self.eventsList!)
        view.addSubview(eventsListView)
        let eventsListViewConstraints: [NSLayoutConstraint] = [
            eventsListView.topAnchor.constraintEqualToAnchor(weekdayRowSelector.bottomAnchor, constant: 15),
            eventsListView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor),
            //eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: -30),
            eventsListView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: 15),
            //eventsListView.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor)
        ]
        
        view.addConstraints(eventsListViewConstraints)
        
    }
    

    

}
