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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.formatView()
        navigationItem.title = "Detail"
    }
    
    /*
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    */
    
    func formatView() {
        
    }
    
    func configureView(RepeatedEvent repeatedEvent : RepeatedEvent) {
        
        let event : Event = repeatedEvent.event
        let frequency : [Weekday] = repeatedEvent.frequency
        
        let eventIcon = UIImageView(image: drawCircle(FillColor: UIColor.grayColor()))
        eventIcon.translatesAutoresizingMaskIntoConstraints = false
        //view.insertSubview(eventIcon, atIndex: 0)
        view.addSubview(eventIcon)
        
        let eventIconConstraints : [NSLayoutConstraint] = [
            eventIcon.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 15),
            eventIcon.rightAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.rightAnchor),
            NSLayoutConstraint(item: eventIcon, attribute: .Width, relatedBy: .Equal, toItem: view.layoutMarginsGuide, attribute: .Width, multiplier: 0.333, constant: 0),
            eventIcon.heightAnchor.constraintEqualToAnchor(eventIcon.widthAnchor)
            //NSLayoutConstraint(item: eventIcon, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 0.333, constant: 0)
        ]
        view.addConstraints(eventIconConstraints)
        
        
        switch event.eventType {
            case .Meal:
                //eventIcon.setTitle("M", forState: .Normal)
                eventIcon.image = drawCircle(FillColor: UIColor.greenColor())
            case .Sleep:
                //eventIcon.setTitle("S", forState: .Normal)
                eventIcon.image = drawCircle(FillColor: UIColor.blueColor())
            case .Exercise:
                //eventIcon.setTitle("E", forState: .Normal)
                eventIcon.image = drawCircle(FillColor: UIColor.redColor())
        }
        
        
        let eventTitle = UILabel()
        eventTitle.translatesAutoresizingMaskIntoConstraints = false
        eventTitle.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        eventTitle.textColor = UIColor.blackColor()
        eventTitle.text = event.name
        view.addSubview(eventTitle)
    
        let eventTitleConstraints : [NSLayoutConstraint] = [
            eventTitle.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 15),
            eventTitle.leftAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leftAnchor),
            eventTitle.rightAnchor.constraintEqualToAnchor(eventIcon.leftAnchor)
        ]
        view.addConstraints(eventTitleConstraints)
        
        
        
    }
}

class NewRepeatedEventViewController: UIViewController {
    
