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
import MCCircadianQueries

let EventPickerPressDuration = 0.2
public let MEMDidUpdateCircadianEvents = "MEMDidUpdateCircadianEvents"

public protocol ManageEventMenuDelegate: class {
    func manageEventMenu(menu: ManageEventMenu, didSelectIndex idx: Int)
    func manageEventMenuDidFinishAnimationClose(menu: ManageEventMenu)
    func manageEventMenuDidFinishAnimationOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateClose(menu: ManageEventMenu)
}

protocol PickerManagerSelectionDelegate {
    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) -> Void
}

class PickerManager: NSObject, AKPickerViewDelegate, AKPickerViewDataSource, UIGestureRecognizerDelegate {
    var delegate: PickerManagerSelectionDelegate! = nil
    var selectionProcessing: Bool = false

    var itemType: String?

    var items: [String]
    var data : [String:AnyObject]
    var current: Int

    var labels: [UILabel!]

    override init() {
        self.itemType = nil
        self.items = []
        self.data = [:]
        self.current = -1
        self.labels = []
    }

    init(itemType: String? = nil, items: [String], data: [String:AnyObject]) {
        self.itemType = itemType
        self.items = items
        self.data = data
        self.current = -1
        self.labels = [UILabel!](count: self.items.count, repeatedValue: nil)
    }

    func refreshData(itemType: String? = nil, items: [String], data: [String:AnyObject]) {
        self.itemType = itemType
        self.items = items
        self.data = data
        self.current = -1
        self.labels = [UILabel!](count: self.items.count, repeatedValue: nil)
    }

    // MARK: - AKPickerViewDataSource
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return self.data.count
    }

    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        return self.items[item]
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        current = item

        for index in (0..<items.count) {
            if labels[index] != nil {
                if item == index { continue }
                else {
                    labels[index].superview?.layer.borderWidth = 0.0
                    labels[index].userInteractionEnabled = false
                }
            }
        }

        Async.main(after: 0.2) {
            self.labels[item].tag = item
            self.labels[item].superview?.layer.borderWidth = 2.0
            if !self.selectionProcessing {
                self.labels[item].userInteractionEnabled = true
            }
        }
    }

    func pickerView(pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int) {
        if labels[item] == nil || labels[item] != label {
            labels[item] = label
            labels[item].tag = item
            labels[item].superview?.layer.borderColor = UIColor.ht_carrotColor().CGColor
            labels[item].superview?.layer.cornerRadius = 8
            labels[item].superview?.layer.masksToBounds = true

            labels[item].userInteractionEnabled = true
            let press = UILongPressGestureRecognizer(target: self, action: #selector(itemSelected(_:)))
            press.minimumPressDuration = EventPickerPressDuration
            press.delegate = self
            labels[item].addGestureRecognizer(press)
        }

    }

    func startProcessingSelection(selected: Int) {
        log.info("Processing selection \(selected)")
        if let delegate = delegate {
            if selected == current {
                // Disable all recognizers and mark the selection as processing to prevent further interaction.
                log.info("Processing selection \(selected) disabling and invoking delegate")
                selectionProcessing = true
                labels.forEach {
                    if let lbl = $0 {
                        lbl.userInteractionEnabled = false
                        lbl.gestureRecognizers?.forEach { g in g.enabled = false }
                    }
                }
                delegate.pickerItemSelected(self, itemType: itemType, index: selected, item: getSelectedItem(), data: getSelectedValue())
            }
        }
    }

    func finishProcessingSelection() {
        selectionProcessing = false
        labels.enumerate().forEach {
            if let lbl = $0.1 {
                lbl.gestureRecognizers?.forEach { g in g.enabled = true }
                if $0.0 == current { lbl.userInteractionEnabled = true }
            }
        }
    }

    func itemSelected(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            if let index = sender.view?.tag {
                labels[index].superview?.layer.borderColor = UIColor.ht_jayColor().CGColor
            }
        }
        if sender.state == .Ended {
            if let index = sender.view?.tag {
                labels[index].superview?.layer.borderColor = UIColor.ht_carrotColor().CGColor
                startProcessingSelection(index)
            }
        }
    }

    func getSelectedItem() -> String { return current < 0 && items.count > 0 ? items[0] : "" }
    func getSelectedValue() -> AnyObject? { return current < 0 && items.count > 0 ? data[items[0]] : data[items[current]] }
}

