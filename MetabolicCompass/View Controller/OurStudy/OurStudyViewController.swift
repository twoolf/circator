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

let studyLabelAttrs: [String: AnyObject] = [
    NSForegroundColorAttributeName: UIColor.whiteColor(),
    NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue)
]

public class OurStudyViewController: UIViewController, ChartViewDelegate {

    var scrollView: UIScrollView!

    // Data model.
    var userRank: Int = 1
    var ringValues: [(Double, Double)] = []
    var fullDays: Int = 0
    var partialDays: Int = 0

    // UI Components.
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
        let bar = BalanceBarView(title: title, color1: OurStudyViewController.red, color2: OurStudyViewController.grey)
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
        (2,    "icon-rock",              "You're chipping away at becoming a contributor, stay steady to grow your awareness"),
        (3,    "icon-quill",             "Your penmanship is improving and you're writing more and more activities!"),
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

    lazy var userRankingBadge: UIStackView =
        UIComponents.createNumberWithImageAndLabel(
            "Your Contributions Rank", imageName: "icon-gold-medal",
            titleAttrs: studyLabelAttrs, bodyFontSize: studyContributionFontSize,
            labelFontSize: studyLabelFontSize, labelSpacing: 0.0, value: 1.0, unit: "%", prefix: "Top", suffix: "of all users")

    lazy var contributionStreakBadge: UIStackView =
        UIComponents.createNumberWithImageAndLabel(
            "Your Contributions Streak", imageName: "icon-gold-medal", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyLabelFontSize, unitsFontSize: studyLabelFontSize, labelFontSize: studyLabelFontSize,
            labelSpacing: 0.0, value: 1.0, unit: "straight days", prefix: "You've logged", suffix: "")

    // Metrics.

    lazy var fullDaysLabel: UIStackView =
        UIComponents.createNumberLabel(
            "Full Days Tracked", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize-2.0, value: 0.0, unit: "days")

    lazy var partialDaysLabel: UIStackView =
        UIComponents.createNumberLabel(
            "Partial Days Tracked", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyBodyFontSize, labelFontSize: studyLabelFontSize-2.0, value: 0.0, unit: "days")


    var phaseProgressTip: TapTip! = nil
    var fullDaysTip: TapTip! = nil
    var partialDaysTip: TapTip! = nil
    var userRankingTip: TapTip! = nil
    var contributionStreakTip: TapTip! = nil

    var activityIndicator: UIActivityIndicatorView! = nil

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
        setupActivityIndicator()

