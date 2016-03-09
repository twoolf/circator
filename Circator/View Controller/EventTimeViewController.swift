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

/// initializations of these variables creates offsets so plots of event transitions are square waves
private let stWorkout = 0.0
private let stSleep = 0.33
private let stFast = 0.66
private let stEat = 1.0

func valueOfCircadianEvent(e: CircadianEvent) -> Double {
    switch e {
    case .Meal:
        return stEat

    case .Fast:
        return stFast

    case .Exercise:
        return stWorkout

    case .Sleep:
        return stSleep
    }
}

private let summaryFontSize = ScreenManager.sharedInstance.eventTimeViewSummaryFontSize()
private let plotFontSize = ScreenManager.sharedInstance.eventTimeViewPlotFontSize()

/**
 This class is the controller for the third view from the dashboard.  The ability to see the circadian aspect (think circator) of daily behavior is a key survey item that we want to capture. The user should be able to readily enter their exercise sleep and meal-times into the data store via this view.  In addition the square-wave plot gives a visual representation of the last 24-hours.  Reinforing that representation is the three numbers reflecting the maximum fasting time, the time since last meal, and the total time spent eating.
 
 - note: this requires pulling history from HealthKit and integrating over time windows
 - remark: st=start and en=end as abbreviations on events, Ty=Type, epsilon needed to avoid diagonal lines / overlapping events
 */
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

        chart.yLabels = [Float(stWorkout), Float(stSleep), Float(stFast), Float(stEat)]
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

        /// Fetch all sleep and workout data since yesterday, and then aggregate sleep, exercise and meal events.
        let yesterday = 1.days.ago
        let startDate = yesterday

        HealthManager.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
            Async.main {
                guard error == nil else {
                    log.error("Failed to fetch circadian events: \(error)")
                    return
                }

                self.mealChart.removeSeries()

                if intervals.isEmpty {
                    let series = ChartSeries(data: [(x: 0.0, y: stFast), (x: 24.0, y: stFast)])
                    series.area = true
                    series.color = .whiteColor()
                    self.mealChart.addSeries(series)

                    self.fastingLabel.text = "N/A"
                    self.eatingLabel.text  = "N/A"
                    self.lastAteLabel.text = "N/A"
                } else {
                    let vals = intervals.map { e in (x: e.0.timeIntervalSinceDate(startDate) / 3600.0, y: valueOfCircadianEvent(e.1)) }
                    let series = ChartSeries(data: vals)
                    series.area = true
                    series.color = .whiteColor()
                    self.mealChart.addSeries(series)

                    // Calculate event statistics. The accumulator is:
                    // i. total eating time
                    // ii. last eating time
                    // iii. max fasting window
                    // iv. previous event
                    // v. a bool indicating whether the current event starts an interval
                    // vi. the accumulated fasting window
                    // vii. a bool indicating if we are in an accumulating fasting interval
                    let szst : (Double, Double, Double, IEvent!, Bool, Double, Bool) = (0.0, 0.0, 0.0, nil, true, 0.0, false)
                    let stats = vals.filter { $0.0 >= yesterday.timeIntervalSinceDate(startDate) }.reduce(szst, combine: { (acc, e) in
                        var nacc = acc
                        let (iStart, prevFast) = (acc.4, acc.6)
                        let fast = e.1 == stSleep || e.1 == stFast || e.1 == stWorkout

                        if !iStart {
                            let duration = e.0 - acc.3.0
                            if prevFast && fast {
                                nacc.5 += duration
                                nacc.2 = nacc.2 > nacc.5 ? nacc.2 : nacc.5
                            } else if fast {
                                nacc.5 = duration
                                nacc.2 = nacc.2 > nacc.5 ? nacc.2 : nacc.5
                            } else if e.1 == stEat {
                                nacc.0 += duration
                            }
                        } else {
                            nacc.6 = acc.3 == nil ? false : (acc.3.1 == stSleep || acc.3.1 == stFast || acc.3.1 == stWorkout)
                        }
                        nacc.1 = e.1 == stEat ? e.0 : nacc.1
                        nacc.3 = e
                        nacc.4 = !iStart
                        return nacc
                    })

                    let today = NSDate().startOf(.Day, inRegion: Region())
                    let lastAte : NSDate? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds )

                    let fastingHrs = Int(floor(stats.2))
                    let fastingMins = (today + Int(round((stats.2 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
                    self.fastingLabel.text = "\(fastingHrs):\(fastingMins)"

                    self.eatingLabel.text  = (today + Int(stats.0 * 3600.0).seconds).toString(DateFormat.Custom("HH:mm"))!
                    self.lastAteLabel.text = lastAte == nil ? "N/A" : lastAte!.toString(DateFormat.Custom("HH:mm"))!
                }
                self.mealChart.setNeedsDisplay()
                Answers.logContentViewWithName("MealTimes",
                    contentType: HKWorkoutType.workoutType().identifier,
                    contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                    customAttributes: nil)
            }
        }
    }
}