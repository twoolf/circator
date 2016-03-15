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

// MARK: - Data Structures

public enum Weekday : Int {
    case Monday = 1
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
    
    var description : String {
        switch self {
        case Monday:
            return "Monday"
        case Tuesday:
            return "Tuesday"
        case Wednesday:
            return "Wednesday"
        case Thursday:
            return "Thursday"
        case Friday:
            return "Friday"
        case Saturday:
            return "Saturday"
        case Sunday:
            return "Sunday"
        }
    }
}

public enum EventType {
    case Meal
    case Exercise
    case Sleep
}

public struct Event {
    var name : String
    var eventType : EventType
    var timeOfDayOffset : NSTimeInterval
    var duration : NSTimeInterval
    
    public init(nameOfEvent name : String, typeOfEvent type : EventType, timeOfDayOffsetInSeconds offset : NSTimeInterval, durationInSeconds duration : NSTimeInterval) {
        self.name = name
        self.eventType = type
        self.timeOfDayOffset = offset
        self.duration = duration
    }
}

public struct RepeatedEvent {
    var event : Event
    var frequency : [Weekday]
    
    public init(metabolicEvent event : Event, daysOfWeekOccurs frequency : [Weekday]) {
        self.event = event
        self.frequency = frequency
    }
}

//this would be saved in some plist eventually
var repeatedEvents : [RepeatedEvent]?

