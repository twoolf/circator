//
//  RepeatedEventsListViewController.swift
//  Circator
//
//  Created by Edwin L. Whitman on 3/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

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

public struct Event : Equatable {
    var name : String
    var eventType : EventType
    var timeOfDayOffset : NSTimeInterval
    var duration : NSTimeInterval
    //optional text info
    var note : String?
    //optional exact time for exact event logging
    var currentDay : NSDate?
    
    init(nameOfEvent name : String, typeOfEvent type : EventType, timeOfDayOffsetInSeconds offset : NSTimeInterval, durationInSeconds duration : NSTimeInterval, CurrentTimeAsCurrentDay time : NSDate? = nil, additionalInfo note : String? = nil) {
        self.name = name
        self.eventType = type
        self.timeOfDayOffset = offset
        self.duration = duration
        self.currentDay = time
        self.note = note
    }
}

public func ==(lhs: Event, rhs: Event) -> Bool {
    return lhs.name == rhs.name && lhs.eventType == rhs.eventType && lhs.timeOfDayOffset == rhs.timeOfDayOffset && lhs.duration == rhs.duration && lhs.currentDay == rhs.currentDay
}

public struct RepeatedEvent {
    var event : Event
    var frequency : [Weekday]
    
    public init(metabolicEvent event : Event, daysOfWeekOccurs frequency : [Weekday]) {
        self.event = event
        self.frequency = frequency
    }
}

