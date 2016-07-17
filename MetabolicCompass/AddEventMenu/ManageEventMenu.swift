//
//  ManageEventMenu.swift
//  Derived from PathMenu/PathMenu.swift
//
//  PathMenu Copyright:
//  Created by pixyzehn on 12/27/14.
//  Copyright (c) 2014 pixyzehn. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import MetabolicCompassKit
import Async
import SwiftDate
import Former
import HTPressableButton
import AKPickerView_Swift

public let MEMDidUpdateCircadianEvents = "MEMDidUpdateCircadianEvents"

public protocol ManageEventMenuDelegate: class {
    func manageEventMenu(menu: ManageEventMenu, didSelectIndex idx: Int)
    func manageEventMenuDidFinishAnimationClose(menu: ManageEventMenu)
    func manageEventMenuDidFinishAnimationOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateClose(menu: ManageEventMenu)
}

class PickerManager: NSObject, AKPickerViewDelegate, AKPickerViewDataSource {
    var items: [String]
    var data : [String:AnyObject]
    var current : String

    override init() {
        self.items = []
        self.data = [:]
        self.current = ""
    }

    init(items: [String], data: [String:AnyObject]) {
        self.items = items
        self.data = data
        self.current = ""
    }

    func refreshData(items: [String], data: [String:AnyObject]) {
        self.items = items
        self.data = data
    }

    // MARK: - AKPickerViewDataSource
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return self.data.count
    }

    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        return self.items[item]
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        current = self.items[item]
    }

    func getSelectedItem() -> String { return current.isEmpty && items.count > 0 ? items[0] : current }
    func getSelectedValue() -> AnyObject? { return current.isEmpty && items.count > 0 ? data[items[0]] : data[current] }
}

// Wrapper class that stores the meal type and duration.
// This prevents any synchronization issues on adding events, since we do not need to look up
// in another modifiable data structure when handling button presses.
class FavoritesButton : MCButton {
    var mealType : String = ""
    var duration : Int = 0

    init(frame: CGRect, buttonStyle: HTPressableButtonStyle, mealType: String, duration: Int) {
        self.mealType = mealType
        self.duration = duration
        super.init(frame: frame, buttonStyle: buttonStyle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let mt = aDecoder.decodeObjectForKey("mealType") as? String else { return nil }
        guard let dr = aDecoder.decodeObjectForKey("duration") as? Int    else { return nil }
        mealType = mt
        duration = dr
        super.init(coder: aDecoder)
    }

    func initEmpty() { mealType = ""; duration = 0 }

    override func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(mealType, forKey: "mealType")
        aCoder.encodeObject(duration, forKey: "duration")
        super.encodeWithCoder(aCoder)
    }
}

/// AKPickerViews as Former cells/rows.
public class AKPickerCell: FormCell, AKPickerFormableRow {
    private var picker: AKPickerView! = nil
    private var manager: PickerManager! = nil

    public override func updateWithRowFormer(rowFormer: RowFormer) {
        super.updateWithRowFormer(rowFormer)
    }

    public override func setup() {
        manager = PickerManager()

        // Delete Recent picker.
        picker = AKPickerView()
        picker.delegate = manager
        picker.dataSource = manager
        picker.interitemSpacing = 50

        let pickerFont = UIFont.systemFontOfSize(16.0)
        picker.font = pickerFont
        picker.highlightedFont = pickerFont

        picker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        picker.highlightedTextColor = UIColor.whiteColor()
        picker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        picker.reloadData()

        picker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(picker)

        let pickerConstraints : [NSLayoutConstraint] = [
            contentView.topAnchor.constraintEqualToAnchor(picker.topAnchor),
            contentView.bottomAnchor.constraintEqualToAnchor(picker.bottomAnchor),
            contentView.leadingAnchor.constraintEqualToAnchor(picker.leadingAnchor),
            contentView.trailingAnchor.constraintEqualToAnchor(picker.trailingAnchor),
            picker.heightAnchor.constraintEqualToConstant(40.0)
        ]

        contentView.addConstraints(pickerConstraints)
    }

    public func formPicker() -> AKPickerView? {
        return picker
    }
}

public protocol AKPickerFormableRow {
    func formPicker() -> AKPickerView?
}

