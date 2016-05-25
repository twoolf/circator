//
//  RepeatedEventManagerViewController.swift
//  MetabolicCompass
//
//  Created by Edwin L. Whitman on 5/24/16.
//  Copyright © 2016 Edwin L. Whitman, Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Former

// MARK: - Data Structures

public enum Weekday : Int {
    case Sunday = 1
    case Monday 
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    
    
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

public func ==(lhs: RepeatedEvent, rhs: RepeatedEvent) -> Bool {
    return lhs.event == rhs.event && lhs.frequency == rhs.frequency
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


class RepeatedEventsOrganizer : NSObject {
    
    static let shared = RepeatedEventsOrganizer()
    
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
    
    func reloadEventsForWeek() {
        
        self.eventsForWeek = [Weekday.Monday.rawValue : [], Weekday.Tuesday.rawValue : [], Weekday.Wednesday.rawValue : [], Weekday.Thursday.rawValue : [], Weekday.Friday.rawValue : [], Weekday.Saturday.rawValue : [], Weekday.Sunday.rawValue : []]
        
        for repeated in self.repeatedEvents {
            for weekday in repeated.frequency {
                eventsForWeek[weekday.rawValue]!.append(repeated.event)
            }
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
        for day in event.frequency {
            eventsForWeek[day.rawValue]!.append(Event(nameOfEvent: event.event.name, typeOfEvent: event.event.eventType, timeOfDayOffsetInSeconds: event.event.timeOfDayOffset, durationInSeconds: event.event.duration))
        }
        
        return true
    }
    
    func removeRepeatedEvent(RepeatedEvent event : RepeatedEvent) -> Bool {
        
        print(self.repeatedEvents.count)
        
        for i in Range(0..<self.repeatedEvents.count) {
            if self.repeatedEvents[i] == event {
                
                print(i)
                self.repeatedEvents.removeAtIndex(i)
                self.reloadEventsForWeek()
                return true
            }
        }
        return false
    }
    
    func getEventsForDay(DayOfWeek day : Weekday) -> [Event?] {
        return self.eventsForWeek[day.rawValue]!
    }
    
    func getEventDataByIntervalForDay(DayOfWeek day : Weekday) -> [Event?] {
        var eventsForDay : [Event?] = [Event?](count: 72, repeatedValue: nil)
        for event in self.getEventsForDay(DayOfWeek: day) {
            let jumps : Int = Int(event!.timeOfDayOffset/3600.0)
            let index : Int = Int(event!.timeOfDayOffset/1800.0) + jumps + 1
            eventsForDay.insert(event, atIndex: index)
        }
        return eventsForDay
    }
    
    func getDaysWhenEventOccurs(Event event : Event) -> [Weekday] {
        
        var days : [Weekday] = []
        for repeatedEvent in self.repeatedEvents {
            if repeatedEvent.event == event {
                days = repeatedEvent.frequency
            }
        }
        return days
    }
    
    func getEventAtTimeDuringWeek() -> Event {
        
        return Event(nameOfEvent: "", typeOfEvent: .Meal, timeOfDayOffsetInSeconds: 0, durationInSeconds: 0)
    }
}


// MARK: - Main View Controller

class RepeatedEventManagerViewController: UIViewController {
    
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
        button.adjustsImageWhenHighlighted = true
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
    
    var events : RepeatedEventsOrganizer = RepeatedEventsOrganizer.shared
    
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
        
    }
    
    //Sets configuration of view controller
    private func configureView() {
        
        //self.navigationItem.title = "Repeated Events"
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: "addRepeatedEvent:")
        
        //set up table view
        self.eventsList.automaticallyAdjustsScrollViewInsets = false
        let eventsListView = self.eventsList.view
        eventsListView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(self.eventsList)
        view.addSubview(eventsListView)
        let eventsListViewConstraints: [NSLayoutConstraint] = [
            eventsListView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            eventsListView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor),
            eventsListView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: -30),
            eventsListView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: 15),
            ]
        
        view.addConstraints(eventsListViewConstraints)
        
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
        self.weekdayLabel.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
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
        
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        blurEffectView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
        
        view.addSubview(blurEffectView)
        
        let blurEffectViewConstraints : [NSLayoutConstraint] = [
            blurEffectView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            blurEffectView.bottomAnchor.constraintEqualToAnchor(weekdayLabel.bottomAnchor),
            blurEffectView.rightAnchor.constraintEqualToAnchor(view.rightAnchor),
            blurEffectView.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
        ]
        
        view.addConstraints(blurEffectViewConstraints)
        
        view.bringSubviewToFront(weekdayLabel)
        view.bringSubviewToFront(weekdayRowSelector)
        
        
        self.eventsList.tableView.contentInset = UIEdgeInsetsMake(30 + weekdayRowSelector.bounds.height, 0, 0, 0)
        
        
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
    
    class EventsListTableViewController : UITableViewController {
        
        
        
        let hours : [String] = ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM", "7 AM", "8 AM", "9 AM", "10 AM", "11 AM", "Noon", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", "6 PM", "7 PM", "8 PM", "9 PM", "10 PM", "11 PM", "12 AM"]
        
        //where day would be set to current day in time
        var currentDay : Weekday = Weekday.Sunday
        
        //where initial data would be loaded from plist
        var events : RepeatedEventsOrganizer = RepeatedEventsOrganizer.shared
        
        func loadData(RepeatedEvents eventData : RepeatedEventsOrganizer) {
            self.events = eventData
        }
        
        func setData(DayOfWeek day : Weekday) {
            
            //tableView.setContentOffset(CGPointZero, animated:true)
            self.currentDay = day
            for view in tableView.subviews {
                if view is EventItemView {
                    if !self.events.getDaysWhenEventOccurs(Event: (view as! EventItemView).event!).contains(self.currentDay) {
                        view.removeFromSuperview()
                    }
                }
            }
        }
        
        override func viewDidAppear(animated: Bool) {
            
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            
            
            
            
            
            //removes default seperator lines
            tableView.separatorColor = UIColor.clearColor()
            
            //TODO: move current custom views into designated table view cell subclasses
            //custom table view cell classes
            //tableView.registerClass(EventItemTableViewCell.self, forCellReuseIdentifier: "EventItemTableViewCell")
            //tableView.registerClass(EventListTimeSeperatorTableViewCell.self, forCellReuseIdentifier: "EventListTimeSeperatorTableViewCell")
            
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
        
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = UITableViewCell()
            
            //removes white layer of each cell's default background for proper line seperator rendering
            cell.backgroundColor = UIColor.clearColor()
            
            //clears subviews previously rendered to cell
            for view in cell.contentView.subviews {
                view.removeFromSuperview()
            }
            
            //sets cell to be filled with event item cell
            if indexPath.row % 3 != 0 && indexPath.row != 73 {
                
                let eventsForDay = self.events.getEventDataByIntervalForDay(DayOfWeek: self.currentDay)
                
                //set up event item view
                if let data = eventsForDay[indexPath.row] {
                    
                    //ensures that no conflicting views are added
                    for view in tableView.subviews {
                        if view is EventItemView {
                            if (view as! EventItemView).event! == data {
                                view.removeFromSuperview()
                            }
                        }
                    }
                    
                    let eventView = EventItemView(Event: data)
                    eventView.addTarget(self, action: "eventDetailDoubleTap:", forControlEvents: .TouchDownRepeat)
                    
                    eventView.translatesAutoresizingMaskIntoConstraints = false
                    
                    view.addSubview(eventView)
                    
                    //eventView.backgroundColor = UIColor(white: 0.667, alpha: 0.5)
                    
                    
                    //sets how high the event view will be in relation to its bottom anchor
                    let cellHeight = Double(cell.contentView.bounds.height)
                    //caclulates the number of additional pixels need to padd event
                    /*
                     var seperatorLinePadding : Double = 0
                     if data.duration > 1800 {
                     seperatorLinePadding = Double(Int((data.duration)/3600.0)) * 2 - 1.5
                     }
                     */
                    //let seperatorLinePadding : Double = data.duration > 1800 ? (Double(Int((data.duration)/3600.0)) * 2 - 1.5) : 0
                    //let offsetValue : Double = ((data.duration - 1800.0)/1800.0) * cellHeight + cellHeight + seperatorLinePadding
                    
                    
                    let seperatorLinePaddingHeight = Double(Int((data.duration)/3600.0)) * 2 - 1.5
                    let seperatorLinePaddingOffset = Double(Int((data.timeOfDayOffset)/3600.0)) * 2 - 1.5
                    
                    let height : CGFloat = CGFloat((data.duration/1800.0) * cellHeight + seperatorLinePaddingHeight)
                    let offset : CGFloat = CGFloat((data.timeOfDayOffset/1800.0) * cellHeight + seperatorLinePaddingOffset)
                    
                    let eventViewConstraints : [NSLayoutConstraint] = [
                        eventView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor, constant: 105),
                        eventView.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor, constant: -135),
                        eventView.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: offset + 7.5),
                        eventView.bottomAnchor.constraintEqualToAnchor(eventView.topAnchor, constant: height),
                        ]
                    
                    view.addConstraints(eventViewConstraints)
                    
                    // TODO: refractor into seperate subclass
                    // set event view's contents
                    
                    let eventTitle = UILabel()
                    eventTitle.translatesAutoresizingMaskIntoConstraints = false
                    eventTitle.text = data.name
                    eventTitle.font = UIFont.systemFontOfSize(14, weight: UIFontWeightSemibold)
                    eventTitle.textColor = UIColor.whiteColor()
                    
                    let eventIcon = UIButton()
                    eventIcon.translatesAutoresizingMaskIntoConstraints = false
                    eventIcon.setBackgroundImage(drawCircle(FillColor: UIColor.whiteColor()), forState: .Normal)
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
                    
                    switch data.eventType {
                    case .Meal:
                        eventView.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.25)
                        //eventIcon.setTitle("M", forState: .Normal)
                        eventIconInner.image = drawCircle(FillColor: UIColor.greenColor().colorWithAlphaComponent(0.25))
                    case .Sleep:
                        eventView.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.25)
                        //eventIcon.setTitle("S", forState: .Normal)
                        eventIconInner.image = drawCircle(FillColor: UIColor.blueColor().colorWithAlphaComponent(0.25))
                    case .Exercise:
                        eventView.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.25)
                        //eventIcon.setTitle("E", forState: .Normal)
                        eventIconInner.image = drawCircle(FillColor: UIColor.redColor().colorWithAlphaComponent(0.25))
                    }
                    
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
        
        func eventDetailDoubleTap(sender: EventItemView) {
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

class EventItemView: UIButton {
    
    var event : Event?
    
    init(Event event : Event, frame: CGRect = CGRectZero) {
        
        super.init(frame : frame)
        self.event = event
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class RepeatedEventDetailViewController : UIViewController {
    
    var event : RepeatedEvent?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.formatView()
        navigationItem.title = "Detail"
        
    }
    
    func formatView() {
        
        self.view.backgroundColor = UIColor(white: 0.9, alpha: 1)
    }
    
    func configureView(RepeatedEvent repeatedEvent : RepeatedEvent) {
        
        self.event = repeatedEvent
        
        let eventIcon = UIImageView()
        eventIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(eventIcon)
        
        let eventIconConstraints : [NSLayoutConstraint] = [
            eventIcon.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 15),
            eventIcon.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor),
            NSLayoutConstraint(item: eventIcon, attribute: .Width, relatedBy: .Equal, toItem: view.layoutMarginsGuide, attribute: .Width, multiplier: 0.25, constant: 0),
            eventIcon.heightAnchor.constraintEqualToAnchor(eventIcon.widthAnchor)
            //NSLayoutConstraint(item: eventIcon, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 0.333, constant: 0)
        ]
        view.addConstraints(eventIconConstraints)
        
        switch self.event!.event.eventType {
        case .Meal:
            //eventIcon.setTitle("M", forState: .Normal)
            eventIcon.image = drawCircle(FillColor: UIColor.greenColor().colorWithAlphaComponent(0.5))
        case .Sleep:
            //eventIcon.setTitle("S", forState: .Normal)
            eventIcon.image = drawCircle(FillColor: UIColor.blueColor().colorWithAlphaComponent(0.5))
        case .Exercise:
            //eventIcon.setTitle("E", forState: .Normal)
            eventIcon.image = drawCircle(FillColor: UIColor.redColor().colorWithAlphaComponent(0.5))
        }
        
        let eventTitleLabel = UILabel()
        eventTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        eventTitleLabel.font = UIFont.systemFontOfSize(26, weight: UIFontWeightSemibold)
        eventTitleLabel.textColor = UIColor.blackColor()
        eventTitleLabel.text = self.event!.event.name
        view.addSubview(eventTitleLabel)
        
        let eventTitleLabelConstraints : [NSLayoutConstraint] = [
            eventTitleLabel.topAnchor.constraintEqualToAnchor(eventIcon.topAnchor),
            eventTitleLabel.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventTitleLabel.rightAnchor.constraintEqualToAnchor(eventIcon.leftAnchor),
            ]
        view.addConstraints(eventTitleLabelConstraints)
        
        let eventTimeLabel = UILabel()
        eventTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        eventTimeLabel.font = UIFont.systemFontOfSize(20, weight: UIFontWeightThin)
        eventTimeLabel.textColor = UIColor.blackColor()
        
        
        let formatTime: (NSDate -> String) = { time in
            let timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return timeFormatter.stringFromDate(time)
        }
        
        let start : String = {
            let components = NSDateComponents()
            components.hour = Int((self.event?.event.timeOfDayOffset)!)/3600
            components.minute = Int((self.event?.event.timeOfDayOffset)!)%60
            return formatTime(NSDate(components: components))
        }()
        
        let end : String = {
            let components = NSDateComponents()
            components.hour = Int((self.event?.event.timeOfDayOffset)! + (self.event?.event.duration)!)/3600
            components.minute = Int((self.event?.event.timeOfDayOffset)! + (self.event?.event.duration)!)%60
            return formatTime(NSDate(components: components))
        }()
        
        eventTimeLabel.text = "from " + start + " to " + end
        view.addSubview(eventTimeLabel)
        
        let eventTimeLabelConstraints : [NSLayoutConstraint] = [
            eventTimeLabel.centerYAnchor.constraintEqualToAnchor(eventIcon.centerYAnchor),
            eventTimeLabel.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventTimeLabel.rightAnchor.constraintEqualToAnchor(eventIcon.leftAnchor),
            
            ]
        view.addConstraints(eventTimeLabelConstraints)
        
        // days of the week
        let eventDaysLabel = UILabel()
        eventDaysLabel.translatesAutoresizingMaskIntoConstraints = false
        eventDaysLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
        eventDaysLabel.textColor = UIColor.blackColor()
        eventDaysLabel.numberOfLines = 0
        eventDaysLabel.lineBreakMode = .ByWordWrapping
        eventDaysLabel.text = self.event?.frequency.sort({$0.rawValue < $1.rawValue}).map{ (day) -> String in return day.description }.joinWithSeparator(", ")
        view.addSubview(eventDaysLabel)
        
        let eventDaysLabelConstraints : [NSLayoutConstraint] = [
            eventDaysLabel.topAnchor.constraintEqualToAnchor(eventTimeLabel.bottomAnchor, constant: 2.5),
            eventDaysLabel.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventDaysLabel.rightAnchor.constraintEqualToAnchor(eventIcon.leftAnchor)
        ]
        view.addConstraints(eventDaysLabelConstraints)
        
        let deleteButton = UIButton()
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        print(deleteButton.titleLabel)
        deleteButton.titleLabel?.textAlignment = .Center
        deleteButton.setTitle("Delete", forState: .Normal)
        deleteButton.setTitleColor(UIColor.redColor(), forState: .Normal)
        deleteButton.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
        
        deleteButton.addTarget(self, action: "deleteEvent:", forControlEvents: .TouchUpInside)
        
        let lineSeperator = UIView()
        lineSeperator.translatesAutoresizingMaskIntoConstraints = false
        lineSeperator.backgroundColor = UIColor.grayColor()
        
        deleteButton.addSubview(lineSeperator)
        let lineSeperatorConstraints : [NSLayoutConstraint] = [
            lineSeperator.rightAnchor.constraintEqualToAnchor(deleteButton.rightAnchor),
            lineSeperator.leftAnchor.constraintEqualToAnchor(deleteButton.leftAnchor),
            lineSeperator.topAnchor.constraintEqualToAnchor(deleteButton.topAnchor),
            lineSeperator.heightAnchor.constraintEqualToConstant(1)
        ]
        
        deleteButton.addConstraints(lineSeperatorConstraints)
        
        view.addSubview(deleteButton)
        
        let deleteButtonConstraints : [NSLayoutConstraint] = [
            deleteButton.heightAnchor.constraintEqualToConstant(45),
            deleteButton.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            deleteButton.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            deleteButton.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor)
        ]
        
        view.addConstraints(deleteButtonConstraints)
        
        let eventInfoView = UIView()
        eventInfoView.translatesAutoresizingMaskIntoConstraints = false
        eventInfoView.layer.cornerRadius = 10
        eventInfoView.clipsToBounds = true
        eventInfoView.backgroundColor = UIColor(white: 1, alpha: 0.5)
        
        view.addSubview(eventInfoView)
        
        let eventInfoViewConstraints : [NSLayoutConstraint] =  [
            eventInfoView.topAnchor.constraintEqualToAnchor(eventIcon.bottomAnchor, constant: 15),
            eventInfoView.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventInfoView.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor),
            eventInfoView.bottomAnchor.constraintEqualToAnchor(deleteButton.topAnchor, constant: -15)
        ]
        
        view.addConstraints(eventInfoViewConstraints)
        
        
        let eventNotes = UILabel()
        eventNotes.translatesAutoresizingMaskIntoConstraints = false
        eventNotes.font = UIFont.systemFontOfSize(16, weight: UIFontWeightLight)
        eventNotes.textColor = UIColor.blackColor()
        eventNotes.numberOfLines = 0
        eventNotes.lineBreakMode = .ByWordWrapping
        
        
        if let note = self.event?.event.note {
            eventNotes.text = note
        } else {
            eventNotes.text = "No notes"
            eventNotes.textColor = UIColor.lightGrayColor()
        }
        
        eventInfoView.addSubview(eventNotes)
        
        let eventNotesConstraints : [NSLayoutConstraint] = [
            eventNotes.topAnchor.constraintEqualToAnchor(eventInfoView.topAnchor, constant: 15),
            eventNotes.leftAnchor.constraintEqualToAnchor(eventInfoView.leftAnchor, constant: 15),
            eventNotes.rightAnchor.constraintEqualToAnchor(eventInfoView.rightAnchor, constant: -15),
            eventInfoView.bottomAnchor.constraintEqualToAnchor(eventInfoView.bottomAnchor, constant: -15)
        ]
        
        view.addConstraints(eventNotesConstraints)
        
        
        
    }
    
    func deleteEvent (sender: UIButton!) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let deleteEventAction = UIAlertAction(title: "Delete", style: .Destructive) { action in
            print(self.navigationController?.viewControllers)
            
            for vc in (self.navigationController?.viewControllers)! {
                if vc is RepeatedEventManagerViewController {
                    (vc as! RepeatedEventManagerViewController).events.removeRepeatedEvent(RepeatedEvent: self.event!)
                    (vc as! RepeatedEventManagerViewController).eventsList.tableView.reloadData()
                    //print((vc as! RepeatedEventsListViewController).eventsList.view.subviews)
                    for view in (vc as! RepeatedEventManagerViewController).eventsList.view.subviews {
                        if view is EventItemView && (view as! EventItemView).event! == self.event?.event {
                            view.removeFromSuperview()
                        }
                    }
                }
            }
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertController.addAction(deleteEventAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}

class NewRepeatedEventViewController: UIViewController {
    
    var event : RepeatedEvent?
    var form : RepeatedEventFormViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func configureView() {
        
        //UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
        
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44))
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        let navigationItems = UINavigationItem()
        
        let left = UIBarButtonItem(title: "cancel", style: .Plain, target: self, action: "cancel:")
        let right = UIBarButtonItem(title: "add", style: .Plain, target: self, action: "add:")
        
        navigationItems.title = "New Repeated Event"
        navigationItems.leftBarButtonItem = left
        navigationItems.rightBarButtonItem = right
        
        navigationBar.items = [navigationItems]
        
        view.addSubview(navigationBar)
        
        let navigationBarConstraints : [NSLayoutConstraint] = [
            
            //NSLayoutConstraint(item: navigationBar, attribute: .Top, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: UIApplication.sharedApplication().statusBarFrame.size.height),
            navigationBar.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            navigationBar.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            navigationBar.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(navigationBarConstraints)
        
        let form = RepeatedEventFormViewController()
        form.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(form)
        view.addSubview(form.view)
        
        let formConstraints : [NSLayoutConstraint] = [
            form.view.topAnchor.constraintEqualToAnchor(navigationBar.bottomAnchor),
            form.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            form.view.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            form.view.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(formConstraints)
        self.form = form
        
    }
    
    func cancel(sender: UIBarItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func add(sender: UIBarItem) {
        var eventTitle : String?
        var eventType : EventType?
        var timeOfDayOffsetInSeconds : NSTimeInterval?
        var durationInSeconds : NSTimeInterval?
        var OccursOnDays: [Weekday] = []
        var note : String?
        
        print(self.presentingViewController?.childViewControllers)
        
        var relvc : UIViewController?
        
        for vc in (self.presentingViewController?.childViewControllers)! {
            if vc is RepeatedEventManagerViewController {
                relvc = vc
            }
        }
        
        let presenting = relvc as! RepeatedEventManagerViewController
        
        if form?.eventTitle != nil {
            if form?.eventTitle?.characters.count > 16 {
                UINotifications.genericError(self, msg: "Event title is too long.")
                return
            }
            if form?.eventTitle?.characters.count < 1 {
                UINotifications.genericError(self, msg: "Event title required.")
                return
            }
            eventTitle = form?.eventTitle
        } else {
            UINotifications.genericError(self, msg: "Event title required.")
            return
        }
        
        if form?.eventType != nil {
            print(form?.eventType)
            eventType = form?.eventType
        } else {
            UINotifications.genericError(self, msg: "Event type required.")
            return
        }
        
        if form?.timeOfDayOffsetInSeconds != nil {
            timeOfDayOffsetInSeconds = form?.timeOfDayOffsetInSeconds
        } else {
            UINotifications.genericError(self, msg: "Event start time required.")
            return
        }
        
        if form?.durationInSeconds != nil {
            durationInSeconds = form?.durationInSeconds
            if durationInSeconds <= 0 {
                UINotifications.genericError(self, msg: "Event must end after it starts.")
                return
            }
        } else {
            UINotifications.genericError(self, msg: "Event end time required.")
            return
        }
        
        if form?.selectedDays.count > 0 {
            print(form?.selectedDays)
            if let selectedDays = form?.selectedDays {
                for day in Array<Int>(selectedDays) {
                    if let weekday = Weekday(rawValue: day + 1) {
                        OccursOnDays.append(weekday)
                    }
                }
            }
            
        } else {
            UINotifications.genericError(self, msg: "Event must occur on at least one day.")
            return
        }
        
        print("\(OccursOnDays)")
        note = form?.note
        
        let event = Event(nameOfEvent: eventTitle!, typeOfEvent: eventType!, timeOfDayOffsetInSeconds: timeOfDayOffsetInSeconds!, durationInSeconds: durationInSeconds!, additionalInfo: note)
        
        //must check if event conflicts with any other existing events
        
        let check = presenting.events.addRepeatedEvent(RepeatedEvent: RepeatedEvent(metabolicEvent: event, daysOfWeekOccurs: OccursOnDays))
        
        if !check {
            UINotifications.genericError(self, msg: "Event conflicts with existing event.")
            return
        }
        
        presenting.loadData()
        self.dismissViewControllerAnimated(true, completion: nil)
        print("added")
        
    }
}

final class RepeatedEventFormViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    
    var eventTitle : String?
    var eventType : EventType?
    var timeOfDayOffsetInSeconds : NSTimeInterval?
    var durationInSeconds : NSTimeInterval?
    var selectedDays: Set<Int> = []
    var note : String?
    
    private static let dayNames = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
    
    private func configure() {
        
        tableView.scrollEnabled = false
        
        //title = "Add Event"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 30
        tableView.contentOffset.y = -10
        
        // Create RowFomers
        
        let eventTypeRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Type"
            $0.titleLabel.textColor = UIColor.blackColor()
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            }.configure {
                $0.segmentTitles = ["Meal", "Sleep", "Exercise"]
                $0.selectedIndex = UISegmentedControlNoSegment
            }.onSegmentSelected { selection in
                switch selection.0 {
                case 0:
                    self.eventType = .Meal
                case 1:
                    self.eventType = .Sleep
                case 2:
                    self.eventType = .Exercise
                default:
                    break
                }
        }
        
        let titleRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.textField.textColor = UIColor.blackColor()
            $0.textField.font = .systemFontOfSize(15)
            }.configure {
                $0.placeholder = "Title"
            }.onTextChanged { title in
                self.eventTitle = title
        }
        
        let formatTime: (NSDate -> String) = { time in
            let timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return timeFormatter.stringFromDate(time)
        }
        
        let startRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "Start"
            $0.titleLabel.textColor = UIColor.blackColor()
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            $0.displayLabel.textColor = UIColor.blackColor()
            $0.displayLabel.font = .systemFontOfSize(15)
            }.inlineCellSetup {
                /*
                 let components = NSDateComponents()
                 components.hour = NSDate().hour
                 components.minute = 0
                 let displayTimeComponents = NSDate().components
                 displayTimeComponents.setValue(0, forComponent: .Minute)
                 displayTimeComponents.setValue(0, forComponent: .Hour)
                 print(NSDate(components: displayTimeComponents))
                 $0.datePicker.minimumDate = NSDate(components: displayTimeComponents)
                 $0.datePicker.date = NSDate(components: displayTimeComponents)
                 $0.datePicker.setDate(NSDate(components: displayTimeComponents), animated: false)
                 */
                $0.datePicker.datePickerMode = .Time
                $0.datePicker.minuteInterval = 30
                //$0.datePicker.setDate(NSDate().startOf(.Minute, inRegion: NSDate().components.dateInRegion), animated: false)
            }.onDateChanged { time in
                var offset : NSTimeInterval = 0
                offset += Double(time.minute) * 60
                offset += Double(time.hour) * 3600
                self.timeOfDayOffsetInSeconds = offset
            }.displayTextFromDate(formatTime)
        
        let endRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "End"
            $0.titleLabel.textColor = UIColor.blackColor()
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            $0.displayLabel.textColor = UIColor.blackColor()
            $0.displayLabel.font = .systemFontOfSize(15)
            
            }.inlineCellSetup {
                
                $0.datePicker.datePickerMode = .Time
                $0.datePicker.minuteInterval = 30
                //let time = $0.datePicker.date.startOf(.Minute, inRegion: NSDate().inRegion().region)
                //$0.datePicker.date = time
            }.onDateChanged { time in
                if let start = self.timeOfDayOffsetInSeconds {
                    var end : NSTimeInterval = 0
                    end += Double(time.minute) * 60
                    end += Double(time.hour) * 3600
                    self.durationInSeconds = end - start
                }
            }.displayTextFromDate(formatTime)
        
        let selectedDaysLabel = UILabel()
        selectedDaysLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedDaysLabel.font = .systemFontOfSize(15)
        
        let repeatRow = LabelRowFormer<FormLabelCell>() {
            $0.textLabel?.text = "Frequency"
            $0.textLabel?.font = .boldSystemFontOfSize(15)
            $0.accessoryType = .DisclosureIndicator
            
            let contentConstraints : [NSLayoutConstraint] = [
                selectedDaysLabel.topAnchor.constraintEqualToAnchor($0.topAnchor),
                selectedDaysLabel.bottomAnchor.constraintEqualToAnchor($0.bottomAnchor),
                selectedDaysLabel.rightAnchor.constraintEqualToAnchor($0.rightAnchor, constant: -37.5)
            ]
            $0.addSubview(selectedDaysLabel)
            $0.addConstraints(contentConstraints)
            
            }.onSelected { row in
                let selectDays = DaySelectionViewController()
                selectDays.selectedIndices = self.selectedDays
                selectDays.selectionUpdateHandler = { [unowned self] days in
                    self.selectedDays = days
                    selectedDaysLabel.text = self.selectedDays.sort().map { self.dynamicType.dayNames[$0] }.joinWithSeparator(", ")
                }
                self.presentViewController(selectDays, animated: true, completion: nil)
                row.former!.deselect(true)
                
        }
        
        let noteRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = UIColor.blackColor()
            $0.textView.font = .systemFontOfSize(15)
            }.configure {
                $0.placeholder = "Notes"
                $0.rowHeight = 150
            }.onTextChanged { text in
                self.note = text
        }
        
        // Create Headers
        
        let createHeader: (() -> ViewFormer) = {
            return CustomViewFormer<FormHeaderFooterView>()
                .configure {
                    $0.viewHeight = 20
            }
        }
        
        // Create SectionFormers
        let eventTypeSection = SectionFormer(rowFormer: eventTypeRow)
            .set(headerViewFormer: createHeader())
        let titleSection = SectionFormer(rowFormer: titleRow)
            .set(headerViewFormer: createHeader())
        let dateSection = SectionFormer(rowFormer: startRow, endRow)
            .set(headerViewFormer: createHeader())
        let repeatSection = SectionFormer(rowFormer: repeatRow)
            .set(headerViewFormer: createHeader())
        let noteSection = SectionFormer(rowFormer: noteRow)
            .set(headerViewFormer: createHeader())
        
        former.append(sectionFormer: eventTypeSection, titleSection, dateSection, repeatSection, noteSection)
    }
}

