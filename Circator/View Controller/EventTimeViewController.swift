//
//  MealTimeViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import CircatorKit
import Fabric
import Crashlytics
import SwiftDate
import Async
import SwiftChart

private let stWorkout = 0.0
private let stSleep = 0.33
private let stFast = 0.66
private let stEat = 1.0

private let summaryFontSize = ScreenManager.sharedInstance.eventTimeViewSummaryFontSize()
private let plotFontSize = ScreenManager.sharedInstance.eventTimeViewPlotFontSize()

class EventTimeViewController : UIViewController {
    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var fastingDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(plotFontSize, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Max Daily Fasting", comment: "Max Daily Fasting")
        return label
    }()

    lazy var fastingLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(summaryFontSize, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Max Daily Fasting")
        return label
    }()

    lazy var eatingDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(plotFontSize, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Daily Eating", comment: "Daily Eating")
        return label
    }()

    lazy var eatingLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(summaryFontSize, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Daily Eating")
        return label
    }()

    lazy var lastAteDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(plotFontSize, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Last Ate", comment: "Last Ate")
        return label
    }()

    lazy var lastAteLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(summaryFontSize, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Last Ate")
        return label
    }()

    lazy var fastingContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.fastingDescLabel, self.fastingLabel])
        stackView.axis = .Vertical
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var eatingContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.eatingDescLabel, self.eatingLabel])
        stackView.axis = .Vertical
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var lastAteContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.lastAteDescLabel, self.lastAteLabel])
        stackView.axis = .Vertical
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var timerContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.fastingContainerView, self.eatingContainerView, self.lastAteContainerView])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var mealChart: Chart = {
        let chart = Chart()
        chart.minX = 0.0
        chart.maxX = 24.0
        chart.minY = 0.0
        chart.maxY = 1.3

        chart.topInset = 25.0
        chart.bottomInset = 50.0
        chart.lineWidth = 2.0
        chart.labelColor = .whiteColor()
        chart.labelFont = UIFont.systemFontOfSize(plotFontSize)

        chart.xLabels = [0.0, 6.0, 12.0, 18.0, 24.0]
        chart.xLabelsTextAlignment = .Left
        chart.xLabelsFormatter = { (labelIndex: Int, labelValue: Float) -> String in
            let d = 24.hours.ago + (Int(labelValue)).hours
            return d.toString(DateFormat.Custom("HH:mm"))!
        }

        chart.yLabels = [0.0, 0.33, 0.66, 1.0]
        chart.yLabelsOnRightSide = true
        chart.yLabelsFormatter = { (labelIndex: Int, labelValue: Float) -> String in
            switch labelIndex {
            case 0:
                return "Exercise"
            case 1:
                return "Sleep"
            case 2:
                return "Fasting"
            case 3:
                return "Eating"
            default:
                return SampleFormatter.numberFormatter.stringFromNumber(labelValue)!
            }
        }

        return chart
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("MealTimes",
            contentType: "",
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
//        BehaviorMonitor.sharedInstance.showView("MealTimes", contentType: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        mealChart.layoutIfNeeded()
        reloadData()
    }

    func configureViews() {
        mealChart.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mealChart)
        let mcConstraints: [NSLayoutConstraint] = [
            mealChart.topAnchor.constraintEqualToAnchor(view.topAnchor),
            mealChart.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            mealChart.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor),
            mealChart.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -(ScreenManager.sharedInstance.eventTimeViewHeight()))
        ]
        view.addConstraints(mcConstraints)

        timerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerContainerView)
        let timerContainerConstraints: [NSLayoutConstraint] = [
            timerContainerView.topAnchor.constraintEqualToAnchor(mealChart.bottomAnchor),
            timerContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            timerContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            timerContainerView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        ]
        view.addConstraints(timerContainerConstraints)
    }

    func reloadData() {
        typealias Event = (NSDate, Double)
        typealias IEvent = (Double, Double)

        // Fetch all sleep and workout data since yesterday.
        let (epsilon, yesterday, now) = (1.seconds, 1.days.ago, NSDate())
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(yesterday, endDate: now, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Aggregate sleep, exercise and meal events.
        HealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            Async.main {
                guard error == nil else {
                    log.error("Failed to fetch meal times: \(error)")
                    return
                }

                self.mealChart.removeSeries()

                if samples.isEmpty {
                    let series = ChartSeries(data: [(x: 0.0, y: stFast), (x: 24.0, y: stFast)])
                    series.area = true
                    series.color = .whiteColor()
                    self.mealChart.addSeries(series)

                    self.fastingLabel.text = "N/A"
                    self.eatingLabel.text  = "N/A"
                    self.lastAteLabel.text = "N/A"
                }
                else {
                    var lastAte : NSDate? = nil

                    // Create event intervals from HKSamples, and calculate the latest eating time.
                    // We truncate any event starting earlier than 24 hours ago.
                    let events = samples.flatMap { (ty,vals) -> [Event]? in
                        switch ty {
                        case is HKWorkoutType:
                            return vals.flatMap { s -> [Event] in
                                let st = s.startDate < yesterday ? yesterday : s.startDate
                                let en = s.endDate
                                guard let v = s as? HKWorkout else { return [] }
                                switch v.workoutActivityType {
                                case HKWorkoutActivityType.PreparationAndRecovery:
                                    lastAte = lastAte == nil ? en : (lastAte! > en ? lastAte! : en)
                                    return [(st, stEat), (en, stEat)]
                                default:
                                    return [(st, stWorkout), (en, stWorkout)]
                                }
                            }

                        case is HKCategoryType:
                            guard ty.identifier == HKCategoryTypeIdentifierSleepAnalysis else {
                                return nil
                            }
                            return vals.flatMap { s -> [Event] in
                                let st = s.startDate < yesterday ? yesterday : s.startDate
                                let en = s.endDate
                                return [(st, stSleep), (en, stSleep)]
                            }

                        default:
                            log.error("Unexpected type \(ty.identifier) in event plot")
                            return nil
                        }
                    }

                    // Sort by starting times across event types (sleep, eat, exercise).
                    var sortedEvents = events.flatten().sort { (a,b) in return a.0 < b.0 }
                    if sortedEvents.isEmpty {
                        let series = ChartSeries(data: [(x: 0.0, y: stFast), (x: 24.0, y: stFast)])
                        series.area = true
                        series.color = .whiteColor()
                        self.mealChart.addSeries(series)

                        self.fastingLabel.text = "N/A"
                        self.eatingLabel.text  = "N/A"
                        self.lastAteLabel.text = "N/A"
                    } else {
                        let lastev = sortedEvents.last ?? sortedEvents.first!
                        let lst = lastev.0 == now ? [] : [(lastev.0, stFast), (now, stFast)]

                        let zst : ([Event], Bool, Event!) = ([], true, nil)
                        sortedEvents = sortedEvents.reduce(zst, combine: { (acc, e) in
                            guard acc.2 != nil else {
                                return ((e.0 == yesterday ? [e] : [(yesterday, stFast), (e.0, stFast), e]), !acc.1, e)
                            }

                            // Skip a fasting interval for back-to-back events
                            if (acc.1 && acc.2.0 == e.0) {
                                return (acc.0 + [(e.0+epsilon, e.1)], !acc.1, e)
                            } else if acc.1 {
                                return (acc.0 + [(acc.2.0+epsilon, stFast), (e.0-epsilon, stFast), e], !acc.1, e)
                            } else {
                                return (acc.0 + [e], !acc.1, e)
                            }
                        }).0 + lst

                        let vals = sortedEvents.map { e in (x: e.0.timeIntervalSinceDate(yesterday) / 3600.0, y: e.1) }
                        let series = ChartSeries(data: vals)
                        series.area = true
                        series.color = .whiteColor()
                        self.mealChart.addSeries(series)

                        // Calculate event statistics. The accumulator is:
                        // i. total eating time
                        // ii. max fasting window
                        // iii. previous event
                        // iv. a bool indicating whether the current event starts an interval
                        // v. the accumulated fasting window
                        // vi. a bool indicating if we are in an accumulating fasting interval
                        let szst : (Double, Double, IEvent!, Bool, Double, Bool) = (0.0, 0.0, nil, true, 0.0, false)
                        let stats = vals.reduce(szst, combine: { (acc, e) in
                            var nacc = acc
                            let (iStart, prevFast) = (acc.3, acc.5)
                            let fast = e.1 == stSleep || e.1 == stFast

                            if !iStart {
                                let duration = e.0 - acc.2.0
                                if prevFast && fast {
                                    nacc.4 += duration
                                    nacc.1 = nacc.1 > nacc.4 ? nacc.1 : nacc.4
                                } else if fast {
                                    nacc.4 = duration
                                    nacc.1 = nacc.1 > nacc.4 ? nacc.1 : nacc.4
                                } else if e.1 == stEat {
                                    nacc.0 += duration
                                }
                            } else {
                                nacc.5 = acc.2 == nil ? false : (acc.2.1 == stSleep || acc.2.1 == stFast)
                            }
                            nacc.2 = e
                            nacc.3 = !iStart
                            return nacc
                        })

                        let today = NSDate().startOf(.Day, inRegion: Region())
                        let fastingHrs = Int(floor(stats.1))
                        let fastingMins = (today + Int(round((stats.1 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
                        self.fastingLabel.text = "\(fastingHrs):\(fastingMins)"

                        self.eatingLabel.text  = (today + Int(stats.0 * 3600.0).seconds).toString(DateFormat.Custom("HH:mm"))!
                        self.lastAteLabel.text = lastAte == nil ? "N/A" : lastAte!.toString(DateFormat.Custom("HH:mm"))!
                    }
                }
                self.mealChart.setNeedsDisplay()
                Answers.logContentViewWithName("MealTimes",
                    contentType: HKWorkoutType.workoutType().identifier,
                    contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                    customAttributes: nil)
//                BehaviorMonitor.sharedInstance.setValue("MealTimes", contentType: HKWorkoutType.workoutType().identifier)
            }
        }
    }
}