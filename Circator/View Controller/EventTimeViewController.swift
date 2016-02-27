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
        BehaviorMonitor.sharedInstance.showView("MealTimes", contentType: "")
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
        // Fetch all sleep and workout data since yesterday.
        let (epsilon, yesterday, now) = (1.seconds, 1.days.ago, NSDate())
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(yesterday, endDate: now, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Aggregate sleep, exercise and meal events.
        HealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            Async.main {
                log.info("SQW: #samples \(samples.count)")
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
                    // Create event intervals from HKSamples. Note that each interval is delimited by a fasting timepoint.
                    let events = samples.flatMap { (ty,vals) -> [(NSDate, Double)]? in
                        switch ty {
                        case is HKWorkoutType:
                            return vals.flatMap { s -> [(NSDate, Double)] in
                                let st = s.startDate
                                let en = s.endDate
                                guard let v = s as? HKWorkout else {
                                    return []
                                }
                                switch v.workoutActivityType {
                                case HKWorkoutActivityType.PreparationAndRecovery:
                                    lastAte = lastAte == nil ? en : (lastAte! > en ? lastAte! : en)
                                    return [(st, stEat), (en, stEat), (en + epsilon, stFast)]
                                default:
                                    return [(st, stWorkout), (en, stWorkout), (en + epsilon, stFast)]
                                }
                            }

                        case is HKCategoryType:
                            guard ty.identifier == HKCategoryTypeIdentifierSleepAnalysis else {
                                return nil
                            }
                            return vals.flatMap { s -> [(NSDate, Double)] in
                                let st = s.startDate
                                let en = s.endDate
                                return [(st, stSleep), (en, stSleep), (en + epsilon, stFast)]
                            }

                        default:
                            log.error("Unexpected type \(ty.identifier) in event plot")
                            return nil
                        }
                    }
                    log.info("SQW: #events \(events.count)")

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
                        let firstev = sortedEvents.first!
                        let lastev = sortedEvents.last ?? firstev

                        // Add a leading sleep or fast segment
                        let zst = (firstev.1 == stEat || firstev.1 == stWorkout) ?
                            [(yesterday, stFast), (firstev.0 - epsilon, stFast)] : [(yesterday, firstev.1)]

                        // Add a trailing segment, which is guaranteed to be a fasting state since we always
                        // append a fasting timepoint to any other event.
                        let lst = [(now, lastev.1)]

                        // Create event intervals from points:
                        // i. add the event as a timepoint if it matches the previous state, or
                        //    if the previous state was a fasting event.
                        // ii. otherwise, we are transitioning; thus add a fasting timepoint, to close the previous
                        //     interval, prior to adding this event.
                        let z = (zst, firstev)
                        sortedEvents = sortedEvents.reduce(z, combine: { (acc, e) in
                            //let eventBlip = e.0.timeIntervalSinceDate(acc.1.0) <= Double(2*epsilon.second)
                            if e.1 == stFast || acc.1.1 == e.1 /*|| eventBlip*/ {
                                return (acc.0 + [e], e)
                            } else {
                                return (acc.0 + [(e.0 - epsilon, stFast), e], e)
                            }
                        }).0 + lst

                        let vals = sortedEvents.map { e in (x: e.0.timeIntervalSinceDate(yesterday) / 3600.0, y: e.1) }
                        let series = ChartSeries(data: vals)
                        series.area = true
                        series.color = .whiteColor()
                        self.mealChart.addSeries(series)

                        // Calculate event statistics. The accumulator is:
                        // i. max fasting window
                        // ii. total eating time
                        // iii. previous event
                        // iv. a bool indicating if we are in an accumulating fasting interval
                        // v. the accumulated fasting window
                        let acc = vals.reduce((0.0, 0.0, vals.first!, false, 0.0), combine: { (acc, e) in
                            var nacc = acc
                            let transition = acc.2.1 != e.1
                            let prevFast = acc.3
                            if !transition {
                                let duration = e.0 - acc.2.0
                                let fast = e.1 == stSleep || e.1 == stFast
                                var fastacc = 0.0

                                if prevFast && fast {
                                    fastacc = acc.4 + duration
                                    nacc.0 = nacc.0 > fastacc ? nacc.0 : fastacc
                                } else if fast {
                                    fastacc = duration
                                    nacc.0 = nacc.0 > fastacc ? nacc.0 : fastacc
                                } else if e.1 == stEat {
                                    nacc.1 += duration
                                }
                                return (nacc.0, nacc.1, e, fast, fastacc)
                            }
                            return (nacc.0, nacc.1, e, false, 0.0)
                        })

                        let today = NSDate().startOf(.Day, inRegion: Region())
                        self.fastingLabel.text = (today + Int(acc.0 * 3600.0).seconds).toString(DateFormat.Custom("HH:mm"))!
                        self.eatingLabel.text  = (today + Int(acc.1 * 3600.0).seconds).toString(DateFormat.Custom("HH:mm"))!
                        self.lastAteLabel.text = lastAte == nil ? "N/A" : lastAte!.toString(DateFormat.Custom("HH:mm"))!
                    }
                }
                self.mealChart.setNeedsDisplay()
                BehaviorMonitor.sharedInstance.setValue("MealTimes", contentType: HKWorkoutType.workoutType().identifier)
            }
        }
    }
}