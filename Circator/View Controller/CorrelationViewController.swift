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
    
    lazy var historyLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Time Correlations: Min to Max (x-axis) vs Value at time (y-axis)", comment: "Plot view section title label")
        return label
    }()
    
    lazy var historyChart: LineChartView = {
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
        chart.legend.enabled = false
        chart.descriptionText = ""
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        chart.rightAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.rightAxis.valueFormatter = SampleFormatter.numberFormatter
        return chart
    }()
    
    var sampleTypes: [HKSampleType]! {
        didSet {
            HealthManager.sharedManager.correlateStatisticsOfType(sampleTypes[0], withType: sampleTypes[1]) { (stat1, stat2, error) -> Void in
                guard error == nil else {
                    return
                }
 //               print("entire stat1, \(stat1.)")
                for (i, stat) in stat1.enumerate() {
                    print("stat1,\(stat.quantity)")
                    print("stat2,\(stat2[i].quantity)")
                }
            }
            // TODO: considering changing the title
//            navigationItem.title = "Correlation"
//
//                    if self.sampleTypes[0] is HKCorrelationType {
//                        // Sleep
//                    } else {
//                        let analyzer = SampleDataAnalyzer(sampleType: self.sampleTypes[0], samples: samples)
//                        analyzer.dataSetConfigurator = { dataSet in
//                            dataSet.drawCircleHoleEnabled = true
//                            dataSet.circleRadius = 7
//                            dataSet.valueFormatter = SampleFormatter.numberFormatter
//                            dataSet.circleHoleColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!
//                            dataSet.circleColors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.6)!]
//                            dataSet.colors = [Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!]
//                            dataSet.lineWidth = 2
//                            dataSet.fillColor = Theme.universityDarkTheme.complementForegroundColors!.colorWithVibrancy(0.1)!
//                        }
//                        self.historyChart.data = analyzer.lineChartData
//                        self.historyChart.data?.setValueTextColor(Theme.universityDarkTheme.bodyTextColor)
//                        self.historyChart.data?.setValueFont(UIFont.systemFontOfSize(10, weight: UIFontWeightThin))
//                    }
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
        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyLabel)
        historyChart.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyChart)
        let constraints: [NSLayoutConstraint] = [
            historyLabel.leadingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.leadingAnchor),
            historyLabel.trailingAnchor.constraintEqualToAnchor(scrollView.layoutMarginsGuide.trailingAnchor),
            historyLabel.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 12),
            historyChart.topAnchor.constraintEqualToAnchor(historyLabel.bottomAnchor, constant: 8),
            historyChart.leadingAnchor.constraintEqualToAnchor(historyLabel.leadingAnchor),
            historyChart.trailingAnchor.constraintEqualToAnchor(historyLabel.trailingAnchor),
        ]
        scrollView.addConstraints(constraints)
        historyChart.translatesAutoresizingMaskIntoConstraints = false
        historyChart.heightAnchor.constraintEqualToConstant(200).active = true
    }

}