public class AKPickerRowFormer<T: UITableViewCell where T: AKPickerFormableRow> : BaseRowFormer<T>, Formable {
    public required init(instantiateType: Former.InstantiateType = .Class, cellSetup: (T -> Void)? = nil) {
        super.init(instantiateType: instantiateType, cellSetup: cellSetup)
    }

    public override func update() {
        super.update()
    }
}

// A UITableView subclass to implement circadian event addition
public class AddEventTable: UITableView, UITableViewDelegate, UITableViewDataSource
{
    //MARK: tags for menu components.
    public let favoritesTag = 1000
    public let itemsTag = 2000

    public var menuItems: [PathMenuItem]

    private let addEventCellIdentifier = "addEventCell"
    private let addEventSectionHeaderCellIdentifier = "addEventSectionHeaderCell"

    private let addPickerSections = ["1-Tap Favorites", "Quick Add Event", "Detailed Event"]

    private var addFavoritesData : [(String, Int)] = []
    private var addFavoritesButtons : [UIStackView] = []

    private let quickAddSectionData = [
        ["Breakfast", "Lunch", "Dinner", "Snack", "Running", "Cycling", "Exercise"]
        , ["5", "10", "15", "20", "30", "45", "60", "75", "90", "120"]
    ]

    private var quickAddPickers: [AKPickerView] = []
    private var quickAddManagers: [PickerManager] = []
    private var quickAddHeaderViews : [UIView] = []

    private var notificationView: UIView! = nil

