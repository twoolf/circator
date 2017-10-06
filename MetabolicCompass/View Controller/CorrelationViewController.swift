//
//  CorrelationViewController.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/29/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.    
//

import UIKit
import Charts
import MetabolicCompassKit
import HealthKit
import Crashlytics
import SwiftDate
import Pages
import Async
import MCCircadianQueries

/**
 This class controls thedisplay of correlation plots (2nd button from left on bottom of the screen).  The type of correlation that is used will show two curves (with different y-values) moving along in a similar way if they are correlated (e.g. both increasing linearly).  If only one variable is increasing, while the other is seen to fluctuate throughout that time, then the two variables are most likely not correlated.
 
 - note: The 1st metric is organized from small to large, while the 2nd is plotted on the same temporal (x-axis) scale, so correlations are both rising from small to large
 */
class CorrelationViewController: UIViewController, ChartViewDelegate {

    var pageIndex  : Int! = nil
    var loadIndex  : Int! = nil
    var errorIndex : Int! = nil

    lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: self.view.bounds)
        return view
    }()
    
    lazy var correlationLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold)
        label.textColor = Theme.universityDarkTheme.backgroundColor
        label.textAlignment = .center
        label.text = NSLocalizedString("Attribute 2 Relative to Increasing Attribute 1", comment: "Plot view section title label")
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    
    
    lazy var correlationChart: LineChartView = {
        let chart = LineChartView()
        chart.delegate = self
//        chartDescription.text = ""
        chart.drawBordersEnabled = true
        chart.doubleTapToZoomEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
//        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.leftAxis.valueFormatter = DefaultAxisValueFormatter()
//        chart.leftAxis.startAtZeroEnabled = false
        chart.leftAxis.axisMinimum = 0.0
        chart.rightAxis.enabled = true
//        chart.rightAxis.startAtZeroEnabled = false
        chart.rightAxis.axisMinimum = 0.0
        chart.rightAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.rightAxis.valueFormatter = DefaultAxisValueFormatter()
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.legend.position = .belowChartCenter
        chart.legend.form = .circle
        chart.legend.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        chart.legend.textColor = Theme.universityDarkTheme.backgroundColor
        return chart
    }()
 
    var lspec: PlotSpec!
    var rspec: PlotSpec!

    var sampleTypes: [HKSampleType]! {
        didSet {
            Async.main {
                let lsp = self.lspec ?? .PlotPredicate("", nil)
                let rsp = self.rspec ?? .PlotPredicate("", nil)

                let attr1 = self.attrNameOfSpec(lsp, name: HMConstants.sharedInstance.healthKitShortNames[self.sampleTypes[0].identifier]!)
                let attr2 = self.attrNameOfSpec(rsp, name: HMConstants.sharedInstance.healthKitShortNames[self.sampleTypes[1].identifier]!)
                self.correlationLabel.text = NSLocalizedString("\(attr2) Relative to Increasing \(attr1)", comment: "Plot view section title label")

                Async.background {
                    switch (lsp, rsp) {
                    case (.PlotFasting, .PlotFasting):
                        MCHealthManager.sharedManager.fetchMaxFastingTimes { (aggregates, error) in
                            guard (error == nil) && !aggregates.isEmpty else {
                                Async.main {
                                    if let idx = self.errorIndex, let pv = self.parent as? PagesController {
                                        pv.goTo(idx)
                                    }
                                }
                                return
                            }
                            self.correlateFastingSelf(aggregates)
                        }

                    case let (.PlotFasting, .PlotPredicate(_, predicate)):
                        MCHealthManager.sharedManager.correlateWithFasting(true, type: self.sampleTypes[1], predicate: predicate) {
                            (zipped, error) -> Void in
                            guard (error == nil) && !zipped.isEmpty else {
                                Async.main {
                                    if let idx = self.errorIndex, let pv = self.parent as? PagesController {
                                        pv.goTo(idx)
                                    }
                                }
                                return
                            }
                            self.correlateFasting(zipped)
                        }

                    case let (.PlotPredicate(_, predicate), .PlotFasting):
                        MCHealthManager.sharedManager.correlateWithFasting(false, type: self.sampleTypes[0], predicate: predicate) {
                            (zipped, error) -> Void in
                            guard (error == nil) && !zipped.isEmpty else {
                                Async.main {
                                    if let idx = self.errorIndex, let pv = self.parent as? PagesController {
                                        pv.goTo(idx)
                                    }
                                }
                                return
                            }
                            self.correlateFasting(zipped, flip: true)
                        }

                    case let (.PlotPredicate(_, lpred), .PlotPredicate(_, rpred)):
                        MCHealthManager.sharedManager.correlateStatisticsOfType(self.sampleTypes[0], withType: self.sampleTypes[1], pred1: lpred!, pred2: rpred!) {
                            (stat1, stat2, error) -> Void in
                            guard (error == nil) && !(stat1.isEmpty || stat2.isEmpty) else {
                                Async.main {
                                    if let idx = self.errorIndex, let pv = self.parent as? PagesController {
                                        pv.goTo(idx)
                                    }
                                }
                                return
                            }
                            self.correlateSamplePair(stat1, stat2: stat2)
                        }
                    }
                }
            }
        }
    }

    func attrNameOfSpec(_ spec: PlotSpec, name: String) -> String {
        switch spec {
        case .PlotFasting:
            return "Fasting"
        case .PlotPredicate(_, nil):
            return name
        case let .PlotPredicate(nm, _):
            return nm
        }
    }

    func specLabels() -> [String] {
        let lsp = self.lspec ?? .PlotPredicate("", nil)
        let rsp = self.rspec ?? .PlotPredicate("", nil)
        return [attrNameOfSpec(lsp, name: sampleTypes[0].displayText!), attrNameOfSpec(rsp, name: sampleTypes[1].displayText!)]

    }
    func correlateSamplePair(_ stat1: [MCSample], stat2: [MCSample]) {
        let analyzer = CorrelationDataAnalyzer(labels: specLabels(), samples: [stat1, stat2])!
        self.plotCorrelate(analyzer)
    }

    func correlateFastingSelf(_ aggregates: [(Date, Double)]) {
        let analyzer = CorrelationDataAnalyzer(labels: specLabels(), values: [aggregates, aggregates])!
        self.plotCorrelate(analyzer)
    }

    func correlateFasting(_ zipped: [(Date, Double, MCSample)], flip: Bool = false) {
        let labels = specLabels()
        let flippedLabels = [labels[1], labels[0]]
        let analyzer = CorrelationDataAnalyzer(labels: flip ? flippedLabels : labels, zipped: zipped)!
        self.plotCorrelate(analyzer)
    }

    func plotCorrelate(_ analyzer: CorrelationDataAnalyzer) {
        let configurator: ((LineChartDataSet) -> Void)? = { dataSet in
            dataSet.drawCircleHoleEnabled = false
            dataSet.circleRadius = 6
            dataSet.valueFormatter = DefaultValueFormatter()
            dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.6)!]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.6)!]
            dataSet.lineWidth = 2
            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.6)!
            dataSet.axisDependency = .left
        }
        let configurator2: ((LineChartDataSet) -> Void)? = { dataSet in
            dataSet.drawCircleHoleEnabled = false
            dataSet.circleRadius = 6
//            dataSet.valueFormatter = SampleFormatter.numberFormatter
            dataSet.valueFormatter = DefaultValueFormatter()
            dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.9)!]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.9)!]
            dataSet.lineWidth = 2
            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(vibrancy: 0.9)!
            dataSet.axisDependency = .right
        }
        analyzer.dataSetConfigurators = [configurator, configurator2]
        let cdata = analyzer.correlationChartData
