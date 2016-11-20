//
//  DialViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 11/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import Charts
import Crashlytics
import SwiftDate

private let dialLegendLabelSize: CGFloat = 14.0

class DialViewController : UIViewController, ChartViewDelegate {

    var activityIndicator: UIActivityIndicatorView! = nil

    lazy var pieChart: PieChartView = {
        let chart = PieChartView()
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
        chart.descriptionText = ""
        chart.backgroundColor = .clearColor()
        chart.holeColor = .clearColor()
        chart.drawMarkers = true
        chart.drawHoleEnabled = true
        chart.drawSliceTextEnabled = false
        chart.usePercentValuesEnabled = false
        chart.rotationEnabled = true
        chart.rotationWithTwoFingers = true
        chart.legend.enabled = false
        return chart
    }()

    lazy var activityLegendLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "GothamBook", size: dialLegendLabelSize)!
        label.textColor = .lightGrayColor()

        let basicAttrs = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        let sleepAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.sleepColor,
                          NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.sleepColor]

        let eatAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.eatingColor,
                        NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.eatingColor]

        let exAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.exerciseColor,
                       NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.exerciseColor]


        let aString = NSMutableAttributedString(string: "◻︎ Sleep ◻︎ Eating ◻︎ Exercise", attributes: basicAttrs)
        aString.addAttributes(sleepAttrs, range: NSRange(location:0, length: 1))
        aString.addAttributes(eatAttrs, range: NSRange(location:9, length: 1))
        aString.addAttributes(exAttrs, range: NSRange(location:19, length: 1))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5.0
        paragraphStyle.alignment = .Center
        aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))

        label.attributedText = aString

        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        label.textAlignment = .Center

        return label
    }()

    private let pieTipMsg = "This heatmap shows when you've typically slept, ate and exercised in the last month"
    private var pieTip: TapTip! = nil

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator?.startAnimating()
        self.logContentView()
        self.refreshData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.logContentView(false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentViewWithName("Cycle",
                                       contentType: asAppear ? "Appear" : "Disappear",
                                       contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
                                       customAttributes: nil)
    }

    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView()

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        let constraints: [NSLayoutConstraint] = [
            activityIndicator.topAnchor.constraintEqualToAnchor(view.topAnchor),
            activityIndicator.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            activityIndicator.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            activityIndicator.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
        ]
        view.addConstraints(constraints)
    }

    func setupView() {

        refreshPieChart()

        let pieChartStack: UIStackView = UIComponents.createLabelledComponent("Circadian Activity In The Last Month", labelFontSize: 16.0, value: (), constructor: {
            _ in return self.pieChart
        })

        pieTip = TapTip(forView: pieChart, withinView: view, text: pieTipMsg, numTouches: 2, asTop: false)
        pieChart.addGestureRecognizer(pieTip.tapRecognizer)

        let toggleRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleDatasets))
        toggleRecognizer.numberOfTapsRequired = 2
        pieChart.addGestureRecognizer(toggleRecognizer)

        pieChartStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pieChartStack)

        activityLegendLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityLegendLabel)

        let constraints: [NSLayoutConstraint] = [
            pieChartStack.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 20),
            pieChartStack.bottomAnchor.constraintEqualToAnchor(activityLegendLabel.topAnchor),
            activityLegendLabel.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -20),
            pieChartStack.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            pieChartStack.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            activityLegendLabel.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            activityLegendLabel.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            activityLegendLabel.heightAnchor.constraintGreaterThanOrEqualToConstant(30.0)
        ]
        view.addConstraints(constraints)

        setupActivityIndicator()
    }

    func refreshPieChart() {
        let model = AnalysisDataModel.sharedInstance.cycleModel
        var segments : [(NSDate, ChartDataEntry)] = []
        var colors : [NSUIColor] = []

        let hrType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        let scType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!

        switch model.segmentIndex {
        case 0:
            segments = model.cycleSegments
            colors = model.cycleColors
        case 1:
            segments = model.measureSegments[hrType]!
            colors = model.measureColors[hrType]!
        default:
            segments = model.measureSegments[scType]!
            colors = model.measureColors[scType]!
        }

        let pieChartDataSet = PieChartDataSet(yVals: segments.map { $0.1 }, label: "Circadian segments")
        pieChartDataSet.colors = colors
        pieChartDataSet.drawValuesEnabled = false

        let xVals : [String] = segments.map { $0.0.toString(DateFormat.Custom("HH:mm")) ?? "" }

        let pieChartData = PieChartData(xVals: xVals, dataSet: pieChartDataSet)
        self.pieChart.data = pieChartData
        self.pieChart.setNeedsDisplay()
    }

    func refreshLegend() {
        let basicAttrs = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        let segmentAttrs = [NSForegroundColorAttributeName: AnalysisDataModel.sharedInstance.cycleModel.segmentColor(),
                            NSBackgroundColorAttributeName: AnalysisDataModel.sharedInstance.cycleModel.segmentColor()]

        let sleepAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.sleepColor,
                          NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.sleepColor]

        let eatAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.eatingColor,
                        NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.eatingColor]

        let exAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.exerciseColor,
                       NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.exerciseColor]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5.0
        paragraphStyle.alignment = .Center

        switch AnalysisDataModel.sharedInstance.cycleModel.segmentIndex {
        case 0:
            let aString = NSMutableAttributedString(string: "◻︎  Sleep ◻︎  Eating ◻︎  Exercise", attributes: basicAttrs)
            aString.addAttributes(sleepAttrs, range: NSRange(location:0, length: 1))
            aString.addAttributes(eatAttrs, range: NSRange(location:10, length: 1))
            aString.addAttributes(exAttrs, range: NSRange(location:21, length: 1))
            aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))
            self.activityLegendLabel.attributedText = aString

        case 1:
            let aString = NSMutableAttributedString(string: "◻︎  Max Heart Rate", attributes: basicAttrs)
            aString.addAttributes(segmentAttrs, range: NSRange(location:0, length: 1))
            aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))
            self.activityLegendLabel.attributedText = aString

        default:
            let aString = NSMutableAttributedString(string: "◻︎  Max Step Count", attributes: basicAttrs)
            aString.addAttributes(segmentAttrs, range: NSRange(location:0, length: 1))
            aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))
            self.activityLegendLabel.attributedText = aString
        }

        self.activityLegendLabel.setNeedsDisplay()
    }

    func refreshData() {
        AnalysisDataModel.sharedInstance.cycleModel.updateData { error in
            guard error == nil else {
                log.error(error)
                return
            }

            Async.main {
                self.activityIndicator?.stopAnimating()
                self.refreshPieChart()
                self.refreshLegend()
            }
        }
    }

    func toggleDatasets() {
        AnalysisDataModel.sharedInstance.cycleModel.segmentIndex =
            (AnalysisDataModel.sharedInstance.cycleModel.segmentIndex + 1) % 3

        Async.main {
            self.refreshPieChart()
            self.refreshLegend()
        }
    }

    //MARK: ChartViewDelegate
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        var entryStr = AnalysisDataModel.sharedInstance.cycleModel.cycleSegments[entry.xIndex].0.toString(DateFormat.Custom("HH:mm")) ?? ""

        let txtFont = UIFont.systemFontOfSize(20, weight: UIFontWeightRegular)
        let numberFont = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)

        var slRange: NSRange! = nil
        var eatRange: NSRange! = nil
        var exRange: NSRange! = nil

        switch AnalysisDataModel.sharedInstance.cycleModel.segmentIndex {
        case 0:
            if let opt = entry.data as? [Int]?, counts = opt {
                let sleepCount = "\(counts[0])"
                let eatCount = "\(counts[1])"
                let exCount = "\(counts[2])"

                entryStr += "\n◻︎ \(sleepCount)  ◻︎ \(eatCount)  ◻︎ \(exCount)"

                slRange = NSRange(location: 6, length: 2)
                eatRange = NSRange(location: 11 + sleepCount.characters.count, length: 1)
                exRange = NSRange(location: 16 + sleepCount.characters.count + eatCount.characters.count, length: 1)
            }

        case 1:
            if let opt = entry.data as? Double?, bpm = opt {
                entryStr += "\n" + String(format: "%.3g", bpm) + " bpm"
            }

        case 2:
            if let opt = entry.data as? Double?, steps = opt {
                entryStr += "\n" + String(format: "%.4g", steps) + " steps"
            }

        default:
            break
        }

        let attrs : [String: AnyObject] = [
            NSFontAttributeName: txtFont,
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]

        let aString = NSMutableAttributedString(string: entryStr, attributes: attrs)

        if aString.length > 5 {
            aString.addAttribute(NSFontAttributeName, value: numberFont, range: NSMakeRange(6, aString.length - 6))

            if AnalysisDataModel.sharedInstance.cycleModel.segmentIndex == 0 {
                let sleepAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.sleepColor,
                                  NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.sleepColor]

                let eatAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.eatingColor,
                                NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.eatingColor]

                let exAttrs = [NSForegroundColorAttributeName: MetabolicDailyProgressChartView.exerciseColor,
                               NSBackgroundColorAttributeName: MetabolicDailyProgressChartView.exerciseColor]

                aString.addAttributes(sleepAttrs, range: slRange)
                aString.addAttributes(eatAttrs, range: eatRange)
                aString.addAttributes(exAttrs, range: exRange)
            }
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Center
        aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))

        pieChart.centerAttributedText = aString
        pieChart.drawCenterTextEnabled = true
    }

    func chartValueNothingSelected(chartView: ChartViewBase) {
        pieChart.centerText = ""
        pieChart.drawCenterTextEnabled = false
    }
}
