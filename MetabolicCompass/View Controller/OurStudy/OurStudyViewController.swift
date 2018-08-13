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
import Crashlytics
import SwiftDate
import Charts

let studyBodyFontSize: CGFloat = 30.0
let studyContributionFontSize: CGFloat = 40.0
let ringLabelFontSize: CGFloat = 12.0
let studyLabelFontSize: CGFloat = 14.0

let studyLabelAttrs: [NSAttributedStringKey : Any] = [
    NSAttributedStringKey.foregroundColor: UIColor.white,
    NSAttributedStringKey.underlineStyle: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)
]

public class OurStudyViewController: UIViewController, ChartViewDelegate, AppActivityIndicatorContainer {
    private(set) var activityIndicator: AppActivityIndicator?

    var scrollView: UIScrollView!

    // UI Components.     
    public static let grey   = UIColor.ht_concrete()
    public static let red    = UIColor.ht_pomegranate()
    public static let orange = ChartColorTemplates.colorful()[1]
    public static let blue   = ChartColorTemplates.joyful()[4]
    public static let yellow = ChartColorTemplates.colorful()[2]
    public static let green  = ChartColorTemplates.colorful()[3]
    public static let purple  = UIColor.ht_amethyst()
    public static let clouds  = UIColor.ht_clouds()

    lazy var phaseProgress: BalanceBarView = {
        let attrs = [NSAttributedStringKey.foregroundColor: UIColor.white,
                     NSAttributedStringKey.underlineStyle: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue),
                     NSAttributedStringKey.font: UIFont(name: "GothamBook", size: studyLabelFontSize)!]

        let userCount = Double(AnalysisDataModel.sharedInstance.studyStatsModel.activeUsers)
        let userTarget = OurStudyViewController.userGrowthTarget(activeUsers: userCount)
        let ratio = userCount >= 0 ? CGFloat(userCount / userTarget) : 0.0

        let title = userCount >= 0 ? OurStudyViewController.userGrowthBarTitle(target: userTarget)
                        : NSMutableAttributedString(string: "Study Progress: N/A, please try later", attributes: attrs)

        let bar = BalanceBarView(ratio: ratio, title: title, color1: OurStudyViewController.red!, color2: OurStudyViewController.grey!)
        return bar
    }()

    static let ringNames = ["Total Study\nData Entries", "Week-over-Week\nData Growth", "Mean Daily\nUser Entries"]
    static let ringUnits = ["", "%", ""]
    static let ringValueDefaults = [(1100, 10000), (20.0, 100.0), (5, 20)]

    let ringIndexKeys = ["total_samples", "wow_growth", "mean_daily_entries"]

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
//            chartDescription.text = ""
            chart.holeRadiusPercent = 0.7
            chart.backgroundColor = .clear
            chart.holeColor = .clear
            chart.highlightPerTapEnabled = false
            chart.drawMarkers = true
            chart.drawHoleEnabled = true
