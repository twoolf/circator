//  MealTimeViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MetabolicCompassKit
import Crashlytics
import SwiftDate
import Async
import SwiftChart
import MCCircadianQueries

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

        MCHealthManager.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
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
                    // Create an array of circadian events for charting as x-y values
                    // for the charting library.
                    //
                    // Each input event is a pair of NSDate and metabolic state (i.e.,
                    // whether you are eating/fasting/sleeping/exercising).
                    //
                    // Conceptually, circadian events are intervals with a starting date
                    // and ending date. We represent these endpoints (i.e., starting vs ending)
                    // as consecutive array elements. For example the following array represents
                    // an eating event (as two array elements) following by a sleeping event
                    // (also as two array elements):
                    //
                    // [('2016-01-01 20:00', .Meal), ('2016-01-01 20:45', .Meal),
                    //  ('2016-01-01 23:00', .Sleep), ('2016-01-02 07:00', .Sleep)]
                    //
                    // In the output, x-values indicate when the event occurred relative
                    // to a date 24 hours ago (i.e., 24-x hours ago)
                    // That is, an x-value of:
                    // a) 1.5 indicates the event occurred 22.5 hours ago
                    // b) 3.0 indicates the event occurred 21.0 hours ago
                    //
                    // y-values are a double value indicating the y-offset corresponding
                    // to a eat/sleep/fast/exercise value where:
                    // workout = 0.0, sleep = 0.33, fast = 0.66, eat = 1.0
                    //
                    let vals : [(x: Double, y: Double)] = intervals.map { event in
                      let startTimeInFractionalHours = event.0.timeIntervalSinceDate(startDate) / 3600.0
                      let metabolicStateAsDouble = valueOfCircadianEvent(event.1)
                      return (x: startTimeInFractionalHours, y: metabolicStateAsDouble)
                    }
                    let series = ChartSeries(data: vals)
                    series.area = true
                    series.color = .whiteColor()
                    self.mealChart.addSeries(series)

                    // Calculate circadian event statistics based on the above array of events.
                    // Again recall that this is an array of event endpoints, where each pair of
                    // consecutive elements defines a single event interval.
                    //
                    // This aggregates/folds over the array, updating an accumulator with the following fields:
                    //
                    // i. a running sum of eating time
                    // ii. the last eating time
                    // iii. the max fasting window
                    //
                    // Computing these statistics require information from the previous events in the array,
                    // so we also include the following fields in the accumulator:
                    //
                    // iv. the previous event
                    // v. a bool indicating whether the current event starts an interval
                    // vi. the accumulated fasting window
                    // vii. a bool indicating if we are in an accumulating fasting interval
                    //
                    let initialAccumulator : (Double, Double, Double, IEvent!, Bool, Double, Bool) =
                      (0.0, 0.0, 0.0, nil, true, 0.0, false)

                    let stats = vals.filter { $0.0 >= yesterday.timeIntervalSinceDate(startDate) }
                                    .reduce(initialAccumulator, combine:
                    { (acc, event) in
                        // Named accumulator components
                        var newEatingTime = acc.0
                        let lastEatingTime = acc.1
                        var maxFastingWindow = acc.2
                        var currentFastingWindow = acc.5

                        // Named components from the current event.
                        let eventEndpointDate = event.0
                        let eventMetabolicState = event.1

                        // Information from previous event endpoint.
                        let prevEvent = acc.3
                        let prevEndpointWasIntervalStart = acc.4
                        let prevEndpointWasIntervalEnd = !acc.4
                        var prevStateWasFasting = acc.6

                        // Define the fasting state as any non-eating state
                        let isFasting = eventMetabolicState != stEat

                        // If this endpoint starts a new event interval, update the accumulator.
                        if prevEndpointWasIntervalEnd {
                            let prevEventEndpointDate = prevEvent.0
                            let duration = eventEndpointDate - prevEventEndpointDate

                            if prevStateWasFasting && isFasting {
                                // If we were fasting in the previous event, and are also fasting in this
                                // event, we extend the currently ongoing fasting period.

                                // Increment the current fasting window.
                                currentFastingWindow += duration

                                // Revise the max fasting window if the current fasting window is now larger.
                                maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow

                            } else if isFasting {
                                // Otherwise if we started fasting in this event, we reset
                                // the current fasting period.

                                // Reset the current fasting window
                                currentFastingWindow = duration

                                // Revise the max fasting window if the current fasting window is now larger.
                                maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow

                            } else if eventMetabolicState == stEat {
                                // Otherwise if we are eating, we increment the total time spent eating.
                                newEatingTime += duration
                            }
                        } else {
                            prevStateWasFasting = prevEvent == nil ? false : prevEvent.1 != stEat
                        }

                        let newLastEatingTime = eventMetabolicState == stEat ? eventEndpointDate : lastEatingTime

                        // Return a new accumulator.
                        return (
                          newEatingTime,
                          newLastEatingTime,
                          maxFastingWindow,
                          event,
                          prevEndpointWasIntervalEnd,
                          currentFastingWindow,
                          prevStateWasFasting
                        )
                    })

                    let today = NSDate().startOf(.Day, inRegion: Region())
                    let lastAte : NSDate? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds )

                    let fastingHrs = Int(floor(stats.2))
                    let fastingMins = (today + Int(round((stats.2 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
                    self.fastingLabel.text = "\(fastingHrs):\(fastingMins)"
                    print("in EventTimeViewController, fasting hours: \(fastingHrs)")
                    print("   and fasting minutes: \(fastingMins)")
//                    MetricsStore.sharedInstance.fastingTime = fastingHrs
                    

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
