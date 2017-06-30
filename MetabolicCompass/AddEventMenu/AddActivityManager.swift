//
//  AddActivityManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import AwesomeCache
import HTPressableButton
import AKPickerView_Swift
import MCCircadianQueries

typealias FrequentActivityCache = Cache<FrequentActivityInfo>

open class AppPickerManager: PickerManager, PickerManagerSelectionDelegate {

    var apps: [UIStackView]

    private var notificationView: UIView! = nil

    static let activityApps: [String: AnyObject] = [
        "Cardiograph"     : "cardiograph:" as AnyObject,
        "Sleep Cycle"     : "fb162575247235:" as AnyObject, /* Sleep Cycle */
        "Runkeeper"       : "fb62572192129:" as AnyObject, /* Runkeeper */
        "FitBit"          : "fitbit:" as AnyObject,
        "Garmin"          : "garmin:" as AnyObject,
        "LoseIt"          : "loseit:" as AnyObject,
        "MyFitnessPal"    : "mfp:" as AnyObject,
        "MyFitnessPal HD" : "mfphd:" as AnyObject,
        "MyPlate"         : "myplate:" as AnyObject,
        "Nike+ Run Club"  : "nikeplus:" as AnyObject,
        "Strava"          : "strava:" as AnyObject,
        "HealthMate"      : "withings-bd2:" as AnyObject
    ]

    static let appIcons: [String: AnyObject] = [
        "Cardiograph"     : "icon-Cardiograph" as AnyObject,
        "Sleep Cycle"     : "icon-SleepCycle" as AnyObject,
        "Runkeeper"       : "icon-runkeeper" as AnyObject,
        "FitBit"          : "icon-fitbit" as AnyObject,
        "Garmin"          : "icon-Garmin" as AnyObject,
        "LoseIt"          : "icon-LoseIt" as AnyObject,
        "MyFitnessPal"    : "icon-myfitnesspal" as AnyObject,
        "MyFitnessPal HD" : "icon-myfitnesspal" as AnyObject,
        "MyPlate"         : "icon-MyPlate" as AnyObject,
        "Nike+ Run Club"  : "icon-Nike+RunClub" as AnyObject,
        "Strava"          : "icon-Strava" as AnyObject,
        "HealthMate"      : "icon-WithingsHealthMate" as AnyObject,
    ]

    var availableActivityApps: [String: AnyObject] = [:]

    init(notificationView: UIView!) {
        self.notificationView = notificationView

        self.availableActivityApps = Dictionary(pairs: AppPickerManager.activityApps.filter { (name, scheme) in
            if let scheme = scheme as? String, let url = NSURL(string: "\(scheme)//") {
                return UIApplication.shared.canOpenURL(url as URL)
            }
            log.debug("App \(name) unavailable with scheme: \(scheme)", feature: "appIntegration")
            return false
        })

        let ctor : (String) -> UIImageView = { name in
            let image = UIImage(named: AppPickerManager.appIcons[name]! as! String)!
            let view = UIImageView(image: image)
            view.backgroundColor = UIColor.clear
            view.contentMode = .scaleAspectFit
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            view.layer.shadowColor = UIColor.lightGray.cgColor
            view.layer.shadowOffset = CGSize(width: 3, height: 3)
            view.layer.shadowOpacity = 0.7
            view.layer.shadowRadius = 4.0
            return view
        }

        let appNames = availableActivityApps.map({ $0.0 }).sorted()

        self.apps = appNames.map { name in
            let stack = UIComponents.createLabelledComponent(title: name, labelOnTop: false, labelFontSize: 12.0, stackAlignment: .center, value: name, constructor: ctor)
            stack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return stack
        }

        super.init(itemType: "Apps", items: appNames, data: availableActivityApps)
    }

    func cellHeight() -> CGFloat {
        let screenSize = UIScreen.main.bounds.size
        return (screenSize.width / 5) + 28.0
    }

    func cellWidth(label: UILabel, image: UIImageView, item: Int) -> CGFloat {
        let height = cellHeight()

        let txt = label.text ?? ""
        let size = txt.size(attributes: [NSFontAttributeName: label.font])
        return max(max(size.width, image.image!.size.width), height)
    }

    // MARK: - AKPickerViewDataSource View-centric interface
    func pickerView(_ pickerView: AKPickerView, viewForItem item: Int) -> UIView {
        return self.apps[item]
    }

