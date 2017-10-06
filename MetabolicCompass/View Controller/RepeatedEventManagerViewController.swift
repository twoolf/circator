
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
        case .Monday:
            return "Monday"
        case .Tuesday:
            return "Tuesday"
        case .Wednesday:
            return "Wednesday"
        case .Thursday:
            return "Thursday"
        case .Friday:
            return "Friday"
        case .Saturday:
            return "Saturday"
        case .Sunday:
            return "Sunday"
        }
    }
}

//public enum EventType {
//    case Meal
//    case Exercise
//    case Sleep
//}

public struct Event : Equatable {
    var name : String
    var eventType : EventType
    var timeOfDayOffset : TimeInterval
    var duration : TimeInterval
    //optional text info
    var note : String?
    //optional exact time for exact event logging
    var currentDay : Date?
    
    init(nameOfEvent name : String, typeOfEvent type : EventType, timeOfDayOffsetInSeconds offset : TimeInterval, durationInSeconds duration : TimeInterval, CurrentTimeAsCurrentDay time : Date? = nil, additionalInfo note : String? = nil) {
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
        let canvas = CGRect(0, 0, 100, 100)
        
        //creates vector path of circle bounded in canvas square
        let path = UIBezierPath(ovalIn: canvas)
        
        //creates core graphics contexts and assigns reference
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        //sets context's fill register with color
        context!.setFillColor(color.cgColor)
        
        //draws path in context
        context!.beginPath()
        context!.addPath(path.cgPath)
        
        //draws path defined in canvas within graphics context
        context!.drawPath(using: .fill)
        
        //creates UIImage from current graphics contexts and returns
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }()
    
    return circleImage
}


open class RepeatedEventsOrganizer : NSObject {
    
    static let shared = RepeatedEventsOrganizer()
    
    private var repeatedEvents : [RepeatedEvent] = []
    
    convenience init(RepeatedEvents events : [RepeatedEvent]) {
        self.init()
        self.repeatedEvents = events
    }
    
    func addRepeatedEvent(RepeatedEvent event : RepeatedEvent) -> Bool {
        
        for eventToCheck in repeatedEvents {
            for dayToCheck in eventToCheck.frequency {
                for dayOfEvent in event.frequency {
                    if dayToCheck == dayOfEvent {
                        if event.event.timeOfDayOffset < eventToCheck.event.timeOfDayOffset {
                            if event.event.timeOfDayOffset + event.event.duration > eventToCheck.event.timeOfDayOffset {
                                return false
                            }
                        }
                        if event.event.timeOfDayOffset > eventToCheck.event.timeOfDayOffset {
                            if eventToCheck.event.timeOfDayOffset + eventToCheck.event.duration > event.event.timeOfDayOffset {
                                return false
                            }
                        }
                        if event.event.timeOfDayOffset == eventToCheck.event.timeOfDayOffset {
                            return false
                        }
                    }
                }
            }
        }

        repeatedEvents.append(event)
        return true
    }
    
/*    public func removeRepeatedEvent(RepeatedEvent event : RepeatedEvent) -> Bool {
        for i in Range(0..<(repeatedEvents.endIndex)) {
            if self.repeatedEvents[i] == event {
                self.repeatedEvents.removeAtIndex(i)
                return true
            }
        }
        return false
    } */
    
    public func getEventsForDay(DayOfWeek day : Weekday) -> [RepeatedEvent] {
        
        var events : [RepeatedEvent] = []
        
        for eventToCheck in self.repeatedEvents {
            for dayToCheck in eventToCheck.frequency {
                if day == dayToCheck {
                    events.append(eventToCheck)
                }
            }
        }
        
        return events
    }
    
    /*
     //TODO
     //method needed for asynchronous request of event starting at time now, should be done in 30 minute intervals
     func getEventAtTimeDuringWeek(dayOfWeek weekday : Weekday, timeOfDayOffset time : NSTimeInterval) -> Event? {
        return nil
     }
     */
}


// MARK: - Main View Controller

open class RepeatedEventManagerViewController: UIViewController {
    
   @objc static let sharedManager = RepeatedEventManagerViewController()
    
    //UIButton subclass to associate button with selected weekday 
    public class WeekdayButton : UIButton {
        
        var day : Weekday = Weekday.Sunday
        
        init(dayOfWeek day : Weekday, frame: CGRect = CGRect.zero) {
            
            super.init(frame : frame)
            self.day = day
            
        }
        
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
    }
    
    //weekday buttons by day
    lazy var sundayButton: WeekdayButton = {
        
        var button = WeekdayButton(dayOfWeek: Weekday.Sunday)
        button.adjustsImageWhenHighlighted = true
        button.titleLabel?.textAlignment = .center
        button.setTitle("Su", for: .normal)
        button.setTitle("Su", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(white: 0.667, alpha: 0.5)), for: .highlighted)
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    
    lazy var mondayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Monday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.setTitle("M", for: .normal)
        button.setTitle("M", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), for: .highlighted)
        
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    lazy var tuesdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Tuesday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.setTitle("Tu", for: .normal)
        button.setTitle("Tu", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), for: .highlighted)
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    lazy var wednesdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Wednesday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.setTitle("W", for: .normal)
        button.setTitle("W", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), for: .highlighted)
