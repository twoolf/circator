//
//  CorrelationViewController.swift
//  Circator
//
//  Created by Sihao Lu on 10/29/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts
import CircatorKit
import HealthKit
import Crashlytics
import SwiftDate
import Pages
import Async

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
        chart.rightAxis.enabled = true
        chart.doubleTapToZoomEnabled = false
        chart.leftAxis.startAtZeroEnabled = false
        chart.rightAxis.startAtZeroEnabled = false
        chart.drawGridBackgroundEnabled = false
        chart.xAxis.labelPosition = .Bottom
        chart.xAxis.avoidFirstLastClippingEnabled = true
        chart.xAxis.drawAxisLineEnabled = true
        chart.xAxis.drawGridLinesEnabled = true
        chart.descriptionText = ""
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.rightAxis.labelTextColor = Theme.universityDarkTheme.backgroundColor
        chart.rightAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.legend.position = .BelowChartCenter
        chart.legend.form = .Circle
        chart.legend.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        chart.legend.textColor = Theme.universityDarkTheme.backgroundColor
        return chart
    }()
    
    var sampleTypes: [HKSampleType]! {
        didSet {
            Async.main {
                let attr1 = HMConstants.sharedInstance.healthKitShortNames[self.sampleTypes[0].identifier]!
                let attr2 = HMConstants.sharedInstance.healthKitShortNames[self.sampleTypes[1].identifier]!
                self.correlationLabel.text = NSLocalizedString("\(attr2) Relative to Increasing \(attr1)", comment: "Plot view section title label")

                Async.background {
                    HealthManager.sharedManager.correlateStatisticsOfType(self.sampleTypes[0], withType: self.sampleTypes[1]) { (stat1, stat2, error) -> Void in
                        guard (error == nil) && !(stat1.isEmpty || stat2.isEmpty) else {
                            Async.main {
                                if let idx = self.errorIndex, pv = self.parentViewController as? PagesController {
                                    pv.goTo(idx)
                                }
                            }
                            return
                        }

                        let analyzer = CorrelationDataAnalyzer(sampleTypes: self.sampleTypes, samples: [stat1, stat2])!
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
                        Answers.logContentViewWithName("Answers looking at Correlate View",
                            contentType: "Testing with Answers",
                            contentId: "near line 115",
                            customAttributes: [:])
                        BehaviorMonitor.sharedInstance.setValue("Correlate", contentType: self.getSampleDescriptor())
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
        Answers.logContentViewWithName("Answers looking at Correlate View",
            contentType: "Testing with Answers",
            contentId: "near line 140",
            customAttributes: [:])
        BehaviorMonitor.sharedInstance.showView("Correlate", contentType: getSampleDescriptor())
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
        return sampleTypes.reduce("", combine: { (acc, t) in acc + ":" + t.identifier })
    }

}
