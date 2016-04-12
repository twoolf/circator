//
//  RepeatedEventsController.swift
//  Circator
//
//  Created by Sihao Lu on 2/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Former
import SwiftDate

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
            eventTimeLabel.rightAnchor.constraintEqualToAnchor(eventIcon.leftAnchor, constant: -15),
            
        ]
        view.addConstraints(eventTimeLabelConstraints)
        
        // days of the week
        let eventDaysLabel = UILabel()
        eventDaysLabel.translatesAutoresizingMaskIntoConstraints = false
        eventDaysLabel.font = UIFont.systemFontOfSize(14, weight: UIFontWeightMedium)
        eventDaysLabel.textColor = UIColor.blackColor()
        eventDaysLabel.numberOfLines = 0
        eventDaysLabel.lineBreakMode = .ByWordWrapping
        eventDaysLabel.text = self.event?.frequency.map{ (day) -> String in return day.description }.joinWithSeparator(", ")
        view.addSubview(eventDaysLabel)
        
        let eventDaysLabelConstraints : [NSLayoutConstraint] = [
            eventDaysLabel.topAnchor.constraintEqualToAnchor(eventTimeLabel.bottomAnchor, constant: 2.5),
            eventDaysLabel.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventDaysLabel.rightAnchor.constraintEqualToAnchor(eventIcon.leftAnchor, constant: -15)
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
        
        let eventNotes = UITextView()
        eventNotes.translatesAutoresizingMaskIntoConstraints = false
        eventNotes.editable = false
        eventNotes.selectable = true
        eventNotes.allowsEditingTextAttributes = false
        
        
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
                if vc is RepeatedEventsListViewController {
                    (vc as! RepeatedEventsListViewController).events.removeRepeatedEvent(RepeatedEvent: self.event!)
                    (vc as! RepeatedEventsListViewController).eventsList.tableView.reloadData()
                    //print((vc as! RepeatedEventsListViewController).eventsList.view.subviews)
                    for view in (vc as! RepeatedEventsListViewController).eventsList.view.subviews {
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
            if vc is RepeatedEventsListViewController {
                relvc = vc
            }
        }
        
        let presenting = relvc as! RepeatedEventsListViewController

        if form?.eventTitle != nil {
            if form?.eventTitle?.characters.count > 16 {
                UINotifications.genericError(self, msg: "Event title is too long.")
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