//        button.addTarget(self, action: #selector(RepeatedEventManagerViewController.setWeekdayView(_:)), for: .TouchUpInside)
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    lazy var thursdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Thursday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.setTitle("Th", for: .normal)
        button.setTitle("Th", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), for: .highlighted)
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    lazy var fridayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Friday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.setTitle("F", for: .normal)
        button.setTitle("F", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), for: .highlighted)
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    lazy var saturdayButton: WeekdayButton = {
        var button = WeekdayButton(dayOfWeek: Weekday.Saturday)
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.textAlignment = .center
        button.setTitle("Sa", for: .normal)
        button.setTitle("Sa", for: .selected)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.black, for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.clear), for: .normal)
        button.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .selected)
        button.setBackgroundImage(drawCircle(FillColor: UIColor(red: 83, green: 83, blue: 83, alpha: 0.5)), for: .highlighted)
        button.addTarget(self, action: #selector(getter: RepeatedEventManagerViewController.sharedManager), for: .touchUpInside)
        return button
    }()
    
    lazy var weekdayButtons : [WeekdayButton] = {
        return [self.sundayButton, self.mondayButton, self.tuesdayButton, self.wednesdayButton, self.thursdayButton, self.fridayButton, self.saturdayButton]
    }()
    
    //UIStack that display weekday buttons as single row
    lazy var weekdayRowSelector : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: self.weekdayButtons)
        stackView.axis = .horizontal
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.fill
        stackView.spacing = 0
        stackView.backgroundColor = UIColor.clear
        
        return stackView
    }()
    
    var currentWeekday : WeekdayButton?
    
    var weekdayLabel = UILabel()
    
    var events = RepeatedEventsOrganizer.shared
    
    var eventsListView : RepeatedEventPlannerView!
    
    open override func viewDidLoad() {
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
        
        
        self.configureView()
        self.selectCurrentWeekday()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        
    }
    
    //Sets configuration of view controller 
    func configureView() {
        
        self.eventsListView = RepeatedEventPlannerView(intervalHeight: 32.0, frame: self.view.bounds)
        self.eventsListView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(eventsListView)
        let eventsListViewConstraints: [NSLayoutConstraint] = [
            eventsListView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            eventsListView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            eventsListView.leftAnchor.constraint(equalTo: view.leftAnchor),
            eventsListView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        view.addConstraints(eventsListViewConstraints)

        weekdayRowSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weekdayRowSelector)
        
        let weekdayRowSelectorConstraints: [NSLayoutConstraint] = [
            weekdayRowSelector.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 15),
            weekdayRowSelector.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            weekdayRowSelector.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            weekdayRowSelector.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            NSLayoutConstraint(item: weekdayRowSelector, attribute: .height, relatedBy: .equal, toItem: view.layoutMarginsGuide, attribute: .width, multiplier: 0.1428571429, constant: 0),
            ]
        
        view.addConstraints(weekdayRowSelectorConstraints)
        
        self.weekdayLabel.translatesAutoresizingMaskIntoConstraints = false
        self.weekdayLabel.textAlignment = .center
        self.weekdayLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        self.weekdayLabel.textColor = UIColor(red: 83, green: 83, blue: 83, alpha: 0.75)
        self.weekdayLabel.backgroundColor = UIColor.clear
        
        view.addSubview(weekdayLabel)
        
        let weekdayLabelConstraints: [NSLayoutConstraint] = [
            weekdayLabel.topAnchor.constraint(equalTo: weekdayRowSelector.bottomAnchor),
            weekdayLabel.bottomAnchor.constraint(equalTo: weekdayRowSelector.bottomAnchor, constant: 30),
            weekdayLabel.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            weekdayLabel.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            weekdayLabel.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
        ]
        
        view.addConstraints(weekdayLabelConstraints)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.addSubview(blurEffectView)
        let blurEffectViewConstraints : [NSLayoutConstraint] = [
            blurEffectView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: weekdayLabel.bottomAnchor),
            blurEffectView.rightAnchor.constraint(equalTo: view.rightAnchor),
            blurEffectView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ]
        view.addConstraints(blurEffectViewConstraints)
        
        view.bringSubview(toFront: weekdayLabel)
        view.bringSubview(toFront: weekdayRowSelector)
        
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.eventsListView.contentInset = UIEdgeInsetsMake(weekdayLabel.bounds.height + weekdayRowSelector.bounds.height + 15, 0, 0, 0)
    }
    
    @objc public func addRepeatedEvent(sender: UIBarItem) {
        let vc = NewRepeatedEventViewController()
        self.present(vc, animated: true, completion: nil)
    }
    
    public func setWeekdayView(_ sender: WeekdayButton!) {
        
        //sets weekday label to selected day
        self.weekdayLabel.text = sender.day.description
        
        //swaps current and selected day buttons setting states respectively
        currentWeekday?.isSelected = false
        sender.isSelected = true
        
        let events = self.events.getEventsForDay(DayOfWeek: sender.day)
        self.eventsListView.layoutEvents(eventsToLayout: events)
        
        //set current day as sender
        currentWeekday = sender
        
    }
    
    public func selectCurrentWeekday() {
        
        self.setWeekdayView(self.weekdayButtons[Date().weekday - 1])
        
    }
    
    public func relayoutEvents() {
        
        let events = self.events.getEventsForDay(DayOfWeek: self.currentWeekday!.day)
        self.eventsListView.layoutEvents(eventsToLayout: events)
    }
    
    public class RepeatedEventPlannerView : UIScrollView {
        
        var contentView : UIView!
        
        //an interval is defined as 30 minutes of time
        var intervalHeight : CGFloat!
        
        init(intervalHeight height : CGFloat, frame: CGRect = CGRect.zero) {
            super.init(frame : frame)
            self.intervalHeight = height
            self.configureView()
        }
        
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        @objc func eventDetailDoubleTap(sender: RepeatedEventItemView) {
            let vc = RepeatedEventDetailViewController(repeatedEvent: sender.event)
            (self.window?.rootViewController as! UINavigationController).pushViewController(vc, animated: true)
        }
        
        func configureView() {
            
            let contentView : UIView = {

                let height : CGFloat = {
                    let dayIntervalHeight : CGFloat = self.intervalHeight * 48
                    let padding : CGFloat = {
                        let paddingTop : CGFloat = 5.0
                        let paddingBottom : CGFloat = 5.0
                        return paddingTop + paddingBottom
                    }()
                    return dayIntervalHeight + padding
                }()
                
                let view = UIView(frame: CGRect(0, 0, self.bounds.width, height))
                
                var previous : UIView?
                
                for hour in ["12 AM", "1 AM", "2 AM", "3 AM", "4 AM", "5 AM", "6 AM", "7 AM", "8 AM", "9 AM", "10 AM", "11 AM", "Noon", "1 PM", "2 PM", "3 PM", "4 PM", "5 PM", "6 PM", "7 PM", "8 PM", "9 PM", "10 PM", "11 PM", "12 AM"] {
                    
                    let timeLabel = UILabel()
                    timeLabel.translatesAutoresizingMaskIntoConstraints = false
                    timeLabel.text = hour
                    timeLabel.font = UIFont.systemFont(ofSize: 11, weight: UIFont.Weight.semibold)
                    timeLabel.textColor = UIColor.lightGray
                    
                    view.addSubview(timeLabel)
                    
                    var timeLabelConstraints : [NSLayoutConstraint] = [
                        timeLabel.heightAnchor.constraint(equalToConstant: 10.0),
                        timeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30)
                    ]
                    
                    //correctly lays out seperator lines such that they are dependent upon each other
                    if previous != nil {
                        timeLabelConstraints.append(timeLabel.topAnchor.constraint(equalTo: (previous?.bottomAnchor)!, constant: self.intervalHeight * 2 - 10.0))
                    } else {
                        timeLabelConstraints.append(timeLabel.topAnchor.constraint(equalTo: view.topAnchor))
                    }
                    
                    view.addConstraints(timeLabelConstraints)
                    
                    let seperatorLine = UIView()
                    seperatorLine.translatesAutoresizingMaskIntoConstraints = false
                    seperatorLine.backgroundColor = UIColor.lightGray
                    
                    view.addSubview(seperatorLine)
                    
                    let seperatorLineConstraints : [NSLayoutConstraint] = [
                        seperatorLine.heightAnchor.constraint(equalToConstant: 1.0),
                        seperatorLine.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
                        seperatorLine.leftAnchor.constraint(equalTo: timeLabel.rightAnchor, constant: 15),
                        seperatorLine.rightAnchor.constraint(equalTo: view.rightAnchor)
                    ]
                    
                    view.addConstraints(seperatorLineConstraints)
                    
                    //ensures next separator to be laid out is dependent upon the previous one
                    previous = timeLabel
                }
                
                return view
            }()

            self.contentView = contentView
            self.contentSize = self.contentView.bounds.size
            self.addSubview(contentView)
        
        }
        
        func clearEvents() {
            for view in self.contentView.subviews {
                if view is RepeatedEventItemView {
                    view.removeFromSuperview()
                }
            }
        }
        
        public func layoutEvent(eventToLayout event : RepeatedEvent) {
            
            let eventItem = RepeatedEventItemView(repeatedEvent: event)
            eventItem.translatesAutoresizingMaskIntoConstraints = false
//            eventItem.addTarget(self, action: #selector(RepeatedEventManagerViewController.eventDetailDoubleTap(_:)), for: .TouchDownRepeat)
            eventItem.addTarget(self, action: #selector(RepeatedEventPlannerView.eventDetailDoubleTap(sender:)), for: .touchDownRepeat)
            
            self.contentView.addSubview(eventItem)

            let height : CGFloat = CGFloat(event.event.duration/1800.0) * self.intervalHeight
            let offset : CGFloat = CGFloat(event.event.timeOfDayOffset/1800.0) * self.intervalHeight
            
            let eventViewConstraints : [NSLayoutConstraint] = [
                eventItem.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 105),
                eventItem.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, constant: -135),
                eventItem.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: offset + 5.5),
                eventItem.bottomAnchor.constraint(equalTo: eventItem.topAnchor, constant: height - 1),
            ]
            
            self.contentView.addConstraints(eventViewConstraints)
        }
        
        func layoutEvents(eventsToLayout events : [RepeatedEvent]) {
            self.clearEvents()
            for event in events {
                self.layoutEvent(eventToLayout: event)
            }
        }
        


    }

}


