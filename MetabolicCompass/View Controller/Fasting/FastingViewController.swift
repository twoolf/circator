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
import GameplayKit

private let fastingViewLabelSize: CGFloat = 12.0
private let fastingViewTextSize: CGFloat = 24.0


public class FastingViewController : UIViewController, ChartViewDelegate {

    var scrollView: UIScrollView!

    var activityIndicator: UIActivityIndicatorView! = nil

    lazy var pieChart: PieChartView = {
        let chart = PieChartView()
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
        chart.descriptionText = ""
        chart.backgroundColor = .clear
        chart.holeColor = .clear
        chart.drawMarkers = true
        chart.drawHoleEnabled = true
//        chart.drawSliceTextEnabled = false
        chart.drawEntryLabelsEnabled = false
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

        colors.append(contentsOf: ChartColorTemplates.material())
        colors.append(contentsOf: ChartColorTemplates.colorful())
        colors.append(contentsOf: ChartColorTemplates.liberty())
        colors.append(contentsOf: ChartColorTemplates.pastel())
        colors.append(contentsOf: ChartColorTemplates.joyful())
        colors.append(contentsOf: ChartColorTemplates.vordiplom())

        return GKRandomSource.sharedRandom().arrayByShufflingObjects(in: colors) as! [NSUIColor]
        return colors
    }()

    public static let orange = ChartColorTemplates.colorful()[1]
    public static let blue   = ChartColorTemplates.joyful()[4]
    public static let yellow = ChartColorTemplates.colorful()[2]
    public static let green  = ChartColorTemplates.colorful()[3]

    // Balance bars.

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

    // Badges.

    static let fastingStreakBadgeBuckets: [(Double, String, String)] = [
        (0,   "icon-matchstick", "Your fasting levels are about to be snuffed out!"),
        (50,  "icon-candle",     "You're in a slow, steady burn."),
        (70,  "icon-lantern",    "Now you're moving, keep going with your fasting levels!"),
        (90,  "icon-torch",      "You're ready to light the next big fast."),
        (100, "icon-fireplace",  "You're basking in a warm comforting fasting level."),
        (110, "icon-bonfire",    "It's a party, you're really having fun with fasting!"),
        (120, "icon-wildfire",   "You're catching on, remember to keep track to hit the next level!"),
        (130, "icon-magma",      "You're smoldering, we can see your glow!"),
        (140, "icon-volcano",    "Careful, you might cause others' fasting levels around you to erupt!"),
        (150, "icon-sun",        "You're a fasting champion, we rise and set to your fasting levels!"),
        (160, "icon-supernova",  "You've done it, you can't burn brighter than this!"),
    ]

    lazy var fastingStreakBadge: UIStackView =
        UIComponents.createNumberWithImageAndLabel(
            title: "Your Fasting Streak", imageName: "icon-gold-medal", titleAttrs: studyLabelAttrs,
            bodyFontSize: studyLabelFontSize, unitsFontSize: studyLabelFontSize, labelFontSize: studyLabelFontSize,
            labelSpacing: 0.0, value: 1.0, unit: "hours this week", prefix: "You've fasted", suffix: "")


    // Metrics.

    lazy var cwfLabel: UIStackView = UIComponents.createNumberLabel(title: "Cumulative Weekly Fasting", labelFontSize: fastingViewLabelSize, value: 0.0, unit: "hrs")
    lazy var wfvLabel: UIStackView = UIComponents.createNumberLabel(title: "Weekly Fasting Variability", labelFontSize: fastingViewLabelSize, value: 0.0, unit: "hrs")

    private let cwfTipMsg = "Your cumulative weekly fasting is the total number of hours that you've spent fasting over the last 7 days"
    private let wfvTipMsg = "Your weekly fasting variability shows you how much your fasting hours varies day-by-day. We calculate this over the last week."

    private let fastingStreakTipMsg = "This badge shows the level of fasting you've achieved for the last week."

