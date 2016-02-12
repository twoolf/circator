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

class MealTimeViewController : UIViewController {
    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var fastingDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Max Daily Fasting", comment: "Max Daily Fasting")
        return label
    }()

    lazy var fastingLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Max Daily Fasting")
        return label
    }()

    lazy var eatingDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Daily Eating", comment: "Daily Eating")
        return label
    }()

    lazy var eatingLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Daily Eating")
        return label
    }()

    lazy var lastAteDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Last Ate", comment: "Last Ate")
        return label
    }()

    lazy var lastAteLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
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
        chart.labelFont = UIFont.systemFontOfSize(12)

        chart.xLabels = [0.0, 6.0, 12.0, 18.0, 24.0]
        chart.xLabelsTextAlignment = .Left
        chart.xLabelsFormatter = { (labelIndex: Int, labelValue: Float) -> String in
            let d = 24.hours.ago + (Int(labelValue)).hours
            return d.toString(DateFormat.Custom("HH:mm"))!
        }

        chart.yLabels = [0.0, 1.0]
        chart.yLabelsOnRightSide = true
        chart.yLabelsFormatter = { (labelIndex: Int, labelValue: Float) -> String in
            switch labelIndex {
            case 0:
                return "Fasting"
            case 1:
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
            mealChart.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -100)
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
        HealthManager.sharedManager.fetchPreparationAndRecoveryWorkout(true, beginDate: 24.hours.ago) { (samples, error) -> Void in
            Async.main {
                guard error == nil else {
                    log.error("Failed to fetch meal times: \(error)")
                    return
                }

                self.mealChart.removeSeries()

                if samples.isEmpty {
                    let series = ChartSeries(data: [(x: 0.0, y: 0.0), (x: 24.0, y:0.0)])
                    series.area = true
                    series.color = .whiteColor()
                    self.mealChart.addSeries(series)

                    self.fastingLabel.text = "N/A"
                    self.eatingLabel.text  = "N/A"
                    self.lastAteLabel.text = "N/A"
                } else {
                    let epsilon = 1.seconds
                    let yesterday = 24.hours.ago

                    let svals : [(x: Double, y: Double)] =
                        samples.reduce([], combine: { (acc, s) in
                            let st = s.startDate
                            let en = s.endDate
                            let points = [(st-epsilon, 0.0), (st, 1.0), (en, 1.0), (en+epsilon, 0.0)]
                            return acc + (points.map { (a,b) in return (x: a.timeIntervalSinceDate(yesterday) / 3600.0, y: b) })
                        })
                    let vals = [(x: 0.0, y: 0.0)] + svals + [(x: 24.0, y: 0.0)]
                    let series = ChartSeries(data: vals)
                    series.area = true
                    series.color = .whiteColor()
                    self.mealChart.addSeries(series)

                    var fdacc : [Double] = []
                    let acc = samples.reduce((0.0, 0.0), combine: { (acc, s) in
                        let st = s.startDate
                        let en = s.endDate
                        let fdelta = st.timeIntervalSinceReferenceDate - (acc.1 == 0.0 ? 24.hours.ago.timeIntervalSinceReferenceDate : acc.1)
                        let edelta = en.timeIntervalSinceDate(st)
                        fdacc.append(fdelta)
                        return (acc.0 + edelta, en.timeIntervalSinceReferenceDate)
                    })

                    let today = NSDate().startOf(.Day, inRegion: Region())
                    let mdf = fdacc.maxElement { (a,b) in return a < b }
                    self.fastingLabel.text = (today + Int(mdf!).seconds).toString(DateFormat.Custom("HH:mm"))!
                    self.eatingLabel.text  = (today + Int(acc.0).seconds).toString(DateFormat.Custom("HH:mm"))!
                    self.lastAteLabel.text = NSDate(timeIntervalSinceReferenceDate: acc.1).toString(DateFormat.Custom("HH:mm"))!
                }
                self.mealChart.setNeedsDisplay()
                BehaviorMonitor.sharedInstance.setValue("MealTimes", contentType: HKWorkoutType.workoutType().identifier)
            }
        }
    }
}