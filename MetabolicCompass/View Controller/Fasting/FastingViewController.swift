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
import MetabolicCompassKit
import Async
import Charts
import SteviaLayout

private let fastingViewLabelSize: CGFloat = 12.0
private let fastingViewTextSize: CGFloat = 24.0

func createLabelledComponent<T>(title: String, labelFontSize: CGFloat, value: T, constructor: T -> UIView) -> UIStackView {
    let desc : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(labelFontSize, weight: UIFontWeightRegular)
        label.textColor = .lightGrayColor()
        label.textAlignment = .Center
        label.text = title
        return label
    }()

    let component : UIView = constructor(value)

    let stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [desc, component])
        stack.axis = .Vertical
        stack.distribution = UIStackViewDistribution.Fill
        stack.alignment = UIStackViewAlignment.Fill
        stack.spacing = 8.0
        return stack
    }()

    desc.translatesAutoresizingMaskIntoConstraints = false
    let constraints : [NSLayoutConstraint] = [
        desc.heightAnchor.constraintEqualToConstant(labelFontSize+4)
    ]

    stack.addConstraints(constraints)
    return stack
}

func createNumberLabel(title: String, labelFontSize: CGFloat, value: Double, unit: String) -> UIStackView {
    return createLabelledComponent(title, labelFontSize: labelFontSize, value: value, constructor: { value in
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(44, weight: UIFontWeightRegular)
        label.textColor = .whiteColor()
        label.textAlignment = .Center

        let vString = String(format: "%.1f", value)
        let aString = NSMutableAttributedString(string: vString + " " + unit)
        let unitFont = UIFont.systemFontOfSize(20, weight: UIFontWeightRegular)
        aString.addAttribute(NSFontAttributeName, value: unitFont, range: NSRange(location:vString.characters.count+1, length: 3))
        label.attributedText = aString
        return label
    })
}

public class FastingViewController : UIViewController, ChartViewDelegate {

    @IBOutlet weak var fastingView: UIView!

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


    lazy var pieChartColors: [NSUIColor] = {
        // Populate 15 colors. Add more if needed.
        var colors : [NSUIColor] = []
        colors.appendContentsOf(ChartColorTemplates.joyful())
        colors.appendContentsOf(ChartColorTemplates.colorful())
        colors.appendContentsOf(ChartColorTemplates.pastel())
        //colors.appendContentsOf(ChartColorTemplates.vordiplom())
        //colors.appendContentsOf(ChartColorTemplates.liberty())
        //colors.appendContentsOf(ChartColorTemplates.material())

        return GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(colors) as! [NSUIColor]
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

        let bar = BalanceBarView(title: title,
                                 color1: FastingViewController.orange,
                                 color2: FastingViewController.blue)
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

        let bar = BalanceBarView(title: title,
                                 color1: FastingViewController.yellow,
                                 color2: FastingViewController.green)
        return bar
    }()

    lazy var cwfLabel: UIStackView = createNumberLabel("Cumulative Weekly Fasting", labelFontSize: fastingViewLabelSize, value: 0.0, unit: "hrs")
    lazy var wfvLabel: UIStackView = createNumberLabel("Weekly Fasting Variability", labelFontSize: fastingViewLabelSize, value: 0.0, unit: "hrs")

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.activityIndicator.startAnimating()
        self.refreshData()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

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

        setupView()
    }

    func setupView() {
        refreshPieChart()

        let pieChartStack: UIStackView = createLabelledComponent("Data Collected This Year", labelFontSize: fastingViewLabelSize, value: (), constructor: {
            _ in return self.pieChart
        })

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
        fastingView.addSubview(stack)

        let constraints: [NSLayoutConstraint] = [
            stack.topAnchor.constraintEqualToAnchor(fastingView.topAnchor),
            stack.bottomAnchor.constraintEqualToAnchor(fastingView.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraintEqualToAnchor(fastingView.leadingAnchor),
            stack.trailingAnchor.constraintEqualToAnchor(fastingView.trailingAnchor),
            //pieChartStack.heightAnchor.constraintEqualToConstant(300),
            sleepAwakeBalance.heightAnchor.constraintEqualToConstant(60),
            eatExerciseBalance.heightAnchor.constraintEqualToConstant(60),
            labelStack.heightAnchor.constraintEqualToConstant(80),
        ]
        fastingView.addConstraints(constraints)
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
                        cwfSubLabel.text = String(format: "%.2f", self.model.cumulativeWeeklyFasting)
                    }
                    cwfSubLabel.setNeedsDisplay()
                }

                if let wfvSubLabel = self.wfvLabel.arrangedSubviews[1] as? UILabel {
                    if saTotal == 0.0 {
                        wfvSubLabel.text = "N/A"
                    } else {
                        wfvSubLabel.text = String(format: "%.2f", self.model.weeklyFastingVariability)
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

