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

let studyBodyFontSize: CGFloat = 36.0
let studyContributionFontSize: CGFloat = 48.0
let studyLabelFontSize: CGFloat = 14.0

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
        let attrs1 = [NSFontAttributeName: UIFont(name: "GothamBook", size: studyLabelFontSize)!]
        var title = NSMutableAttributedString(string: "Study Progress: Phase 1 (100 users)", attributes: attrs1)

        let tooltip = "This progress bar indicates our near-term study deployment status and goals"
        let bar = BalanceBarView(title: title,
                                 color1: OurStudyViewController.red,
                                 color2: OurStudyViewController.grey,
                                 tooltipText: tooltip)
        return bar
    }()

    static let ringNames = ["Total Data", "Weekly Growth", "Daily Samples"]
    static let ringValues = [(1100, 10000), (0.2, 1.0), (5, 20)]

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
            "Full days tracked", bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize, value: 8.0, unit: "days")

    lazy var partialDaysLabel: UIStackView =
        UIComponents.createNumberLabel(
            "Partial days tracked", bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize, value: 11.0, unit: "days")

    lazy var userRankingBadge: UIStackView =
        UIComponents.createNumberWithImageAndLabel(
            "Your Contributions Rank", imageName: "icon-gold-medal", bodyFontSize: studyContributionFontSize,
            labelFontSize: 14.0, labelSpacing: 0.0, value: 1.0, unit: "%", prefix: "Top", suffix: "of all users")

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
            phaseProgress.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor, multiplier: 0.1),
            userRankingBadge.topAnchor.constraintEqualToAnchor(phaseProgress.bottomAnchor, constant: 20),
            userRankingBadge.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor, constant: 10),
            userRankingBadge.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor, constant: -10),
            userRankingBadge.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor, multiplier: 0.2),

        ]
        self.view.addConstraints(phaseConstraints)

        var firstChart: UIStackView! = nil

        rings.enumerate().forEach { (index, pieChart) in
            let chart: UIStackView =
                UIComponents.createLabelledComponent(
                    OurStudyViewController.ringNames[index], labelOnTop: index != 2, labelFontSize: studyLabelFontSize, labelSpacing: 0.0, value: (), constructor: {
                        _ in return pieChart
                })

            if firstChart == nil { firstChart = chart }

            chart.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(chart)

            var constraints: [NSLayoutConstraint] = []
            if index == 0 {
                constraints.appendContentsOf([
                    chart.topAnchor.constraintEqualToAnchor(userRankingBadge.bottomAnchor),
                    chart.heightAnchor.constraintGreaterThanOrEqualToAnchor(self.view.heightAnchor, multiplier: 0.25),
                    chart.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
                    chart.widthAnchor.constraintEqualToAnchor(self.view.widthAnchor, multiplier: 0.45)
                    ])
            } else if index == 1 {
                constraints.appendContentsOf([
                    chart.topAnchor.constraintEqualToAnchor(userRankingBadge.bottomAnchor),
                    chart.heightAnchor.constraintEqualToAnchor(firstChart.heightAnchor),
                    chart.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor),
                    chart.widthAnchor.constraintEqualToAnchor(firstChart.widthAnchor)
                    ])

            } else if index == 2 {
                ring2TopConstraint = chart.topAnchor.constraintEqualToAnchor(rings[0].bottomAnchor)
                constraints.appendContentsOf([
                    ring2TopConstraint,
                    chart.heightAnchor.constraintEqualToAnchor(firstChart.heightAnchor),
                    chart.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor),
                    chart.widthAnchor.constraintEqualToAnchor(firstChart.widthAnchor)
                    ])

            }
            self.view.addConstraints(constraints)
        }


        let constraints: [NSLayoutConstraint] = [
            labelStack.topAnchor.constraintEqualToAnchor(rings[2].bottomAnchor, constant: 40),
            labelStack.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            labelStack.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
            labelStack.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor),
        ]
        self.view.addConstraints(constraints)

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        if ring2TopConstraint != nil && rings.count > 0 {
            ring2TopConstraint.constant = -(rings[0].frame.height / 2)
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

            let ringText = MetricSuffixFormatter.sharedInstance.formatDouble(value)
            self.rings[index].centerAttributedText = NSMutableAttributedString(string: ringText, attributes: attrs)
            self.rings[index].centerTextRadiusPercent = 100.0
            self.rings[index].setNeedsDisplay()
        }
    }
}