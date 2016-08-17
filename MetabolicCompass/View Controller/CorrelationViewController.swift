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
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.backgroundColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Attribute 2 Relative to Increasing Attribute 1", comment: "Plot view section title label")
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    
    
    lazy var correlationChart: LineChartView = {
        let chart = LineChartView()
        chart.delegate = self
        chart.descriptionText = ""
        chart.drawBordersEnabled = true
        chart.doubleTapToZoomEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.leftAxis.startAtZeroEnabled = false
        chart.rightAxis.enabled = true
        chart.rightAxis.startAtZeroEnabled = false
        chart.rightAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.rightAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.legend.position = .BelowChartCenter
        chart.legend.form = .Circle
        chart.legend.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
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
                                    if let idx = self.errorIndex, pv = self.parentViewController as? PagesController {
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
                                    if let idx = self.errorIndex, pv = self.parentViewController as? PagesController {
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
                                    if let idx = self.errorIndex, pv = self.parentViewController as? PagesController {
                                        pv.goTo(idx)
                                    }
                                }
                                return
                            }
                            self.correlateFasting(zipped, flip: true)
                        }

                    case let (.PlotPredicate(_, lpred), .PlotPredicate(_, rpred)):
                        MCHealthManager.sharedManager.correlateStatisticsOfType(self.sampleTypes[0], withType: self.sampleTypes[1], pred1: lpred, pred2: rpred) {
                            (stat1, stat2, error) -> Void in
                            guard (error == nil) && !(stat1.isEmpty || stat2.isEmpty) else {
                                Async.main {
                                    if let idx = self.errorIndex, pv = self.parentViewController as? PagesController {
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

    func specLabels() -> [String] {
        let lsp = self.lspec ?? .PlotPredicate("", nil)
        let rsp = self.rspec ?? .PlotPredicate("", nil)
        return [attrNameOfSpec(lsp, name: sampleTypes[0].displayText!), attrNameOfSpec(rsp, name: sampleTypes[1].displayText!)]

    }
    func correlateSamplePair(stat1: [MCSample], stat2: [MCSample]) {
        let analyzer = CorrelationDataAnalyzer(labels: specLabels(), samples: [stat1, stat2])!
        self.plotCorrelate(analyzer)
    }

    func correlateFastingSelf(aggregates: [(NSDate, Double)]) {
        let analyzer = CorrelationDataAnalyzer(labels: specLabels(), values: [aggregates, aggregates])!
        self.plotCorrelate(analyzer)
    }

    func correlateFasting(zipped: [(NSDate, Double, MCSample)], flip: Bool = false) {
        let labels = specLabels()
        let flippedLabels = [labels[1], labels[0]]
        let analyzer = CorrelationDataAnalyzer(labels: flip ? flippedLabels : labels, zipped: zipped)!
        self.plotCorrelate(analyzer)
    }

    func plotCorrelate(analyzer: CorrelationDataAnalyzer) {
        let configurator: ((LineChartDataSet) -> Void)? = { dataSet in
            dataSet.drawCircleHoleEnabled = false
            dataSet.circleRadius = 6
            dataSet.valueFormatter = SampleFormatter.numberFormatter
            dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!]
            dataSet.lineWidth = 2
            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!
            dataSet.axisDependency = .Left
        }
        let configurator2: ((LineChartDataSet) -> Void)? = { dataSet in
            dataSet.drawCircleHoleEnabled = false
            dataSet.circleRadius = 6
            dataSet.valueFormatter = SampleFormatter.numberFormatter
            dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.9)!]
            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.9)!]
            dataSet.lineWidth = 2
            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.9)!
            dataSet.axisDependency = .Right
        }
        analyzer.dataSetConfigurators = [configurator, configurator2]
        let cdata = analyzer.correlationChartData
        self.correlationChart.data = cdata.yValCount == 0 ? nil : cdata
        self.correlationChart.data?.setValueTextColor(Theme.universityDarkTheme.bodyTextColor)
        self.correlationChart.data?.setValueFont(UIFont.systemFontOfSize(10, weight: UIFontWeightThin))

        Async.main {
            if let idx = self.pageIndex, pv = self.parentViewController as? PagesController {
                pv.goTo(idx)
            }
        }

        Answers.logContentViewWithName("Correlate",
            contentType: self.getSampleDescriptor(),
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("Correlate",
            contentType: getSampleDescriptor(),
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
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
            correlationLabel.leadingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.leadingAnchor),
            correlationLabel.trailingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.trailingAnchor),
            correlationLabel.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 12),
            correlationChart.topAnchor.constraintEqualToAnchor(correlationLabel.bottomAnchor, constant: 8),
            correlationChart.leadingAnchor.constraintEqualToAnchor(correlationLabel.leadingAnchor),
            correlationChart.trailingAnchor.constraintEqualToAnchor(correlationLabel.trailingAnchor),
        ]
        scrollView.addConstraints(constraints)
        correlationChart.translatesAutoresizingMaskIntoConstraints = false
        correlationChart.heightAnchor.constraintEqualToConstant(200).active = true

        let svconstraints : [NSLayoutConstraint] = [
            scrollView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            scrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            scrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
        ]
        view.addConstraints(svconstraints)
    }

    func getSampleDescriptor() -> String {
        if sampleTypes == nil {
            return ""
        }
        return sampleTypes.reduce("", combine: { (acc, t) in acc + ":" + t.identifier })
    }

}