//renders image of circle using bezier path
public func drawCircle(FillColor color : UIColor) -> UIImage {
    
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

// MARK: - Main View Controller

class RepeatedEventsListViewController: UIViewController {
    
    //UIButton subclass to associate button with selected weekday
    class WeekdayButton : UIButton {
        
        var day : Weekday = Weekday.Sunday
        
        init(dayOfWeek day : Weekday, frame: CGRect = CGRectZero) {
            
            super.init(frame : frame)
            self.day = day
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
    }
    
    //weekday buttons by day
    lazy var sundayButton: WeekdayButton = {
        
        var button = WeekdayButton(dayOfWeek: Weekday.Sunday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Su", forState: .Normal)
        button.setTitle("Su", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(white: 0.667, alpha: 0.5)), forState: .Highlighted)
        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    
    lazy var mondayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Monday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("M", forState: .Normal)
        button.setTitle("M", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), forState: .Highlighted)

        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var tuesdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Tuesday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Tu", forState: .Normal)
        button.setTitle("Tu", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), forState: .Highlighted)
        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var wednesdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Wednesday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("W", forState: .Normal)
        button.setTitle("W", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), forState: .Highlighted)
        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var thursdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Thursday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Th", forState: .Normal)
        button.setTitle("Th", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), forState: .Highlighted)
        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var fridayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Friday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("F", forState: .Normal)
        button.setTitle("F", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), forState: .Highlighted)
        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var saturdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Saturday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .Center
        button.setTitle("Sa", forState: .Normal)
        button.setTitle("Sa", forState: .Selected)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clearColor()), forState: .Normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), forState: .Highlighted)
        button.addTarget(self, action: "setWeekdayView:", forControlEvents: .TouchUpInside)
        return button
    }()
    
    lazy var weekdayButtons : [WeekdayButton] = {
        return [self.sundayButton, self.mondayButton, self.tuesdayButton, self.wednesdayButton, self.thursdayButton, self.fridayButton, self.saturdayButton]
    }()
    
    //UIStack that display weekday buttons as single row
    lazy var weekdayRowSelector : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: self.weekdayButtons)
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        stackView.backgroundColor = UIColor.clearColor()
        return stackView
    }()
    
    //variables used within table view
    
    //TODO: some of these variables should be initialized in or need to be moved to data source delegate...??
    
    var currentWeekday : WeekdayButton?
    
    var weekdayLabel : UILabel = UILabel()
    
    var events : RepeatedEventsOrganizer = RepeatedEventsOrganizer()
    
    var eventsList : EventsListTableViewController = EventsListTableViewController()
    
    
    func loadData() {
        
        self.eventsList.loadData(RepeatedEvents: self.events)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add test data
        let sunday : [Weekday] = [Weekday.Sunday]
        let somedays : [Weekday] = [Weekday.Sunday, Weekday.Monday, Weekday.Wednesday, Weekday.Friday]
        
        
        let sleep : RepeatedEvent = RepeatedEvent(metabolicEvent: Event(nameOfEvent: "sleep", typeOfEvent: .Sleep, timeOfDayOffsetInSeconds: 0, durationInSeconds: 10800), daysOfWeekOccurs: somedays)
        self.events.addRepeatedEvent(RepeatedEvent: sleep)
        
        let breakfast : RepeatedEvent = RepeatedEvent(metabolicEvent: Event(nameOfEvent: "breakfast", typeOfEvent: .Meal, timeOfDayOffsetInSeconds: 18000, durationInSeconds: 1800), daysOfWeekOccurs: somedays)
        self.events.addRepeatedEvent(RepeatedEvent: breakfast)
        
        let workout : RepeatedEvent = RepeatedEvent(metabolicEvent: Event(nameOfEvent: "workout", typeOfEvent: .Exercise, timeOfDayOffsetInSeconds: 32400, durationInSeconds: 25200), daysOfWeekOccurs: sunday)
        self.events.addRepeatedEvent(RepeatedEvent: workout)
    
        print(NSDate().weekday)
        
        self.currentWeekday = self.weekdayButtons[NSDate().weekday - 1]
        self.currentWeekday?.selected = true
        //sets weekday label to selected day
        self.weekdayLabel.text = self.currentWeekday!.day.description
        
        //sets day state of table view and reloads data
        eventsList.setData(DayOfWeek: (self.currentWeekday?.day)!)
        eventsList.tableView.reloadData()
        

        //load and configure data
        self.eventsList.loadData(RepeatedEvents: self.events)
        self.configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Repeated Events"
        
        let addButton = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: "addRepeatedEvent:")
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    //formats and styles view
    private func formatView() {
        
        view.backgroundColor = UIColor.lightGrayColor()
        
    }
    
    //Sets configuration of view controller
    private func configureView() {
        
        //Sets format options
        self.formatView()
        
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
        self.weekdayLabel.textAlignment = .Center
        self.weekdayLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightSemibold)
        self.weekdayLabel.textColor = UIColor(red: 83, green: 83, blue: 83, alpha: 0.75)
        self.weekdayLabel.backgroundColor = UIColor.clearColor()
        
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
            eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: -30),
            eventsListView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: 15),
        ]
        
        view.addConstraints(eventsListViewConstraints)
        
    }
    
    
    
    func addRepeatedEvent(sender: UIBarItem) {
        let vc = NewRepeatedEventViewController()
        //let vc = NewRepeatedEventViewController()
        //let nav = UINavigationController(rootViewController: vc)
        self.presentViewController(vc, animated: true, completion: nil)
        //navigationController?.pushViewController(vc, animated: true)

    }
    
    func setWeekdayView(sender: WeekdayButton!) {
        
        //sets weekday label to selected day
        self.weekdayLabel.text = sender.day.description
        
        //swaps current and selected day buttons setting states respectively
        currentWeekday?.selected = false
        sender.selected = true
        
        //sets day state of table view and reloads data
        eventsList.setData(DayOfWeek: sender.day)
        eventsList.tableView.reloadData()
        
        //set current day as sender
        currentWeekday = sender
    
    }
    
    // MARK: - Event Item, Cell and Table View
    
    class RepeatedEventsOrganizer : NSObject {
     
        private var repeatedEvents : [RepeatedEvent] = []
        private var eventsForWeek : [Int : [Event?]] = [Weekday.Monday.rawValue : [], Weekday.Tuesday.rawValue : [], Weekday.Wednesday.rawValue : [], Weekday.Thursday.rawValue : [], Weekday.Friday.rawValue : [], Weekday.Saturday.rawValue : [], Weekday.Sunday.rawValue : []]
        
        override init() {
            super.init()
        }
        
        convenience init(RepeatedEvents events : [RepeatedEvent]) {
            self.init()
            for event in events {
                self.repeatedEvents.append(event)
            }
            for item in self.repeatedEvents {
                self.addRepeatedEvent(RepeatedEvent: item)
            }
        }
        
        func addRepeatedEvent(RepeatedEvent event : RepeatedEvent) -> Bool {

            //checks if added event conflicts with any existing event
            for eventsForDay in eventsForWeek {
                for optional in eventsForDay.1 {
                    if let eventOfDay = optional {
                        if event.event.timeOfDayOffset < eventOfDay.timeOfDayOffset {
                            if event.event.timeOfDayOffset + event.event.duration > eventOfDay.timeOfDayOffset {
                                return false
                            }
                        } else if event.event.timeOfDayOffset > eventOfDay.timeOfDayOffset {
                            if eventOfDay.timeOfDayOffset + eventOfDay.duration > event.event.timeOfDayOffset {
                                return false
                            }
                        } else {
                            return false
                        }
                    }
                }
            }
                
            //adding repeated event
            repeatedEvents.append(event)
            //print("loading...")
            for day in event.frequency {
                //print("\(day)")
                eventsForWeek[day.rawValue]!.append(Event(nameOfEvent: event.event.name, typeOfEvent: event.event.eventType, timeOfDayOffsetInSeconds: event.event.timeOfDayOffset, durationInSeconds: event.event.duration))
            }
            
            return true
        }
        
        func removeRepeatedEvent(RepeatedEvent event : RepeatedEvent) {
            
            // TODO
            
            // TODO: Error handling and contains
            //if repeatedEvents.contains(event) { }
        }
        
        func getEventsForDay(DayOfWeek day : Weekday) -> [Event?] {
            return self.eventsForWeek[day.rawValue]!
        }
        
        func getEventDataByIntervalForDay(DayOfWeek day : Weekday) -> [Event?] {
            var eventsForDay : [Event?] = [Event?](count: 72, repeatedValue: nil)
            for event in self.getEventsForDay(DayOfWeek: day) {
                //puts event in designated index for eventual index path reference
                // TODO: better way to design this with optional binding? -- index calculation feels hacky?

                let jumps : Int = Int(event!.timeOfDayOffset/3600.0)
                let index : Int = Int(event!.timeOfDayOffset/1800.0) + jumps + 1
                // edge case - view disappears if loading cell with top anchor disappears and vice-versa, solution: redudancy
                //let jumpsRedundancy : Int = Int(((event!.timeOfDayOffset + event!.duration) - 1.0)/3600.0)
                //let indexRedundancy : Int = Int((event!.timeOfDayOffset + event!.duration)/1800.0) + jumpsRedundancy
                
                eventsForDay.insert(event, atIndex: index)
                //edge case - do not add redudancy if event only occupies space of one cell
                //if event!.duration > 1800 {
                  //  eventsForDay.insert(event, atIndex: indexRedundancy)
                //}
                
                
            }
            return eventsForDay
        }
    }
    
    class EventsListTableViewController : UITableViewController {
        
        let hours : [String] = ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM", "7 AM", "8 AM", "9 AM", "10 AM", "11 AM", "Noon", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", "6 PM", "7 PM", "8 PM", "9 PM", "10 PM", "11 PM", "12 AM"]
        
        //where day would be set to current day in time
        var currentDay : Weekday = Weekday.Sunday
        
        //where initial data would be loaded from plist
        var events : RepeatedEventsOrganizer = RepeatedEventsOrganizer()
        
        func loadData(RepeatedEvents eventData : RepeatedEventsOrganizer) {
            self.events = eventData
        }
        
        func setData(DayOfWeek day : Weekday) {
            self.currentDay = day
        }
        
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
                return 32.0
            }
        }
        
        /*override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
            
            if indexPath.row % 3 != 0 && indexPath.row != 73 && cell.contentView.subviews.count > 0  && (cell.contentView.subviews.first as! EventItemView).event!.duration > 1800 {

                
                //if tableView.subviews.count > 3 {
                //    tableView.subviews[3].removeFromSuperview()
                //}
                
                let view : EventItemView = cell.contentView.subviews.first as! EventItemView
                view.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(view)
                
                let data : Event = view.event!
                
                let cellHeight = Double(cell.contentView.bounds.height)
                let seperatorLinePaddingHeight = Double(Int((data.duration)/3600.0)) * 2 - 1.5
                let seperatorLinePaddingOffset = Double(Int((data.timeOfDayOffset)/3600.0)) * 2 - 1.5
                
                let height : CGFloat = CGFloat((data.duration/1800.0) * cellHeight + seperatorLinePaddingHeight)
                let offset : CGFloat = CGFloat((data.timeOfDayOffset/1800.0) * cellHeight + seperatorLinePaddingOffset)
                
                let viewConstraints : [NSLayoutConstraint] = [
                    view.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor, constant: 15 + 90),
                    view.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor, constant: -135),
                    //view.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor, constant: -30),
                    view.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: offset + 7.5),
                    view.bottomAnchor.constraintEqualToAnchor(view.topAnchor, constant: height),
                    
                ]
                
                self.view.addConstraints(viewConstraints)
                
                // TODO: Deprecate old event view that is loaded for cell and make it view in self.view
                // CLEAN UP BUNCH OF CODE USING CONVENTION BELOW FOR MUCH EASIER SOLUTION
                let eventDetailClick : EventItemView = EventItemView(Event: data)
                eventDetailClick.translatesAutoresizingMaskIntoConstraints = false
                //print("\(eventDetailClick)")
                eventDetailClick.addTarget(self, action: "eventDetailDoubleTap:", forControlEvents: .TouchDownRepeat)
                
                view.addSubview(eventDetailClick)
                
                let eventDetailClickConstraints : [NSLayoutConstraint] = [
                    eventDetailClick.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
                    eventDetailClick.rightAnchor.constraintEqualToAnchor(view.rightAnchor),
                    eventDetailClick.topAnchor.constraintEqualToAnchor(view.topAnchor),
                    eventDetailClick.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
                ]
                
                view.addConstraints(eventDetailClickConstraints)
                
                //print(cell.contentView.subviews.count)
                //tableView.addSubview(cell.contentView)
            }
            
        }*/
        
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
                
                /*
                //debug prints to keep track of indexPath count
                let subview = FormLabelCell()
                subview.formTextLabel()?.text = "\(indexPath.row)"
                cell.contentView.addSubview(subview)
                */

                let eventsForDay = self.events.getEventDataByIntervalForDay(DayOfWeek: self.currentDay)
                
                
                
                
                
                //set up event item view
                if let data = eventsForDay[indexPath.row] {
                    
                    //sets event view
                    //let view = EventItemView(Event: data)
                    
                    /*
                    //ensures that no conflicting views are added
                    */
                    
                    for view in tableView.subviews {
                        if view is EventItemView {
                            if (view as! EventItemView).event! == data {
                                view.removeFromSuperview()
                            }
                        }
                    }
                    
                    let eventView = EventItemView(Event: data)
                    
                    eventView.translatesAutoresizingMaskIntoConstraints = false
                    
                    cell.contentView.addSubview(eventView)
                    
                    eventView.backgroundColor = UIColor(white: 0.667, alpha: 0.5)
                    
                    
                    //sets how high the event view will be in relation to its bottom anchor
                    let cellHeight = Double(cell.contentView.bounds.height)
                    //caclulates the number of additional pixels need to padd event
                    var seperatorLinePadding : Double = 0
                    if data.duration > 1800 {
                        seperatorLinePadding = Double(Int((data.duration)/3600.0)) * 2 - 1.5
                    }
                    let offsetValue : Double = ((data.duration - 1800.0)/1800.0) * cellHeight + cellHeight + seperatorLinePadding
                    let offset : CGFloat = CGFloat(offsetValue)
                    
                    let eventViewConstraints : [NSLayoutConstraint] = [
                        eventView.rightAnchor.constraintEqualToAnchor(cell.contentView.rightAnchor, constant: -30),
                        eventView.leftAnchor.constraintEqualToAnchor(cell.contentView.leftAnchor, constant: 15 + 90),
                        eventView.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                        eventView.bottomAnchor.constraintEqualToAnchor(cell.contentView.topAnchor, constant: offset)
                    ]
                    
                    cell.contentView.addConstraints(eventViewConstraints)
                    
                    // TODO: refractor into seperate subclass
                    // set event view's contents
                    
                    let eventTitle = UILabel()
                    eventTitle.translatesAutoresizingMaskIntoConstraints = false
                    eventTitle.text = data.name
                    eventTitle.font = UIFont.systemFontOfSize(14, weight: UIFontWeightSemibold)
                    eventTitle.textColor = UIColor.whiteColor()
                    
                    let eventIcon = UIButton()
                    eventIcon.translatesAutoresizingMaskIntoConstraints = false
                    eventIcon.setBackgroundImage(drawCircle(FillColor: UIColor.grayColor()), forState: .Normal)
                    eventIcon.adjustsImageWhenHighlighted = false
                    eventIcon.titleLabel?.adjustsFontSizeToFitWidth = true
                    eventIcon.titleLabel?.textAlignment = .Center
                    eventIcon.titleLabel?.minimumScaleFactor = 0.5;

                    
                    let eventIconInner = UIImageView()
                    eventIconInner.translatesAutoresizingMaskIntoConstraints = false
                    
                    eventIcon.addSubview(eventIconInner)
                    let eventIconInnerConstraints : [NSLayoutConstraint] = [
                        eventIconInner.centerXAnchor.constraintEqualToAnchor(eventIcon.centerXAnchor),
                        eventIconInner.centerYAnchor.constraintEqualToAnchor(eventIcon.centerYAnchor),
                        NSLayoutConstraint(item: eventIconInner, attribute: .Height, relatedBy: .Equal, toItem: eventIcon, attribute: .Height, multiplier: 0.75, constant: 0),
                        NSLayoutConstraint(item: eventIconInner, attribute: .Width, relatedBy: .Equal, toItem: eventIcon, attribute: .Width, multiplier: 0.75, constant: 0)
                    ]
                    eventIcon.addConstraints(eventIconInnerConstraints)
                    
                    
                    switch data.eventType {
                        case .Meal:
                            //eventIcon.setTitle("M", forState: .Normal)
                            eventIconInner.image = drawCircle(FillColor: UIColor.greenColor())
                        case .Sleep:
                            //eventIcon.setTitle("S", forState: .Normal)
                            eventIconInner.image = drawCircle(FillColor: UIColor.blueColor())
                        case .Exercise:
                            //eventIcon.setTitle("E", forState: .Normal)
                            eventIconInner.image = drawCircle(FillColor: UIColor.redColor())
                    }
                    
                    //eventIcon.titleLabel!.layer.zPosition = eventIconInner.layer.zPosition + 1
                    
                    eventView.addSubview(eventTitle)
                    eventView.addSubview(eventIcon)
                    
                    let eventViewContentConstraints : [NSLayoutConstraint] = [
                        eventTitle.leftAnchor.constraintEqualToAnchor(eventView.leftAnchor, constant: 7.5),
                        eventTitle.bottomAnchor.constraintEqualToAnchor(eventView.bottomAnchor, constant: -7.5),
                        eventIcon.rightAnchor.constraintEqualToAnchor(eventView.rightAnchor, constant: -3.5),
                        NSLayoutConstraint(item: eventIcon, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 25),
                        eventIcon.bottomAnchor.constraintEqualToAnchor(eventView.bottomAnchor, constant: -3.5),
                        eventIcon.heightAnchor.constraintEqualToAnchor(eventIcon.widthAnchor)
                        
                    ]
                    
                    eventView.addConstraints(eventViewContentConstraints)
                    
                    let eventDetailClick : EventItemView = EventItemView(Event: data)
                    eventDetailClick.backgroundColor = UIColor.blueColor()
                    eventDetailClick.translatesAutoresizingMaskIntoConstraints = false
                    //print("\(eventDetailClick)")
                    eventDetailClick.addTarget(self, action: "eventDetailDoubleTap:", forControlEvents: .TouchDownRepeat)
                    

                    
                    // TODO: Deprecate old event view that is loaded for cell and make it view in self.view
                    // CLEAN UP BUNCH OF CODE USING CONVENTION BELOW FOR MUCH EASIER SOLUTION
                    //to account for row ovewriting
                    self.view.addSubview(eventDetailClick)
                    
                    let seperatorLinePaddingHeight = Double(Int((data.duration)/3600.0)) * 2 - 1.5
                    let seperatorLinePaddingOffset = Double(Int((data.timeOfDayOffset)/3600.0)) * 2 - 1.5
                    
                    let height : CGFloat = CGFloat((data.duration/1800.0) * cellHeight + seperatorLinePaddingHeight)
                    let offset2 : CGFloat = CGFloat((data.timeOfDayOffset/1800.0) * cellHeight + seperatorLinePaddingOffset)
                    
                    let viewConstraints : [NSLayoutConstraint] = [
                        eventDetailClick.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor, constant: 105),
                        eventDetailClick.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor, constant: -135),
                        eventDetailClick.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: offset2 + 7.5),
                        eventDetailClick.bottomAnchor.constraintEqualToAnchor(eventDetailClick.topAnchor, constant: height),
                    ]
                    
                    self.view.addConstraints(viewConstraints)
                    
                    
                } else {
                    
                    //make such that blank view controller area does not affect clickable event area
                    //cell.contentView.layer.zPosition = -999
                    //print("moving cell back")
                }

            //sets cell to filled with time seperator
            } else {
                
                // TODO: refractor time seperator into separate subclass
                //time label for seperator
                let timeLabel = UILabel()
                timeLabel.translatesAutoresizingMaskIntoConstraints = false
                timeLabel.text = hours[indexPath.row/3]
                timeLabel.font = UIFont.systemFontOfSize(11, weight: UIFontWeightSemibold)
                timeLabel.textColor = UIColor.lightGrayColor()

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
                seperatorLine.backgroundColor = UIColor.lightGrayColor()
                
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
        
        /*
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            if segue.identifier == "showDetail" {
                
            }
        }
        */
        
        func eventDetailDoubleTap(sender: EventItemView) {
            //print("\(sender)")
            //let event : Event = (sender as! EventItemView).event!
            var repeatedEvent : RepeatedEvent?
            for item in events.repeatedEvents {
                let check = item.event
                if check == sender.event! {
                    repeatedEvent = item
                }
            }
            let vc : RepeatedEventDetailViewController = RepeatedEventDetailViewController()
            vc.configureView(RepeatedEvent: repeatedEvent!)
            navigationController?.pushViewController(vc, animated: true)
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