    private var cwfTip: TapTip! = nil
    private var wfvTip: TapTip! = nil
    private var fastingStreakTip: TapTip! = nil

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator.startAnimating()
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
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentView(withName: "Fasting",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
            contentId: Date().string(),
                                       customAttributes: nil)
    }

    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView()

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        let constraints: [NSLayoutConstraint] = [
            activityIndicator.topAnchor.constraint(equalTo: view.topAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        view.addConstraints(constraints)
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

        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false

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

        refreshPieChart()

        let pieChartStack: UIStackView = UIComponents.createLabelledComponent(title: "Data Collected This Year", labelFontSize: fastingViewLabelSize, value: (), constructor: {
            _ in return self.pieChart
        })

        setupTooltips()

        let labelStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [cwfLabel, wfvLabel])
            stack.axis = .horizontal
            stack.distribution = UIStackViewDistribution.fillEqually
            stack.alignment = UIStackViewAlignment.fill
            return stack
        }()

        let stack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [pieChartStack, fastingStreakBadge, sleepAwakeBalance, eatExerciseBalance, labelStack])
            stack.axis = .vertical
            stack.distribution = UIStackViewDistribution.fill
            stack.alignment = UIStackViewAlignment.fill
            stack.spacing = 20
            return stack
        }() 

        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        var constraints: [NSLayoutConstraint] = [
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            pieChartStack.heightAnchor.constraint(equalTo: pieChartStack.widthAnchor, multiplier: 0.8),
            fastingStreakBadge.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.33),
            sleepAwakeBalance.heightAnchor.constraint(equalToConstant: 60),
            eatExerciseBalance.heightAnchor.constraint(equalToConstant: 60),
            labelStack.heightAnchor.constraint(equalToConstant: 80),
        ]

        let badgeSize = ScreenManager.sharedInstance.badgeIconSize()

        if let imageLabelStack = fastingStreakBadge.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView
        {
            constraints.append(badge.widthAnchor.constraint(equalToConstant: badgeSize))
            constraints.append(badge.heightAnchor.constraint(equalTo: badge.widthAnchor))
        }

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
        fastingStreakTip = TapTip(forView: fastingStreakBadge, withinView: scrollView, text: fastingStreakTipMsg, asTop: true)

        cwfLabel.addGestureRecognizer(cwfTip.tapRecognizer)
        cwfLabel.isUserInteractionEnabled = true

        wfvLabel.addGestureRecognizer(wfvTip.tapRecognizer)
        wfvLabel.isUserInteractionEnabled = true

        fastingStreakBadge.addGestureRecognizer(fastingStreakTip.tapRecognizer)
        fastingStreakBadge.isUserInteractionEnabled = true

        sleepAwakeBalance.tip.withinView = scrollView
        eatExerciseBalance.tip.withinView = scrollView
    }

    func refreshPieChart() {
        let model = AnalysisDataModel.sharedInstance.fastingModel
        let pieChartDataSet = PieChartDataSet(values: model.samplesCollectedDataEntries.map { $0.1 }, label: "Samples per type")
        pieChartDataSet.colors = pieChartColors
        pieChartDataSet.drawValuesEnabled = false

        let xVals : [String] = model.samplesCollectedDataEntries.map {
            switch $0.0 {
            case .HKType(let sampleType):
                return sampleType.displayText!
            case .Other:
                return "Other"
            }
        }

//        let pieChartDataEntry = PieChartDataEntry(labels: xVals, dataSet: pieChartDataSet)
//        self.pieChart.data = pieChartDataEntry
        self.pieChart.setNeedsDisplay()
    }

    func refreshFastingStreak(fastingLevel: Double) {
        if let descLabel = fastingStreakBadge.subviews[0] as? UILabel,
            let imageLabelStack = fastingStreakBadge.subviews[1] as? UIStackView,
            let badge = imageLabelStack.subviews[0] as? UIImageView,
            let label = imageLabelStack.subviews[1] as? UILabel
        {
            let compact = UIScreen.main.bounds.size.height < 569
            let (_, icon, desc) = FastingViewController.fastingStreakClassAndIcon(fastingLevel: fastingLevel)
            let (descAttrText, lblAttrText) = FastingViewController.fastingStreakLabelText(fastingLevel: fastingLevel, description: desc, compact: compact, descFontSize: studyLabelFontSize, labelFontSize: studyLabelFontSize)

            descLabel.attributedText = descAttrText
            descLabel.setNeedsDisplay()

            label.attributedText = lblAttrText
            label.setNeedsDisplay()

            badge.image = UIImage(named: icon)
            badge.setNeedsDisplay()
        } else {
 //           log.error("FASTING could not get streak badge/label")
        }
    }

    public func refreshData() {
        //log.info("FastingViewController refreshing data")
        //let refreshStartDate = NSDate()

        AnalysisDataModel.sharedInstance.fastingModel.updateData { error in
            guard error == nil else {
//                log.error(error!.localizedDescription)
                return
            }

            //log.info("FastingViewController refreshing charts (\(NSDate().timeIntervalSinceDate(refreshStartDate)))")

//            Async.main {
            OperationQueue.main.addOperation {
                self.activityIndicator.stopAnimating()
                self.refreshPieChart()

                let cwfHours = AnalysisDataModel.sharedInstance.fastingModel.cumulativeWeeklyFasting / 3600.0
                let wfvHours = AnalysisDataModel.sharedInstance.fastingModel.weeklyFastingVariability / 3600.0

                let saTotal = AnalysisDataModel.sharedInstance.fastingModel.fastSleep + AnalysisDataModel.sharedInstance.fastingModel.fastAwake
                let eeTotal = AnalysisDataModel.sharedInstance.fastingModel.fastEat + AnalysisDataModel.sharedInstance.fastingModel.fastExercise

                self.refreshFastingStreak(fastingLevel: cwfHours)

                self.sleepAwakeBalance.ratio = saTotal == 0.0 ? -1.0 : CGFloat( AnalysisDataModel.sharedInstance.fastingModel.fastSleep / saTotal )
                self.sleepAwakeBalance.refreshData()

                self.eatExerciseBalance.ratio = eeTotal == 0.0 ? -1.0 : CGFloat( AnalysisDataModel.sharedInstance.fastingModel.fastEat / eeTotal )
                self.eatExerciseBalance.refreshData()

                if let cwfSubLabel = self.cwfLabel.arrangedSubviews[1] as? UILabel {
                    if saTotal == 0.0 {
                        cwfSubLabel.text = "N/A"
                    } else {
                        cwfSubLabel.text = String(format: "%.1f h", cwfHours)
                    }
                    cwfSubLabel.setNeedsDisplay()
                }

                if let wfvSubLabel = self.wfvLabel.arrangedSubviews[1] as? UILabel {
                    if saTotal == 0.0 {
                        wfvSubLabel.text = "N/A"
                    } else {
                        wfvSubLabel.text = String(format: "%.1f h", wfvHours)
                    }
                    wfvSubLabel.setNeedsDisplay()
                }
            }
        }
    }

    //MARK: ChartViewDelegate
    public func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: Highlight) {
        var typeIdentifier : String = ""
/*        switch AnalysisDataModel.sharedInstance.fastingModel.samplesCollectedDataEntries[entry.x].0 {
        case .HKType(let sampleType):
            typeIdentifier = HMConstants.sharedInstance.healthKitShortNames[sampleType.identifier]!
        case .Other:
            typeIdentifier = "Other"
        } */

        let numberFont = UIFont.systemFont(ofSize: 20, weight: UIFontWeightRegular)
        let smallFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)

