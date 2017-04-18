//
//  LogEventViewControllerEventViewController.swift
//  MetabolicCompass
//
//  Created by Edwin L. Whitman on 5/24/16.
//  Copyright © 2016 Edwin L. Whitman, Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Former
import SwiftDate

class LogEventViewController: UIViewController {
    
    var event : Event?
    var coreInfo : EventCoreInfoFormViewController?
    var additionalInfo : EventAdditionalInfoFormViewController?
    
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
        let right = UIBarButtonItem(title: "log", style: .Bordered, target: self, action: "add:")
        
        navigationItems.title = "Log Event"
        navigationItems.leftBarButtonItem = left
        navigationItems.rightBarButtonItem = right
        
        navigationBar.items = [navigationItems]
        
        view.addSubview(navigationBar)
        
        let navigationBarConstraints : [NSLayoutConstraint] = [
            
            navigationBar.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            navigationBar.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            navigationBar.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(navigationBarConstraints)
        
        let mealTypeButton : UIButton = {
            let button = MCButton(frame: CGRectMake(0, 0, 50, 50), buttonStyle: .Circular)
            return button
        }()
        
        let sleepTypeButton : UIButton = {
            let button = MCButton(frame: CGRectMake(0, 0, 50, 50), buttonStyle: .Circular)
            return button
        }()
        
        let exerciseTypeButton : UIButton = {
            let button = MCButton(frame: CGRectMake(0, 0, 50, 50), buttonStyle: .Circular)
            return button
        }()
        
        
        let eventTypeSelectorView : UIStackView = {
            let view = UIStackView(arrangedSubviews: [mealTypeButton, sleepTypeButton, exerciseTypeButton])
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .Horizontal
            view.distribution = UIStackViewDistribution.FillEqually
            view.alignment = UIStackViewAlignment.Fill
            view.spacing = 15
            
            view.backgroundColor = UIColor.magentaColor()
            return view
        }()
        
        
        view.addSubview(eventTypeSelectorView)
        
        let eventTypeSelectorViewConstraints : [NSLayoutConstraint] = [
            eventTypeSelectorView.topAnchor.constraintEqualToAnchor(navigationBar.bottomAnchor, constant: 15),
            eventTypeSelectorView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 15),
            eventTypeSelectorView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -15),
            eventTypeSelectorView.heightAnchor.constraintEqualToConstant(75)
        ]
        
        view.addConstraints(eventTypeSelectorViewConstraints)
        
        
        let coreInfoViewController = EventCoreInfoFormViewController()
        coreInfoViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(coreInfoViewController)
        view.addSubview(coreInfoViewController.view)
        
        let coreInfoViewConstraints : [NSLayoutConstraint] = [
            coreInfoViewController.view.topAnchor.constraintEqualToAnchor(eventTypeSelectorView.bottomAnchor),
            coreInfoViewController.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -250),
            coreInfoViewController.view.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            coreInfoViewController.view.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(coreInfoViewConstraints)
        self.coreInfo = coreInfoViewController
        
        
        
        let additionalInfoViewController = UITableViewController()
        additionalInfoViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(additionalInfoViewController)
        view.addSubview(additionalInfoViewController.view)
        
        let additionalInfoViewConstraints : [NSLayoutConstraint] = [
            additionalInfoViewController.view.topAnchor.constraintEqualToAnchor(coreInfoViewController.view.bottomAnchor),
            additionalInfoViewController.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            additionalInfoViewController.view.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            additionalInfoViewController.view.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(additionalInfoViewConstraints)
        //self.additionalInfo = additionalInfoViewController
        
        
        
    }
    
    func cancel(sender: UIBarItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func add(sender: UIBarItem) {
        
        /*
         
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
         
         if coreInfo?.eventTitle != nil {
         if coreInfo?.eventTitle?.characters.count > 16 {
         UINotifications.genericError(self, msg: "Event title is too long.")
         return
         }
         if coreInfo?.eventTitle?.characters.count < 1 {
         UINotifications.genericError(self, msg: "Event title required.")
         return
         }
         eventTitle = coreInfo?.eventTitle
         } else {
         UINotifications.genericError(self, msg: "Event title required.")
         return
         }
         
         if coreInfo?.eventType != nil {
         print(coreInfo?.eventType)
         eventType = coreInfo?.eventType
         } else {
         UINotifications.genericError(self, msg: "Event type required.")
         return
         }
         
         if coreInfo?.timeOfDayOffsetInSeconds != nil {
         timeOfDayOffsetInSeconds = coreInfo?.timeOfDayOffsetInSeconds
         } else {
         UINotifications.genericError(self, msg: "Event start time required.")
         return
         }
         
         if coreInfo?.durationInSeconds != nil {
         durationInSeconds = coreInfo?.durationInSeconds
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
         note = coreInfo?.note
         
         let event = Event(nameOfEvent: eventTitle!, typeOfEvent: eventType!, timeOfDayOffsetInSeconds: timeOfDayOffsetInSeconds!, durationInSeconds: durationInSeconds!, additionalInfo: note)
         
         //must check if event conflicts with any other existing events
         
         let check = presenting.events.addRepeatedEvent(RepeatedEvent: RepeatedEvent(metabolicEvent: event, daysOfWeekOccurs: OccursOnDays))
         
         if !check {
         UINotifications.genericError(self, msg: "Event conflicts with existing event.")
         return
         }
         
         presenting.loadData()
         */
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
}

final class EventCoreInfoFormViewController: FormViewController {
    
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
        
        let formatTime: (Date -> String) = { time in
            let timeFormatter = DateFormatter()
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
        
        
        former.append(sectionFormer: eventTypeSection, titleSection, dateSection)
    }
}

class EventAdditionalInfoFormViewController : FormViewController {
    
    
    
}