    func pickerView(_ pickerView: AKPickerView, cellForItem: UICollectionViewCell, constraintsForItem item: Int) -> [NSLayoutConstraint] {
        let height = cellHeight()

        let image = apps[item].subviews[0] as! UIImageView
        let label = apps[item].subviews[1] as! UILabel

        image.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        let width = cellWidth(label: label, image: image, item: item)

        let constraints: [NSLayoutConstraint] = [
            image.widthAnchor.constraint(equalTo: image.heightAnchor),
            cellForItem.contentView.heightAnchor.constraint(equalToConstant: height),
            cellForItem.contentView.topAnchor.constraint(equalTo: apps[item].topAnchor, constant: -10.0),
            cellForItem.contentView.bottomAnchor.constraint(equalTo: apps[item].bottomAnchor, constant: 10.0),
            cellForItem.contentView.centerXAnchor.constraint(equalTo: apps[item].centerXAnchor),
            apps[item].heightAnchor.constraint(equalToConstant: height - 20.0),
            apps[item].centerXAnchor.constraint(equalTo: image.centerXAnchor),
            apps[item].centerXAnchor.constraint(equalTo: label.centerXAnchor),
            image.heightAnchor.constraint(equalToConstant: height - (label.font.lineHeight + 28.0)),
            label.widthAnchor.constraint(equalToConstant: width)
        ]

        constraints[0].priority = 1000
        return constraints
    }

    func pickerView(_ pickerView: AKPickerView, configureView view: UIView, forItem item: Int) {
        configureItemContentView(view, item: item)
    }

    func pickerView(_ pickerView: AKPickerView, contentHeightForItem item: Int) -> CGFloat {
        return cellHeight()
    }

    func pickerView(pickerView: AKPickerView, contentWidthForItem item: Int) -> CGFloat {
        let height = cellHeight()

        if let label = apps[item].subviews[1] as? UILabel, let image = apps[item].subviews[0] as? UIImageView {
            return cellWidth(label: label, image: image, item: item)
        }
        return height
    }

    // MARK : - PickerManagerSelectionDelegate
    func pickerItemSelected(_ pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
        if let scheme = data as? String, let url = NSURL(string: "\(scheme)//") {
            if UIApplication.shared.canOpenURL(url as URL) {
                UIApplication.shared.openURL(url as URL)
            }
            else {
                Async.main {
                    log.error("Could not find \(url)", feature: "appIntegration")
                    let msg = "We could not find your \(item) app, please restart Metabolic Compass if you've uninstalled it."
                    UINotifications.genericErrorOnView(view: self.notificationView, msg: msg)
                }
            }
        }
        else {
            Async.main {
                log.error("Invalid URL scheme for \(data ?? DT_UNKNOWN as AnyObject)", feature: "appIntegration")
                let msg = "Failed to open your \(item) app!"
                UINotifications.genericErrorOnView(view: self.notificationView, msg: msg)
            }
        }

        self.finishProcessingSelection()
    }
}


open class AddActivityManager: UITableView, UITableViewDelegate, UITableViewDataSource, PickerManagerSelectionDelegate {
 
    public var menuItems: [PathMenuItem]

    private var quickAddButtons: [SlideButtonArray] = []

    // Cache frequent activities by day of week.
    private var frequentActivitiesCache: FrequentActivityCache

    private var frequentActivities: [FrequentActivity] = []
    private var shadowActivities: [FrequentActivity] = []

    // Row to activity date
    private var frequentActivityByRow: [Int: FrequentActivity] = [:]
    private var nextActivityRowExpiry: Date = Date().startOf(component: .day)
    private let nextActivityExpiryIncrement: DateComponents = 1.minutes // 10.minutes

    // Activity date to cell contents.
    private var frequentActivityCells: [Int: [UIView]] = [:]

    private let cacheDuration: Double = 60 * 60

    private let addEventCellIdentifier = "addEventCell"
    private let addEventSectionHeaderCellIdentifier = "addEventSectionHeaderCell"

    private var notificationView: UIView! = nil

    private var appManager: AppPickerManager! = nil
    private var appPicker: AKPickerView! = nil

    // Section and title configuration
    private var addSectionTitles = [String]()
    private var sectionRows = [Int]()

    private var frequentActivitySectionIdx = 3

    // Section title and index constants.
    private let sectionTitlesWithApps = ["Just-In-Time Activity", "Retrospective Activity", "Your Apps", "Frequent Activities"]
    private let sectionTitlesNoApps = ["Just-In-Time Activity", "Retrospective Activity", "Frequent Activities"]