//        let cString = typeIdentifier + "\n\(String(format: "%.1f%%", Double(entry.value) * 100.0))"
        let _ : [String: AnyObject] = [
            NSFontAttributeName: numberFont,
            NSForegroundColorAttributeName: UIColor.white
        ]

//        let aString = NSMutableAttributedString(string: cString, attributes: attrs)
//        aString.addAttribute(NSFontAttributeName, value: smallFont, range: NSRange(location:0, length: typeIdentifier.characters.count))

//        pieChart.centerAttributedText = aString
        pieChart.drawCenterTextEnabled = true
    }

    public func chartValueNothingSelected(chartView: ChartViewBase) {
        pieChart.centerText = ""
        pieChart.drawCenterTextEnabled = false
    }

    class func fastingStreakClassAndIcon(fastingLevel: Double) -> (Double, String, String) {
        var rankIndex = FastingViewController.fastingStreakBadgeBuckets.index { $0.0 >= fastingLevel }
        if rankIndex == nil { rankIndex = FastingViewController.fastingStreakBadgeBuckets.count }
        rankIndex = max(0, rankIndex! - 1)
        return FastingViewController.fastingStreakBadgeBuckets[rankIndex!]
    }

    class func fastingStreakLabelText(fastingLevel: Double, description: String, compact: Bool,
                                      descFontSize: CGFloat = 20.0, labelFontSize: CGFloat = 20.0)
        -> (NSAttributedString, NSAttributedString)
    {
        let descFont = UIFont(name: "GothamBook", size: descFontSize)!
        let labelFont = UIFont(name: "GothamBook", size: labelFontSize)!

        let vStr = String(format: "%.3g", fastingLevel)

        var descStr =  NSMutableAttributedString(string: "You've Fasted \(vStr) Hours This Week!", attributes: studyLabelAttrs)
        descStr.addAttribute(NSFontAttributeName, value: descFont, range: NSMakeRange(0, descStr.length))

        var lblStr = NSMutableAttributedString(string: description)
        lblStr.addAttribute(NSFontAttributeName, value: labelFont, range: NSMakeRange(0, lblStr.length))

        if !compact {
            descStr = NSMutableAttributedString(string: "Your Fasting Streak", attributes: studyLabelAttrs)
            descStr.addAttribute(NSFontAttributeName, value: descFont, range: NSMakeRange(0, descStr.length))

            lblStr = NSMutableAttributedString(string: "You've fasted \(vStr) hours this week. \(description)")
            lblStr.addAttribute(NSFontAttributeName, value: labelFont, range: NSMakeRange(0, lblStr.length))
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4.0
        paragraphStyle.alignment = .center

        descStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, descStr.length))
        lblStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, lblStr.length))
        
        return (descStr, lblStr)
    }
}