open class RepeatedEventItemView: UIButton {
    
    var event : RepeatedEvent!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(repeatedEvent event : RepeatedEvent, frame: CGRect = CGRect.zero) {
        super.init(frame : frame)
        self.event = event
        self.configureView()
    }
    
    private func configureView() {
        
        self.layer.cornerRadius = 16.0
        
        let eventTitle = UILabel()
        eventTitle.translatesAutoresizingMaskIntoConstraints = false
        eventTitle.text = self.event.event.name
        eventTitle.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.semibold)
        eventTitle.textColor = UIColor.white
        
        let eventIcon = UIButton()
        eventIcon.translatesAutoresizingMaskIntoConstraints = false
        eventIcon.setBackgroundImage(drawCircle(FillColor: UIColor.white), for: .normal)
        eventIcon.adjustsImageWhenHighlighted = false
        eventIcon.titleLabel?.adjustsFontSizeToFitWidth = true
        eventIcon.titleLabel?.textAlignment = .center
        eventIcon.titleLabel?.minimumScaleFactor = 0.5;
        
        let eventIconInner = UIImageView()
        eventIconInner.translatesAutoresizingMaskIntoConstraints = false
        
        eventIcon.addSubview(eventIconInner)
        let eventIconInnerConstraints : [NSLayoutConstraint] = [
            eventIconInner.centerXAnchor.constraint(equalTo: eventIcon.centerXAnchor),
            eventIconInner.centerYAnchor.constraint(equalTo: eventIcon.centerYAnchor),
            NSLayoutConstraint(item: eventIconInner, attribute: .height, relatedBy: .equal, toItem: eventIcon, attribute: .height, multiplier: 0.75, constant: 0),
            NSLayoutConstraint(item: eventIconInner, attribute: .width, relatedBy: .equal, toItem: eventIcon, attribute: .width, multiplier: 0.75, constant: 0)
        ]
        