    var event : RepeatedEvent?
    var form : AddEventViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //se.rootViewController = navController
        
        
        self.configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func configureView() {
        
        
        
        //navigationController?.setNavigationBarHidden(false, animated: false)
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44))
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        //navigationBar.delegate =
        
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
        
        //let table = RepeatedEventViewController()
        //let table = RepeatedEventViewController()
        //let tableView = table.view
        //tableView.translatesAutoresizingMaskIntoConstraints = false
        //self.addChildViewController(table)
        //view.addSubview(tableView)
        
        let form = AddEventViewController()
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
        
        //tableView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor)
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
            eventTitle = form?.eventTitle
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        if form?.eventType != nil {
            print(form?.eventType)
            eventType = form?.eventType
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        if form?.timeOfDayOffsetInSeconds != nil {
            timeOfDayOffsetInSeconds = form?.timeOfDayOffsetInSeconds
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        if form?.durationInSeconds != nil {
            durationInSeconds = form?.durationInSeconds
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
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
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
    
        print("\(OccursOnDays)")
        note = form?.note
        
        let event = Event(nameOfEvent: eventTitle!, typeOfEvent: eventType!, timeOfDayOffsetInSeconds: timeOfDayOffsetInSeconds!, durationInSeconds: durationInSeconds!, additionalInfo: note)
        
        presenting.events.addRepeatedEvent(RepeatedEvent: RepeatedEvent(metabolicEvent: event, daysOfWeekOccurs: OccursOnDays))
        
        self.dismissViewControllerAnimated(true, completion: nil)
        print("added")
        
    }
    
}

final class AddEventViewController: FormViewController {
    
    
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    // MARK: Private
    
    //let workout : RepeatedEvent = RepeatedEvent(metabolicEvent: Event(nameOfEvent: "workout", typeOfEvent: .Exercise, timeOfDayOffsetInSeconds: 32400, durationInSeconds: 25200), daysOfWeekOccurs: sunday)
    
    var eventTitle : String?
    var eventType : EventType?
    var timeOfDayOffsetInSeconds : NSTimeInterval?
    var durationInSeconds : NSTimeInterval?
    var selectedDays: Set<Int> = []
    var note : String?
    
    
    private static let dayNames = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
    
    
    /*
    private enum Repeat {
        case Never, Daily, Weekly, Monthly, Yearly
        func title() -> String {
            switch self {
            case Never: return "Never"
            case Daily: return "Daily"
            case Weekly: return "Weekly"
            case Monthly: return "Monthly"
            case Yearly: return "Yearly"
            }
        }
        static func values() -> [Repeat] {
            return [Daily, Weekly, Monthly, Yearly]
        }
    }
    
    private enum Alert {
        case None, AtTime, Five, Thirty, Hour, Day, Week
        func title() -> String {
            switch self {
            case None: return "None"
            case AtTime: return "At time of event"
            case Five: return "5 minutes before"
            case Thirty: return "30 minutes before"
            case Hour: return "1 hour before"
            case Day: return "1 day before"
            case Week: return "1 week before"
            }
        }
        static func values() -> [Alert] {
            return [AtTime, Five, Thirty, Hour, Day, Week]
        }
    }
    */
    
    private func configure() {
        //title = "Add Event"
        tableView.contentInset.top = 22
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
        
        /*let allDayRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = "All-day"
            $0.titleLabel.textColor = UIColor.blackColor()
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            $0.switchButton.onTintColor = UIColor.blackColor()
            }.onSwitchChanged { on in
                startRow.update {
                    $0.displayTextFromDate(
                        on ? String.mediumDateNoTime : String.mediumDateShortTime
                    )
                }
                startRow.inlineCellUpdate {
                    $0.datePicker.datePickerMode = on ? .Date : .DateAndTime
                }
                endRow.update {
                    $0.displayTextFromDate(
                        on ? String.mediumDateNoTime : String.mediumDateShortTime
                    )
                }
                endRow.inlineCellUpdate {
                    $0.datePicker.datePickerMode = on ? .Date : .DateAndTime
                }
        }*/
        
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
        
        /*let repeatRow = InlinePickerRowFormer<FormInlinePickerCell, Repeat>() {
            $0.titleLabel.text = "Repeat"
            $0.titleLabel.textColor = UIColor.blackColor()
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            $0.displayLabel.textColor = UIColor.blackColor()
            $0.displayLabel.font = .systemFontOfSize(15)
            }.configure {
                let never = Repeat.Never
                $0.pickerItems.append(
                    InlinePickerItem(title: never.title(),
                        displayTitle: NSAttributedString(string: never.title(),
                            attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()]),
                        value: never)
                )
                $0.pickerItems += Repeat.values().map {
                    InlinePickerItem(title: $0.title(), value: $0)
                }
        }
        
        let alertRow = InlinePickerRowFormer<FormInlinePickerCell, Alert>() {
            $0.titleLabel.text = "Alert"
            $0.titleLabel.textColor = UIColor.blackColor()
            $0.titleLabel.font = .boldSystemFontOfSize(15)
            $0.displayLabel.textColor = UIColor.blackColor()
            $0.displayLabel.font = .systemFontOfSize(15)
            }.configure {
                let none = Alert.None
                $0.pickerItems.append(
                    InlinePickerItem(title: none.title(),
                        displayTitle: NSAttributedString(string: none.title(),
                            attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()]),
                        value: none)
                )
                $0.pickerItems += Alert.values().map {
                    InlinePickerItem(title: $0.title(), value: $0)
                }
        }*/
        
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






class RepeatedEventViewController: UITableViewController, UITextFieldDelegate {
    
    class SegmentedCell: UITableViewCell {
        
        typealias SegmentedControlBlock = (UISegmentedControl) -> Void
        
        var segmentedControl: UISegmentedControl!
        
        var segmentSelectedHandler: SegmentedControlBlock?
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setup()
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setup()
        }
        
        private func setup() {
            selectionStyle = .None
        }
        
        func configureSegmentControlWithItems(items: [String], customizations: SegmentedControlBlock? = nil) {
            segmentedControl = UISegmentedControl(items: items)
            segmentedControl.addTarget(self, action: "segmentSelected:", forControlEvents: .ValueChanged)
            customizations?(segmentedControl)
            accessoryView = segmentedControl
        }
        
        func segmentSelected(sender: UISegmentedControl) {
            segmentSelectedHandler?(sender)
        }
    }
    
    private let titles = ["Type", "Title", "Time", "Time"]
    
    private var selectedDays: Set<Int> = []
    private static let dayNames = ["M", "Tu", "W", "Th", "F", "Sa", "Su"]
    
    private var selectedEvent: EventType = .Meal
    
    
    //private var eventManager: EventPickerManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigationItem.title = "Detail"
        tableView.registerClass(SegmentedCell.self, forCellReuseIdentifier: "segmentedCell")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 15.0
        }
        return 30.0
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return titles.count
        case 1:
            return 1
        case 2:
            return 3
        case 3:
            return 1
        default:
            return 0
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell : UITableViewCell = UITableViewCell()
        
        switch indexPath.section {
        case 0:
            break
        case 1:
            if indexPath.row == 0 {
                let field = FormTextFieldCell()
                field.translatesAutoresizingMaskIntoConstraints = false
                //field.FormTextFieldCell()?.placeholder = "Title"
                field.formTextField().placeholder = "Title"
                cell.contentView.addSubview(field)
                
                let fieldConstraints : [NSLayoutConstraint] = [
                    field.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    field.bottomAnchor.constraintEqualToAnchor(cell.contentView.bottomAnchor),
                    field.leadingAnchor.constraintEqualToAnchor(cell.contentView.leadingAnchor, constant: -7.5),
                    field.trailingAnchor.constraintEqualToAnchor(cell.contentView.trailingAnchor)
                ]
                
                cell.contentView.addConstraints(fieldConstraints)
                
                return cell
            }
        case 2:
            switch indexPath.row {
            case 0:
                
                //cell = tableView.dequeueReusableCellWithIdentifier(cellID)! as UITableViewCell
                
                //cell.textLabel?.text = "Start"
                //cell.accessoryType = .DisclosureIndicator
                return cell
            case 1:
                cell.textLabel?.text = "End"
                //cell.accessoryType = .DisclosureIndicator
                return cell
            case 2:
                cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
                cell.textLabel?.text = "Frequency"
                cell.accessoryType = .DisclosureIndicator
                cell.detailTextLabel?.text = "test"
                //cell.detailTextLabel?.text = selectedDays.sort().map { self.dynamicType.dayNames[$0] }.joinWithSeparator(", ")
                cell.detailTextLabel?.textColor = UIColor.blackColor()
                cell.detailTextLabel?.text = selectedDays.sort().map { self.dynamicType.dayNames[$0] }.joinWithSeparator(", ")
                return cell
            default:
                break
            }
            break
        case 3:
            break
        default:
            break
        }
        
        /////
        /////
        
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                // Event type
                let cell = tableView.dequeueReusableCellWithIdentifier("segmentedCell", forIndexPath: indexPath) as! SegmentedCell
                //cell.textLabel?.text = titles[indexPath.row]
                cell.configureSegmentControlWithItems(["Meal", "Sleep", "Exercise"]) {
                    $0.selectedSegmentIndex = 0
                }
                cell.segmentSelectedHandler = { [unowned self] sender in
                    let index = sender.selectedSegmentIndex
                    switch index {
                    case 0:
                        self.selectedEvent = .Meal
                    case 1:
                        self.selectedEvent = .Sleep
                    case 2:
                        self.selectedEvent = .Exercise
                    default:
                        break
                    }
                }
                return cell
            case 1:
                var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("nameCell")
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: "nameCell")
                }
                cell.accessoryView = {
                    let textField = UITextField(frame: CGRectMake(0, 0, 200, 40))
                    textField.delegate = self
                    textField.textAlignment = .Right
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    textField.placeholder = "Enter the name of event"
                    return textField
                }()
                cell.selectionStyle = .None
                cell.textLabel?.text = "Name"
                return cell
            case 2:
                var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("nextLevelCell")
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: "nextLevelCell")
                }
                cell.textLabel?.text = titles[indexPath.row]
                cell.accessoryType = .DisclosureIndicator
                cell.detailTextLabel?.text = selectedDays.sort().map { self.dynamicType.dayNames[$0] }.joinWithSeparator(", ")
                return cell
            case 3:
                var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("timePickerCell")
                if cell == nil {
                    cell = UITableViewCell(style: .Default, reuseIdentifier: "timePickerCell")
                }
                cell.accessoryView = {
                    let textField = UITextField(frame: CGRectMake(0, 0, 0, 0))
                    textField.textAlignment = .Right
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    return textField
                }()
                cell.textLabel?.text = "Time"
                return cell
            default:
                break
            }
            
        }
        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        switch indexPath.section {
        case 0:
            break
        case 1:
            break
        case 2:
            switch indexPath.row {
            case 0:
                break
                //self.displayInlineDatePickerForRowAtIndexPath(indexPath)
            case 1:
                break
                //self.displayInlineDatePickerForRowAtIndexPath(indexPath)
            case 2:
                print("select")
                let selectDays = DaySelectionViewController()
                selectDays.selectedIndices = selectedDays
                selectDays.selectionUpdateHandler = { [unowned self] days in
                    self.selectedDays = days
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 2)], withRowAnimation: .None)
                }
                self.presentViewController(selectDays, animated: true, completion: nil)
                //UINavigationController(rootViewController: self).pushViewController(selectDays, animated: true)
            default:
                break
            }
        case 3:
            break
        default:
            break
        }
        
        ////
        ////
        
        //let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if indexPath.section == 0 {
            switch indexPath.row {
            case 2:
                let daySelectionVC = DaySelectionViewController()
                daySelectionVC.selectedIndices = selectedDays
                daySelectionVC.selectionUpdateHandler = { [unowned self] days in
                    self.selectedDays = days
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .None)
                }
                navigationController?.pushViewController(daySelectionVC, animated: true)
            case 3:
                let textField = cell!.accessoryView as! UITextField
                //eventManager = EventPickerManager(event: selectedEvent)
                //textField.inputView = eventManager.pickerView
                textField.becomeFirstResponder()
            default:
                break
            }
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Text field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