//        self.correlationChart.data = cdata.yValCount == 0 ? nil : cdata
        self.correlationChart.data?.setValueTextColor(Theme.universityDarkTheme.bodyTextColor)
        self.correlationChart.data?.setValueFont(UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.thin))

        Async.main {
            if let idx = self.pageIndex, let pv = self.parent as? PagesController {
                pv.goTo(idx)
            }
        }

        Answers.logContentView(withName: "Correlate",
            contentType: self.getSampleDescriptor(),
//            contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            contentId: Date().string(),
            customAttributes: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentView(withName: "Correlate",
            contentType: getSampleDescriptor(),
//            contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            contentId: Date().string(),
            customAttributes: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureViews() {
        scrollView.backgroundColor = Theme.universityDarkTheme.foregroundColor

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        correlationLabel.translatesAutoresizingMaskIntoConstraints = false
        correlationChart.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(correlationLabel)
        scrollView.addSubview(correlationChart)

        let constraints: [NSLayoutConstraint] = [
            correlationLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor),
            correlationLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor),
            correlationLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            correlationChart.topAnchor.constraint(equalTo: correlationLabel.bottomAnchor, constant: 8),
            correlationChart.leadingAnchor.constraint(equalTo: correlationLabel.leadingAnchor),
            correlationChart.trailingAnchor.constraint(equalTo: correlationLabel.trailingAnchor),
        ]
        scrollView.addConstraints(constraints)
        correlationChart.translatesAutoresizingMaskIntoConstraints = false
        correlationChart.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let svconstraints : [NSLayoutConstraint] = [
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        view.addConstraints(svconstraints)
    }

    func getSampleDescriptor() -> String {
        if sampleTypes == nil {
            return ""
        }
        return sampleTypes.reduce("", { (acc, t) in acc + ":" + t.identifier })
    }

}
