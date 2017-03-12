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
import Former
import HTPressableButton
import AKPickerView_Swift

public protocol ManageEventMenuDelegate: class {
    func manageEventMenu(menu: ManageEventMenu, didSelectIndex idx: Int)
    func manageEventMenuDidFinishAnimationClose(menu: ManageEventMenu)
    func manageEventMenuDidFinishAnimationOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateOpen(menu: ManageEventMenu)
    func manageEventMenuWillAnimateClose(menu: ManageEventMenu)
}

class PickerManager: NSObject, AKPickerViewDelegate, AKPickerViewDataSource {
    var data : [String]
    var current : String

    init(data: [String]) {
        self.data = data
        self.current = ""
    }

    // MARK: - AKPickerViewDataSource

    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return self.data.count
    }

    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        return self.data[item]
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        current = self.data[item]
    }

    func getSelectedItem() -> String { return current }
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

public class ManageEventMenu: UIView, PathMenuItemDelegate, UITableViewDelegate, UITableViewDataSource {

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
    public let tableView: UITableView = UITableView(frame: CGRect.zero, style: .Grouped)

    private let addEventCellIdentifier = "addEventCell"
    private let addEventSectionHeaderCellIdentifier = "addEventSectionHeaderCell"

    private let pickerSections = ["1-Tap Favorites", "Quick Add Event", "Detailed Event"]

    private var favoritesData : [(String, Int)] = []
    private var favoritesButtons : [UIStackView] = []

    private let quickAddSectionData = [
          ["Breakfast", "Lunch", "Dinner", "Snack", "Running", "Cycling", "Exercise"]
        , ["5", "10", "15", "20", "30", "45", "60", "75", "90", "120"]
    ]

    private var quickAddPickers: [AKPickerView] = []
    private var quickAddManagers: [PickerManager] = []
    private var quickAddHeaderViews : [UIView] = []

    struct Duration {
        static var DefaultAnimation: CGFloat      = 0.5
        static var MenuDefaultAnimation: CGFloat  = 0.2
    }

    public enum State {
        case Close
        case Expand
    }
        
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

        self.setupQuickAdd()
    }

    private func setupQuickAdd() {
        tableView.hidden = true
        tableView.layer.opacity = 0.0

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventCellIdentifier)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventSectionHeaderCellIdentifier)

        tableView.delegate = self;
        tableView.dataSource = self;

        tableView.estimatedRowHeight = 80.0
        tableView.estimatedSectionHeaderHeight = 40.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        if #available(iOS 9, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        self.setupFavorites()

        quickAddManagers = quickAddSectionData.enumerate().flatMap { (index,_) in
            return index > 1 ? nil : PickerManager(data: quickAddSectionData[index])
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
            label.text = pickerSections[1]
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
            self.favoritesData = [("Breakfast", 15), ("Breakfast", 30), ("Breakfast", 60), ("Lunch", 30), ("Lunch", 60)]
        }

        if 11 <= hour && hour < 18 {
            // Lunch and early dinner
            self.favoritesData = [("Lunch", 15), ("Lunch", 30), ("Lunch", 60), ("Dinner", 30), ("Dinner", 60)]
        }

        if 18 <= hour || hour < 3 {
            // Dinner
            self.favoritesData = [("Dinner", 15), ("Dinner", 30), ("Dinner", 45), ("Dinner", 60), ("Dinner", 90)]
        }

        self.favoritesButtons = self.favoritesData.enumerate().flatMap { (index, buttonSpec) in
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
                UINotifications.genericErrorOnView(self, msg: msg)
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
            addMeal(fButton.mealType, minutesSinceStart: fButton.duration) { _ in
                Async.main {
                    log.info("Renabling sender after meal")
                    sender.enabled = true
                    sender.setNeedsDisplay()
                }
            }
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
                addMeal(mt, minutesSinceStart: minutesSinceStart) { _ in
                    Async.main {
                        log.info("Renabling sender after meal")
                        sender.enabled = true
                        sender.setNeedsDisplay()
                    }
                }
            } else {
                sender.enabled = true
                log.error("Failed to convert duration into integer: \(quickAddDuration)")
            }
        }
        else if let wt = workoutType {
            if let minutesSinceStart = Int(quickAddDuration) {
                addExercise(wt, minutesSinceStart: minutesSinceStart) { _ in
                    Async.main {
                        log.info("Renabling sender after exercise")
                        sender.enabled = true
                        sender.setNeedsDisplay()
                    }
                }
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
                UINotifications.genericErrorOnView(self, msg: msg)
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
    }

    //MARK: UIView's methods

    override public func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if motionState == .Expand { return true }
        return CGRectContainsPoint(startButton!.frame, point)
    }

    public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
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
//        animationgroup.delegate = self

        if flag == 10 {
            animationgroup.setValue("firstAnimation", forKey: "id")
        }

        tableView.layer.addAnimation(animationgroup, forKey: "Expand")
        tableView.layer.opacity = 1.0

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
//        animationgroup.delegate = self

        if flag == 0 {
            animationgroup.setValue("lastAnimation", forKey: "id")
        }

        tableView.layer.addAnimation(animationgroup, forKey: "Close")
        tableView.layer.opacity = 0.0

        flag! -= 1
    }
    
    public func setMenu() {
        for (index, menuItem) in menuItems.enumerate() {
            let item = menuItem
            item.tag = itemsTag + index
            item.delegate = self
        }

        tableView.backgroundColor = .clearColor()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(tableView, belowSubview: startButton!)

        let tableConstraints = [
            NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-60-[table]-0-|",
                options: [],
                metrics: nil,
                views: ["table": tableView]
            ),
            NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-10-[table]-10-|",
                options: [],
                metrics: nil,
                views: ["table": tableView]
            )
            ].flatMap { $0 }

        self.addConstraints(tableConstraints)
    }

    //MARK: UITableViewDataSource

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return pickerSections.count
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
        return pickerSections[section]
    }

    /*
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 { return 100.0 }
        if indexPath.section == 1 { return 44.0 }
        return 65.0
    }
    */

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

            let stackView: UIStackView = UIStackView(arrangedSubviews: indexPath.section == 0 ? self.favoritesButtons : (self.menuItems ?? []))
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
                self.favoritesButtons.forEach { stack in
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
            cell.textLabel?.text = self.pickerSections[section]
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
            cell.textLabel?.text = self.pickerSections[section]
            cell.textLabel?.textColor = .whiteColor()
        }
        return cell;
    }

    /*
    public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if section == 0 { return 100 }
        return 40
    }

    public func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 100 }
        return 40
    }
    */

}

