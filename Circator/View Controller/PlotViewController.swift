//
//  PlotViewController.swift
//  Circator
//
//  Created by Sihao Lu on 10/23/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts
import HealthKit
import CircatorKit
import Crashlytics
import SwiftDate
import Async
import Pages

/**
 This class controls the display of our temporal plots and of our summary statistics.  The ability of the user to see the comparison of their data over time nicely complements what is present in HealthKit and is meant to help keep the participants motiviated into making positive metabolic changes.
 
 - note: LineChart and BubbleChart types used
 */
class PlotViewController: UIViewController, ChartViewDelegate {

    var pageIndex  : Int! = nil
    var loadIndex  : Int! = nil
    var errorIndex : Int! = nil

    var hcConstraints: [NSLayoutConstraint] = []
    var scConstraints: [NSLayoutConstraint] = []
    var svConstraints: [NSLayoutConstraint] = []

    lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: self.view.bounds)
        return view
    }()

    lazy var historyLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.backgroundColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Personal History", comment: "Plot view section title label")
        return label
    }()

    lazy var summaryLabel: UILabel = {
        let label: UILabel = UILabel()
        let number = 4
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.backgroundColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("20% Increments of your Data", comment: "Summary view section title label")
        return label
    }()

    lazy var historyChart: LineChartView = {
        let chart = LineChartView()
        chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        chart.delegate = self
        chart.drawBordersEnabled = true
        chart.drawGridBackgroundEnabled = false
        chart.descriptionText = ""
        chart.doubleTapToZoomEnabled = false

        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.leftAxis.startAtZeroEnabled = false
        chart.rightAxis.enabled = false

        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor

        chart.legend.enabled = false
        return chart
    }()

    lazy var summaryChart: BubbleChartView = {
        let chart = BubbleChartView()
        chart.delegate = self
        chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        chart.descriptionText = ""
        chart.drawBordersEnabled = true
        chart.drawGridBackgroundEnabled = false
        chart.doubleTapToZoomEnabled = false

        chart.leftAxis.startAtZeroEnabled = false
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.rightAxis.enabled = false

        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor

        chart.legend.enabled = false
        return chart
    }()

    var spec: PlotSpec!

    var sampleType: HKSampleType! {
        didSet {
            Async.main {
                let spec = self.spec ?? .PlotPredicate("", nil)
                self.navigationItem.title = self.attrNameOfSpec(spec, name: self.sampleType.displayText!)
                Async.background {
                    switch spec {
                    case .PlotFasting:
                        HealthManager.sharedManager.fetchMaxFastingTimes { (aggregates, error) -> Void in
                            guard error == nil else {
                                self.showError()
                                return
                            }
                            self.plotValues(aggregates)
                            Answers.logContentViewWithName("Plot",
                                contentType: self.sampleType.identifier,
                                contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                                customAttributes: nil)
                        }

                    case let .PlotPredicate(_, predicate):
                        HealthManager.sharedManager.fetchStatisticsOfType(self.sampleType, predicate: predicate) { (results, error) -> Void in
                            guard error == nil else {
                                self.showError()
                                return
                            }
                            self.plotResults(results)
                            Answers.logContentViewWithName("Plot",
                                contentType: self.sampleType.identifier,
                                contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                                customAttributes: nil)
                        }
                    }
                }
            }
        }
    }

    func attrNameOfSpec(spec: PlotSpec, name: String) -> String {
        switch spec {
        case .PlotFasting:
            return "Fasting"
        case .PlotPredicate(_, nil):
            return name
        case let .PlotPredicate(nm, _):
            return nm
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)

        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceDidRotate:", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("Plot",
            contentType: sampleType.identifier,
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self)
        if UIDevice.currentDevice().generatesDeviceOrientationNotifications {
            UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
        }

        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func configureViews() {
        scrollView.backgroundColor = Theme.universityDarkTheme.foregroundColor

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        historyChart.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyLabel)
        scrollView.addSubview(historyChart)

        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryChart.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(summaryLabel)
        scrollView.addSubview(summaryChart)
        refreshConstraints(false, asPortrait: true)
    }

    func refreshConstraints(withRemove: Bool, asPortrait: Bool) {
        if withRemove {
            scrollView.removeConstraints(hcConstraints)
            scrollView.removeConstraints(scConstraints)
            view.removeConstraints(svConstraints)
        }

        hcConstraints = [
            historyLabel.leadingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.leadingAnchor),
            historyLabel.trailingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.trailingAnchor),
            historyLabel.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 12),
            historyChart.topAnchor.constraintEqualToAnchor(historyLabel.bottomAnchor, constant: 8),
            historyChart.leadingAnchor.constraintEqualToAnchor(historyLabel.leadingAnchor),
            historyChart.trailingAnchor.constraintEqualToAnchor(historyLabel.trailingAnchor),
        ]

        scrollView.addConstraints(hcConstraints)

        if asPortrait {
            summaryLabel.hidden = false
            summaryChart.hidden = false

            scConstraints = [
                summaryLabel.leadingAnchor.constraintEqualToAnchor(historyChart.layoutMarginsGuide.leadingAnchor),
                summaryLabel.trailingAnchor.constraintEqualToAnchor(historyChart.layoutMarginsGuide.trailingAnchor),
                summaryLabel.topAnchor.constraintEqualToAnchor(historyChart.bottomAnchor, constant: 24),
                summaryChart.topAnchor.constraintEqualToAnchor(summaryLabel.bottomAnchor, constant: 8),
                summaryChart.leadingAnchor.constraintEqualToAnchor(summaryLabel.leadingAnchor),
                summaryChart.trailingAnchor.constraintEqualToAnchor(summaryLabel.trailingAnchor),
            ]

            scrollView.addConstraints(scConstraints)

            historyChart.translatesAutoresizingMaskIntoConstraints = false
            historyChart.heightAnchor.constraintEqualToConstant(200).active = true

            summaryChart.translatesAutoresizingMaskIntoConstraints = false
            summaryChart.heightAnchor.constraintEqualToConstant(200).active = true
        } else {
            summaryLabel.hidden = true
            summaryChart.hidden = true
        }

        svConstraints = [
            scrollView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            scrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            scrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
        ]
        view.addConstraints(svConstraints)
    }

    func deviceDidRotate(notification: NSNotification) {
        let currentOrientation = UIDevice.currentDevice().orientation
        if !UIDeviceOrientationIsValidInterfaceOrientation(currentOrientation) {
            return
        }

        let isLandscape = UIDeviceOrientationIsLandscape(currentOrientation)
        let isPortrait = UIDeviceOrientationIsPortrait(currentOrientation)

        if isLandscape {
            refreshConstraints(true, asPortrait: false)
        } else if isPortrait {
            refreshConstraints(false, asPortrait: true)
        }
    }

    func plotChart(analyzer: PlotDataAnalyzer) {
        analyzer.dataSetConfigurator = { dataSet in
            dataSet.circleRadius = 7
            dataSet.lineWidth = 2
            dataSet.valueFormatter = SampleFormatter.numberFormatter
            dataSet.circleHoleColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!
            //dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!]
            dataSet.circleColors = [Theme.universityDarkTheme.backgroundColor]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!]
            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!
        }
        let ldata = analyzer.lineChartData
        let sdata = analyzer.bubbleChartData

        if ldata.yValCount == 0 || sdata.yValCount == 0 {
            self.showError()
        } else {
            self.historyChart.data = ldata
            self.historyChart.data?.setValueTextColor(Theme.universityDarkTheme.backgroundColor)
            self.historyChart.data?.setValueFont(UIFont.systemFontOfSize(10, weight: UIFontWeightThin))

            self.summaryChart.data = sdata
            self.summaryChart.data?.setValueTextColor(Theme.universityDarkTheme.backgroundColor)
            self.summaryChart.data?.setValueFont(UIFont.systemFontOfSize(10, weight: UIFontWeightThin))

            self.showChart()
        }
    }

    func plotResults(results: [MCSample]) {
        let analyzer = PlotDataAnalyzer(sampleType: self.sampleType, samples: results)
        plotChart(analyzer)
    }

    func plotValues(values: [(NSDate, Double)]) {
        let analyzer = PlotDataAnalyzer(sampleType: self.sampleType, values: values)
        plotChart(analyzer)
    }

    func showError() {
        Async.main {
            if let idx = self.errorIndex, pv = self.parentViewController as? PagesController {
                pv.goTo(idx)
            }
        }
    }

    func showChart() {
        Async.main {
            if let idx = self.pageIndex, pv = self.parentViewController as? PagesController {
                pv.goTo(idx)
            }
        }
    }
}