    private let sectionRowsWithApps = [2, 1, 1, 0]
    private let sectionRowsNoApps = [2, 1, 0]

    private var frequentActivitySectionIdxWithApps = 3
    private var frequentActivitySectionIdxNoApps = 2


    public init(frame: CGRect, style: UITableViewStyle, menuItems: [PathMenuItem], notificationView: UIView!) {
        do {
            self.frequentActivitiesCache = try FrequentActivityCache(name: "MCAddFrequentActivities")
        } catch _ {
            fatalError("Unable to create frequent activites cache.")
        }

        self.menuItems = menuItems
        self.notificationView = notificationView
        super.init(frame: frame, style: style)
        self.setupTable()
    }

    required public init?(coder aDecoder: NSCoder) {
        do {
            self.frequentActivitiesCache = try FrequentActivityCache(name: "MCAddFrequentActivities")
        } catch _ {
            fatalError("Unable to create frequent activites cache.")
        }

        guard let mi = aDecoder.decodeObject(forKey: "menuItems") as? [PathMenuItem] else {
            menuItems = []; super.init(frame: CGRect.zero, style: .grouped); return nil
        }

        menuItems = mi
        super.init(coder: aDecoder)
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encode(menuItems, forKey: "menuItems")
    }

    func frequentActivityCacheKey(date: Date) -> String {
        return "\(date.weekday)"
    }

    private func setupTable() {
        self.isHidden = true
        self.allowsSelection = false
        self.separatorStyle = .none
        self.layer.opacity = 0.0

        self.register(UITableViewCell.self, forCellReuseIdentifier: addEventCellIdentifier)
        self.register(UITableViewCell.self, forCellReuseIdentifier: addEventSectionHeaderCellIdentifier)

        self.delegate = self;
        self.dataSource = self;

        self.estimatedRowHeight = 100.0
        self.estimatedSectionHeaderHeight = 66.0
        self.rowHeight = UITableViewAutomaticDimension
        self.sectionHeaderHeight = UITableViewAutomaticDimension

        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
        self.cellLayoutMarginsFollowReadableWidth = false

        quickAddButtons.append(SlideButtonArray(frame: CGRect.zero, buttonsTag: 3000, arrayRowIndex: 0))
        quickAddButtons.append(SlideButtonArray(frame: CGRect.zero, buttonsTag: 4000, arrayRowIndex: 1))

        // Configure delegates.
        quickAddButtons[0].delegate = self
        quickAddButtons[1].delegate = self

        // Configure exclusive selection.
        quickAddButtons[0].exclusiveArrays.append(quickAddButtons[1])
        quickAddButtons[1].exclusiveArrays.append(quickAddButtons[0])

        // Configure app picker.
        let manager = AppPickerManager(notificationView: self.notificationView ?? self.superview)
        if manager.availableActivityApps.isEmpty {
            addSectionTitles = sectionTitlesNoApps
            sectionRows = sectionRowsNoApps
            frequentActivitySectionIdx = frequentActivitySectionIdxNoApps

        } else {
            addSectionTitles = sectionTitlesWithApps
            sectionRows = sectionRowsWithApps
            frequentActivitySectionIdx = frequentActivitySectionIdxWithApps

            appManager = manager
            appManager.delegate = appManager

            appPicker = AKPickerView()
            appPicker.delegate = appManager
            appPicker.dataSource = appManager
            appPicker.interitemSpacing = 10

            let pickerFont = UIFont(name: "GothamBook", size: 18.0)!
            appPicker.font = pickerFont
            appPicker.highlightedFont = pickerFont

            appPicker.backgroundColor = UIColor.clear.withAlphaComponent(0.0)
            appPicker.highlightedTextColor = UIColor.white
            appPicker.textColor = UIColor.white.withAlphaComponent(0.7)
            appPicker.reloadData()
        }
    }

    private func descOfCircadianEvent(event: CircadianEvent) -> String {
        switch event {
        case .meal(let mealType):
            return mealType.rawValue
        case .exercise(let exerciseType):
            switch exerciseType {
            case .running: return "Running"
            case .cycling: return "Cycling"
            default: return "Exercise"
            }
        case .sleep:
            return "Sleep"
        default:
            return ""
        }
    }