        eventIcon.addConstraints(eventIconInnerConstraints)
        
        self.addSubview(eventTitle)
        self.addSubview(eventIcon)
        
        let eventViewContentConstraints : [NSLayoutConstraint] = [
            eventTitle.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 7.5),
            eventTitle.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -7.5),
            eventIcon.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -3.5),
            NSLayoutConstraint(item: eventIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 25),
            eventIcon.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -3.5),
            eventIcon.heightAnchor.constraint(equalTo: eventIcon.widthAnchor)
            
        ]
        
        self.addConstraints(eventViewContentConstraints)
        
        switch self.event.event.eventType {
        case .Meal:
            self.backgroundColor = UIColor.green.withAlphaComponent(0.25)
            //eventIcon.setTitle("M", forState: .Normal)
            eventIconInner.image = drawCircle(FillColor: UIColor.green.withAlphaComponent(0.25))
        case .Sleep:
            self.backgroundColor = UIColor.blue.withAlphaComponent(0.25)
            //eventIcon.setTitle("S", forState: .Normal)
            eventIconInner.image = drawCircle(FillColor: UIColor.blue.withAlphaComponent(0.25))
        case .Exercise:
            self.backgroundColor = UIColor.red.withAlphaComponent(0.25)
            //eventIcon.setTitle("E", forState: .Normal)
            eventIconInner.image = drawCircle(FillColor: UIColor.red.withAlphaComponent(0.25))
        }
    }
}

open class RepeatedEventDetailViewController : UIViewController {
    
    var event : RepeatedEvent!
    
    convenience init(repeatedEvent event : RepeatedEvent) {
        self.init()
        self.event = event
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.formatView()
        self.configureView()
    }
    
    func formatView() {
        navigationItem.title = "Detail"
        self.view.backgroundColor = UIColor(white: 0.9, alpha: 1)
    }
    