/// AKPickerViews as Former cells/rows.
public class AKPickerCell: FormCell, AKPickerFormableRow {

    private var imageview: UIImageView! = nil
    private var picker: AKPickerView! = nil
    private var manager: PickerManager! = nil

    public override func updateWithRowFormer(rowFormer: RowFormer) {
        super.updateWithRowFormer(rowFormer)
    }

    public override func setup() {
        selectionStyle = .None

        imageview = UIImageView(frame: CGRect.zero)
        imageview.contentMode = .ScaleAspectFit

        manager = PickerManager()

        // Delete Recent picker.
        picker = AKPickerView()
        picker.delegate = manager
        picker.dataSource = manager
        picker.interitemSpacing = 50

        let pickerFont = UIFont(name: "GothamBook", size: 18.0)!
        picker.font = pickerFont
        picker.highlightedFont = pickerFont

        picker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        picker.highlightedTextColor = UIColor.whiteColor()
        picker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        picker.reloadData()

        imageview.translatesAutoresizingMaskIntoConstraints = false
        picker.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageview)
        contentView.addSubview(picker)

        let pickerConstraints : [NSLayoutConstraint] = [
            contentView.topAnchor.constraintEqualToAnchor(imageview.topAnchor),
            contentView.bottomAnchor.constraintEqualToAnchor(imageview.bottomAnchor),
            contentView.topAnchor.constraintEqualToAnchor(picker.topAnchor),
            contentView.bottomAnchor.constraintEqualToAnchor(picker.bottomAnchor),
            contentView.leadingAnchor.constraintEqualToAnchor(imageview.leadingAnchor, constant: -20),
            contentView.trailingAnchor.constraintEqualToAnchor(picker.trailingAnchor, constant: 20),
            picker.leadingAnchor.constraintEqualToAnchor(imageview.trailingAnchor)
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

public protocol SlideButtonArrayDelegate {
    func layoutDefault() -> Void
}

public class SlideButtonArray: UIView, SlideButtonArrayDelegate {

    public var buttonsTagBase: Int
    public var arrayRowIndex: Int
    public var activeButtonIndex: Int

    public var exclusiveArrays: [SlideButtonArrayDelegate!] = []

    var buttons: [UIButton] = []
    var pickers: [AKPickerView] = []
    var managers: [PickerManager] = []

    var delegate: PickerManagerSelectionDelegate! = nil {
        didSet {
            self.managers.forEach { $0.delegate = delegate }
        }
    }

    var firstLayout = true
    var buttonLeadingConstraints: [NSLayoutConstraint] = []
    var pickerLeadingConstraints: [NSLayoutConstraint] = []

    public init(frame: CGRect, buttonsTag: Int, arrayRowIndex: Int) {
        self.buttonsTagBase = buttonsTag
        self.arrayRowIndex = arrayRowIndex
        self.activeButtonIndex = -1
        super.init(frame: frame)
        setupButtonArray()
    }

    required public init?(coder aDecoder: NSCoder) {
        buttonsTagBase = aDecoder.decodeIntegerForKey("buttonsTagBase")
        arrayRowIndex = aDecoder.decodeIntegerForKey("arrayRowIndex")
        activeButtonIndex = aDecoder.decodeIntegerForKey("activeButtonIndex")
        super.init(coder: aDecoder)
    }

    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(buttonsTagBase, forKey: "buttonsTagBase")
        aCoder.encodeInteger(arrayRowIndex, forKey: "arrayRowIndex")
        aCoder.encodeInteger(activeButtonIndex, forKey: "activeButtonIndex")
    }

    private func setupButtonArray() {
        var buttonSpecs: [(String, String, [(String, Double)])] = []

        if arrayRowIndex == 0 {
            let mealPickerData : [(String, Double)] =
                [5, 10, 15, 20, 30, 45, 60, 75, 90, 120].map { ("\(Int($0)) m", $0) }

            buttonSpecs = [
                ("Breakfast", "icon-breakfast-quick", mealPickerData),
                ("Lunch", "icon-lunch-quick", mealPickerData),
                ("Dinner", "icon-dinner-quick", mealPickerData),
                ("Snack", "icon-snack-quick", mealPickerData)
            ]
        } else {
            let exercisePickerData : [(String, Double)] =
                [5, 10, 15, 20, 30, 45, 60, 75, 90, 120].map { ("\(Int($0)) m", $0)}

            let sleepPickerData : [(String, Double)] = (1...30).map { i in
                let h = Double(i) / 2
                let s = String(format: i >= 20 ? "%.3g" : "%.2g", h)
                return ("\(s) h", h)
            }

            buttonSpecs = [
                ("Running", "icon-running-quick", exercisePickerData),
                ("Exercise", "icon-exercises-quick", exercisePickerData),
                ("Cycling", "icon-cycling-quick", exercisePickerData),
                ("Sleep", "icon-sleep-quick", sleepPickerData)
            ]
        }

        let screenSize = UIScreen.mainScreen().bounds.size

        buttonSpecs.enumerate().forEach { (index, spec) in
            let button = UIButton(frame: CGRectMake(0, 0, 60, 60))
            button.tag = self.buttonsTagBase + index
            button.backgroundColor = .clearColor()

            button.setImage(UIImage(named: spec.1), forState: .Normal)
            button.imageView?.contentMode = .ScaleAspectFit

            button.setTitle(spec.0, forState: .Normal)
            button.setTitleColor(UIColor.ht_midnightBlueColor(), forState: .Normal)
            button.titleLabel?.contentMode = .Center
            button.titleLabel?.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightBold)

            let imageSize: CGSize = button.imageView!.image!.size
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -((screenSize.height < 569 ? 0.62 : 0.7) * imageSize.height), 0.0)

            /*
            let labelString = NSString(string: button.titleLabel!.text!)
            let titleSize = labelString.sizeWithAttributes([NSFontAttributeName: button.titleLabel!.font])
            button.imageEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, -titleSize.width)
            */

            button.addTarget(self, action: #selector(self.handleTap(_:)), forControlEvents: .TouchUpInside)

            var pickerData: [String: AnyObject] = [:]
            spec.2.forEach { pickerData[$0.0] = $0.1 }
            let manager = PickerManager(itemType: spec.0, items: spec.2.map { $0.0 }, data: pickerData)
            manager.delegate = delegate

            let picker = AKPickerView()
            picker.delegate = manager
            picker.dataSource = manager
            picker.interitemSpacing = 50

            let pickerFont = UIFont(name: "GothamBook", size: 18.0)!
            picker.font = pickerFont
            picker.highlightedFont = pickerFont

            picker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
            picker.highlightedTextColor = UIColor.whiteColor()
            picker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
            picker.reloadData()

            buttons.append(button)
            managers.append(manager)
            pickers.append(picker)
        }

        initializeLayout()
    }