        refreshData()
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentViewWithName("Our Study",
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

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

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

        let labelStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [fullDaysLabel, partialDaysLabel])
            stack.axis = .Horizontal
            stack.distribution = UIStackViewDistribution.FillEqually
            stack.alignment = UIStackViewAlignment.Fill
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
            phaseProgress.topAnchor.constraintEqualToAnchor(scrollView.topAnchor, constant: 10),
            phaseProgress.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            phaseProgress.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            phaseProgress.heightAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.2),
            userRankingBadge.topAnchor.constraintEqualToAnchor(phaseProgress.bottomAnchor, constant: 10),
            userRankingBadge.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: 10),
            userRankingBadge.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -10),
            userRankingBadge.heightAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.3),
            contributionStreakBadge.topAnchor.constraintEqualToAnchor(userRankingBadge.bottomAnchor),
            contributionStreakBadge.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor, constant: 10),
            contributionStreakBadge.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor, constant: -10),
            contributionStreakBadge.heightAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.4)
        ]

        if let imageLabelStack = userRankingBadge.subviews[1] as? UIStackView,
            badge = imageLabelStack.subviews[0] as? UIImageView
        {
            phaseConstraints.append(badge.widthAnchor.constraintEqualToConstant(64.0))
            phaseConstraints.append(badge.heightAnchor.constraintEqualToAnchor(badge.widthAnchor))
        }

        if let imageLabelStack = contributionStreakBadge.subviews[1] as? UIStackView,
            badge = imageLabelStack.subviews[0] as? UIImageView
        {
            phaseConstraints.append(badge.widthAnchor.constraintEqualToConstant(64.0))
            phaseConstraints.append(badge.heightAnchor.constraintEqualToAnchor(badge.widthAnchor))
        }

        view.addConstraints(phaseConstraints)

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
            let tipView = chart.subviews[index == 2 ? 0 : 1]
            let tip = TapTip(forView: tipView, withinView: scrollView, text: desc, width: 350, numTaps: 1, numTouches: 1, asTop: index == 2)
            self.ringTips.append(tip)
            tipView.addGestureRecognizer(tip.tapRecognizer)

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
        scrollView.addSubview(labelledRings)

        let ringHeightMultiplier: CGFloat = UIScreen.mainScreen().bounds.size.height < 569 ? 1.0 : 0.7

        let constraints: [NSLayoutConstraint] = [
            labelledRings.topAnchor.constraintEqualToAnchor(contributionStreakBadge.bottomAnchor, constant: 20),
            labelledRings.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            labelledRings.widthAnchor.constraintEqualToAnchor(view.widthAnchor),
            labelledRings.heightAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: ringHeightMultiplier),
            labelStack.topAnchor.constraintEqualToAnchor(labelledRings.bottomAnchor, constant: 40.0),
            labelStack.bottomAnchor.constraintEqualToAnchor(scrollView.bottomAnchor),
            labelStack.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            labelStack.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
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


    // TODO: cache results for 1-5 mins
    func refreshData() {
        PopulationHealthManager.sharedManager.fetchStudyStats { (success, payload) in
            if success && payload != nil { self.refreshStudyStats(payload) }
            self.activityIndicator.stopAnimating()
        }
    }

    func refreshStudyStats(payload: AnyObject?) {
        if let response = payload as? [String:AnyObject],
            studystats = response["result"] as? [String:AnyObject]
        {
            if let r = studystats["user_rank"] as? Int {
                refreshUserRanking(r)
            } else if let s = studystats["user_rank"] as? String, r = Int(s) {
                refreshUserRanking(r)
            }

            /*
            if let r = studystats["contribution_streak"] as? Int {
                refreshContributionStreak(r)
            } else if let s = studystats["contribution_streak"] as? String, r = Int(s) {
                refreshContributionStreak(r)
            }
            */
            refreshContributionStreak(91)

            if let u = studystats["active_users"] as? Int {
                refreshUserGrowth(u)
            } else if let s = studystats["active_users"] as? String, u = Int(s) {
                refreshUserGrowth(u)
            }

            refreshStudyRings(studystats)

            if let label = fullDaysLabel.subviews[1] as? UILabel {
                if let f = studystats["full_days"] as? Int  {
                    label.attributedText = OurStudyViewController.collectedDaysLabelText(f, unit: "days")
                } else if let s = studystats["full_days"] as? String, f = Int(s) {
                    label.attributedText = OurStudyViewController.collectedDaysLabelText(f, unit: "days")
                }
            }

            if let label = partialDaysLabel.subviews[1] as? UILabel {
                if let p = studystats["partial_days"] as? Int {
                    label.attributedText = OurStudyViewController.collectedDaysLabelText(p, unit: "days")
                } else if let s = studystats["partial_days"] as? String, p = Int(s) {
                    label.attributedText = OurStudyViewController.collectedDaysLabelText(p, unit: "days")
                }
            }

        } else {
            log.error("Failed to refresh study stats from \(payload)")
        }
    }

    func refreshUserRanking(rank: Int) {
        userRank = rank
        if let imageLabelStack = userRankingBadge.subviews[1] as? UIStackView,
               badge = imageLabelStack.subviews[0] as? UIImageView,
               label = imageLabelStack.subviews[1] as? UILabel
        {
            label.attributedText = OurStudyViewController.userRankingLabelText(userRank)
            label.setNeedsDisplay()
            let (_, icon) = OurStudyViewController.userRankingClassAndIcon(userRank)
            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        } else {
            log.error("OUR STUDY could not get ranking badge/label")
        }
    }

    func refreshContributionStreak(days: Int) {
        if let imageLabelStack = contributionStreakBadge.subviews[1] as? UIStackView,
            badge = imageLabelStack.subviews[0] as? UIImageView,
            label = imageLabelStack.subviews[1] as? UILabel
        {
            let (_, icon, desc) = OurStudyViewController.contributionStreakClassAndIcon(days)
            label.attributedText = OurStudyViewController.contributionStreakLabelText(days, description: desc, unitsFontSize: studyLabelFontSize)
            label.setNeedsDisplay()
            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        } else {
            log.error("OUR STUDY could not get contribution streak badge/label")
        }
    }

    func refreshUserGrowth(activeUsers: Int) {
        let userCount = Double(activeUsers)
        let userTarget = OurStudyViewController.userGrowthTarget(userCount)
        self.phaseProgress.ratio = CGFloat(userCount / userTarget)
        self.phaseProgress.refreshData()
        self.phaseProgress.refreshTitle(OurStudyViewController.userGrowthBarTitle(userTarget))
    }

    func refreshStudyRings(studystats: [String:AnyObject]) {
        ringValues = OurStudyViewController.ringValueDefaults.enumerate().map { (index, defaultValue) in
            var value: Double! = nil
            if let v = studystats[ringIndexKeys[index]] as? Double {
                value = v
            } else if let s = studystats[ringIndexKeys[index]] as? String, v = Double(s) {
                value = v
            }

            if value == nil {
                return defaultValue
            } else {
                if index == 1 { value = value * 100.0 }
                let target = pow(10, ceil(log10(value)))
                return (value, target)
            }
        }

        OurStudyViewController.ringNames.enumerate().forEach { (index, _) in
            let (value, maxValue) = ringValues[index]
            let labels = ["Value", "Target"]
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

    class func userGrowthTarget(activeUsers: Double) -> Double {
        if activeUsers < 100.0 { return 100.0 }
        return pow(10, ceil(log10(activeUsers)))
    }

    class func userGrowthBarTitle(target: Double) -> NSAttributedString {
        let phase = max(1, Int(log10(target)) - 1)
        let attrs = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                     NSUnderlineStyleAttributeName: NSNumber(integer: NSUnderlineStyle.StyleSingle.rawValue),
                     NSFontAttributeName: UIFont(name: "GothamBook", size: studyLabelFontSize)!]

        return NSMutableAttributedString(string: "Study Progress: Phase \(phase): \(Int(ceil(target))) users", attributes: attrs)
    }

    class func userRankingClassAndIcon(rank: Int) -> (Double, String) {
        let doubleRank = Double(rank)
        var rankIndex = OurStudyViewController.userRankingBadgeBuckets.indexOf { $0.0 >= doubleRank }
        if rankIndex == nil { rankIndex = OurStudyViewController.userRankingBadgeBuckets.count }
        rankIndex = max(0, rankIndex! - 1)
        return OurStudyViewController.userRankingBadgeBuckets[rankIndex!]
    }

    class func contributionStreakClassAndIcon(days: Int) -> (Double, String, String) {
        let doubleDays = Double(days)
        var rankIndex = OurStudyViewController.contributionStreakBadgeBuckets.indexOf { $0.0 >= doubleDays }
        if rankIndex == nil { rankIndex = OurStudyViewController.contributionStreakBadgeBuckets.count }
        rankIndex = max(0, rankIndex! - 1)
        return OurStudyViewController.contributionStreakBadgeBuckets[rankIndex!]
    }

    class func userRankingLabelText(rank: Int, unitsFontSize: CGFloat = 20.0) -> NSAttributedString {
        let prefixStr = "Top"
        let suffixStr = "% of all users"

        let (rankClass, _) = OurStudyViewController.userRankingClassAndIcon(rank)
        let vStr = String(format: "%.2g", rankClass)
        let aStr = NSMutableAttributedString(string: prefixStr + " " + vStr + " " + suffixStr)

        let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!

        if prefixStr.characters.count > 0 {
            let headRange = NSRange(location:0, length: prefixStr.characters.count + 1)
            aStr.addAttribute(NSFontAttributeName, value: unitFont, range: headRange)
        }

        let tailRange = NSRange(location:prefixStr.characters.count + vStr.characters.count + 1, length: suffixStr.characters.count + 1)
        aStr.addAttribute(NSFontAttributeName, value: unitFont, range: tailRange)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2.0
        paragraphStyle.alignment = .Center
        aStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aStr.length))

        return aStr
    }

    class func contributionStreakLabelText(days: Int, description: String, unitsFontSize: CGFloat = 20.0) -> NSAttributedString {
        let prefixStr = "You've logged"
        let suffixStr = "straight days. \(description)"

        let vStr = "\(days)"
        let aStr = NSMutableAttributedString(string: prefixStr + " " + vStr + " " + suffixStr)

        let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!

        if prefixStr.characters.count > 0 {
            let headRange = NSRange(location:0, length: prefixStr.characters.count + 1)
            aStr.addAttribute(NSFontAttributeName, value: unitFont, range: headRange)
        }

        let tailRange = NSRange(location:prefixStr.characters.count + vStr.characters.count + 1, length: suffixStr.characters.count + 1)
        aStr.addAttribute(NSFontAttributeName, value: unitFont, range: tailRange)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4.0
        paragraphStyle.alignment = .Center
        aStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aStr.length))

        return aStr
    }

    class func collectedDaysLabelText(value: Int, unit: String, unitsFontSize: CGFloat = 20.0) -> NSAttributedString {
        let vString = "\(value)"
        let aString = NSMutableAttributedString(string: vString + " " + unit)
        let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!
        aString.addAttribute(NSFontAttributeName, value: unitFont, range: NSRange(location:vString.characters.count+1, length: unit.characters.count))
        return aString
    }
}