    private func configureView() {
        
        let eventIcon = UIImageView()
        eventIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(eventIcon)
        
        let eventIconConstraints : [NSLayoutConstraint] = [
            eventIcon.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 15),
            eventIcon.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            NSLayoutConstraint(item: eventIcon, attribute: .width, relatedBy: .equal, toItem: view.layoutMarginsGuide, attribute: .width, multiplier: 0.25, constant: 0),
            eventIcon.heightAnchor.constraint(equalTo: eventIcon.widthAnchor)
        ]
        view.addConstraints(eventIconConstraints)
        
        switch self.event!.event.eventType {
        case .Meal:
            eventIcon.image = drawCircle(FillColor: UIColor.green.withAlphaComponent(0.5))
        case .Sleep:
            eventIcon.image = drawCircle(FillColor: UIColor.blue.withAlphaComponent(0.5))
        case .Exercise:
            eventIcon.image = drawCircle(FillColor: UIColor.red.withAlphaComponent(0.5))
        }
        
        let eventTitleLabel = UILabel()
        eventTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        eventTitleLabel.font = UIFont.systemFont(ofSize: 26, weight: UIFont.Weight.semibold)
        eventTitleLabel.textColor = UIColor.black
        eventTitleLabel.text = self.event!.event.name
        view.addSubview(eventTitleLabel)
        
        let eventTitleLabelConstraints : [NSLayoutConstraint] = [
            eventTitleLabel.topAnchor.constraint(equalTo: eventIcon.topAnchor),
            eventTitleLabel.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            eventTitleLabel.rightAnchor.constraint(equalTo: eventIcon.leftAnchor),
        ]
        view.addConstraints(eventTitleLabelConstraints)
        