public func drawCirlce(FillColor color : UIColor) -> UIImage {
    
    let circleImage : UIImage = {
        
        //creates square in pixels as bounds of canvas
        let canvas = CGRectMake(0, 0, 100, 100)
        
        //creates vector path of circle bounded in canvas square
        let path = UIBezierPath(ovalInRect: canvas)
        
        //creates core graphics contexts and assigns reference
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        //sets context's fill register with color
        CGContextSetFillColorWithColor(context, color.CGColor)

        //draws path in context
        CGContextBeginPath(context)
        CGContextAddPath(context, path.CGPath)
        
        //draws path defined in canvas within graphics context
        CGContextDrawPath(context, .Fill)
        
        //creates UIImage from current graphics contexts and returns
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()
    
    return circleImage
}

class RepeatedEventsListViewController: UIViewController {
    
    // MARK: - Weekday Selector
    
    //UIButton subclass to associate selected weekday
    class WeekdayButton : UIButton {
        
        var dayOfWeek : Weekday? = nil
        
        init(dayOfWeek day : Weekday, frame: CGRect = CGRectZero) {
            super.init(frame : frame)
            self.dayOfWeek = day
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
    }
    
    //weekday buttons
    lazy var sundayButton: UIButton = {
        
        var button = WeekdayButton(dayOfWeek: Weekday.Sunday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Su", forState: .Normal)
        button.setTitle("Su", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var mondayButton: UIButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Monday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("M", forState: .Normal)
        button.setTitle("M", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var tuesdayButton: UIButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Tuesday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Tu", forState: .Normal)
        button.setTitle("Tu", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var wednesdayButton: UIButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Wednesday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("W", forState: .Normal)
        button.setTitle("W", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var thursdayButton: UIButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Thursday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Th", forState: .Normal)
        button.setTitle("Th", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var fridayButton: UIButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Friday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("F", forState: .Normal)
        button.setTitle("F", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var saturdayButton: UIButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Saturday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Sa", forState: .Normal)
        button.setTitle("Sa", forState: .Selected)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.orangeColor()), forState: .Normal)
        button.setBackgroundImage(drawCirlce(FillColor: UIColor.magentaColor()), forState: .Selected)
        button.addTarget(self, action: "setWeekdayButtonAndWeekdayLabel:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    //UIStack that display weekday buttons as single row
    lazy var weekdayRowSelector : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.sundayButton, self.mondayButton, self.tuesdayButton, self.wednesdayButton, self.thursdayButton, self.fridayButton, self.saturdayButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        stackView.backgroundColor = UIColor.clearColor()
        return stackView
    }()
    
    //variables used within table view
    
    //TODO: some of these variables should be initialized in or need to be moved to data source delegate...??
    
    var weekdayLabel : UILabel = UILabel()
    
    var eventsList : EventsListTableViewController = EventsListTableViewController()
    
    var currentDay : UIButton?
    
    var eventsForCurrentDay : [Event?] = [Event?](count: 48, repeatedValue: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Repeated Events"
    }
    
    //formats and styles view
    private func format() {
        
        view.backgroundColor = UIColor.lightGrayColor()
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
        
        view.addConstraints(weekdayRowSelectorConstraints)
        
        //set up weekday view
        self.weekdayLabel.translatesAutoresizingMaskIntoConstraints = false
        self.weekdayLabel.text = "Sunday"
        self.weekdayLabel.textAlignment = .Center
        self.weekdayLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightSemibold)
        self.weekdayLabel.textColor = UIColor.whiteColor()
        self.weekdayLabel.backgroundColor = UIColor.purpleColor()
        
        view.addSubview(weekdayLabel)
        
        let weekdayLabelConstraints: [NSLayoutConstraint] = [
            weekdayLabel.topAnchor.constraintEqualToAnchor(weekdayRowSelector.bottomAnchor),
            weekdayLabel.bottomAnchor.constraintEqualToAnchor(weekdayRowSelector.bottomAnchor, constant: 30),
            weekdayLabel.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor),
            weekdayLabel.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            weekdayLabel.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor),
        ]
        
        view.addConstraints(weekdayLabelConstraints)
        
        //set up table view
        self.eventsList.automaticallyAdjustsScrollViewInsets = false
        let eventsListView = self.eventsList.view
        eventsListView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(self.eventsList)
        view.addSubview(eventsListView)
        let eventsListViewConstraints: [NSLayoutConstraint] = [
            eventsListView.topAnchor.constraintEqualToAnchor(weekdayLabel.bottomAnchor),
            eventsListView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor),
            //eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: -30),
            eventsListView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: 15),
            //eventsListView.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor)
        ]
        
        view.addConstraints(eventsListViewConstraints)
        
    }
    
    internal func setWeekdayButtonAndWeekdayLabel(sender: WeekdayButton!) {
        
        //sets weekday label to selected day
        self.weekdayLabel.text = sender.dayOfWeek?.description
        
        //swaps current and selected day buttons setting states respectively
        currentDay?.selected = false
        sender.selected = true
        currentDay = sender
        
        //eventsList.tableView.reloadData()
        
        
    }
    
    // MARK: - Event Item, Cell and Table View
    
    class EventsListTableViewController : UITableViewController {
        
        let hours : [String] = ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM", "7 AM", "8 AM", "9 AM", "10 AM", "11 AM", "Noon", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", "6 PM", "7 PM", "8 PM", "9 PM", "10 PM", "11 PM", "12 AM"]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            //TODO: are these necessary? what are these values used for??
            //tableView.estimatedRowHeight = 44.0
            //tableView.rowHeight = UITableViewAutomaticDimension
            
            //removes default seperator lines
            tableView.separatorColor = UIColor.clearColor()
            
            //TODO: move current custom views into designated table view cell subclasses
            //custom table view cell classes
            tableView.registerClass(EventItemTableViewCell.self, forCellReuseIdentifier: "EventItemTableViewCell")
            tableView.registerClass(EventListTimeSeperatorTableViewCell.self, forCellReuseIdentifier: "EventListTimeSeperatorTableViewCell")
            
        }
        
        override func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
            tableView.reloadData()
        }
        
        //Set section of table
        override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            //two of these sections are to format the seperator lines properly
            return 3
        }
        
        //Set table to have one cell for every 30 mins within day
        override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            
            //main content
            if section == 1 {
               return 24 * 2 + 24 + 1
            }
            //top and bottom buffer sections
            return 1
        }
        
        //sets height of cells in table
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            if indexPath.row % 3 == 0 || indexPath.row == 73 {
                //edge case: height of buffer cell in top and bottom sections
                if indexPath.section != 1 {
                    return 5.0
                }
                //height of time seperator cells
                return 1.0
            } else {
                //height of cell containing event item view
                return 33.0
            }
        }
        
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            var cell : UITableViewCell
            //TODO: implement these subclasses, currently being unused
            //Initialize and clear cell for input
            if indexPath.row % 3 != 0 && indexPath.row != 73 {
                cell = tableView.dequeueReusableCellWithIdentifier("EventItemTableViewCell", forIndexPath: indexPath) as! EventItemTableViewCell
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("EventListTimeSeperatorTableViewCell", forIndexPath: indexPath) as! EventListTimeSeperatorTableViewCell
            }
            
            //removes white layer of each cell's default background for proper line seperator rendering
            cell.backgroundColor = UIColor.clearColor()
            
            //clears subviews previously rendered to cell
            for view in cell.contentView.subviews {
                view.removeFromSuperview()
            }
            
            //sets cell to be filled with event item cell
            if indexPath.row % 3 != 0 && indexPath.row != 73 {
                //debug prints to keep track of indexPath count
                let subview = FormLabelCell() 
                subview.formTextLabel()?.text = "\(indexPath.row)"
                cell.contentView.addSubview(subview)
                
                //set up event item view
                // TODO: refractor into seperate subclass
                
                //LOAD EVENT DATA FOR SPECIFIC CELL
                
                let eventView = EventItemView()
                eventView.translatesAutoresizingMaskIntoConstraints = false
                eventView.backgroundColor = UIColor.greenColor()
                
                cell.contentView.addSubview(eventView)
                
                let eventViewConstraints : [NSLayoutConstraint] = [
                    eventView.rightAnchor.constraintEqualToAnchor(cell.contentView.rightAnchor, constant: -30),
                    eventView.leftAnchor.constraintEqualToAnchor(cell.contentView.leftAnchor, constant: 15 + 90),
                    //TODO: need to build out if statement around top and bottom anchors for continuous and discrete event views
                    eventView.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    eventView.bottomAnchor.constraintEqualToAnchor(cell.contentView.bottomAnchor)
                ]
                
                cell.contentView.addConstraints(eventViewConstraints)
                
            //sets cell to filled with time seperator
            } else {
                
                // TODO: refractor time seperator into separate subclass
                //time label for seperator
                let timeLabel = UILabel()
                timeLabel.translatesAutoresizingMaskIntoConstraints = false
                timeLabel.text = hours[indexPath.row/3]
                timeLabel.font = UIFont.systemFontOfSize(11, weight: UIFontWeightSemibold)
                timeLabel.textColor = UIColor.magentaColor()

                cell.contentView.addSubview(timeLabel)
                
                let timeLabelConstraints : [NSLayoutConstraint] = [
                    timeLabel.centerYAnchor.constraintEqualToAnchor(cell.contentView.centerYAnchor),
                    timeLabel.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor, constant: 10),
                    timeLabel.leftAnchor.constraintEqualToAnchor(cell.contentView.leftAnchor, constant: 30)
                ]
                
                cell.contentView.addConstraints(timeLabelConstraints)
                
                //seperator line adjacent to time label, 1 pixel high
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
                
                // edge case: for buffer sections, remove all renderings
                if indexPath.section != 1 {
                    for view in cell.contentView.subviews {
                        view.removeFromSuperview()
                    }
                }

            }

            return cell
        }
        
        //proprietry table view formatting
        override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return UITableViewAutomaticDimension
        }
        
        override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
            return false
        }
        
        override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
            return 0
        }
    }
}