    func initializeLayout() {
        let numButtons = buttons.count
        activeButtonIndex = -1

        buttons.enumerate().forEach { (index, button) in
            let picker = self.pickers[index]
            picker.layer.opacity = 0.0

            button.translatesAutoresizingMaskIntoConstraints = false
            picker.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            addSubview(picker)

            var constraints: [NSLayoutConstraint] = [
                button.topAnchor.constraintEqualToAnchor(topAnchor),
                button.heightAnchor.constraintEqualToAnchor(heightAnchor),
                button.leadingAnchor.constraintEqualToAnchor(index == 0 ? leadingAnchor : buttons[index-1].trailingAnchor, constant: 5.0),
                button.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 1.0 / CGFloat(numButtons), constant: -5),
                picker.topAnchor.constraintEqualToAnchor(button.topAnchor),
                picker.heightAnchor.constraintEqualToAnchor(heightAnchor),
                picker.leadingAnchor.constraintEqualToAnchor(button.trailingAnchor, constant: -3000),
                picker.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: (CGFloat(numButtons) - 1.0) / CGFloat(numButtons), constant: 0.0)
            ]

            buttonLeadingConstraints.append(constraints[2])
            pickerLeadingConstraints.append(constraints[6])

            addConstraints(constraints)
        }

        self.layoutIfNeeded()
    }

    func fixLayout() {
        let numButtons = buttons.count
        removeConstraints(buttonLeadingConstraints)
        buttonLeadingConstraints.removeAll()

        buttons.enumerate().forEach { (index, button) in
            let o = 5 + (CGFloat(index) * self.frame.width) / CGFloat(numButtons)
            let c = button.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: o)
            self.addConstraint(c)
            buttonLeadingConstraints.append(c)
        }
        self.layoutIfNeeded()
    }

    public func layoutDefault() {
        let numButtons = buttons.count
        let prevActiveButtonIndex = activeButtonIndex
        activeButtonIndex = -1

        if firstLayout {
            firstLayout = false
            fixLayout()
        }

        buttonLeadingConstraints.enumerate().forEach { (index, constraint) in
            constraint.constant = 5 + ( (CGFloat(index) * self.frame.width) / CGFloat(numButtons) )
        }

        pickerLeadingConstraints.forEach { $0.constant = -3000.0 }

        UIView.animateWithDuration(0.4, animations: {
            self.buttons.forEach { $0.layer.opacity = 1.0 }
            if prevActiveButtonIndex >= 0 {
                self.pickers[prevActiveButtonIndex].layer.opacity = 0.0
            }
            self.layoutIfNeeded()
        })
    }

    func layoutFocused(buttonTag: Int) {
        let index = buttonTag - self.buttonsTagBase
        let numButtons = buttons.count

        if firstLayout {
            firstLayout = false
            fixLayout()
        }

        if 0 <= index && index < numButtons {
            activeButtonIndex = index

            buttonLeadingConstraints.enumerate().forEach { (index, constraint) in
                if index == activeButtonIndex {
                    // Set the constraint's offset relative to the button's original anchor.
                    constraint.constant = 5.0
                } else {
                    // Move all other buttons offscreen.
                    constraint.constant += self.frame.width * (CGFloat(numButtons+1) / CGFloat(numButtons))
                }
            }

            pickerLeadingConstraints[activeButtonIndex].constant = 0.0

            UIView.animateWithDuration(0.4, animations: {
                self.buttons.enumerate().forEach { if $0.0 != self.activeButtonIndex { $0.1.layer.opacity = 0.0 } }
                self.pickers[self.activeButtonIndex].layer.opacity = 1.0
                self.layoutIfNeeded()
            })
        }

        exclusiveArrays.forEach { array in
            if array != nil { array.layoutDefault() }
        }
    }

    func handleTap(sender: UIButton) {
        if activeButtonIndex >= 0 {
            layoutDefault()
        } else {
            layoutFocused(sender.tag)
        }
    }

    func getSelection() -> (PickerManager, String?, Int, String, AnyObject?)? {
        if activeButtonIndex >= 0 {
            let m = managers[activeButtonIndex]
            return (m, m.itemType, m.current, m.getSelectedItem(), m.getSelectedValue())
        }
        return nil
    }

}