        let eventTimeLabel = UILabel()
        eventTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        eventTimeLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)
        eventTimeLabel.textColor = UIColor.black
        
        //TODO
        //events that end or start on the half-hour are not displaying correctly
        
        let formatTime: ((Date) -> String) = { time in
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return timeFormatter.string(from: time)
        }
        
        let start : String = {
            var components = DateComponents()
            components.hour = Int((self.event?.event.timeOfDayOffset)!)/3600
            components.minute = Int((self.event?.event.timeOfDayOffset)!)%60
            return formatTime(Date())
        }()
        
        let end : String = {
            var components = DateComponents()
            components.hour = Int((self.event?.event.timeOfDayOffset)! + (self.event?.event.duration)!)/3600
            components.minute = Int((self.event?.event.timeOfDayOffset)! + (self.event?.event.duration)!)%60
            return formatTime(Date())
        }()
        
        eventTimeLabel.text = "from " + start + " to " + end
        view.addSubview(eventTimeLabel)
        
        let eventTimeLabelConstraints : [NSLayoutConstraint] = [
            eventTimeLabel.centerYAnchor.constraint(equalTo: eventIcon.centerYAnchor),
            eventTimeLabel.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            eventTimeLabel.rightAnchor.constraint(equalTo: eventIcon.leftAnchor),
            
            ]
        view.addConstraints(eventTimeLabelConstraints)
        
        // days of the week
        let eventDaysLabel = UILabel()
        eventDaysLabel.translatesAutoresizingMaskIntoConstraints = false
        eventDaysLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        eventDaysLabel.textColor = UIColor.black
        eventDaysLabel.numberOfLines = 0
        eventDaysLabel.lineBreakMode = .byWordWrapping
        eventDaysLabel.text = self.event?.frequency.sorted(by: {$0.rawValue < $1.rawValue}).map{ (day) -> String in return day.description }.joined(separator: ", ")
        view.addSubview(eventDaysLabel)
        
        let eventDaysLabelConstraints : [NSLayoutConstraint] = [
            eventDaysLabel.topAnchor.constraint(equalTo: eventTimeLabel.bottomAnchor, constant: 2.5),
            eventDaysLabel.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            eventDaysLabel.rightAnchor.constraint(equalTo: eventIcon.leftAnchor)
        ]
        view.addConstraints(eventDaysLabelConstraints)
        
        let deleteButton = UIButton()
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        print(deleteButton.titleLabel ?? "default")
        deleteButton.titleLabel?.textAlignment = .center
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(UIColor.red, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.regular)
        
        deleteButton.addTarget(self, action: "deleteEvent:", for: .touchUpInside)
        
        let lineSeperator = UIView()
        lineSeperator.translatesAutoresizingMaskIntoConstraints = false
        lineSeperator.backgroundColor = UIColor.gray
        
        deleteButton.addSubview(lineSeperator)
        let lineSeperatorConstraints : [NSLayoutConstraint] = [
            lineSeperator.rightAnchor.constraint(equalTo: deleteButton.rightAnchor),
            lineSeperator.leftAnchor.constraint(equalTo: deleteButton.leftAnchor),
            lineSeperator.topAnchor.constraint(equalTo: deleteButton.topAnchor),
            lineSeperator.heightAnchor.constraint(equalToConstant: 1)
        ]
        
        deleteButton.addConstraints(lineSeperatorConstraints)
        
        view.addSubview(deleteButton)
        
        let deleteButtonConstraints : [NSLayoutConstraint] = [
            deleteButton.heightAnchor.constraint(equalToConstant: 45),
            deleteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            deleteButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            deleteButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor)
        ]
        
        view.addConstraints(deleteButtonConstraints)
        
        let eventInfoView = UIView()
        eventInfoView.translatesAutoresizingMaskIntoConstraints = false
        eventInfoView.layer.cornerRadius = 10
        eventInfoView.clipsToBounds = true
        eventInfoView.backgroundColor = UIColor(white: 1, alpha: 0.5)
        
        view.addSubview(eventInfoView)
        
        let eventInfoViewConstraints : [NSLayoutConstraint] =  [
            eventInfoView.topAnchor.constraint(equalTo: eventIcon.bottomAnchor, constant: 15),
            eventInfoView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            eventInfoView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            eventInfoView.bottomAnchor.constraint(equalTo: deleteButton.topAnchor, constant: -15)
        ]
        
        view.addConstraints(eventInfoViewConstraints)
        
        
        let eventNotes = UILabel()
        eventNotes.translatesAutoresizingMaskIntoConstraints = false
        eventNotes.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.light)
        eventNotes.textColor = UIColor.black
        eventNotes.numberOfLines = 0
        eventNotes.lineBreakMode = .byWordWrapping
        
        
        if let note = self.event?.event.note {
            eventNotes.text = note
        } else {
            eventNotes.text = "No notes"
            eventNotes.textColor = UIColor.lightGray
        }
        
        eventInfoView.addSubview(eventNotes)
        
        let eventNotesConstraints : [NSLayoutConstraint] = [
            eventNotes.topAnchor.constraint(equalTo: eventInfoView.topAnchor, constant: 15),
            eventNotes.leftAnchor.constraint(equalTo: eventInfoView.leftAnchor, constant: 15),
            eventNotes.rightAnchor.constraint(equalTo: eventInfoView.rightAnchor, constant: -15),
            eventInfoView.bottomAnchor.constraint(equalTo: eventInfoView.bottomAnchor, constant: -15)
        ]
        
        view.addConstraints(eventNotesConstraints)
        
        
        
    }
    
    public func deleteEvent (_ sender: UIButton!) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let deleteEventAction = UIAlertAction(title: "Delete", style: .destructive) { action in
            
//            RepeatedEventsOrganizer.shared.removeRepeatedEvent(RepeatedEvent: self.event)
//            RepeatedEventsOrganizer.shared.
            
            for view in RepeatedEventManagerViewController.sharedManager.eventsListView.contentView.subviews {
                if view is RepeatedEventItemView && (view as! RepeatedEventItemView).event == self.event {
                    view.removeFromSuperview()
                }
            }
            
            self.navigationController?.popViewController(animated: true)
        }
        
        alertController.addAction(deleteEventAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

open class NewRepeatedEventViewController: UIViewController {
    
    var event : RepeatedEvent!
    var form : RepeatedEventFormViewController!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public func configureView() {
        
        //UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)   
        
        let navigationBar = UINavigationBar(frame: CGRect(0, 0, self.view.frame.size.width, 44))
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        let navigationItems = UINavigationItem()
        
//        let left = UIBarButtonItem(title: "cancel", style: .Plain, target: self, action: #selector(NewRepeatedEventViewController.cancel(_:)))
        let left = UIBarButtonItem(title: "cancel", style: .plain, target: self, action: #selector(RepeatedEventManagerViewController.cancelPreviousPerformRequests(withTarget:)))
//        let right = UIBarButtonItem(title: "add", style: .Plain, target: self, action: #selector(RepeatedEventManagerViewController.add(_:)))
        let right = UIBarButtonItem(title: "add", style: .plain, target: self, action: #selector(RepeatedEventManagerViewController.addRepeatedEvent(sender:)))
        
        navigationItems.title = "New Repeated Event"
        navigationItems.leftBarButtonItem = left
        navigationItems.rightBarButtonItem = right
        
        navigationBar.items = [navigationItems]
        
        view.addSubview(navigationBar)
        
        let navigationBarConstraints : [NSLayoutConstraint] = [
            navigationBar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        view.addConstraints(navigationBarConstraints)
        
        let form = RepeatedEventFormViewController()
        form.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(form)
        view.addSubview(form.view)
        
        let formConstraints : [NSLayoutConstraint] = [
            form.view.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            form.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            form.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            form.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        view.addConstraints(formConstraints)
        self.form = form
        
    }
    
    public func cancel(_ sender: UIBarItem) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    public func add(_ sender: UIBarItem) {
        
        var eventTitle : String?
        var eventType : EventType?
        var timeOfDayOffsetInSeconds : TimeInterval?
        var durationInSeconds : TimeInterval?
        var OccursOnDays: [Weekday] = []
        var note : String?
        
        //TODO
        //testing needed
        //believe there are few bugs here, needs more rigorous testing to ensure events are added properly with various test cases
        
        if form?.eventTitle != nil {
            if (form?.eventTitle?.characters.count)! > 16 {
                UINotifications.genericError(vc: self, msg: "Event title is too long.")
                return
            }
            if (form?.eventTitle?.characters.count)! < 1 {
                UINotifications.genericError(vc: self, msg: "Event title required.")
                return
            }
            eventTitle = form?.eventTitle
        } else {
            UINotifications.genericError(vc: self, msg: "Event title required.")
            return
        }
        
        if form?.eventType != nil {
            eventType = form?.eventType
        } else {
            UINotifications.genericError(vc: self, msg: "Event type required.")
            return
        }
        
        if form?.timeOfDayOffsetInSeconds != nil {
            timeOfDayOffsetInSeconds = form?.timeOfDayOffsetInSeconds
        } else {
            UINotifications.genericError(vc: self, msg: "Event start time required.")
            return
        }
        
        if form?.durationInSeconds != nil {
            durationInSeconds = form?.durationInSeconds
            if ((durationInSeconds?.negate()) != nil) {
                UINotifications.genericError(vc: self, msg: "Event must end after it starts.")
                return
            }
        } else {
            UINotifications.genericError(vc: self, msg: "Event end time required.")
            return
        }
        
        if (form?.selectedDays.count)! > 0 {
            if let selectedDays = form?.selectedDays {
                for day in Array<Int>(selectedDays) {
                    if let weekday = Weekday(rawValue: day + 1) {
                        OccursOnDays.append(weekday)
                    }
                }
            }
            
        } else {
            UINotifications.genericError(vc: self, msg: "Event must occur on at least one day.")
            return
        }
        
        note = form?.note
        
        let event = Event(nameOfEvent: eventTitle!, typeOfEvent: eventType!, timeOfDayOffsetInSeconds: timeOfDayOffsetInSeconds!, durationInSeconds: durationInSeconds!, additionalInfo: note)
        
        //must check if event conflicts with any other existing events
        
        let check = RepeatedEventsOrganizer.shared.addRepeatedEvent(RepeatedEvent: RepeatedEvent(metabolicEvent: event, daysOfWeekOccurs: OccursOnDays))
        
        if !check {
            UINotifications.genericError(vc: self, msg: "Event conflicts with existing event.")
            return
        }

        self.dismiss(animated: true, completion: nil)
        
    }
}

final class RepeatedEventFormViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    var eventTitle : String?
    var eventType : EventType?
    var timeOfDayOffsetInSeconds : TimeInterval?
    var durationInSeconds : TimeInterval?
    var selectedDays: Set<Int> = []
    var note : String?
    
    private static let dayNames = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
    
    private func configure() {
        
        tableView.isScrollEnabled = false
        
        //title = "Add Event"
        tableView.contentInset.top = 0
        tableView.contentInset.bottom = 30
        tableView.contentOffset.y = -10
        
        // Create RowFomers
        
        let eventTypeRow = SegmentedRowFormer<FormSegmentedCell>() {
            $0.titleLabel.text = "Type"
            $0.titleLabel.textColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            }.configure {
                $0.segmentTitles = ["Meal", "Sleep", "Exercise"]
                $0.selectedIndex = UISegmentedControlNoSegment
            }.onSegmentSelected { selection, cell in
                switch selection {
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
            $0.textField.textColor = UIColor.black
            $0.textField.font = .systemFont(ofSize: 15)
            }.configure {
                $0.placeholder = "Title"
            }.onTextChanged { title in
                self.eventTitle = title
        }
        
        let formatTime: ((Date) -> String) = { time in
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            return timeFormatter.string(from: time)
        }
        
        let startRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "Start"
            $0.titleLabel.textColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = UIColor.black
            $0.displayLabel.font = .systemFont(ofSize: 15)
            }.inlineCellSetup {
                
                //TODO
                //timeToShow instantiated properply but datePicker setDate won't change the date properly
                
                let timeToShow : Date = {
                    var components = DateComponents()
                    if components.minute! < 30 {
                        components.minute = 0
                    } else {
                        components.minute = 30
                    }
//                    return Date(components: components)
                    return Date()
                }()
                
                print(timeToShow)
                //setDate not working?
                $0.datePicker.setDate(timeToShow, animated: false)
                
                $0.datePicker.datePickerMode = .time
                $0.datePicker.minuteInterval = 30
            }.onDateChanged { time in
                var offset : TimeInterval = 0
                offset += Double(time.minute) * 60
                offset += Double(time.hour) * 3600
                self.timeOfDayOffsetInSeconds = offset
            }.displayTextFromDate(formatTime)
        
        let endRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
            $0.titleLabel.text = "End"
            $0.titleLabel.textColor = UIColor.black
            $0.titleLabel.font = .boldSystemFont(ofSize: 15)
            $0.displayLabel.textColor = UIColor.black
            $0.displayLabel.font = .systemFont(ofSize: 15)
            
            }.inlineCellSetup {
                
                $0.datePicker.datePickerMode = .time
                $0.datePicker.minuteInterval = 30
                
            }.onDateChanged { time in
                if let start = self.timeOfDayOffsetInSeconds {
                    var end : TimeInterval = 0
                    end += Double(time.minute) * 60
                    end += Double(time.hour) * 3600
                    self.durationInSeconds = end - start
                }
            }.displayTextFromDate(formatTime)
        
        let selectedDaysLabel = UILabel()
        selectedDaysLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedDaysLabel.font = .systemFont(ofSize: 15)
        
        let repeatRow = LabelRowFormer<FormLabelCell>() {
            $0.textLabel?.text = "Frequency"
            $0.textLabel?.font = .boldSystemFont(ofSize: 15)
            $0.accessoryType = .disclosureIndicator
            
            let contentConstraints : [NSLayoutConstraint] = [
                selectedDaysLabel.topAnchor.constraint(equalTo: $0.topAnchor),
                selectedDaysLabel.bottomAnchor.constraint(equalTo: $0.bottomAnchor),
                selectedDaysLabel.rightAnchor.constraint(equalTo: $0.rightAnchor, constant: -37.5)
            ]
            $0.addSubview(selectedDaysLabel)
            $0.addConstraints(contentConstraints)
            
            }.onSelected { row in
                let selectDays = DaySelectionViewController()
                selectDays.selectedIndices = self.selectedDays
                selectDays.selectionUpdateHandler = { [unowned self] days in
                    self.selectedDays = days
                    selectedDaysLabel.text = self.selectedDays.sorted().map { type(of: self).dayNames[$0] }.joined(separator: ", ")
                }
                self.present(selectDays, animated: true, completion: nil)
                row.former!.deselect(animated: true)
                
        }
        
        let noteRow = TextViewRowFormer<FormTextViewCell>() {
            $0.textView.textColor = UIColor.black
            $0.textView.font = .systemFont(ofSize: 15)
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

public class DaySelectionViewController: UIViewController {
    
    var selectedIndices: Set<Int> = []
    var selectionUpdateHandler: ((Set<Int>) -> Void)?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        selectionUpdateHandler?(selectedIndices)
    }
    
    private func configureView() {
        
        let navigationBar : UINavigationBar = {
            let bar = UINavigationBar(frame: CGRect(0, 0, self.view.frame.size.width, 44))
            bar.translatesAutoresizingMaskIntoConstraints = false
            let navigationItem = UINavigationItem()
            let leftButton = UIBarButtonItem(title: "back", style: .plain, target: self, action: "back:")
            navigationItem.title = "Frequency"
            navigationItem.leftBarButtonItem = leftButton
            bar.items = [navigationItem]
            return bar
        }()
        
        view.addSubview(navigationBar)
        
        let navigationBarConstraints : [NSLayoutConstraint] = [
            navigationBar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        view.addConstraints(navigationBarConstraints)
        
        let table = DaySelection(SelectedIndices: self.selectedIndices, SelectionUpdateHandler: self.selectionUpdateHandler)
        let tableView = table.view
        tableView?.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(table)
        view.addSubview(tableView!)
        
        let tableViewConstraints : [NSLayoutConstraint] = [
            tableView!.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView!.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView!.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        
        view.addConstraints(tableViewConstraints)
        
    }
    
    func back(_ sender: UIBarItem) {
        self.dismiss(animated: true, completion: nil)
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
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
            selectionUpdateHandler?(selectedIndices)
            self.tableView.isScrollEnabled = false
        }
        
        override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 44.0
        }
        
        override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 22.0
        }
        
        override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return view.bounds.height - UIApplication.shared.statusBarFrame.size.height - 44.0*7
            
        }
        
        func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 7
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "dayCell", for: indexPath as IndexPath)
            cell.textLabel?.text = type(of: self).dayNames[indexPath.row]
            cell.accessoryType = selectedIndices.contains(indexPath.row) ? .checkmark : .none
            return cell
        }
        
        override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
            let cell = tableView.cellForRow(at: indexPath as IndexPath)!
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
            if selectedIndices.contains(indexPath.row) {
                selectedIndices.remove(indexPath.row)
            } else {
                selectedIndices.insert(indexPath.row)
            }
            cell.accessoryType = selectedIndices.contains(indexPath.row) ? .checkmark : .none
            selectionUpdateHandler?(selectedIndices)
        }
    }
}