    public init(frame: CGRect, style: UITableViewStyle, menuItems: [PathMenuItem], notificationView: UIView!) {
        self.menuItems = menuItems
        self.notificationView = notificationView
        super.init(frame: frame, style: style)
        self.setupTable()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        guard let mi = aDecoder.decodeObjectForKey("menuItems") as? [PathMenuItem] else {
            menuItems = []; super.init(frame: CGRect.zero, style: .Grouped); return nil
        }

        menuItems = mi
        super.init(coder: aDecoder)
    }

    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(menuItems, forKey: "menuItems")
    }

    private func setupTable() {
        self.hidden = true
        self.layer.opacity = 0.0

        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventCellIdentifier)
        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventSectionHeaderCellIdentifier)

        self.delegate = self;
        self.dataSource = self;

        self.estimatedRowHeight = 80.0
        self.estimatedSectionHeaderHeight = 40.0
        self.rowHeight = UITableViewAutomaticDimension
        self.sectionHeaderHeight = UITableViewAutomaticDimension

        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
        if #available(iOS 9, *) {
            self.cellLayoutMarginsFollowReadableWidth = false
        }

        self.setupFavorites()

        quickAddManagers = quickAddSectionData.enumerate().flatMap { (index,_) in
            if index > 1 { return nil }
            var data: [String: AnyObject] = [:]
            quickAddSectionData[index].forEach { data[$0] = $0 }
            return PickerManager(items: quickAddSectionData[index], data: data)
        }

        quickAddPickers = quickAddSectionData.enumerate().flatMap { (index, _) in
            if index > 1 { return nil }

            let picker = AKPickerView()
            picker.delegate = quickAddManagers[index]
            picker.dataSource = quickAddManagers[index]
            picker.interitemSpacing = 50

            let pickerFont = UIFont.systemFontOfSize(16.0)
            picker.font = pickerFont
            picker.highlightedFont = pickerFont

            picker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
            picker.highlightedTextColor = UIColor.whiteColor()
            picker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
            picker.reloadData()
            return picker
        }

        quickAddHeaderViews.append({
            let label = UILabel()
            label.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)
            label.textColor = .whiteColor()
            label.textAlignment = .Center
            label.text = addPickerSections[1]
            return label
            }())

        quickAddHeaderViews.append({
            let button = MCButton(frame: CGRectMake(0, 0, 100, 44), buttonStyle: .Rounded)
            button.buttonColor = .clearColor()
            button.shadowColor = .clearColor()
            button.shadowHeight = 0
            button.setTitle("Add", forState: .Normal)
            button.setTitleColor(.whiteColor(), forState: .Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
            button.titleLabel?.textAlignment = .Right
            button.addTarget(self, action: #selector(handleQuickAddTap(_:)), forControlEvents: .TouchUpInside)
            return button
        }())
    }

    func setupFavorites() {
        let hour = NSDate().nearestHour
        if 3 <= hour && hour < 11 {
            // Breakfast and early lunch
            self.addFavoritesData = [("Breakfast", 15), ("Breakfast", 30), ("Breakfast", 60), ("Lunch", 30), ("Lunch", 60)]
        }

        if 11 <= hour && hour < 18 {
            // Lunch and early dinner
            self.addFavoritesData = [("Lunch", 15), ("Lunch", 30), ("Lunch", 60), ("Dinner", 30), ("Dinner", 60)]
        }

        if 18 <= hour || hour < 3 {
            // Dinner
            self.addFavoritesData = [("Dinner", 15), ("Dinner", 30), ("Dinner", 45), ("Dinner", 60), ("Dinner", 90)]
        }

        self.addFavoritesButtons = self.addFavoritesData.enumerate().flatMap { (index, buttonSpec) in
            let favButton: UIButton = {
                let button = FavoritesButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular, mealType: buttonSpec.0, duration: buttonSpec.1)
                button.tag = self.favoritesTag + index
                button.buttonColor = .whiteColor()
                button.shadowColor = .lightGrayColor()
                button.shadowHeight = 6
                button.setTitle("\(buttonSpec.1)", forState: .Normal)
                button.setTitleColor(.redColor(), forState: .Normal)
                button.addTarget(self, action: #selector(self.handleFavoritesTap(_:)), forControlEvents: .TouchUpInside)
                return button
            }()

            let favLabel : UILabel = {
                let label = UILabel()
                label.font = UIFont.systemFontOfSize(10, weight: UIFontWeightRegular)
                label.textColor = .whiteColor()
                label.textAlignment = .Center
                label.text = buttonSpec.0
                return label
            }()

            let stack: UIStackView = {
                let stack = UIStackView(arrangedSubviews: [favButton, favLabel])
                stack.axis = .Vertical
                stack.distribution = UIStackViewDistribution.FillProportionally
                stack.alignment = UIStackViewAlignment.Fill
                return stack
            }()

            return stack
        }
    }

    func circadianOpCompletion(sender: UIButton) -> (NSError? -> Void) {
        return { error in
            Async.main {
                if error == nil { UINotifications.genericSuccessMsgOnView(self.notificationView ?? self.superview!, msg: "Successfully added events.") }
                sender.enabled = true
                sender.setNeedsDisplay()
            }
            if error != nil { log.error(error) }
            else { NSNotificationCenter.defaultCenter().postNotificationName(MEMDidUpdateCircadianEvents, object: nil) }
        }
    }

    func validateTimedEvent(startTime: NSDate, endTime: NSDate, completion: NSError? -> Void) {
        // Fetch all sleep and workout data since yesterday.
        let (yesterday, now) = (1.days.ago, NSDate())
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(yesterday, endDate: now, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Aggregate sleep, exercise and meal events.
        HealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { log.error(error); return }
            let overlaps = samples.reduce(false, combine: { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, combine: { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })

            if !overlaps { completion(nil) }
            else {
                let msg = "This event overlaps with another, please try again"
                let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: msg)
                completion(err)
            }
        }
    }

    func addMeal(mealType: String, minutesSinceStart: Int, completion: NSError? -> Void) {
        let endTime = NSDate()
        let startTime = minutesSinceStart.minutes.ago
        let metadata = ["Meal Type": mealType]

        log.info("Saving meal event: \(mealType) \(startTime) \(endTime)")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            HealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                kiloCalories: 0.0, metadata: metadata)
            {
                (success, error) -> Void in
                if error != nil { log.error(error) }
                else { log.info("Saved meal event as workout type: \(mealType) \(startTime) \(endTime)") }
                completion(error)
            }
        }
    }

    func addExercise(workoutType: HKWorkoutActivityType, minutesSinceStart: Int, completion: NSError? -> Void) {
        let endTime = NSDate()
        let startTime = minutesSinceStart.minutes.ago

        log.info("Saving exercise event: \(workoutType) \(startTime) \(endTime)")

        log.info("Exercise event \(startTime) \(endTime)")
        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            HealthManager.sharedManager.saveWorkout(
                startTime, endDate: endTime, activityType: workoutType,
                distance: 0.0, distanceUnit: HKUnit(fromString: "km"), kiloCalories: 0.0, metadata: [:])
            {
                (success, error ) -> Void in
                if error != nil { log.error(error) }
                else { log.info("Saved exercise event as workout type: \(workoutType) \(startTime) \(endTime)") }
                completion(error)
            }
        }
    }

    func handleFavoritesTap(sender: UIButton) {
        if let fButton = sender as? FavoritesButton {
            sender.enabled = false
            addMeal(fButton.mealType, minutesSinceStart: fButton.duration, completion: circadianOpCompletion(sender))
        } else {
            log.error("Invalid sender for handleFavoritesTap (expected a FavoritesButton)")
        }
    }

    func handleQuickAddTap(sender: UIButton) {
        var workoutType : HKWorkoutActivityType? = nil
        var mealType: String? = nil

        Async.main {
            sender.enabled = false
        }

        let quickAddType = quickAddManagers[0].getSelectedItem()
        let quickAddDuration = quickAddManagers[1].getSelectedItem()

        switch quickAddType {
        case "Breakfast":
            fallthrough
        case "Lunch":
            fallthrough
        case "Dinner":
            fallthrough
        case "Snack":
            mealType = quickAddType

        case "Running":
            workoutType = .Running
        case "Cycling":
            workoutType = .Cycling
        case "Exercise":
            workoutType = .Other

        default:
            break
        }

        if let mt = mealType {
            if let minutesSinceStart = Int(quickAddDuration) {
                addMeal(mt, minutesSinceStart: minutesSinceStart, completion: circadianOpCompletion(sender))
            } else {
                sender.enabled = true
                log.error("Failed to convert duration into integer: \(quickAddDuration)")
            }
        }
        else if let wt = workoutType {
            if let minutesSinceStart = Int(quickAddDuration) {
                addExercise(wt, minutesSinceStart: minutesSinceStart, completion: circadianOpCompletion(sender))
            } else {
                Async.main {
                    sender.enabled = true
                    sender.setNeedsDisplay()
                    log.error("Failed to convert duration into integer: \(quickAddDuration)")
                }
            }
        }
        else {
            Async.main {
                let msg = "Unknown quick add event type \(quickAddType)"
                log.error(msg)
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: msg)
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
    }

    //MARK: UITableViewDataSource

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return addPickerSections.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return quickAddSectionData.count
        } else {
            return 1
        }
    }

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return addPickerSections[section]
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(addEventCellIdentifier, forIndexPath: indexPath)

        for sv in cell.contentView.subviews { sv.removeFromSuperview() }
        cell.textLabel?.hidden = true
        cell.imageView?.image = nil
        cell.accessoryType = .None
        cell.selectionStyle = .None

        cell.backgroundColor = UIColor.clearColor()
        cell.contentView.backgroundColor = UIColor.clearColor()

        if indexPath.section == 0 || indexPath.section == 2 {
            if indexPath.section == 0 {
                setupFavorites()
            }

            let stackView: UIStackView = UIStackView(arrangedSubviews: indexPath.section == 0 ? self.addFavoritesButtons : (self.menuItems ?? []))
            stackView.axis = .Horizontal
            stackView.distribution = UIStackViewDistribution.FillEqually
            stackView.alignment = UIStackViewAlignment.Fill
            stackView.spacing = 10

            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            var stackConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(stackView.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(stackView.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(stackView.leadingAnchor),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(stackView.trailingAnchor)
            ]

            if indexPath.section == 0 {
                self.addFavoritesButtons.forEach { stack in
                    let button = stack.arrangedSubviews[0]
                    let label = stack.arrangedSubviews[1]
                    stackConstraints.appendContentsOf([
                        button.heightAnchor.constraintEqualToAnchor(button.widthAnchor),
                        label.widthAnchor.constraintEqualToAnchor(button.widthAnchor),
                        label.topAnchor.constraintEqualToAnchor(button.bottomAnchor),
                        label.heightAnchor.constraintEqualToConstant(15),
                        stack.topAnchor.constraintEqualToAnchor(button.topAnchor),
                        stack.bottomAnchor.constraintEqualToAnchor(label.bottomAnchor),
                        stack.leadingAnchor.constraintEqualToAnchor(button.leadingAnchor),
                        stack.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor)
                        ])
                }
            }
            cell.contentView.addConstraints(stackConstraints)
        }
        else if indexPath.section == 1 {
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero

            let picker = quickAddPickers[indexPath.row]
            picker.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(picker)

            let pickerConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(picker.topAnchor),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(picker.bottomAnchor),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(picker.leadingAnchor),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(picker.trailingAnchor),
                picker.heightAnchor.constraintEqualToConstant(40.0)
            ]

            cell.contentView.addConstraints(pickerConstraints)
        }

        return cell
    }

    //MARK: UITableViewDelegate
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(addEventSectionHeaderCellIdentifier)!

        if section == 1 {
            for sv in cell.contentView.subviews { sv.removeFromSuperview() }
            cell.textLabel?.text = self.addPickerSections[section]
            cell.textLabel?.textColor = .whiteColor()

            cell.imageView?.image = nil
            cell.accessoryType = .None
            cell.selectionStyle = .None

            cell.backgroundColor = UIColor.clearColor()
            cell.contentView.backgroundColor = UIColor.clearColor()

            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero

            let button = self.quickAddHeaderViews[1]
            button.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(button)

            let buttonConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(button.topAnchor),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(button.bottomAnchor),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor),
                button.widthAnchor.constraintEqualToConstant(100),
                button.heightAnchor.constraintEqualToConstant(44)
            ]

            cell.contentView.addConstraints(buttonConstraints)

        } else {
            cell.textLabel?.text = self.addPickerSections[section]
            cell.textLabel?.textColor = .whiteColor()
        }
        return cell;
    }
}