public class AddManager: UITableView, UITableViewDelegate, UITableViewDataSource, PickerManagerSelectionDelegate {

    public var menuItems: [PathMenuItem]

    private var quickAddButtons: [SlideButtonArray] = []

    private let addSectionTitles = ["Quick Add Activity", "Detailed Activity"]

    private let addEventCellIdentifier = "addEventCell"
    private let addEventSectionHeaderCellIdentifier = "addEventSectionHeaderCell"

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
        self.allowsSelection = false
        self.separatorStyle = .None
        self.layer.opacity = 0.0

        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventCellIdentifier)
        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventSectionHeaderCellIdentifier)

        self.delegate = self;
        self.dataSource = self;

        self.estimatedRowHeight = 100.0
        self.estimatedSectionHeaderHeight = 66.0
        self.rowHeight = UITableViewAutomaticDimension
        self.sectionHeaderHeight = UITableViewAutomaticDimension

        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
        self.cellLayoutMarginsFollowReadableWidth = false

        quickAddButtons.append(SlideButtonArray(frame: CGRect.zero, buttonsTag: 3000, arrayRowIndex: 0))
        quickAddButtons.append(SlideButtonArray(frame: CGRect.zero, buttonsTag: 4000, arrayRowIndex: 1))

        // Configure delegates.
        quickAddButtons[0].delegate = self
        quickAddButtons[1].delegate = self

        // Configure exclusive selection.
        quickAddButtons[0].exclusiveArrays.append(quickAddButtons[1])
        quickAddButtons[1].exclusiveArrays.append(quickAddButtons[0])
    }

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return addSectionTitles.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else {
            return 1
        }
    }

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return addSectionTitles[section]
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

        if indexPath.section == 0  {
            let v = quickAddButtons[indexPath.row]
            v.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(v)

            let constraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(v.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(v.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(v.leadingAnchor, constant: -10),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(v.trailingAnchor, constant: 10)
            ]

            cell.contentView.addConstraints(constraints)
        }
        else {
            let stackView: UIStackView = UIStackView(arrangedSubviews: self.menuItems ?? [])
            stackView.axis = .Horizontal
            stackView.distribution = UIStackViewDistribution.FillEqually
            stackView.alignment = UIStackViewAlignment.Fill
            stackView.spacing = 0

            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            let stackConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(stackView.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(stackView.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(stackView.leadingAnchor),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(stackView.trailingAnchor)
            ]

            cell.contentView.addConstraints(stackConstraints)
        }
        return cell
    }

    //MARK: UITableViewDelegate
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(addEventSectionHeaderCellIdentifier)!

        cell.textLabel?.text = self.addSectionTitles[section]
        cell.textLabel?.font = UIFont(name: "GothamBook", size: 18.0)
        cell.textLabel?.textColor = .lightGrayColor()
        cell.textLabel?.numberOfLines = 0

        if section == 0 {
            let button = UIButton(frame: CGRectMake(0, 0, 44, 44))
            button.backgroundColor = .clearColor()

            button.setImage(UIImage(named: "icon-quick-add-tick"), forState: .Normal)
            button.imageView?.contentMode = .ScaleAspectFit

            button.addTarget(self, action: #selector(self.handleQuickAddTap(_:)), forControlEvents: .TouchUpInside)

            button.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(button)

            let buttonConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(button.topAnchor, constant: -20),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(button.bottomAnchor, constant: 10),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor, constant: 20),
                button.widthAnchor.constraintEqualToConstant(44),
                button.heightAnchor.constraintEqualToConstant(44)
            ]

            cell.contentView.addConstraints(buttonConstraints)
        }

        return cell;
    }

    func circadianOpCompletion(sender: UIButton?, manager: PickerManager?, displayError: Bool, error: NSError?) -> Void {
        Async.main {
            if error == nil {
                UINotifications.genericSuccessMsgOnView(self.notificationView ?? self.superview!, msg: "Successfully added events.")
            }
            else {
                let msg = displayError ? (error?.localizedDescription ?? "Unknown error") : "Failed to add event"
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: msg)
            }
            if let sender = sender {
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
        manager?.finishProcessingSelection()
        if error != nil { log.error(error) }
        else {
            NSNotificationCenter.defaultCenter().postNotificationName(MEMDidUpdateCircadianEvents, object: nil)
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
        MCHealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
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

    func addSleep(hoursSinceStart: Double, completion: NSError? -> Void) {
        let endTime = NSDate()
        let startTime = (Int(hoursSinceStart * 60)).minutes.ago

        log.info("Saving sleep event: \(startTime) \(endTime)")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.saveSleep(startTime, endDate: endTime, metadata: [:]) {
                (success, error) -> Void in
                if error != nil { log.error(error) }
                else { log.info("Saved sleep event: \(startTime) \(endTime)") }
                completion(error)
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

            MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
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

            MCHealthManager.sharedManager.saveWorkout(
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

    func processSelection(sender: UIButton?, pickerManager: PickerManager,
                          itemType: String?, index: Int, item: String, data: AnyObject?)
    {
        if let itemType = itemType, let duration = data as? Double {
            var asSleep = false
            var workoutType : HKWorkoutActivityType? = nil
            var mealType: String? = nil

            switch itemType {
            case "Breakfast", "Lunch", "Dinner", "Snack":
                mealType = itemType

            case "Running":
                workoutType = .Running

            case "Cycling":
                workoutType = .Cycling

            case "Exercise":
                workoutType = .Other

            case "Sleep":
                asSleep = true

            default:
                break
            }

            if asSleep {
                addSleep(duration) {
                    self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
                }
            }
            else if let mt = mealType {
                let minutesSinceStart = Int(duration)
                addMeal(mt, minutesSinceStart: minutesSinceStart) {
                    self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
                }
            }
            else if let wt = workoutType {
                let minutesSinceStart = Int(duration)
                addExercise(wt, minutesSinceStart: minutesSinceStart) {
                    self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
                }
            }
            else {
                let msg = "Unknown quick add event type \(itemType)"
                let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
                circadianOpCompletion(sender, manager: pickerManager, displayError: true, error: err)
            }
        } else {
            let msg = itemType == nil ?
                "Unknown quick add event type \(itemType)" : "Failed to convert duration into integer: \(data)"

            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
            circadianOpCompletion(sender, manager: pickerManager, displayError: true, error: err)
        }
    }

    func handleQuickAddTap(sender: UIButton) {
        log.info("Quick add button pressed")

        Async.main {
            sender.enabled = false
            sender.setNeedsDisplay()
        }

        let selection = quickAddButtons.reduce(nil, combine: { (acc, buttonArray) in
            return acc != nil ? acc : buttonArray.getSelection()
        })

        if let s = selection {
            processSelection(sender, pickerManager: s.0, itemType: s.1, index: s.2, item: s.3, data: s.4)
        }
        else {
            Async.main {
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: "No event selected")
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
    }

    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
        log.info("Quick add picker selected \(itemType) \(item) \(data)")
        processSelection(nil, pickerManager: pickerManager, itemType: itemType, index: index, item: item, data: data)
    }
    
}

public class DeleteManager: UITableView, PickerManagerSelectionDelegate {

    private lazy var delFormer: Former = Former(tableView: self)

    private let buttonsTag: Int = 5000

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

    private var delRecentImage: UIImageView! = nil
    private var delRecentManager: PickerManager! = nil
    private var delDates: [NSDate] = []

    //private var byDateStartButton: MCButton! = nil
    //private var byDateEndButton: MCButton! = nil

    private let delPickerSections = ["Delete Recent Activities", "Delete Activities By Date"]

    private var notificationView: UIView! = nil

    public init(frame: CGRect, style: UITableViewStyle, notificationView: UIView!) {
        self.notificationView = notificationView
        super.init(frame: frame, style: style)
        self.setupFormer()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setupFormer() {
        self.hidden = true
        self.separatorStyle = .None

        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
        self.cellLayoutMarginsFollowReadableWidth = false

        /*
        let deleteButton: (Int, String, String) -> MCButton = { (index, title, icon) in
            let button = MCButton(frame: CGRectMake(0, 0, 200, 80), buttonStyle: .Rounded)
            button.tag = self.buttonsTag + index

            button.buttonColor = UIColor.ht_peterRiverColor()
            button.shadowColor = UIColor.ht_belizeHoleColor()
            button.shadowHeight = 6

            button.setImage(UIImage(named: icon), forState: .Normal)
            button.imageView?.contentMode = .Center

            button.setTitle(title, forState: .Normal)
            button.setTitleColor(UIColor.ht_midnightBlueColor(), forState: .Normal)
            button.titleLabel?.contentMode = .Center
            button.titleLabel?.font = UIFont(name: "GothamBook", size: 18.0)

            let spacing: CGFloat = 20.0
            let imageSize: CGSize = button.imageView!.image!.size
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(imageSize.height + spacing), 0.0)

            let labelString = NSString(string: button.titleLabel!.text!)
            let titleSize = labelString.sizeWithAttributes([NSFontAttributeName: button.titleLabel!.font])
            button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width)

            return button
        }

        byDateStartButton = deleteButton(0, "Start Date", "icon-start-period")
        byDateStartButton.addTarget(self, action: #selector(self.handleStartTap(_:)), forControlEvents: .TouchUpInside)

        byDateEndButton = deleteButton(1, "End Date", "icon-finish-period")
        byDateEndButton.addTarget(self, action: #selector(self.handleEndTap(_:)), forControlEvents: .TouchUpInside)
        */


        let datePickerFontSize: CGFloat = 16.0

        let mediumDateShortTime: NSDate -> String = { date in
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = .currentLocale()
            dateFormatter.timeStyle = .ShortStyle
            dateFormatter.dateStyle = .MediumStyle
            return dateFormatter.stringFromDate(date)
        }

        let deleteRecentRow = AKPickerRowFormer<AKPickerCell>() {
            $0.backgroundColor = .clearColor()
            $0.manager.refreshData(items: self.quickDelRecentItems, data: self.quickDelRecentData)
            $0.manager.delegate = self
            $0.picker.reloadData()
            $0.imageview.image = UIImage(named: "icon-delete-quick")
            self.delRecentImage = $0.imageview
            self.delRecentManager = $0.manager
            }.configure {
                $0.rowHeight = UITableViewAutomaticDimension
        }

        var endDate = NSDate()
        endDate = endDate.add(minutes: 15 - (endDate.minute % 15))
        delDates = [endDate - 15.minutes, endDate]

        let deleteByDateRows = ["Start Date", "End Date"].enumerate().map { (index, rowName) in
            return InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
                $0.backgroundColor = .clearColor()
                $0.titleLabel.text = rowName
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: datePickerFontSize)!
                $0.displayLabel.textColor = .lightGrayColor()
                $0.displayLabel.font = UIFont(name: "GothamBook", size: datePickerFontSize)!
                }.inlineCellSetup {
                    $0.datePicker.datePickerMode = .DateAndTime
                    $0.datePicker.minuteInterval = 15
                    $0.datePicker.date = self.delDates[index]
                }.configure {
                    $0.displayEditingColor = .whiteColor()
                    $0.date = self.delDates[index]
                }.displayTextFromDate(mediumDateShortTime)
        }

        deleteByDateRows[0].onDateChanged { self.delDates[0] = $0 }
        deleteByDateRows[1].onDateChanged { self.delDates[1] = $0 }

        let headers = delPickerSections.map { sectionName in
            return LabelViewFormer<FormLabelHeaderView> {
                $0.contentView.backgroundColor = .clearColor()
                $0.titleLabel.backgroundColor = .clearColor()
                $0.titleLabel.textColor = .lightGrayColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: 18.0)!

                let button: MCButton = {
                    let button = MCButton(frame: CGRectMake(0, 0, 66, 66), buttonStyle: .Rounded)
                    button.buttonColor = .clearColor()
                    button.shadowColor = .clearColor()
                    button.shadowHeight = 0

                    button.setImage(UIImage(named: "icon-trash"), forState: .Normal)
                    button.imageView?.contentMode = .ScaleAspectFit

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
                    $0.contentView.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor, constant: 10),
                    button.widthAnchor.constraintEqualToConstant(66),
                    button.heightAnchor.constraintEqualToConstant(66),
                    $0.titleLabel.heightAnchor.constraintEqualToAnchor(button.heightAnchor)
                ]

                $0.contentView.addConstraints(buttonConstraints)

                }.configure { view in
                    view.viewHeight = 66
                    view.text = sectionName
            }
        }

        let deleteRecentSection = SectionFormer(rowFormer: deleteRecentRow).set(headerViewFormer: headers[0])
        let deleteByDateSection = SectionFormer(rowFormers: deleteByDateRows).set(headerViewFormer: headers[1])
        delFormer.append(sectionFormer: deleteRecentSection, deleteByDateSection)
    }

    func circadianOpCompletion(sender: UIButton?, pickerManager: PickerManager?, error: NSError?) {
        pickerManager?.finishProcessingSelection()
        if error != nil { log.error(error) }
        else {
            Async.main {
                UINotifications.genericSuccessMsgOnView(self.notificationView ?? self.superview!, msg: "Successfully deleted events.")
                if let sender = sender {
                    sender.enabled = true
                    sender.setNeedsDisplay()
                }
            }
            NSNotificationCenter.defaultCenter().postNotificationName(MEMDidUpdateCircadianEvents, object: nil)
        }
    }

    func handleQuickDelRecentTap(sender: UIButton)  {
        log.info("Delete recent tapped")
        if let mins = delRecentManager.getSelectedValue() as? Int {
            let endDate = NSDate()
            let startDate = endDate.dateByAddingTimeInterval(-(Double(mins) * 60.0))
            log.info("Delete circadian events between \(startDate) \(endDate)")
            Async.main { sender.enabled = false; sender.setNeedsDisplay() }
            MCHealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate) {
                self.circadianOpCompletion(sender, pickerManager: nil, error: $0)
            }
        }
    }

    func handleQuickDelDateTap(sender: UIButton) {
        let startDate = delDates[0]
        let endDate = delDates[1]
        if startDate < endDate {
            log.info("Delete circadian events between \(startDate) \(endDate)")
            Async.main { sender.enabled = false; sender.setNeedsDisplay() }
            MCHealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate) {
                self.circadianOpCompletion(sender, pickerManager: nil, error: $0)
            }
        } else {
            UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: "Start date must be before the end date")
        }
    }

    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
        log.info("Delete recent picker selected \(item) \(data)")
        if let mins = data as? Int {
            let endDate = NSDate()
            let startDate = endDate.dateByAddingTimeInterval(-(Double(mins) * 60.0))
            log.info("Delete circadian events between \(startDate) \(endDate)")

            if let rootVC = UIApplication.sharedApplication().delegate?.window??.rootViewController {
                var interval = "\(mins) minutes"
                if mins == 60 { interval = "1 hour" }
                else if mins % 60 == 0 { interval = "\(mins/60) hours" }

                let msg = "Are you sure you wish to delete all events in the last \(interval)?"
                let alertController = UIAlertController(title: "", message: msg, preferredStyle: .Alert)

                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alertAction: UIAlertAction!) in
                    rootVC.dismissViewControllerAnimated(true, completion: nil)
                    pickerManager.finishProcessingSelection()
                }

                let okAction = UIAlertAction(title: "OK", style: .Default) { (alertAction: UIAlertAction!) in
                    rootVC.dismissViewControllerAnimated(true, completion: nil)
                    MCHealthManager.sharedManager.deleteCircadianEvents(startDate, endDate: endDate) {
                        self.circadianOpCompletion(nil, pickerManager: pickerManager, error: $0)
                    }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                rootVC.presentViewController(alertController, animated: true, completion: nil)
            }
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
    

    //MARK: Quick add event.
    public var addView: AddManager! = nil

    //MARK: Quick delete event.
    public var delView: DeleteManager! = nil

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
        self.segmenter = UISegmentedControl(items: ["Add Activity", "Delete Activity"])
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

        // self.addTableView = AddEventTable(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)
        // self.delTableView = DeleteEventTable(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)

        self.addView = AddManager(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)
        self.delView = DeleteManager(frame: CGRect.zero, style: .Grouped, notificationView: self.segmenter)
    }

    public func getCurrentManagerView() -> UIView? {
        if segmenter.selectedSegmentIndex == 0 {
            return addView
        } else {
            return delView
        }
    }

    public func getOtherManagerView() -> UIView? {
        if segmenter.selectedSegmentIndex == 0 {
            return delView
        } else {
            return addView
        }
    }

    public func hideView(hide: Bool = false) {
        self.segmenter.hidden = hide
        refreshHiddenFromSegmenter(hide)
    }

    public func refreshHiddenFromSegmenter(hide: Bool = false) {
        getCurrentManagerView()?.hidden = hide
        getOtherManagerView()?.hidden = true
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

        getCurrentManagerView()?.layer.addAnimation(animationgroup, forKey: "Expand")
        getCurrentManagerView()?.layer.opacity = 1.0

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

        getCurrentManagerView()?.layer.addAnimation(animationgroup, forKey: "Close")
        getCurrentManagerView()?.layer.opacity = 0.0

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

    func removeManagersFromSuperview() {
        for sv in subviews {
            if let _ = sv as? AddManager {
                sv.removeFromSuperview()
            }
            else if let _ = sv as? DeleteManager {
                sv.removeFromSuperview()
            }
        }
    }

    public func updateViewFromSegmenter() {
        removeManagersFromSuperview()

        if let manager = getCurrentManagerView() {
            manager.backgroundColor = .clearColor()
            manager.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(manager, belowSubview: startButton!)

            let screenSize = UIScreen.mainScreen().bounds.size
            let topAnchorOffset: CGFloat = screenSize.height < 569 ? 0.0: 20.0

            let managerConstraints: [NSLayoutConstraint] = [
                manager.topAnchor.constraintEqualToAnchor(segmenter.bottomAnchor, constant: topAnchorOffset),
                manager.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
                manager.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
                manager.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
            ]
            self.addConstraints(managerConstraints)
        }
    }
}

