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
import Fabric
import Crashlytics
import SwiftDate
import Async
import Pages

/**
 Controls display of temporal plots and summary statistics.
 
 - note: LineChart and BubbleChart types used
 */
class PlotViewController: UIViewController, ChartViewDelegate {

    var pageIndex  : Int! = nil
    var loadIndex  : Int! = nil
    var errorIndex : Int! = nil

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
        chart.rightAxis.enabled = false
        chart.doubleTapToZoomEnabled = false
        chart.leftAxis.startAtZeroEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.legend.enabled = false
        chart.descriptionText = ""
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        return chart
    }()

    lazy var summaryChart: BubbleChartView = {
        let chart = BubbleChartView()
        chart.delegate = self
        chart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        chart.rightAxis.enabled = false
        chart.doubleTapToZoomEnabled = false
        chart.leftAxis.startAtZeroEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.legend.enabled = false
        chart.descriptionText = ""
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        return chart
    }()

    var spec: PlotSpec!

    var sampleType: HKSampleType! {
        didSet {
            navigationItem.title = sampleType.displayText!
            Async.main {
                Async.background {
                    let spec = self.spec ?? .PlotPredicate(nil)
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

                    case let .PlotPredicate(predicate):
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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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

        let constraints: [NSLayoutConstraint] = [
            historyLabel.leadingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.leadingAnchor),
            historyLabel.trailingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.trailingAnchor),
            historyLabel.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 12),
            historyChart.topAnchor.constraintEqualToAnchor(historyLabel.bottomAnchor, constant: 8),
            historyChart.leadingAnchor.constraintEqualToAnchor(historyLabel.leadingAnchor),
            historyChart.trailingAnchor.constraintEqualToAnchor(historyLabel.trailingAnchor),
            summaryLabel.leadingAnchor.constraintEqualToAnchor(historyChart.layoutMarginsGuide.leadingAnchor),
            summaryLabel.trailingAnchor.constraintEqualToAnchor(historyChart.layoutMarginsGuide.trailingAnchor),
            summaryLabel.topAnchor.constraintEqualToAnchor(historyChart.bottomAnchor, constant: 24),
            summaryChart.topAnchor.constraintEqualToAnchor(summaryLabel.bottomAnchor, constant: 8),
            summaryChart.leadingAnchor.constraintEqualToAnchor(summaryLabel.leadingAnchor),
            summaryChart.trailingAnchor.constraintEqualToAnchor(summaryLabel.trailingAnchor),
        ]

        scrollView.addConstraints(constraints)
        historyChart.translatesAutoresizingMaskIntoConstraints = false
        historyChart.heightAnchor.constraintEqualToConstant(200).active = true

        summaryChart.translatesAutoresizingMaskIntoConstraints = false
        summaryChart.heightAnchor.constraintEqualToConstant(200).active = true

        let svconstraints : [NSLayoutConstraint] = [
            scrollView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            scrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            scrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
        ]
        view.addConstraints(svconstraints)
    }

    func plotChart(analyzer: PlotDataAnalyzer) {
        analyzer.dataSetConfigurator = { dataSet in
            dataSet.drawCircleHoleEnabled = true
            dataSet.circleRadius = 7
            dataSet.valueFormatter = SampleFormatter.numberFormatter
            dataSet.circleHoleColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!
            dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!]
            dataSet.lineWidth = 2
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