// A UITableView subclass to implement circadian event deletion
// This is implemented as a Former-based form
public class DeleteEventTable: UITableView
{
    public var menuItems: [PathMenuItem]
    private lazy var delFormer: Former = Former(tableView: self)

    private let delPickerSections = ["Delete All Recent Events", "Delete Events By Date"]

    private let quickDelRecentItems = [
        "15m",
        "30m",
        "1h",
        "1h 30m",
        "2h",
        "3h",
        "4h",
        "6h",
        "8h",
        "12h",
        "18h",
        "24h"
    ]

    private let quickDelRecentData = [
        "15m"    : 15,
        "30m"    : 30,
        "1h"     : 60,
        "1h 30m" : 90,
        "2h"     : 120,
        "3h"     : 180,
        "4h"     : 240,
        "6h"     : 360,
        "8h"     : 480,
        "12h"    : 720,
        "18h"    : 1080,
        "24h"    : 1440
    ]

    private var quickDelRecentManager: PickerManager! = nil
    private var quickDelDates: [NSDate] = []

    private var notificationView: UIView! = nil

    public init(frame: CGRect, style: UITableViewStyle, menuItems: [PathMenuItem], notificationView: UIView!) {
        self.menuItems = menuItems
        self.notificationView = notificationView
        super.init(frame: frame, style: style)
        self.setupFormer()
    }