//            chart.drawSliceTextEnabled = false
            chart.drawEntryLabelsEnabled = false
            chart.usePercentValuesEnabled = true
            chart.rotationEnabled = false
            chart.legend.enabled = false
            return chart
        }
    }()

    var ringTips: [TapTip] = []

    lazy var pieChartColors: [[UIColor?]] = {
        return [
            [OurStudyViewController.yellow, OurStudyViewController.green],
            [OurStudyViewController.orange, OurStudyViewController.blue],
            [OurStudyViewController.clouds, OurStudyViewController.purple]
        ]
    }()

    var ring2TopConstraint: NSLayoutConstraint! = nil

    // Badges.

    static let userRankingBadgeBuckets: [(Double, String)] = [
        (1.0,  "icon-trophy-cup-gold"),
        (2.0,  "icon-trophy-cup-silver"),
        (5.0,  "icon-trophy-cup-bronze"),
        (10.0, "icon-medallion-gold"),
        (20.0, "icon-medallion-silver"),
        (30.0, "icon-medallion-bronze"),
        (40.0, "icon-star-gold"),
        (50.0, "icon-star-silver"),
        (60.0, "icon-thumbs-up-gold"),
        (70.0, "icon-thumbs-up-silver"),
        (80.0, "icon-arms-raised-gold"),
        (90.0, "icon-arms-raised-silver")
    ]

    static let contributionStreakBadgeBuckets: [(Double, String, String)] = [
        (2,    "icon-rock",              "You're chipping away at your contributions, stay steady to grow your awareness."),
        (3,    "icon-quill",             "Your penmanship is improving, you're writing more and more activities!"),
        (5,    "icon-typewriter",        "You're keeping a steady log, well worth continuing your story"),
        (7,    "icon-polaroid",          "You've made an instant flash and your tracking is adding up"),
        (10,   "icon-pendulum",          "Tick-tock, you've hit your stride in sustaining your tracking momentum"),
        (14,   "icon-metronome",         "You're a metronome, the epitomy of timeliness in your tracking"),
        (21,   "icon-grandfather-clock", "You're chiming loudly and melodically, keep sharing your beat!"),
        (30,   "icon-sherlock",          "You've contributed clues that will solve real mysteries"),
        (60,   "icon-robot",             "You're powering an artificial intelligence, unless you already are one?"),
        (90,   "icon-satellite",         "You're a health satellite, and your intense laser beam is heating up our database!"),
        (180,  "icon-neo",               "You're a time-warping tracker, with a multidimensional mastery of your body clock!"),
        (360,  "icon-eye",               "You're a tracking master, part of an elite group that shapes our human health knowledge!"),
    ]

    lazy var userRankingBadge: UIStackView = {
        var rank = AnalysisDataModel.sharedInstance.studyStatsModel.userRank
        if rank < 0 { rank = 1 }

        let stack = UIComponents.createNumberWithImageAndLabel(
            title: "Your Contributions Rank", imageName: "icon-gold-medal",
            titleAttrs: studyLabelAttrs, bodyFontSize: studyContributionFontSize,
            labelFontSize: studyLabelFontSize, labelSpacing: 0.0, value: Double(rank), unit: "%", prefix: "Top", suffix: "of all users")

        if let imageLabelStack = stack.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView,
            let label = imageLabelStack.subviews[1] as? UILabel
        {
            label.attributedText = OurStudyViewController.userRankingLabelText(rank: rank)
            label.setNeedsDisplay()
            let (_, icon) = OurStudyViewController.userRankingClassAndIcon(rank: rank)
            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        }

        return stack
    }()

    lazy var contributionStreakBadge: UIStackView = {
        var streak = AnalysisDataModel.sharedInstance.studyStatsModel.contributionStreak
        if streak < 0 { streak = 0 }

        let stack = UIComponents.createNumberWithImageAndLabel(
            title: "Your Contributions Streak", imageName: "icon-gold-medal", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyLabelFontSize, unitsFontSize: studyLabelFontSize, labelFontSize: studyLabelFontSize,
            labelSpacing: 0.0, value: 1.0, unit: "straight days", prefix: "You've logged", suffix: "")

        if let descLabel = stack.subviews[0] as? UILabel,
            let imageLabelStack = stack.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView,
            let label = imageLabelStack.subviews[1] as? UILabel
        {
            let compact = UIScreen.main.bounds.size.height < 569
            let (_, icon, desc) = OurStudyViewController.contributionStreakClassAndIcon(days: streak)
            let (descAttrText, labelAttrText) = OurStudyViewController.contributionStreakLabelText(days: streak, description: desc, compact: compact, descFontSize: studyLabelFontSize, labelFontSize: studyLabelFontSize)

            descLabel.attributedText = descAttrText
            descLabel.setNeedsDisplay()

            label.attributedText = labelAttrText
            label.setNeedsDisplay()

            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        }

        return stack
    }()

    // Metrics.  

    lazy var fullDaysLabel: UIStackView = {
        var fullDays = AnalysisDataModel.sharedInstance.studyStatsModel.fullDays

        let stack = UIComponents.createNumberLabel(
            title: "Full Days Tracked", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize-2.0, value: 0.0, unit: "days")

        if let label = stack.subviews[1] as? UILabel {
            if fullDays >= 0 {
                label.attributedText = OurStudyViewController.collectedDaysLabelText(value: fullDays, unit: "days")
            } else {
                label.attributedText = NSAttributedString(string: "N/A")
            }
        }

        return stack
    }()

    lazy var partialDaysLabel: UIStackView = {
        var partialDays = AnalysisDataModel.sharedInstance.studyStatsModel.partialDays

        let stack = UIComponents.createNumberLabel(
            title: "Partial Days Tracked", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize-2.0, value: 0.0, unit: "days")

        if let label = stack.subviews[1] as? UILabel {
            if partialDays >= 0 {
                label.attributedText = OurStudyViewController.collectedDaysLabelText(value: partialDays, unit: "days")
            } else {
                label.attributedText = NSAttributedString(string: "N/A")
            }
        }

        return stack
    }()


    var phaseProgressTip: TapTip! = nil
    var fullDaysTip: TapTip! = nil
    var partialDaysTip: TapTip! = nil
    var userRankingTip: TapTip! = nil
    var contributionStreakTip: TapTip! = nil

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showActivity()
        self.logContentView()
        self.refreshData()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.logContentView(asAppear: false)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupActivityIndicator()

        refreshData()
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentView(withName: "Our Study",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
            contentId: Date().string(),
                                       customAttributes: nil)
    }

    func setupActivityIndicator() {
        self.activityIndicator = AppActivityIndicator.forView(container: view)
    }

    func setupBackground() {
        let backgroundImage = UIImageView(image: UIImage(named: "university_logo"))
        backgroundImage.contentMode = .center
        backgroundImage.layer.opacity = 0.03
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(backgroundImage, at: 0)

        let bgConstraints: [NSLayoutConstraint] = [
            backgroundImage.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            backgroundImage.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ]

        self.view.addConstraints(bgConstraints)
    }

    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.isUserInteractionEnabled = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let scrollConstraints: [NSLayoutConstraint] = [
            view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ]
        view.addConstraints(scrollConstraints)
    }

    func setupView() {

        setupBackground()

        setupScrollView()

        let labelStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [fullDaysLabel, partialDaysLabel])
            stack.axis = .horizontal
            stack.distribution = UIStackViewDistribution.fillEqually
            stack.alignment = UIStackViewAlignment.fill
            return stack
        }()

        phaseProgress.translatesAutoresizingMaskIntoConstraints = false
        userRankingBadge.translatesAutoresizingMaskIntoConstraints = false
        contributionStreakBadge.translatesAutoresizingMaskIntoConstraints = false
        labelStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(phaseProgress)
        scrollView.addSubview(userRankingBadge)
        scrollView.addSubview(contributionStreakBadge)
        scrollView.addSubview(labelStack)

        var phaseConstraints: [NSLayoutConstraint] = [
            phaseProgress.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            phaseProgress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            phaseProgress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            phaseProgress.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            userRankingBadge.topAnchor.constraint(equalTo: phaseProgress.bottomAnchor, constant: 10),
            userRankingBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            userRankingBadge.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            userRankingBadge.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            contributionStreakBadge.topAnchor.constraint(equalTo: userRankingBadge.bottomAnchor),
            contributionStreakBadge.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            contributionStreakBadge.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            contributionStreakBadge.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4)
        ]

        let badgeSize = ScreenManager.sharedInstance.badgeIconSize()

        if let imageLabelStack = userRankingBadge.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView
        {
            phaseConstraints.append(badge.widthAnchor.constraint(equalToConstant: badgeSize))
            phaseConstraints.append(badge.heightAnchor.constraint(equalTo: badge.widthAnchor))
        }

        if let imageLabelStack = contributionStreakBadge.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView
        {
            phaseConstraints.append(badge.widthAnchor.constraint(equalToConstant: badgeSize))
            phaseConstraints.append(badge.heightAnchor.constraint(equalTo: badge.widthAnchor))
        }

        view.addConstraints(phaseConstraints)

        let compositeView = UIView()
        compositeView.translatesAutoresizingMaskIntoConstraints = false

        var firstChart: UIStackView! = nil

        rings.enumerated().forEach { (index, pieChart) in
            let chart: UIStackView =
                UIComponents.createLabelledComponent(
                    title: OurStudyViewController.ringNames[index], labelOnTop: index != 2, labelFontSize: ringLabelFontSize, labelSpacing: 0.0, value: (), constructor: {
                        _ in return pieChart
                })

            if firstChart == nil { firstChart = chart }

            chart.translatesAutoresizingMaskIntoConstraints = false
            compositeView.addSubview(chart)

            let desc = OurStudyViewController.ringDescriptions[index]
            let tipView = chart.subviews[index == 2 ? 0 : 1]
            let tip = TapTip(forView: tipView, withinView: scrollView, text: desc, width: 350, numTaps: 1, numTouches: 1, asTop: index == 2)
            self.ringTips.append(tip)
            tipView.addGestureRecognizer(tip.tapRecognizer)

            var constraints: [NSLayoutConstraint] = []
            if index == 0 {
                constraints.append(contentsOf: [
                    chart.topAnchor.constraint(equalTo: compositeView.topAnchor, constant: 10),
                    chart.heightAnchor.constraint(greaterThanOrEqualTo: compositeView.heightAnchor, multiplier: 0.66),
                    chart.leadingAnchor.constraint(equalTo: compositeView.leadingAnchor, constant: -5),
                    chart.widthAnchor.constraint(equalTo: compositeView.widthAnchor, multiplier: 0.45)
                    ])
            } else if index == 1 {
                constraints.append(contentsOf: [
                    chart.topAnchor.constraint(equalTo: compositeView.topAnchor, constant: 10),
                    chart.heightAnchor.constraint(equalTo: firstChart.heightAnchor),
                    chart.trailingAnchor.constraint(equalTo: compositeView.trailingAnchor, constant: 5),
                    chart.widthAnchor.constraint(equalTo: firstChart.widthAnchor)
                    ])

            } else if index == 2 {
                ring2TopConstraint = chart.topAnchor.constraint(equalTo: firstChart.bottomAnchor)
                constraints.append(contentsOf: [
                    ring2TopConstraint,
                    chart.heightAnchor.constraint(equalTo: firstChart.heightAnchor),
                    chart.centerXAnchor.constraint(equalTo: compositeView.centerXAnchor),
                    chart.widthAnchor.constraint(equalTo: firstChart.widthAnchor)
                    ])

            }
            compositeView.addConstraints(constraints)
        }

        let labelledRings = UIComponents.createLabelledComponent(
            title: "Study-Wide Dataset Statistics", attrs: studyLabelAttrs,
            labelFontSize: studyLabelFontSize, labelSpacing: 8.0, value: (), constructor: { _ in return compositeView })

        labelledRings.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(labelledRings)

        let ringHeightMultiplier: CGFloat = UIScreen.main.bounds.size.height < 569 ? 1.0 : 0.7

        let constraints: [NSLayoutConstraint] = [
            labelledRings.topAnchor.constraint(equalTo: contributionStreakBadge.bottomAnchor, constant: 20),
            labelledRings.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            labelledRings.widthAnchor.constraint(equalTo: view.widthAnchor),
            labelledRings.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: ringHeightMultiplier),
            labelStack.topAnchor.constraint(equalTo: labelledRings.bottomAnchor, constant: 40.0),
            labelStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            labelStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]

        view.addConstraints(constraints)

        setupToolTips()

        // Adjust middle ring vertical placement.
        view.setNeedsLayout()
        view.layoutIfNeeded()

        if ring2TopConstraint != nil && rings.count > 0 {
            ring2TopConstraint.constant = -(rings[0].frame.height / 2.5)
        }
        view.layoutIfNeeded()
    }

    // Tooltips
    func setupToolTips() {
        let phaseProgressDesc = "This bar shows the number of users actively contributing data in our study, relative to our participation goals for the current phase of the study"
        phaseProgressTip = TapTip(forView: phaseProgress, withinView: scrollView, text: phaseProgressDesc, width: 350, numTaps: 1, numTouches: 1, asTop: false)
        phaseProgress.addGestureRecognizer(phaseProgressTip.tapRecognizer)

        let fullDayDesc = "This label shows the number of days where you have contributed a sleep event and at least one meal or exercise event. We call this a Full Data day."
        fullDaysTip = TapTip(forView: fullDaysLabel, withinView: scrollView, text: fullDayDesc, width: 350, numTaps: 1, numTouches: 1, asTop: true)
        fullDaysLabel.addGestureRecognizer(fullDaysTip.tapRecognizer)

        let partialDayDesc = "This label shows the number of days where you have contributed any sleep, meal or exercise event. We call this a Partial Data day."
        partialDaysTip = TapTip(forView: partialDaysLabel, withinView: scrollView, text: partialDayDesc, width: 350, numTaps: 1, numTouches: 1, asTop: true)
        partialDaysLabel.addGestureRecognizer(partialDaysTip.tapRecognizer)

        let userRankingDesc = "This label shows your ranking relative to other study users, based on the number of circadian events you have tracked."
        userRankingTip = TapTip(forView: userRankingBadge, withinView: scrollView, text: userRankingDesc, width: 350, numTaps: 1, numTouches: 1, asTop: false)
        userRankingBadge.addGestureRecognizer(userRankingTip.tapRecognizer)

        let contributionStreakDesc = "This label shows how many straight days you've tracked at least one meal and a sleep activitiy."
        contributionStreakTip = TapTip(forView: contributionStreakBadge, withinView: scrollView, text: contributionStreakDesc, width: 350, numTaps: 1, numTouches: 1, asTop: false)
        contributionStreakBadge.addGestureRecognizer(contributionStreakTip.tapRecognizer)
    }


    func refreshData() {
        AnalysisDataModel.sharedInstance.refreshStudyStats(ringIndexKeys: ringIndexKeys) { success in
            if success {
                let studystats = AnalysisDataModel.sharedInstance.studyStatsModel
                self.refreshUserGrowth(activeUsers: studystats.activeUsers)
                self.refreshUserRanking(rank: studystats.userRank)
                self.refreshContributionStreak(days: studystats.contributionStreak)
                self.refreshDaysCollected(fullDays: studystats.fullDays, partialDays: studystats.partialDays)
                self.refreshStudyRings(ringValues: studystats.ringValues)
            }
            else {
//                log.error("STUDYSTATS Failed to refresh from server")
            }

            self.hideActivity()
        }
    }

    func refreshUserRanking(rank: Int) {
        if let imageLabelStack = userRankingBadge.subviews[1] as? UIStackView,
               let badge = imageLabelStack.subviews[0] as? UIImageView,
               let label = imageLabelStack.subviews[1] as? UILabel
        {
            label.attributedText = OurStudyViewController.userRankingLabelText(rank: rank)
            label.setNeedsDisplay()
            let (_, icon) = OurStudyViewController.userRankingClassAndIcon(rank: rank)
            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        } else {
//            log.error("OUR STUDY could not get ranking badge/label")
        }
    }

    func refreshContributionStreak(days: Int) {
        if let descLabel = contributionStreakBadge.subviews[0] as? UILabel,
            let imageLabelStack = contributionStreakBadge.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView,
            let label = imageLabelStack.subviews[1] as? UILabel
        {
            let compact = UIScreen.main.bounds.size.height < 569
            let (_, icon, desc) = OurStudyViewController.contributionStreakClassAndIcon(days: days)
            let (descAttrText, labelAttrText) = OurStudyViewController.contributionStreakLabelText(days: days, description: desc, compact: compact, descFontSize: studyLabelFontSize, labelFontSize: studyLabelFontSize)

            descLabel.attributedText = descAttrText
            descLabel.setNeedsDisplay()

            label.attributedText = labelAttrText
            label.setNeedsDisplay()

            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        } else {
//            log.error("OUR STUDY could not get contribution streak badge/label")
        }
    }

    func refreshDaysCollected(fullDays: Int, partialDays: Int) {
        if let label = fullDaysLabel.subviews[1] as? UILabel {
            if fullDays >= 0 {
                label.attributedText = OurStudyViewController.collectedDaysLabelText(value: fullDays, unit: "days")
            } else {
                label.attributedText = NSAttributedString(string: "N/A")
            }
        }

        if let label = partialDaysLabel.subviews[1] as? UILabel {
            if partialDays >= 0 {
                label.attributedText = OurStudyViewController.collectedDaysLabelText(value: partialDays, unit: "days")
            } else {
                label.attributedText = NSAttributedString(string: "N/A")
            }
        }
    }
    
    func refreshUserGrowth(activeUsers: Int) {
        if activeUsers < 0 {
            self.phaseProgress.ratio = 0.0
            self.phaseProgress.refreshData()

            let attrs = [NSAttributedStringKey.foregroundColor: UIColor.white,
                         NSAttributedStringKey.underlineStyle: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue),
                         NSAttributedStringKey.font: UIFont(name: "GothamBook", size: studyLabelFontSize)!]

            let aStr = NSMutableAttributedString(string: "Study Progress: N/A, please try later", attributes: attrs)
            self.phaseProgress.refreshTitle(aStr)
        }
        else {
            let userCount = Double(activeUsers)
            let userTarget = OurStudyViewController.userGrowthTarget(activeUsers: userCount)
            self.phaseProgress.ratio = CGFloat(userCount / userTarget)
            self.phaseProgress.refreshData()
            self.phaseProgress.refreshTitle(OurStudyViewController.userGrowthBarTitle(target: userTarget))
        }
    }

    func refreshStudyRings(ringValues: [(Double, Double)]) {
        let attrs = [NSAttributedStringKey.font: UIFont(name: "GothamBook", size: studyLabelFontSize)!,
                     NSAttributedStringKey.foregroundColor: UIColor.white,
                     NSAttributedStringKey.backgroundColor: UIColor.clear]
        
        OurStudyViewController.ringNames.enumerated().forEach { (index, _) in
            let (value, maxValue) = ringValues[index]

            var ringText: String = "N/A"
            var pieChartDataSet = PieChartDataSet(values: [], label: "")
            var pieChartLabels: [String] = []

            if value >= 0 || maxValue >= 0 {
                let entries = [value, maxValue - value].enumerated().map { return ChartDataEntry(x: $0.1, y: Double($0.0)) }

                ringText = MetricSuffixFormatter.sharedInstance.formatDouble(i: value) + OurStudyViewController.ringUnits[index]

                pieChartDataSet = PieChartDataSet(values: entries, label: "")
//                pieChartLabels = ["Value", "Target"]
                pieChartLabels = ["Value"]
            }

            pieChartDataSet.colors = pieChartColors[index] as! [NSUIColor]
            pieChartDataSet.drawValuesEnabled = false

//            let pieChartDataEntry = PieChartDataEntry(x: pieChartLabels, dataSet: pieChartDataSet)
//            let pieChartData = PieChartDataEntry(value: 1.0, label: pieChartLabels, data: pieChartDataSet)
//            self.rings[index].data = pieChartData

            self.rings[index].centerAttributedText = NSMutableAttributedString(string: ringText, attributes: attrs)
            self.rings[index].centerTextRadiusPercent = 100.0
            self.rings[index].setNeedsDisplay()
        }
    }

    class func userGrowthTarget(activeUsers: Double) -> Double {
        if activeUsers < 100.0 { return 100.0 }
        return pow(10, ceil(log10(activeUsers)))
    }

    class func userGrowthBarTitle(target: Double) -> NSAttributedString {
        let phase = max(1, Int(log10(target)) - 1)
        let attrs = [NSAttributedStringKey.foregroundColor: UIColor.white,
                     NSAttributedStringKey.underlineStyle: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue),
                     NSAttributedStringKey.font: UIFont(name: "GothamBook", size: studyLabelFontSize)!]

        return NSMutableAttributedString(string: "Study Progress: Phase \(phase): \(Int(ceil(target))) users", attributes: attrs)
    }

    class func userRankingClassAndIcon(rank: Int) -> (Double, String) {
        let doubleRank = Double(rank)
        var rankIndex = OurStudyViewController.userRankingBadgeBuckets.index { $0.0 >= doubleRank }
        if rankIndex == nil { rankIndex = OurStudyViewController.userRankingBadgeBuckets.count }
        rankIndex = max(0, rankIndex! - 1)
        return OurStudyViewController.userRankingBadgeBuckets[rankIndex!]
    }

    class func contributionStreakClassAndIcon(days: Int) -> (Double, String, String) {
        let doubleDays = Double(days)
        var rankIndex = OurStudyViewController.contributionStreakBadgeBuckets.index { $0.0 >= doubleDays }
        if rankIndex == nil { rankIndex = OurStudyViewController.contributionStreakBadgeBuckets.count }
        rankIndex = max(0, rankIndex! - 1)
        return OurStudyViewController.contributionStreakBadgeBuckets[rankIndex!]
    }

    class func userRankingLabelText(rank: Int, unitsFontSize: CGFloat = 20.0) -> NSAttributedString {
        var aStr = NSMutableAttributedString(string: "")

        if rank >= 0 {
            let prefixStr = "Top"
            let suffixStr = "% of all users"

            let (rankClass, _) = OurStudyViewController.userRankingClassAndIcon(rank: rank)
            let vStr = String(format: "%.2g", rankClass)
            aStr = NSMutableAttributedString(string: prefixStr + " " + vStr + " " + suffixStr)

            let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!

            if prefixStr.count > 0 {
                let headRange = NSRange(location:0, length: prefixStr.count + 1)
                aStr.addAttribute(NSAttributedStringKey.font, value: unitFont, range: headRange)
            }

            let tailRange = NSRange(location: prefixStr.count + vStr.count + 1, length: suffixStr.count + 1)
            aStr.addAttribute(NSAttributedStringKey.font, value: unitFont, range: tailRange)
        }
        else {
            aStr = NSMutableAttributedString(string: "Not available, please try later")
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.0
        paragraphStyle.alignment = .center
        aStr.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, aStr.length))

        return aStr
    }

    class func contributionStreakLabelText(days: Int, description: String, compact: Bool,
                                           descFontSize: CGFloat = 20.0, labelFontSize: CGFloat = 20.0)
                    -> (NSAttributedString, NSAttributedString)
    {
        let descFont = UIFont(name: "GothamBook", size: descFontSize)!
        let labelFont = UIFont(name: "GothamBook", size: labelFontSize)!

        var descStr =  NSMutableAttributedString(string: "You've Logged \(days) Straight Days!", attributes: studyLabelAttrs)
        descStr.addAttribute(NSAttributedStringKey.font, value: descFont, range: NSMakeRange(0, descStr.length))

        var lblStr = NSMutableAttributedString(string: description)
        lblStr.addAttribute(NSAttributedStringKey.font, value: labelFont, range: NSMakeRange(0, lblStr.length))

        if days < 0 {
            descStr = NSMutableAttributedString(string: "Your Contributions Streak", attributes: studyLabelAttrs)
            descStr.addAttribute(NSAttributedStringKey.font, value: descFont, range: NSMakeRange(0, descStr.length))

            lblStr = NSMutableAttributedString(string: "Not available, please try later")
            lblStr.addAttribute(NSAttributedStringKey.font, value: labelFont, range: NSMakeRange(0, lblStr.length))
        }
        else if !compact {
            descStr = NSMutableAttributedString(string: "Your Contributions Streak", attributes: studyLabelAttrs)
            descStr.addAttribute(NSAttributedStringKey.font, value: descFont, range: NSMakeRange(0, descStr.length))

            lblStr = NSMutableAttributedString(string: "You've logged \(days) straight days. \(description)")
            lblStr.addAttribute(NSAttributedStringKey.font, value: labelFont, range: NSMakeRange(0, lblStr.length))
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4.0
        paragraphStyle.alignment = .center

        descStr.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, descStr.length))
        lblStr.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, lblStr.length))

        return (descStr, lblStr)
    }

    class func collectedDaysLabelText(value: Int, unit: String, unitsFontSize: CGFloat = 20.0) -> NSAttributedString {
        let vString = "\(value)"
        let aString = NSMutableAttributedString(string: vString + " " + unit)
        let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!
        aString.addAttribute(NSAttributedStringKey.font, value: unitFont, range: NSRange(location:vString.count+1, length: unit.count))
        return aString
    }
}
