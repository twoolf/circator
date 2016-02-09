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
import Charts
import Crashlytics
import SwiftDate
import Async

class MealTimeViewController : UIViewController, ChartViewDelegate {
    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var mealChart: LineChartView = {
        let chart = LineChartView()
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self

        chart.descriptionText = ""
        chart.legend.enabled = false
        chart.rightAxis.enabled = false
        chart.doubleTapToZoomEnabled = false
        chart.leftAxis.startAtZeroEnabled = true
        chart.drawGridBackgroundEnabled = false

        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        return chart
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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
            mealChart.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        ]
        view.addConstraints(mcConstraints)
    }

    func reloadData() {
        HealthManager.sharedManager.fetchPreparationAndRecoveryWorkout { (samples, error) -> Void in
            Async.main {
                UINotifications.genericMsg(self, msg: "Count/error: \(samples.count) \(error == nil)")

                guard error == nil else {
                    log.error("Failed to fetch meal times: \(error)")
                    return
                }

                if samples.isEmpty {
                    self.mealChart.data = nil
                } else {
                    let today = NSDate().startOf(.Day, inRegion: Region())

                    let lvals = samples.reduce([], combine: { (acc, s) in
                                    return acc + [s.startDate.timeIntervalSinceDate(today), s.startDate.timeIntervalSinceDate(today)]
                                })

                    let rvals = samples.reduce([], combine: { (acc, s) in return acc + [1.0, 1.0] })

                    let xVals = lvals.map { t in return String(t) }
                    let yVals = (0..<rvals.count).map { i in return ChartDataEntry(value: rvals[i], xIndex: i) }

                    let dataSet = LineChartDataSet(yVals: yVals, label: "")
                    dataSet.valueFormatter = SampleFormatter.numberFormatter
                    dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!]
                    dataSet.lineWidth = 2
                    dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!

                    self.mealChart.data = LineChartData(xVals: xVals, dataSet: dataSet)
                }
                self.mealChart.notifyDataSetChanged()
                BehaviorMonitor.sharedInstance.setValue("MealTimes", contentType: HKWorkoutType.workoutType().identifier)
            }
        }
    }
}