    required public init?(coder aDecoder: NSCoder) {
        guard let mi = aDecoder.decodeObjectForKey("menuItems") as? [PathMenuItem] else {
            menuItems = []; super.init(frame: CGRect.zero, style: .Grouped); return nil
        }

        menuItems = mi
        super.init(coder: aDecoder)
    }

    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(menuItems, forKey: "menuItems")
    }

    private func setupFormer() {
        self.hidden = true

        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero

        let mediumDateShortTime: NSDate -> String = { date in
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = .currentLocale()
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.dateStyle = .MediumStyle
            return dateFormatter.stringFromDate(date)
        }

        let deleteRecentRow = AKPickerRowFormer<AKPickerCell>() {
                $0.backgroundColor = .clearColor()
                $0.manager.refreshData(self.quickDelRecentItems, data: self.quickDelRecentData)
                $0.picker.reloadData()
                self.quickDelRecentManager = $0.manager
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }

        var endDate = NSDate()
        endDate = endDate.add(minutes: 15 - (endDate.minute % 15))
        quickDelDates = [endDate - 15.minutes, endDate]

        let deleteByDateRows = ["Start Date", "End Date"].enumerate().map { (index, rowName) in
            return InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
                $0.backgroundColor = .clearColor()
                $0.titleLabel.text = rowName
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
                $0.displayLabel.textColor = .lightGrayColor()
                $0.displayLabel.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
                }.inlineCellSetup {
                    $0.datePicker.datePickerMode = .DateAndTime
                    $0.datePicker.minuteInterval = 15
                    $0.datePicker.date = self.quickDelDates[index]
                }.configure {
                    $0.displayEditingColor = .whiteColor()
                    $0.date = self.quickDelDates[index]
                }.displayTextFromDate(mediumDateShortTime)
        }

        deleteByDateRows[0].onDateChanged { self.quickDelDates[0] = $0 }
        deleteByDateRows[1].onDateChanged { self.quickDelDates[1] = $0 }

        let headers = delPickerSections.map { sectionName in
            return LabelViewFormer<FormLabelHeaderView> {
                $0.contentView.backgroundColor = .clearColor()
                $0.titleLabel.backgroundColor = .clearColor()
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)

                let button: MCButton = {
                    let button = MCButton(frame: CGRectMake(0, 0, 100, 44), buttonStyle: .Rounded)
                    button.buttonColor = .clearColor()
                    button.shadowColor = .clearColor()
                    button.shadowHeight = 0
                    button.setTitle("Delete", forState: .Normal)
                    button.setTitleColor(.whiteColor(), forState: .Normal)
                    button.titleLabel?.font = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
                    button.titleLabel?.textAlignment = .Right
                    if sectionName == self.delPickerSections[0] {
                        button.addTarget(self, action: #selector(self.handleQuickDelRecentTap(_:)), forControlEvents: .TouchUpInside)

                    } else {
                        button.addTarget(self, action: #selector(self.handleQuickDelDateTap(_:)), forControlEvents: .TouchUpInside)
                    }
                    return button
                }()

                button.translatesAutoresizingMaskIntoConstraints = false
                $0.contentView.addSubview(button)

                let buttonConstraints : [NSLayoutConstraint] = [
                    $0.contentView.topAnchor.constraintEqualToAnchor(button.topAnchor),
                    $0.contentView.bottomAnchor.constraintEqualToAnchor(button.bottomAnchor),
                    $0.contentView.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor),
                    button.widthAnchor.constraintEqualToConstant(100),
                    button.heightAnchor.constraintEqualToConstant(44)
                ]

                $0.contentView.addConstraints(buttonConstraints)

                }.configure { view in
                    view.viewHeight = 44
                    view.text = sectionName
            }
        }

        let deleteRecentSection = SectionFormer(rowFormer: deleteRecentRow).set(headerViewFormer: headers[0])
        let deleteByDateSection = SectionFormer(rowFormers: deleteByDateRows).set(headerViewFormer: headers[1])
        delFormer.append(sectionFormer: deleteRecentSection, deleteByDateSection)

    }

    func circadianOpCompletion(error: NSError?) {
        if error != nil { log.error(error) }
        else {
            Async.main { UINotifications.genericSuccessMsgOnView(self.notificationView ?? self.superview!, msg: "Successfully deleted events.") }
            NSNotificationCenter.defaultCenter().postNotificationName(MEMDidUpdateCircadianEvents, object: nil)
        }
    }

    func handleQuickDelRecentTap(sender: UIButton) {
        log.info("Delete recent tapped")
        if let mins = quickDelRecentManager.getSelectedValue() as? Int {
            let endDate = NSDate()
            let startDate = endDate.dateByAddingTimeInterval(-(Double(mins) * 60.0))
            log.info("Delete circadian events between \(startDate) \(endDate)")
            HealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate, completion: self.circadianOpCompletion)
        }
    }

    func handleQuickDelDateTap(sender: UIButton) {
        let startDate = quickDelDates[0]
        let endDate = quickDelDates[1]
        if startDate < endDate {
            log.info("Delete circadian events between \(startDate) \(endDate)")
            HealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate, completion: self.circadianOpCompletion)
        } else {
            UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: "Start date must be before the end date")
        }
    }
}

