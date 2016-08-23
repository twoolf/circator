//
//  OurStudyViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 8/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit
import Async
import Charts

let studyBodyFontSize: CGFloat = 30.0
let studyContributionFontSize: CGFloat = 40.0
let ringLabelFontSize: CGFloat = 12.0
let studyLabelFontSize: CGFloat = 14.0

let studyLabelAttrs: [String: AnyObject] = [
    NSForegroundColorAttributeName: UIColor.whiteColor(),
    NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue)
]

public class OurStudyViewController: UIViewController, ChartViewDelegate {

    public static let grey   = UIColor.ht_concreteColor()
    public static let red    = UIColor.ht_pomegranateColor()
    public static let orange = ChartColorTemplates.colorful()[1]
    public static let blue   = ChartColorTemplates.joyful()[4]
    public static let yellow = ChartColorTemplates.colorful()[2]
    public static let green  = ChartColorTemplates.colorful()[3]
    public static let purple  = UIColor.ht_amethystColor()
    public static let clouds  = UIColor.ht_cloudsColor()

    lazy var phaseProgress: BalanceBarView = {
        let attrs1 = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                      NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
                      NSFontAttributeName: UIFont(name: "GothamBook", size: studyLabelFontSize)!]
        var title = NSMutableAttributedString(string: "Study Progress: Phase 1: 100 users", attributes: attrs1)