    func frequentActivityCellView(_ tag: Int, aInfo: FrequentActivity) -> [UIView] {
        let fmt = DateFormat.custom("HH:mm")
        let endDate = aInfo.start.addingTimeInterval(aInfo.duration)

        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .lightGray
        label.textAlignment = .left

        let dayTxt = aInfo.start.isToday ? "" : "yesterday "
        let stTxt = aInfo.start.string(format: fmt)
        let enTxt = endDate.string(format: fmt)
        label.text = "\(aInfo.desc), \(dayTxt)\(stTxt) - \(enTxt)"

        let unchecked_image = UIImage(named: "checkbox-unchecked-register") as UIImage?
        let checked_image = UIImage(named: "checkbox-checked-register") as UIImage?
        let button = UIButton(type: .custom)

        button.tag = tag
        button.backgroundColor = .clear
        button.setImage(unchecked_image, for: .normal)
        button.setImage(checked_image, for: .selected)
        button.addTarget(self, action: #selector(self.addFrequentActivity(_:)), for: .touchUpInside)

        return [label, button]
    }

    public func addFrequentActivity(_ sender: UIButton) {
        log.debug("Selected freq. activity \(sender.tag)", feature: "freqActivity")
        sender.isSelected = !sender.isSelected
    }

    private func refreshFrequentActivities() {
        let now = Date()
        let nowStart = now.startOf(component: .day)

        let cacheKey = frequentActivityCacheKey(date: nowStart)

        log.debug("Refreshing activities \(self.nextActivityRowExpiry)", feature: "freqActivity")

        frequentActivitiesCache.setObject(forKey: cacheKey, cacheBlock: { (success, failure) in
            // if weekday populate from previous day and same day last week
            // else populate from the same day for the past 4 weekends
            var queryStartDates: [Date] = []
            
            // Since sleep events may span the end of day boundary, we also include the previous day.
            if nowStart.weekday < 6 {
                queryStartDates = [(nowStart - 1.weeks) - 1.days, nowStart - 1.weeks, nowStart - 2.days, nowStart - 1.days]
            } else {
                // TODO: the 3rd and 4th weeks will not be cached since MCHealthManager uses a 2-week cache by default.
                queryStartDates = (1...4).flatMap { [(nowStart - $0.weeks) - 1.days, nowStart - $0.weeks] }
            }
            
            var activities: [FrequentActivity] = []
            
            var circadianEvents: [Date: [(Date, CircadianEvent)]] = [:]
            var queryErrors: [NSError?] = []
            let queryGroup = DispatchGroup()
            
            queryStartDates.forEach { date in
                queryGroup.enter()
                MCHealthManager.sharedManager.fetchCircadianEventIntervals(date, endDate: date.endOf(component: .day), noTruncation: true)
                { (intervals, error) in
                    guard error == nil else {
                        log.error("Failed to fetch circadian events: \(String(describing: error))", feature: "freqActivity")
                        queryErrors.append(error as? NSError)
                        queryGroup.leave()
                        return
                    }
                    circadianEvents[date] = intervals
                    queryGroup.leave()
                }
            }
            
            queryGroup.notify(queue: DispatchQueue.global()) {
                guard queryErrors.isEmpty else {
                    failure(queryErrors.first!)
                    return
                }
                
                // Turn into activities by merging and accumulating circadian events.
                log.info("FAQ finished with \(circadianEvents.count) results")
                log.info("FAQ results \(circadianEvents)")
                
                var dateIndex = 0
                while dateIndex < queryStartDates.count {
                    let nextDateIndex = dateIndex + 1
                    if ( nextDateIndex < queryStartDates.count )
                        && ( queryStartDates[dateIndex].compare(queryStartDates[nextDateIndex] - 1.days) == .orderedSame )
                    {
                        if let e1 = circadianEvents[queryStartDates[dateIndex]], let e2 = circadianEvents[queryStartDates[nextDateIndex]] {
                            let eventsUnion = e1 + e2
                            eventsUnion.enumerated().forEach { (index, eventEdge) in
                                let nextIndex = index+1
                                if index % 2 == 0 && nextIndex < eventsUnion.count {
                                    let (nextEdgeDate, nextEdgeEvent) = eventsUnion[nextIndex]
                                    if ( eventEdge.1 != CircadianEvent.fast ) && ( eventEdge.1 == nextEdgeEvent ) {
                                        let desc = self.descOfCircadianEvent(event: eventEdge.1)
                                        let duration = nextEdgeDate.timeIntervalSinceReferenceDate  - eventEdge.0.timeIntervalSinceReferenceDate
                                        activities.append(FrequentActivity(desc: desc, start: eventEdge.0, duration: duration))
                                    }
                                }
                            }
                        }
                    }
                    dateIndex += 1
                }
                
                // Deduplicate activities relative to today.
                var activitiesToday : [Int: FrequentActivity] = [:]
                
                activities.forEach { aInfo in
                    let secondsSinceDay = aInfo.start.timeIntervalSince(aInfo.start.startOf(component: .day))
                    let startInToday = nowStart.addingTimeInterval(secondsSinceDay)
                    
                    let aInfo = FrequentActivity(desc: aInfo.desc, start: startInToday, duration: aInfo.duration)
                    let key = aInfo.start.hashValue + Int(aInfo.duration)
                    activitiesToday[key] = aInfo
                }
                
                log.info("FAQ dedup \(activitiesToday)")
                
                activities = activitiesToday.map({ $0.1 }).sorted { $0.0.start < $0.1.start }
                success(FrequentActivityInfo(activities: activities), CacheExpiry.seconds(self.cacheDuration))
            } // end cacheBlock
        
        
    
        }, completion: { (activityInfoFromCache, loadedFromCache, error) in
                log.debug("Cache result: \(activityInfoFromCache?.activities.count ?? -1) (hit: \(loadedFromCache))", feature: "cache:freqActivity")
                
                guard error == nil else {
                    log.error("Failed to populate frequent activities: \(String(describing: error))")
                    self.frequentActivities = []
                    self.shadowActivities = []
                    return
                }
                
                // Create a cell's content for each frequent activity.
                if let aInfos = activityInfoFromCache?.activities {
                    self.shadowActivities = aInfos
                    if aInfos.isEmpty {
                        // Advance the refresh guard if we have no cached activities
                        self.nextActivityRowExpiry = now + self.nextActivityExpiryIncrement
                    }
                } else {
                    // Advance the refresh guard if we have no cached activities
                    self.nextActivityRowExpiry = now + self.nextActivityExpiryIncrement
                }
                
                // Refresh the table.
                Async.main { self.reloadData() }
        })
    }

    @nonobjc public func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return addSectionTitles.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == frequentActivitySectionIdx {
            log.debug("Activities #rows \(shadowActivities.count) \(frequentActivities.count)", feature: "freqActivity")

            let now = Date()
            let nowStart = now.startOf(component: .day)

            // Swap buffer.
            if shadowActivities.count > 0 {
                frequentActivities = shadowActivities
                shadowActivities = []
            }

            if nextActivityRowExpiry <= now {
                // Refresh cache as needed.
                let cacheKey = frequentActivityCacheKey(date: nowStart)

                if frequentActivities.isEmpty || frequentActivitiesCache.object(forKey: cacheKey) == nil {
                    log.debug("Refreshing cache", feature: "cache:freqActivity")
                    frequentActivitiesCache.removeExpiredObjects()
                    refreshFrequentActivities()
                    return frequentActivityCells.isEmpty ? 1 : frequentActivityCells.count
                }
                else {
                    log.info("Creating cells \(nextActivityRowExpiry) (now: \(now))", feature: "cache:freqActivity")

                    // Filter activities to within the last 24 hours and create the row mapping.
                    frequentActivityByRow.removeAll()
                    frequentActivityCells.removeAll()

                    let reorderedActivities: [FrequentActivity] = frequentActivities.map({ aInfo in
                        if aInfo.start > now {
                            return FrequentActivity(desc: aInfo.desc, start: aInfo.start - 1.days, duration: aInfo.duration)
                        }
                        return aInfo
                    }).sorted(by: { $0.0.start < $0.1.start })

                    reorderedActivities.enumerated().forEach { (index, aInfo) in
                        self.frequentActivityByRow[index] = aInfo
                        self.frequentActivityCells[index] = self.frequentActivityCellView(index, aInfo: aInfo)
                    }
                    
                    nextActivityRowExpiry = now + nextActivityExpiryIncrement
                }
            } else {
                log.debug("Activities will expire at \(nextActivityRowExpiry) (now: \(now))", feature: "cache:freqActivity")
            }

            return frequentActivityCells.isEmpty ? 1 : frequentActivityCells.count
        }
        else if section < sectionRows.count {
            return sectionRows[section]
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return addSectionTitles[section]
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: addEventCellIdentifier, for: indexPath as IndexPath)

        for sv in cell.contentView.subviews { sv.removeFromSuperview() }
        cell.textLabel?.isHidden = true
        cell.imageView?.image = nil
        cell.accessoryType = .none
        cell.selectionStyle = .none

        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear

        if indexPath.section == 0  {
            let v = quickAddButtons[indexPath.row]
            v.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(v)

            let constraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraint(equalTo: v.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: -10),
                cell.contentView.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: 10)
            ]

