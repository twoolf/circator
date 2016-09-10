//
//  FastingViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/8/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import GameKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import Charts
import EasyTipView

private let fastingViewLabelSize: CGFloat = 12.0
private let fastingViewTextSize: CGFloat = 24.0


public class FastingViewController : UIViewController, ChartViewDelegate {

    var scrollView: UIScrollView!

    var activityIndicator: UIActivityIndicatorView! = nil

    private var model: FastingDataModel = FastingDataModel()

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
        chart.usePercentValuesEnabled = true
        chart.rotationEnabled = false
        chart.legend.enabled = false
        return chart
    }()

    private let pieTipMsg = "This pie chart shows a breakdown of the types of data you've been collecting over the past year"
    private var pieTip: TapTip! = nil

    lazy var pieChartColors: [NSUIColor] = {
        // Populate 15 colors. Add more if needed.
        var colors : [NSUIColor] = []

        colors.appendContentsOf(ChartColorTemplates.material())
        colors.appendContentsOf(ChartColorTemplates.colorful())
        colors.appendContentsOf(ChartColorTemplates.liberty())
        colors.appendContentsOf(ChartColorTemplates.pastel())
        colors.appendContentsOf(ChartColorTemplates.joyful())
        colors.appendContentsOf(ChartColorTemplates.vordiplom())

        //return GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(colors) as! [NSUIColor]
        return colors
    }()

    public static let orange = ChartColorTemplates.colorful()[1]
    public static let blue   = ChartColorTemplates.joyful()[4]
    public static let yellow = ChartColorTemplates.colorful()[2]
    public static let green  = ChartColorTemplates.colorful()[3]

    lazy var sleepAwakeBalance: BalanceBarView = {
        let attrs1 = [NSForegroundColorAttributeName: FastingViewController.orange,
                      NSBackgroundColorAttributeName: FastingViewController.orange]

        let attrs2 = [NSForegroundColorAttributeName: FastingViewController.blue,
                      NSBackgroundColorAttributeName: FastingViewController.blue]

        var title = NSMutableAttributedString(string: "Weekly fasting asleep (◻︎) vs awake (◻︎)")
        title.addAttributes(attrs1, range: NSRange(location:23, length: 1))
        title.addAttributes(attrs2, range: NSRange(location:37, length: 1))

        let tooltip = "This compares the hours you spent fasting while asleep in the last week vs the hours spent fasting while awake"
        let bar = BalanceBarView(title: title,
                                 color1: FastingViewController.orange,
                                 color2: FastingViewController.blue,
                                 tooltipText: tooltip)
        return bar
    }()

    lazy var eatExerciseBalance: BalanceBarView = {
        let attrs1 = [NSForegroundColorAttributeName: FastingViewController.yellow,
                      NSBackgroundColorAttributeName: FastingViewController.yellow]

        let attrs2 = [NSForegroundColorAttributeName: FastingViewController.green,
                      NSBackgroundColorAttributeName: FastingViewController.green]

        var title = NSMutableAttributedString(string: "Weekly eating (◻︎) vs exercise (◻︎)")
        title.addAttributes(attrs1, range: NSRange(location:15, length: 1))
        title.addAttributes(attrs2, range: NSRange(location:32, length: 1))

        let tooltip = "This compares the hours you spent in the last week eating vs the hours spent exercising"
        let bar = BalanceBarView(title: title,
                                 color1: FastingViewController.yellow,
                                 color2: FastingViewController.green,
                                 tooltipText: tooltip)
        return bar
    }()

    lazy var cwfLabel: UIStackView = UIComponents.createNumberLabel("Cumulative Weekly Fasting", labelFontSize: fastingViewLabelSize, value: 0.0, unit: "hrs")
    lazy var wfvLabel: UIStackView = UIComponents.createNumberLabel("Weekly Fasting Variability", labelFontSize: fastingViewLabelSize, value: 0.0, unit: "hrs")

    private let cwfTipMsg = "Your cumulative weekly fasting is the total number of hours that you've spent fasting over the last 7 days"
    private let wfvTipMsg = "Your weekly fasting variability shows you how much your fasting hours varies day-by-day. We calculate this over the last week."

    private var cwfTip: TapTip! = nil
    private var wfvTip: TapTip! = nil

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator.startAnimating()
        self.logContentView()
        self.refreshData()
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.logContentView(false)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        log.warning("OUR STUDY contentSize \(scrollView.contentSize)")
        log.warning("OUR STUDY view bounds \(view.bounds) \(view.frame) \(scrollView.bounds) \(scrollView.frame)")
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentViewWithName("Fasting",
                                       contentType: asAppear ? "Appear" : "Disappear",
                                       contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
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

    func setupBackground() {
        let backgroundImage = UIImageView(image: UIImage(named: "university_logo"))
        backgroundImage.contentMode = .Center
        backgroundImage.layer.opacity = 0.03
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(backgroundImage, atIndex: 0)

        let bgConstraints: [NSLayoutConstraint] = [
            backgroundImage.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor),
            backgroundImage.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor)
        ]

        self.view.addConstraints(bgConstraints)
    }

    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.userInteractionEnabled = true

        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let scrollConstraints: [NSLayoutConstraint] = [
            view.leadingAnchor.constraintEqualToAnchor(scrollView.leadingAnchor),
            view.trailingAnchor.constraintEqualToAnchor(scrollView.trailingAnchor),
            view.topAnchor.constraintEqualToAnchor(scrollView.topAnchor),
            view.bottomAnchor.constraintEqualToAnchor(scrollView.bottomAnchor)
        ]
        view.addConstraints(scrollConstraints)
    }

    func setupView() {
        setupBackground()

        setupScrollView()

        refreshPieChart()

        let pieChartStack: UIStackView = UIComponents.createLabelledComponent("Data Collected This Year", labelFontSize: fastingViewLabelSize, value: (), constructor: {
            _ in return self.pieChart
        })

        setupTooltips()

        let labelStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [cwfLabel, wfvLabel])
            stack.axis = .Horizontal
            stack.distribution = UIStackViewDistribution.FillEqually
            stack.alignment = UIStackViewAlignment.Fill
            return stack
        }()

        let stack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [pieChartStack, sleepAwakeBalance, eatExerciseBalance, labelStack])
            stack.axis = .Vertical
            stack.distribution = UIStackViewDistribution.Fill
            stack.alignment = UIStackViewAlignment.Fill
            stack.spacing = 15
            return stack
        }()

        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let constraints: [NSLayoutConstraint] = [
            stack.topAnchor.constraintEqualToAnchor(scrollView.topAnchor),
            stack.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            stack.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            stack.bottomAnchor.constraintEqualToAnchor(scrollView.bottomAnchor),
            pieChartStack.heightAnchor.constraintEqualToAnchor(pieChartStack.widthAnchor, multiplier: 0.8),
            sleepAwakeBalance.heightAnchor.constraintEqualToConstant(60),
            eatExerciseBalance.heightAnchor.constraintEqualToConstant(60),
            labelStack.heightAnchor.constraintEqualToConstant(80),
        ]
        view.addConstraints(constraints)

        setupActivityIndicator()

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func setupTooltips() {
        pieTip = TapTip(forView: pieChart, withinView: scrollView, text: pieTipMsg, numTouches: 2, asTop: false)
        pieChart.addGestureRecognizer(pieTip.tapRecognizer)

        cwfTip = TapTip(forView: cwfLabel, withinView: scrollView, text: cwfTipMsg, asTop: true)
        wfvTip = TapTip(forView: wfvLabel, withinView: scrollView, text: wfvTipMsg, asTop: true)

        cwfLabel.addGestureRecognizer(cwfTip.tapRecognizer)
        cwfLabel.userInteractionEnabled = true

        wfvLabel.addGestureRecognizer(wfvTip.tapRecognizer)
        wfvLabel.userInteractionEnabled = true

        sleepAwakeBalance.tip.withinView = scrollView
        eatExerciseBalance.tip.withinView = scrollView
    }

    func refreshPieChart() {
        let pieChartDataSet = PieChartDataSet(yVals: self.model.samplesCollectedDataEntries.map { $0.1 }, label: "Samples per type")
        pieChartDataSet.colors = pieChartColors
        pieChartDataSet.drawValuesEnabled = false

        let xVals : [String] = self.model.samplesCollectedDataEntries.map {
            switch $0.0 {
            case .HKType(let sampleType):
                return sampleType.displayText!
            case .Other:
                return "Other"
            }
        }

        let pieChartData = PieChartData(xVals: xVals, dataSet: pieChartDataSet)
        self.pieChart.data = pieChartData
        self.pieChart.setNeedsDisplay()
    }

    public func refreshData() {
        log.info("FastingViewController refreshing data")
        let refreshStartDate = NSDate()

        model.updateData { error in
            guard error == nil else {
                log.error(error)
                return
            }

            log.info("FastingViewController refreshing charts (\(NSDate().timeIntervalSinceDate(refreshStartDate)))")

            Async.main {
                self.activityIndicator.stopAnimating()
                self.refreshPieChart()

                let saTotal = self.model.fastSleep + self.model.fastAwake
                let eeTotal = self.model.fastEat + self.model.fastExercise

                self.sleepAwakeBalance.ratio = saTotal == 0.0 ? -1.0 : CGFloat( self.model.fastSleep / saTotal )
                self.sleepAwakeBalance.refreshData()

                self.eatExerciseBalance.ratio = eeTotal == 0.0 ? -1.0 : CGFloat( self.model.fastEat / eeTotal )
                self.eatExerciseBalance.refreshData()

                if let cwfSubLabel = self.cwfLabel.arrangedSubviews[1] as? UILabel {
                    if saTotal == 0.0 {
                        cwfSubLabel.text = "N/A"
                    } else {
                        cwfSubLabel.text = String(format: "%.1f h", (self.model.cumulativeWeeklyFasting / 3600.0))
                    }
                    cwfSubLabel.setNeedsDisplay()
                }

                if let wfvSubLabel = self.wfvLabel.arrangedSubviews[1] as? UILabel {
                    if saTotal == 0.0 {
                        wfvSubLabel.text = "N/A"
                    } else {
                        wfvSubLabel.text = String(format: "%.1f h", (self.model.weeklyFastingVariability / 3600.0))
                    }
                    wfvSubLabel.setNeedsDisplay()
                }
            }
        }
    }

    //MARK: ChartViewDelegate
    public func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        var typeIdentifier : String = ""
        switch model.samplesCollectedDataEntries[entry.xIndex].0 {
        case .HKType(let sampleType):
            typeIdentifier = HMConstants.sharedInstance.healthKitShortNames[sampleType.identifier]!
        case .Other:
            typeIdentifier = "Other"
        }

        let numberFont = UIFont.systemFontOfSize(20, weight: UIFontWeightRegular)
        let smallFont = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)

        let cString = typeIdentifier + "\n\(String(format: "%.1f%%", entry.value * 100.0))"
        let attrs : [String: AnyObject] = [
            NSFontAttributeName: numberFont,
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]

        let aString = NSMutableAttributedString(string: cString, attributes: attrs)
        aString.addAttribute(NSFontAttributeName, value: smallFont, range: NSRange(location:0, length: typeIdentifier.characters.count))

        pieChart.centerAttributedText = aString
        pieChart.drawCenterTextEnabled = true
    }

    public func chartValueNothingSelected(chartView: ChartViewBase) {
        pieChart.centerText = ""
        pieChart.drawCenterTextEnabled = false
    }

}