public class ManageEventMenu: UIView, PathMenuItemDelegate {

    //MARK: Internal typdefs
    struct Duration {
        static var DefaultAnimation: CGFloat      = 0.5
        static var MenuDefaultAnimation: CGFloat  = 0.2
    }

    public enum State {
        case Close
        case Expand
    }

    //MARK: tags for menu components.
    public let favoritesTag = 1000
    public let itemsTag = 2000

    public var menuItems: [PathMenuItem] = []

    public var startButton: PathMenuItem?
    public weak var delegate: ManageEventMenuDelegate?

    public var flag: Int?
    public var timer: NSTimer?

    public var timeOffset: CGFloat!

    public var animationDuration: CGFloat!
    public var startMenuAnimationDuration: CGFloat!

    public var motionState: State?

    public var startPoint: CGPoint = CGPointZero {
        didSet {
            startButton?.center = startPoint
        }
    }

    //MARK: Image

    public var image: UIImage? {
        didSet {
            startButton?.image = image
        }
    }

    public var highlightedImage: UIImage? {
        didSet {
            startButton?.highlightedImage = highlightedImage
        }
    }

    public var contentImage: UIImage? {
        didSet {
            startButton?.contentImageView?.image = contentImage
        }
    }

    public var highlightedContentImage: UIImage? {
        didSet {
            startButton?.contentImageView?.highlightedImage = highlightedContentImage
        }
    }
    