            cell.contentView.addConstraints(constraints)
        }
        else if indexPath.section == 1 {
            let stackView: UIStackView = UIStackView(arrangedSubviews: self.menuItems )
            stackView.axis = .horizontal
            stackView.distribution = UIStackViewDistribution.fillEqually
            stackView.alignment = UIStackViewAlignment.fill
            stackView.spacing = 0

            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            let stackConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                cell.contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ]

            cell.contentView.addConstraints(stackConstraints)
        }
        else if indexPath.section == 2 && appPicker != nil {
            appPicker.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(appPicker)

            let constraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraint(equalTo: appPicker.topAnchor),
                cell.contentView.bottomAnchor.constraint(equalTo: appPicker.bottomAnchor),
                cell.contentView.leadingAnchor.constraint(equalTo: appPicker.leadingAnchor, constant: -10),
                cell.contentView.trailingAnchor.constraint(equalTo: appPicker.trailingAnchor, constant: 10)
            ]

            cell.contentView.addConstraints(constraints)
        }
        else {
            var activityCells: [UIView] = []
            if let views = frequentActivityCells[indexPath.row] {
                activityCells = views
            } else {
                let label = UILabel()
                label.backgroundColor = .clear
                label.textColor = .lightGray
                label.textAlignment = .center
                label.text = "No frequent activities found"
                activityCells.append(label)
            }

            let stackView: UIStackView = UIStackView(arrangedSubviews: activityCells)

            stackView.axis = .horizontal
            stackView.distribution = UIStackViewDistribution.equalSpacing
            stackView.alignment = UIStackViewAlignment.fill
            stackView.spacing = 0

            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            let stackConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -20),
                cell.contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20)
            ]

            cell.contentView.addConstraints(stackConstraints)
        }
        return cell
    }

    //MARK: UITableViewDelegate
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: addEventSectionHeaderCellIdentifier)!

        let sectionHeaderSize = ScreenManager.sharedInstance.quickAddSectionHeaderFontSize()

        cell.textLabel?.text = self.addSectionTitles[section]
        cell.textLabel?.font = UIFont(name: "GothamBook", size: sectionHeaderSize)
        cell.textLabel?.textColor = .lightGray
        cell.textLabel?.numberOfLines = 0

        if section == 0 || section == frequentActivitySectionIdx {
            for sv in cell.contentView.subviews { sv.removeFromSuperview() }

            let button = UIButton(frame: CGRect(0, 0, 44, 44))
            button.backgroundColor = .clear

            button.setImage(UIImage(named: "icon-quick-add-tick"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit

            button.addTarget(self, action: (section == frequentActivitySectionIdx ? #selector(self.handleFrequentAddTap(_:)) : #selector(AddActivityManager.handleQuickAddTap(_:))), for: .touchUpInside)

            button.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(button)

            let buttonConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraint(equalTo: button.topAnchor, constant: -20),
                cell.contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 10),
                cell.contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 20),
                button.widthAnchor.constraint(equalToConstant: 44),
                button.heightAnchor.constraint(equalToConstant: 44)
            ]

            cell.contentView.addConstraints(buttonConstraints)
        }

        return cell;
    }

    func circadianOpCompletion(_ sender: UIButton?, manager: PickerManager?, displayError: Bool, error: Error?) -> Void {
        Async.main {
            if error == nil {
                UINotifications.genericSuccessMsgOnView(view: self.notificationView ?? self.superview!, msg: "Successfully added events.")
            }
            else {
                let msg = displayError ? (error?.localizedDescription ?? "Unknown error") : "Failed to add event"
                UINotifications.genericErrorOnView(view: self.notificationView ?? self.superview!, msg: msg)
            }
            if let sender = sender {
                sender.isEnabled = true
                sender.setNeedsDisplay()
            }
        }
        manager?.finishProcessingSelection()
        if error != nil { print(error!.localizedDescription) }
        else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MEMDidUpdateCircadianEvents), object: nil)
        }
    }

    func validateTimedEvent(_ startTime: Date, endTime: Date, completion: @escaping (Error?) -> Void) {
        // Fetch all sleep and workout data since yesterday.
        let (yesterday, now) = (Date().addDays(daysToAdd: -1), Date())
        let sleepTy = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: [])
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Aggregate sleep, exercise and meal events.
        MCHealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { print(error!.localizedDescription); return }
            let overlaps = samples.reduce(false, { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })

            if !overlaps { completion(nil) }
            else {
                let msg = "This event overlaps with another, please try again"
                let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
                UINotifications.genericErrorOnView(view: self.notificationView ?? self.superview!, msg: msg)
                completion(err)
            }
        }
    }

    func addSleep(hoursSinceStart: Double, startDate: Date? = nil, completion: @escaping (Error?) -> Void) {
//        let startTime = startDate == nil ? (Int(hoursSinceStart * 60)).minutes.ago : startDate!
        let startTime = startDate == nil ? Date().addingTimeInterval(hoursSinceStart)  : startDate!
//        var startTime = startDate = nil ? Date().addingTimeInterval(Int(hoursSinceStart * 60)) : startDate!
        let endTime = startDate == nil ? Date() : startDate! + (Int(hoursSinceStart * 60)).minutes

        log.debug("Saving sleep event: \(startDate ?? (no_argument as AnyObject) as! Date) \(endTime)", feature: "addActivity")

        validateTimedEvent(startDate!, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.saveSleep(startDate!, endDate: endTime, metadata: [:]) {
                (success, error) -> Void in
//                if error != nil { log.error(error!.localizedDescription) }
                if error != nil { print("error in localized description") }
                else { log.debug("Saved sleep event: \(String(describing: startDate)) \(endTime)", feature: "addActivity") }
//                else { print("logged") }
                completion(error)
            }
        }
    }

    func addMeal(_ mealType: String, minutesSinceStart: Int, startDate: Date? = nil, completion: @escaping (Error?) -> Void) {
//        let startTime = startDate == nil ? minutesSinceStart.minutes.ago : startDate!
        let startTime = startDate == nil ? Date().addingTimeInterval(TimeInterval(minutesSinceStart)) : startDate!
        let endTime = startDate == nil ? Date() : startDate! + (Int(minutesSinceStart)).minutes
        let metadata = ["Meal Type": mealType]

        log.debug("Saving meal event: \(mealType) \(startTime) \(endTime)", feature: "addActivity")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(from: "km"),
                kiloCalories: 0.0, metadata: metadata as NSDictionary)
            {
                (success, error) -> Void in
                if error != nil { print("error!.localizedDescription") }
//                else { print("Saved meal event as workout type: \(mealType) \(startTime) \(endTime)", feature: "addActivity") }
                else { print("saved meal event")
                completion(error)
            }
        }
    }
    }

    func addExercise(workoutType: HKWorkoutActivityType, minutesSinceStart: Int, startDate: Date? = nil, completion: @escaping (Error?) -> Void) {
//        let startTime = startDate == nil ? minutesSinceStart.minutes.ago : startDate!
        let startTime = startDate == nil ? Date().addingTimeInterval(TimeInterval(minutesSinceStart)) : startDate!
        let endTime = startDate == nil ? Date() : startDate! + (Int(minutesSinceStart)).minutes

        log.debug("Saving exercise event: \(workoutType) \(startTime) \(endTime)", feature: "addActivity")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.saveWorkout(
                startTime, endDate: endTime, activityType: workoutType,
                distance: 0.0, distanceUnit: HKUnit(from: "km"), kiloCalories: 0.0, metadata: [:])
            {
                (success, error ) -> Void in
 //               if error != nil { log.error(error!.localizedDescription) }
                if error != nil { print("localized error") }
//                else { log.debug("Saved exercise event as workout type: \(workoutType) \(startTime) \(endTime)", feature: "addActivity") }
                else { print("saved as workout type") }
                completion(error)
            }
        }
    }

    func processSelection(_ sender: UIButton?, pickerManager: PickerManager?, itemType: String, startDate: Date? = nil, duration: Double, durationInSecs: Bool) {
        var asSleep = false
        var workoutType : HKWorkoutActivityType? = nil
        var mealType: String? = nil

        switch itemType {
        case "Breakfast", "Lunch", "Dinner", "Snack":
            mealType = itemType

        case "Running":
            workoutType = .running

        case "Cycling":
            workoutType = .cycling

        case "Exercise":
            workoutType = .other

        case "Sleep":
            asSleep = true

        default:
            break
        }

        if asSleep {
            addSleep(hoursSinceStart: durationInSecs ? duration / 3600.0 : duration, startDate: startDate) {
                self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
            }
        }
        else if let mt = mealType {
            let minutesSinceStart = Int(durationInSecs ? (duration / 60) : duration)
            addMeal(mt, minutesSinceStart: minutesSinceStart, startDate: startDate) {
                self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
            }
        }
        else if let wt = workoutType {
            let minutesSinceStart = Int(durationInSecs ? (duration / 60) : duration)
            addExercise(workoutType: wt, minutesSinceStart: minutesSinceStart, startDate: startDate) {
                self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
            }
        }
        else {
            let msg = "Unknown activity type \(itemType)"
            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
            circadianOpCompletion(sender, manager: pickerManager, displayError: true, error: err)
        }
    }


    func processSelection(_ sender: UIButton?, pickerManager: PickerManager,
                          itemType: String?, index: Int, item: String, data: AnyObject?)
    {
        if let itemType = itemType, let duration = data as? Double {
            processSelection(sender, pickerManager: pickerManager, itemType: itemType, duration: duration, durationInSecs: false)
        }
        else {
            let msg = itemType == nil ?
                "Unknown quick add event type \(String(describing: itemType))" : "Failed to convert duration into integer: \(data)"

            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
            circadianOpCompletion(sender, manager: pickerManager, displayError: true, error: err)
        }
    }

    public func handleQuickAddTap(_ sender: UIButton) {
        log.debug("Quick add button pressed", feature: "addActivity")

        Async.main {
            sender.isEnabled = false
            sender.setNeedsDisplay()
        }

        let selection = quickAddButtons.reduce(nil, { (acc, buttonArray) in
            return acc != nil ? acc : buttonArray.getSelection()
        })

        if let s = selection {
//            processSelection(sender, pickerManager: s.0, itemType: s.1, index: s.2, item: s.3, data: s.4)
             processSelection(sender, pickerManager: s.0, itemType: s.1, index: s.2, item: s.3, data: s.4)
        } else {
            Async.main {
                UINotifications.genericErrorOnView(view: self.notificationView ?? self.superview!, msg: "No event selected")
                sender.isEnabled = true
                sender.setNeedsDisplay()
            }
        }
    }

    func handleFrequentAddTap(_ sender: UIButton) {
        log.debug("Adding selected frequent activities", feature: "addActivity")

        Async.main {
            sender.isEnabled = false
            sender.setNeedsDisplay()
        }

        // Iterate through all freq activity cells, check if button is selected, warn on overlap, and then add.
        var activitiesToAdd: [FrequentActivity] = []

        self.frequentActivityCells.forEach { kv in
            if let button = kv.1[1] as? UIButton, button.isSelected {
                if let aInfo = self.frequentActivityByRow[kv.0] {
                    activitiesToAdd.append(aInfo)
                }
                Async.main {
                    button.isSelected = false
                    button.setNeedsDisplay()
                }
            }
        }

        let overlaps = false
        for i in (0..<activitiesToAdd.count) {
            let iSt = activitiesToAdd[i].start
            let iEn = activitiesToAdd[i].start.addingTimeInterval(activitiesToAdd[i].duration)
//            let iEn = activitiesToAdd[i].start.dateByAddingTimeInterval(activitiesToAdd[i].duration)
//            let iEn = activitiesToAdd[i].start(activitiesToAdd[i].duration)

            for j in (i+1..<activitiesToAdd.count) {
                let jSt = activitiesToAdd[j].start
                let jEn = activitiesToAdd[j].start.addingTimeInterval(activitiesToAdd[j].duration)
//                let jEn = activitiesToAdd[j].start.dateByAddingTimeInterval(activitiesToAdd[j].duration)
//                overlaps = overlaps || !(jEn <= iSt || iEn <= jSt)
            }
        }
        
        if overlaps {
            Async.main {
                let msg = "You selected overlapping events, please try again"
                UINotifications.genericErrorOnView(view: self.notificationView ?? self.superview!, msg: msg)
                sender.isEnabled = true
                sender.setNeedsDisplay()
            }
        } else {
            for aInfo in activitiesToAdd {
//                processSelection(nil, pickerManager: nil, itemType: aInfo.desc, startDate: aInfo.start, duration: aInfo.duration, durationInSecs: true)
            }
            Async.main {
                sender.isEnabled = true
                sender.setNeedsDisplay()
            }
        }
    }
    
    func pickerItemSelected(_ pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
            processSelection(nil, pickerManager: pickerManager, itemType: itemType, index: index, item: item, data: data)
        }
}
