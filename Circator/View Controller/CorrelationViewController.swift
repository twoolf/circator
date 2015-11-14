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

class CorrelationViewController: UIViewController, ChartViewDelegate {
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: self.view.bounds)
        return view
    }()
    
    lazy var correlationLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = "aaa vs bbb"
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
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.rightAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.rightAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.legend.position = .BelowChartCenter
        chart.legend.form = .Circle
        chart.legend.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        chart.legend.textColor = Theme.universityDarkTheme.bodyTextColor
        return chart
    }()
    
    var sampleTypes: [HKSampleType]! {
        didSet {
            HealthManager.sharedManager.correlateStatisticsOfType(sampleTypes[0], withType: sampleTypes[1]) { (stat1, stat2, error) -> Void in
                guard error == nil else {
                    return
                }
                let analyzer = CorrelationDataAnalyzer(sampleTypes: self.sampleTypes, statistics: [stat1, stat2])!
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
                self.correlationChart.data = analyzer.correlationChartData
                self.correlationChart.data?.setValueTextColor(Theme.universityDarkTheme.bodyTextColor)
                self.correlationChart.data?.setValueFont(UIFont.systemFontOfSize(10, weight: UIFontWeightThin))
            }
            navigationItem.title = "Correlation"
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureViews() {
        view.addSubview(scrollView)
        scrollView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        correlationLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(correlationLabel)
        correlationChart.translatesAutoresizingMaskIntoConstraints = false
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
    }

}
