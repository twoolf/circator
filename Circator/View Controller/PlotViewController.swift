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

class PlotViewController: UIViewController, ChartViewDelegate {
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: self.view.bounds)
        return view
    }()
    
    lazy var historyLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Personal History", comment: "Plot view section title label")
        return label
    }()
    
    lazy var populationLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.text = NSLocalizedString("Population", comment: "Plot view section title label")
        return label
    }()
    
    lazy var historyChart: LineChartView = {
        let chart = LineChartView()
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
        chart.xAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.labelTextColor = Theme.universityDarkTheme.titleTextColor
        chart.leftAxis.valueFormatter = SampleFormatter.numberFormatter
        return chart
    }()
    
    lazy var populationChart: LineChartView = {
        let chart = LineChartView()
        chart.delegate = self
        chart.doubleTapToZoomEnabled = false
        return chart
    }()
    
    var sampleType: HKSampleType! {
        didSet {
            navigationItem.title = sampleType.displayText!
            HealthManager.sharedManager.fetchSamplesOfType(sampleType) { (samples, error) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    guard error == nil else {
                        return
                    }
                    if self.sampleType is HKCorrelationType {
                        
                    } else {
                        let analyzer = SampleDataAnalyzer(sampleType: self.sampleType, samples: samples)
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
                        self.historyChart.data = analyzer.lineChartData
                        self.historyChart.data?.setValueTextColor(Theme.universityDarkTheme.bodyTextColor)
                        self.historyChart.data?.setValueFont(UIFont.systemFontOfSize(10, weight: UIFontWeightThin))
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureViews() {
        view.addSubview(scrollView)
        scrollView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyLabel)
        populationLabel.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(populationLabel)
        historyChart.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(historyChart)
        populationChart.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(populationChart)
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
        populationChart.translatesAutoresizingMaskIntoConstraints = false
        populationChart.heightAnchor.constraintEqualToConstant(200).active = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
