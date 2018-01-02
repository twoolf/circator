//
//  PlotViewController.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/23/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts
import HealthKit
import MetabolicCompassKit
import Crashlytics
import SwiftDate
import Async
import Pages
import MCCircadianQueries

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
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
        label.textColor = Theme.universityDarkTheme.backgroundColor
        label.textAlignment = .center
        label.text = NSLocalizedString("Personal History", comment: "Plot view section title label")
        return label
    }()

    lazy var summaryLabel: UILabel = {
        let label: UILabel = UILabel()
        let number = 4
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
        label.textColor = Theme.universityDarkTheme.backgroundColor
        label.textAlignment = .center
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
//        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
//        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
//        chart.leftAxis.startAtZeroEnabled = false
//        chart.axisMinimum = false
        chart.leftAxis.axisMinimum = 0.0
        chart.rightAxis.enabled = false

        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.xAxis.labelPosition = .bottom
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

//        chart.leftAxis.startAtZeroEnabled = false
//        chart.leftAxis.axisMinimum = false
        chart.leftAxis.axisMinimum = 0.0
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
//        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.rightAxis.enabled = false

        chart.xAxis.labelPosition = .bottom
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
                self.navigationItem.title = self.attrNameOfSpec(spec: spec, name: self.sampleType.displayText!)
                Async.background {
                    switch spec {
                    case .PlotFasting:
                        MCHealthManager.sharedManager.fetchMaxFastingTimes { (aggregates, error) -> Void in
                            guard error == nil else {
                                self.showError()
                                return
                            }
                            self.plotValues(values: aggregates)
                            Answers.logContentView(withName: "Plot",
                                contentType: self.sampleType.identifier,
//                                contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                                contentId: Date().string(),
                                customAttributes: nil)
                        }

                    case let .PlotPredicate(_, predicate):
                        MCHealthManager.sharedManager.fetchStatisticsOfType(self.sampleType, predicate: predicate) { (results, error) -> Void in
                            guard error == nil else {
                                self.showError()
                                return
                            }
                            self.plotResults(results: results)
                            Answers.logContentView(withName: "Plot",
                                contentType: self.sampleType.identifier,
//                                contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                                contentId: Date().string(),
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//        NotificationCenter.defaultCenter.addObserver(self, selector: #selector(PlotViewController.deviceDidRotate(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentView(withName: "Plot",
            contentType: sampleType.identifier,
//            contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            contentId: Date().string(),
            customAttributes: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
        if UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }

        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
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
        refreshConstraints(withRemove: false, asPortrait: true)
    }

    func refreshConstraints(withRemove: Bool, asPortrait: Bool) {
        if withRemove {
            scrollView.removeConstraints(hcConstraints)
            scrollView.removeConstraints(scConstraints)
            view.removeConstraints(svConstraints)
        }

        hcConstraints = [
            historyLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            historyLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            historyLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            historyChart.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 8),
            historyChart.leadingAnchor.constraint(equalTo: historyLabel.leadingAnchor),
            historyChart.trailingAnchor.constraint(equalTo: historyLabel.trailingAnchor),
        ]

        scrollView.addConstraints(hcConstraints)

        if asPortrait {
            summaryLabel.isHidden = false
            summaryChart.isHidden = false

            scConstraints = [
                summaryLabel.leadingAnchor.constraint(equalTo: historyChart.layoutMarginsGuide.leadingAnchor),
                summaryLabel.trailingAnchor.constraint(equalTo: historyChart.layoutMarginsGuide.trailingAnchor),
                summaryLabel.topAnchor.constraint(equalTo: historyChart.bottomAnchor, constant: 24),
                summaryChart.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 8),
                summaryChart.leadingAnchor.constraint(equalTo: summaryLabel.leadingAnchor),
                summaryChart.trailingAnchor.constraint(equalTo: summaryLabel.trailingAnchor),
            ]

            scrollView.addConstraints(scConstraints)

            historyChart.translatesAutoresizingMaskIntoConstraints = false
            historyChart.heightAnchor.constraint(equalToConstant: 200).isActive = true

            summaryChart.translatesAutoresizingMaskIntoConstraints = false
            summaryChart.heightAnchor.constraint(equalToConstant: 200).isActive = true
        } else {
            summaryLabel.isHidden = true
            summaryChart.isHidden = true
        }

        svConstraints = [
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        view.addConstraints(svConstraints)
    }

    func deviceDidRotate(notification: NSNotification) {
        let currentOrientation = UIDevice.current.orientation
        if !UIDeviceOrientationIsValidInterfaceOrientation(currentOrientation) {
            return
        }

        let isLandscape = UIDeviceOrientationIsLandscape(currentOrientation)
        let isPortrait = UIDeviceOrientationIsPortrait(currentOrientation)

        if isLandscape {
            refreshConstraints(withRemove: true, asPortrait: false)
        } else if isPortrait {
            refreshConstraints(withRemove: false, asPortrait: true)
        }
    }

    func plotChart(analyzer: PlotDataAnalyzer) {
        analyzer.dataSetConfigurator = { dataSet in
            dataSet.circleRadius = 7
            dataSet.lineWidth = 2
//            dataSet.valueFormatter = SampleFormatter.numberFormatter
            dataSet.circleHoleColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.1)!
            //dataSet.circleColors =  [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!]
            dataSet.circleColors = [Theme.universityDarkTheme.backgroundColor]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.1)!]
            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.1)!
        }
        let ldata = analyzer.lineChartData
        let sdata = analyzer.bubbleChartData

 /*       if ldata.yValCount == 0 || sdata.yValCount == 0 {
            self.showError()
        } else {
            self.historyChart.data = ldata
            self.historyChart.data?.setValueTextColor(Theme.universityDarkTheme.backgroundColor)
            self.historyChart.data?.setValueFont(UIFont.systemFont(ofSize: 10, weight: UIFontWeightThin))

            self.summaryChart.data = sdata
            self.summaryChart.data?.setValueTextColor(Theme.universityDarkTheme.backgroundColor)
            self.summaryChart.data?.setValueFont(UIFont.systemFont(ofSize: 10, weight: UIFontWeightThin))

            self.showChart()
        }  */
    }

    func plotResults(results: [MCSample]) {
        let analyzer = PlotDataAnalyzer(sampleType: self.sampleType, samples: results)
        plotChart(analyzer: analyzer)
    }

    func plotValues(values: [(Date, Double)]) {
        let analyzer = PlotDataAnalyzer(sampleType: self.sampleType, values: values)
        plotChart(analyzer: analyzer)
    }

    func showError() {
        Async.main {
            if let idx = self.errorIndex, let pv = self.parent as? PagesController {
                pv.goTo(idx)
            }
        }
    }

    func showChart() {
        Async.main {
            if let idx = self.pageIndex, let pv = self.parent as? PagesController {
                pv.goTo(idx)
            }
        }
    }
}