class DaySelectionViewController: UIViewController {
    
    var selectedIndices: Set<Int> = []
    
    var selectionUpdateHandler: ((Set<Int>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        selectionUpdateHandler?(selectedIndices)
    }
    
    private func configureView() {
        
        let navigationBar : UINavigationBar = {
            let bar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44))
            bar.translatesAutoresizingMaskIntoConstraints = false
            let navigationItem = UINavigationItem()
            let leftButton = UIBarButtonItem(title: "back", style: .Plain, target: self, action: "back:")
            navigationItem.title = "Frequency"
            navigationItem.leftBarButtonItem = leftButton
            bar.items = [navigationItem]
            return bar
        }()
        
        view.addSubview(navigationBar)
        
        let navigationBarConstraints : [NSLayoutConstraint] = [
            navigationBar.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            navigationBar.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            navigationBar.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(navigationBarConstraints)
        
        let table = DaySelection(SelectedIndices: self.selectedIndices, SelectionUpdateHandler: self.selectionUpdateHandler)
        let tableView = table.view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(table)
        view.addSubview(tableView)
        
        let tableViewConstraints : [NSLayoutConstraint] = [
            tableView.topAnchor.constraintEqualToAnchor(navigationBar.bottomAnchor),
            tableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            tableView.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            tableView.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(tableViewConstraints)
        
    }
    
    func back(sender: UIBarItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    class DaySelection: UITableViewController {
        
        private static let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var selectedIndices: Set<Int> = []
        var selectionUpdateHandler: ((Set<Int>) -> Void)?
        
        convenience init(SelectedIndices selectedIndices: Set<Int>, SelectionUpdateHandler selectionUpdateHandler: ((Set<Int>) -> Void)?) {
            self.init()
            self.selectedIndices = selectedIndices
            self.selectionUpdateHandler = selectionUpdateHandler
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.title = "Days"
            tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
            selectionUpdateHandler?(selectedIndices)
            self.tableView.scrollEnabled = false
        }
        
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return 44.0
        }
        
        override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 22.0
        }
        
        override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return view.bounds.height - UIApplication.sharedApplication().statusBarFrame.size.height - 44.0*7
            
        }
        
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
}