    //MARK: Quick add event table.
    public var addTableView: AddEventTable! = nil

    //MARK: Quick delete event table.
    public var delTableView: DeleteEventTable! = nil

    //MARK: Segmented control for add/delete interation
    var segmenter: UISegmentedControl! = nil

    //MARK: Initializers
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience public init(frame: CGRect!, startItem: PathMenuItem?, items:[PathMenuItem]?) {
        self.init(frame: frame)

        self.menuItems = items ?? []
        self.menuItems.enumerate().forEach { (index, item) in
            item.tag = itemsTag + index
        }

        self.timeOffset = 0.036
        self.animationDuration = Duration.DefaultAnimation
        self.startMenuAnimationDuration = Duration.MenuDefaultAnimation
        self.startPoint = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/2)
        self.motionState = .Close
        
        self.startButton = startItem
        self.startButton!.delegate = self
        self.startButton!.center = startPoint
        self.addSubview(startButton!)

        let attrs = [NSFontAttributeName: UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)]
        self.segmenter = UISegmentedControl(items: ["Add event", "Delete events"])
        self.segmenter.selectedSegmentIndex = 0
        self.segmenter.setTitleTextAttributes(attrs, forState: .Normal)
        self.segmenter.addTarget(self, action: #selector(segmentChanged(_:)), forControlEvents: .ValueChanged)

        self.segmenter.hidden = true
        self.segmenter.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(segmenter)

        let segConstraints : [NSLayoutConstraint] = [
            segmenter.topAnchor.constraintEqualToAnchor(topAnchor, constant: 60.0),
            segmenter.heightAnchor.constraintEqualToConstant(30.0),
            segmenter.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: 20.0),
            segmenter.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -20.0)
        ]

        self.addConstraints(segConstraints)

        self.addTableView = AddEventTable(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)
        self.delTableView = DeleteEventTable(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)
    }

    public func getCurrentTable() -> UITableView? {
        if segmenter.selectedSegmentIndex == 0 {
            return addTableView
        } else {
            return delTableView
        }
    }

    public func getOtherTable() -> UITableView! {
        if segmenter.selectedSegmentIndex == 0 {
            return delTableView
        } else {
            return addTableView
        }
    }

    public func hideView(hide: Bool = false) {
        self.segmenter.hidden = hide
        refreshHiddenFromSegmenter(hide)
    }

    public func refreshHiddenFromSegmenter(hide: Bool = false) {
        getCurrentTable()?.hidden = hide
        getOtherTable()?.hidden = true
    }

    func segmentChanged(sender: UISegmentedControl) {
        Async.main {
            self.refreshHiddenFromSegmenter()
            self.updateViewFromSegmenter()
        }
    }

    //MARK: UIView's methods

    override public func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if motionState == .Expand { return true }
        return CGRectContainsPoint(startButton!.frame, point)
    }

    override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let animId = anim.valueForKey("id") {
            if animId.isEqual("lastAnimation") {
                delegate?.manageEventMenuDidFinishAnimationClose(self)
            }
            if animId.isEqual("firstAnimation") {
                delegate?.manageEventMenuDidFinishAnimationOpen(self)
            }
        }
    }

    //MARK: UIGestureRecognizer
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        handleTap()
    }
    
    //MARK: PathMenuItemDelegate
    
    public func pathMenuItemTouchesBegin(item: PathMenuItem) {
        if item == startButton { handleTap() }
    }
    
    public func pathMenuItemTouchesEnd(item:PathMenuItem) {
        if item == startButton { return }

        motionState = .Close
        delegate?.manageEventMenuWillAnimateClose(self)
        
        let angle = motionState == .Expand ? CGFloat(M_PI_4) + CGFloat(M_PI) : 0.0
        UIView.animateWithDuration(Double(startMenuAnimationDuration!), animations: { [weak self] () -> Void in
            self?.startButton?.transform = CGAffineTransformMakeRotation(angle)
        })
        
        delegate?.manageEventMenu(self, didSelectIndex: item.tag - itemsTag)
    }
    
    //MARK: Animation, Position
    
    public func handleTap() {
        let state = motionState!

        let selector: Selector
        let angle: CGFloat
        
        switch state {
        case .Close:
            setMenu()
            delegate?.manageEventMenuWillAnimateOpen(self)
            selector = #selector(expand)
            flag = 0
            motionState = .Expand
            angle = CGFloat(M_PI_4) + CGFloat(M_PI)
        case .Expand:
            delegate?.manageEventMenuWillAnimateClose(self)
            selector = #selector(close)
            flag = 10
            motionState = .Close
            angle = 0
        }
        
        UIView.animateWithDuration(Double(startMenuAnimationDuration!), animations: { [weak self] () -> Void in
            self?.startButton?.transform = CGAffineTransformMakeRotation(angle)
        })
        
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(Double(timeOffset!), target: self, selector: selector, userInfo: nil, repeats: true)
            if let timer = timer {
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            }
        }
    }
    
    public func expand() {
        if flag == 11 {
            timer?.invalidate()
            timer = nil
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(float: 0.0)
        opacityAnimation.toValue = NSNumber(float: 1.0)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))
        scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1, 1, 1))

        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations     = [opacityAnimation, scaleAnimation]
        animationgroup.duration       = CFTimeInterval(animationDuration!)
        animationgroup.fillMode       = kCAFillModeForwards
        animationgroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animationgroup.delegate = self

        if flag == 10 {
            animationgroup.setValue("firstAnimation", forKey: "id")
        }

        getCurrentTable()?.layer.addAnimation(animationgroup, forKey: "Expand")
        getCurrentTable()?.layer.opacity = 1.0

        flag! += 1
    }
    
    public func close() {
        if flag! == -1 {
            timer?.invalidate()
            timer = nil
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(float: 1.0)
        opacityAnimation.toValue = NSNumber(float: 0.0)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(1, 1, 1))
        scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))

        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations     = [opacityAnimation, scaleAnimation]
        animationgroup.duration       = CFTimeInterval(animationDuration!)
        animationgroup.fillMode       = kCAFillModeForwards
        animationgroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animationgroup.delegate = self

        if flag == 0 {
            animationgroup.setValue("lastAnimation", forKey: "id")
        }

        getCurrentTable()?.layer.addAnimation(animationgroup, forKey: "Close")
        getCurrentTable()?.layer.opacity = 0.0

        flag! -= 1
    }
    
    public func setMenu() {
        for (index, menuItem) in menuItems.enumerate() {
            let item = menuItem
            item.tag = itemsTag + index
            item.delegate = self
        }
        updateViewFromSegmenter()
    }

    func removeTablesFromSuperview() {
        for sv in subviews {
            if let _ = sv as? AddEventTable {
                sv.removeFromSuperview()
            }
            else if let _ = sv as? DeleteEventTable {
                sv.removeFromSuperview()
            }
        }
    }

    public func updateViewFromSegmenter() {
        removeTablesFromSuperview()

        if let table = getCurrentTable() {
            table.backgroundColor = .clearColor()
            table.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(table, belowSubview: startButton!)

            let tableConstraints: [NSLayoutConstraint] = [
                table.topAnchor.constraintEqualToAnchor(segmenter.bottomAnchor),
                table.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
                table.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
                table.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
            ]
            self.addConstraints(tableConstraints)
        }
    }
}