        let tooltip = "This progress bar indicates our near-term study deployment status and goals"
        let bar = BalanceBarView(title: title,
                                 color1: OurStudyViewController.red,
                                 color2: OurStudyViewController.grey,
                                 tooltipText: tooltip)
        return bar
    }()

    static let ringNames = ["Total Study\nData Entries", "Week-over-Week\nData Growth", "Mean Daily\nUser Entries"]
    static let ringUnits = ["", "%", ""]
    static let ringValues = [(1100, 10000), (20.0, 100.0), (5, 20)]

    static let ringDescriptions = [
        "This ring shows the total number of data entries uploaded by all users in our study relative to our next target.",
        "This ring shows the week-over-week percentage growth in the data entries contributed by our users",
        "This ring shows the average number of daily entries contributed by each user in our study"
    ]

    lazy var rings: [PieChartView] = {
        return OurStudyViewController.ringNames.map { _ in
            let chart = PieChartView()
            chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
            chart.delegate = self
            chart.descriptionText = ""
            chart.holeRadiusPercent = 0.7
            chart.backgroundColor = .clearColor()
            chart.holeColor = .clearColor()
            chart.highlightPerTapEnabled = false
            chart.drawMarkers = true
            chart.drawHoleEnabled = true
            chart.drawSliceTextEnabled = false
            chart.usePercentValuesEnabled = true
            chart.rotationEnabled = false
            chart.legend.enabled = false
            return chart
        }
    }()

    var ringTips: [TapTip] = []

    lazy var pieChartColors: [[NSUIColor]] = {
        return [
            [OurStudyViewController.yellow, OurStudyViewController.green],
            [OurStudyViewController.orange, OurStudyViewController.blue],
            [OurStudyViewController.clouds, OurStudyViewController.purple]
        ]
    }()

    var ring2TopConstraint: NSLayoutConstraint! = nil

    lazy var fullDaysLabel: UIStackView =
        UIComponents.createNumberLabel(
            "Your Full Days Tracked", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize-2.0, value: 8.0, unit: "days")

    lazy var partialDaysLabel: UIStackView =
        UIComponents.createNumberLabel(
            "Your Partial Days Tracked", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize-2.0, value: 11.0, unit: "days")

    lazy var userRankingBadge: UIStackView =
        UIComponents.createNumberWithImageAndLabel(
            "Your Contributions Rank", imageName: "icon-gold-medal",
            titleAttrs: studyLabelAttrs, bodyFontSize: studyContributionFontSize,
            labelFontSize: 14.0, labelSpacing: 0.0, value: 1.0, unit: "%", prefix: "Top", suffix: "of all users")

    var phaseProgressTip: TapTip! = nil
    var fullDaysTip: TapTip! = nil
    var partialDaysTip: TapTip! = nil
    var userRankingTip: TapTip! = nil

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        refreshData()
    }

    func setupView() {

        let labelStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [fullDaysLabel, partialDaysLabel])
            stack.axis = .Horizontal
            stack.distribution = UIStackViewDistribution.FillEqually
            stack.alignment = UIStackViewAlignment.Fill
            return stack
        }()

        phaseProgress.translatesAutoresizingMaskIntoConstraints = false
        userRankingBadge.translatesAutoresizingMaskIntoConstraints = false
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(phaseProgress)
        self.view.addSubview(userRankingBadge)
        self.view.addSubview(labelStack)

        let phaseConstraints: [NSLayoutConstraint] = [
            phaseProgress.topAnchor.constraintEqualToAnchor(self.view.topAnchor, constant: 10),
            phaseProgress.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
            phaseProgress.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor),
            phaseProgress.heightAnchor.constraintLessThanOrEqualToAnchor(self.view.heightAnchor, multiplier: 0.1),
            userRankingBadge.topAnchor.constraintEqualToAnchor(phaseProgress.bottomAnchor, constant: 10),
            userRankingBadge.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor, constant: 10),
            userRankingBadge.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor, constant: -10),
            userRankingBadge.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor, multiplier: 0.2),

        ]
        self.view.addConstraints(phaseConstraints)

        let compositeView = UIView()
        compositeView.translatesAutoresizingMaskIntoConstraints = false

        var firstChart: UIStackView! = nil

        rings.enumerate().forEach { (index, pieChart) in
            let chart: UIStackView =
                UIComponents.createLabelledComponent(
                    OurStudyViewController.ringNames[index], labelOnTop: index != 2, labelFontSize: ringLabelFontSize, labelSpacing: 0.0, value: (), constructor: {
                        _ in return pieChart
                })

            if firstChart == nil { firstChart = chart }

            chart.translatesAutoresizingMaskIntoConstraints = false
            compositeView.addSubview(chart)

            let desc = OurStudyViewController.ringDescriptions[index]
            let tip = TapTip(forView: chart, text: desc, width: 350, numTaps: 1, numTouches: 1, asTop: index == 2)
            self.ringTips.append(tip)
            chart.addGestureRecognizer(tip.tapRecognizer)

            var constraints: [NSLayoutConstraint] = []
            if index == 0 {
                constraints.appendContentsOf([
                    chart.topAnchor.constraintEqualToAnchor(compositeView.topAnchor, constant: 10),
                    chart.heightAnchor.constraintGreaterThanOrEqualToAnchor(compositeView.heightAnchor, multiplier: 0.66),
                    chart.leadingAnchor.constraintEqualToAnchor(compositeView.leadingAnchor, constant: -5),
                    chart.widthAnchor.constraintEqualToAnchor(compositeView.widthAnchor, multiplier: 0.45)
                    ])
            } else if index == 1 {
                constraints.appendContentsOf([
                    chart.topAnchor.constraintEqualToAnchor(compositeView.topAnchor, constant: 10),
                    chart.heightAnchor.constraintEqualToAnchor(firstChart.heightAnchor),
                    chart.trailingAnchor.constraintEqualToAnchor(compositeView.trailingAnchor, constant: 5),
                    chart.widthAnchor.constraintEqualToAnchor(firstChart.widthAnchor)
                    ])

            } else if index == 2 {
                ring2TopConstraint = chart.topAnchor.constraintEqualToAnchor(firstChart.bottomAnchor)
                constraints.appendContentsOf([
                    ring2TopConstraint,
                    chart.heightAnchor.constraintEqualToAnchor(firstChart.heightAnchor),
                    chart.centerXAnchor.constraintEqualToAnchor(compositeView.centerXAnchor),
                    chart.widthAnchor.constraintEqualToAnchor(firstChart.widthAnchor)
                    ])

            }
            compositeView.addConstraints(constraints)
        }

        let labelledRings = UIComponents.createLabelledComponent(
            "Study-Wide Dataset Statistics", attrs: studyLabelAttrs,
            labelFontSize: studyLabelFontSize, labelSpacing: 8.0, value: (), constructor: { _ in return compositeView })

        labelledRings.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(labelledRings)


        let constraints: [NSLayoutConstraint] = [
            labelledRings.topAnchor.constraintEqualToAnchor(userRankingBadge.bottomAnchor, constant: 20),
            labelledRings.heightAnchor.constraintGreaterThanOrEqualToAnchor(self.view.heightAnchor, multiplier: 0.2),
            labelledRings.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
            labelledRings.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor),
            labelStack.topAnchor.constraintEqualToAnchor(labelledRings.bottomAnchor, constant: 10),
            labelStack.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            labelStack.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
            labelStack.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor),
        ]
        self.view.addConstraints(constraints)

        // Tooltips
        let phaseProgressDesc = "This bar shows our progress in meeting its active user goals for the current phase of the study"
        phaseProgressTip = TapTip(forView: phaseProgress, text: phaseProgressDesc, width: 350, numTaps: 1, numTouches: 1, asTop: false)
        phaseProgress.addGestureRecognizer(phaseProgressTip.tapRecognizer)

        let fullDayDesc = "This label shows the number of days where you have contributed a sleep event and at least one meal or exercise event. We call this a Full Data day."
        fullDaysTip = TapTip(forView: fullDaysLabel, text: fullDayDesc, width: 350, numTaps: 1, numTouches: 1, asTop: true)
        fullDaysLabel.addGestureRecognizer(fullDaysTip.tapRecognizer)

        let partialDayDesc = "This label shows the number of days where you have contributed any sleep, meal or exercise event. We call this a Partial Data day."
        partialDaysTip = TapTip(forView: partialDaysLabel, text: partialDayDesc, width: 350, numTaps: 1, numTouches: 1, asTop: true)
        partialDaysLabel.addGestureRecognizer(partialDaysTip.tapRecognizer)

        let userRankingDesc = "This label shows your ranking relative to other study users, based on the number of circadian events you have tracked."
        userRankingTip = TapTip(forView: userRankingBadge, text: userRankingDesc, width: 350, numTaps: 1, numTouches: 1, asTop: false)
        userRankingBadge.addGestureRecognizer(userRankingTip.tapRecognizer)

        // Adjust middle ring vertical placement.
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        if ring2TopConstraint != nil && rings.count > 0 {
            ring2TopConstraint.constant = -(rings[0].frame.height / 2.5)
        }
        self.view.layoutIfNeeded()
    }


    func refreshData() {
        self.phaseProgress.ratio = 0.1
        self.phaseProgress.refreshData()
        refreshStudyRings()
    }

    func refreshStudyRings() {
        OurStudyViewController.ringNames.enumerate().forEach { (index, _) in
            let (value, maxValue) = OurStudyViewController.ringValues[index]
            let labels = ["A", "B"]
            let entries = [value, maxValue - value].enumerate().map { return ChartDataEntry(value: $0.1, xIndex: $0.0) }

            let pieChartDataSet = PieChartDataSet(yVals: entries, label: "Samples per type")
            pieChartDataSet.colors = pieChartColors[index]
            pieChartDataSet.drawValuesEnabled = false

            let pieChartData = PieChartData(xVals: labels, dataSet: pieChartDataSet)
            self.rings[index].data = pieChartData

            let attrs = [NSFontAttributeName: UIFont(name: "GothamBook", size: studyLabelFontSize)!,
                         NSForegroundColorAttributeName: UIColor.whiteColor(),
                         NSBackgroundColorAttributeName: UIColor.clearColor()]

            let ringText = MetricSuffixFormatter.sharedInstance.formatDouble(value) + OurStudyViewController.ringUnits[index]
            self.rings[index].centerAttributedText = NSMutableAttributedString(string: ringText, attributes: attrs)
            self.rings[index].centerTextRadiusPercent = 100.0
            self.rings[index].setNeedsDisplay()
        }
    }
}