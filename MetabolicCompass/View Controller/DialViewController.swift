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
import NVActivityIndicatorView

private let dialLegendLabelSize: CGFloat = 14.0

class DialViewController : UIViewController, ChartViewDelegate {

    var visible: Bool = false

    var activityIndicator: NVActivityIndicatorView! = nil

    lazy var pieChart: PieChartView = {
        let chart = PieChartView()
        chart.renderer = CycleChartRender(chart: chart, animator: chart.chartAnimator, viewPortHandler: chart.viewPortHandler)
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
//        chartDescription.text = ""
        chart.backgroundColor = .clear
        chart.holeColor = .clear
        chart.drawMarkers = true
        chart.drawHoleEnabled = true
//        chart.drawSliceTextEnabled = true 
        chart.drawEntryLabelsEnabled = true
        chart.usePercentValuesEnabled = false
        chart.rotationEnabled = true
        chart.rotationWithTwoFingers = true
        chart.legend.enabled = false
        return chart
    }()

    lazy var activityLegendLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "GothamBook", size: dialLegendLabelSize)!
        label.textColor = .lightGray

        let basicAttrs = [NSForegroundColorAttributeName: UIColor.white]

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
        paragraphStyle.alignment = .center
        aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))

        label.attributedText = aString

        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        label.textAlignment = .center

        return label
    }()

    private let pieTipMsg = "This heatmap shows when you've typically slept, ate and exercised in the last month"
    private var pieTip: TapTip! = nil

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.visible = true
        self.logContentView()
        self.refreshData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.logContentView(asAppear: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.visible = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentView(withName: "Cycle",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().String(DateFormat.Custom("YYYY-MM-dd:HH")),
            contentId: Date().string(),
                                       customAttributes: nil)
    }

    func setupActivityIndicator() {
        let screenSize = UIScreen.main.bounds.size
        let sz: CGFloat = screenSize.height < 569 ? 75 : 100
        let activityFrame = CGRect((screenSize.width - sz) / 2, (screenSize.height - sz) / 2, sz, sz)
        self.activityIndicator = NVActivityIndicatorView(frame: activityFrame, type: .orbit, color: UIColor.yellow)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        let constraints: [NSLayoutConstraint] = [
            activityIndicator.centerXAnchor.constraint(equalTo: pieChart.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: pieChart.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: sz),
            activityIndicator.heightAnchor.constraint(equalToConstant: sz)
        ]
        view.addConstraints(constraints)
    }

    func setupView() {

        refreshPieChart()

        let pieChartStack: UIStackView = UIComponents.createLabelledComponent(title: "Circadian Activity In The Last Month", labelFontSize: 16.0, value: (), constructor: {
            _ in return self.pieChart
        })

        pieTip = TapTip(forView: pieChart, withinView: view, text: pieTipMsg, numTouches: 2, asTop: false)
        pieChart.addGestureRecognizer(pieTip.tapRecognizer)

        let toggleRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleDatasets))
        toggleRecognizer.numberOfTapsRequired = 2
        pieChart.addGestureRecognizer(toggleRecognizer)

        pieChartStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pieChartStack)

        activityLegendLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityLegendLabel)

        let constraints: [NSLayoutConstraint] = [
            pieChartStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            pieChartStack.bottomAnchor.constraint(equalTo: activityLegendLabel.topAnchor),
            activityLegendLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            pieChartStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pieChartStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityLegendLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            activityLegendLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityLegendLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0)
        ]
        view.addConstraints(constraints)

        setupActivityIndicator()

        NotificationCenter.default.addObserver(self, selector: #selector(self.invalidateView), name: NSNotification.Name(rawValue: CDMNeedsRefresh), object: nil)
    }

    func refreshPieChart() {
        let model = AnalysisDataModel.sharedInstance.cycleModel
        var segments : [(Date, ChartDataEntry)] = []
        var colors : [UIColor] = []

        let hrType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let scType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!

        switch model.segmentIndex {
        case 0:
            segments = model.cycleSegments
            colors = model.cycleColors
        case 1:
            segments = model.measureSegments[hrType] ?? []
            colors = model.measureColors[hrType] ?? []
        default:
            segments = model.measureSegments[scType] ?? []
            colors = model.measureColors[scType] ?? []
        }
        let pieChartDataSet = PieChartDataSet(values: segments.map { $0.1 }, label: "Circadian segments")
        pieChartDataSet.colors = colors
        pieChartDataSet.drawValuesEnabled = false
        pieChartDataSet.xValuePosition = .outsideSlice
        pieChartDataSet.valueLineColor = UIColor.lightGray
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        self.pieChart.data = pieChartData
        self.pieChart.drawEntryLabelsEnabled = false
        self.pieChart.drawCenterTextEnabled = true
        self.pieChart.setNeedsDisplay()
    }

    func refreshLegend() {
        let basicAttrs = [NSForegroundColorAttributeName: UIColor.white]

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
        paragraphStyle.alignment = .center

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
        self.activityIndicator?.startAnimating()
        AnalysisDataModel.sharedInstance.cycleModel.updateData { error in
            guard error == nil else {
//                log.error(error!.localizedDescription)
                return
            }

 //           Async.main {
            OperationQueue.main.addOperation {
                self.activityIndicator?.stopAnimating()
                self.refreshPieChart()
                self.refreshLegend()
            }
        }
    }

    func toggleDatasets() {
        AnalysisDataModel.sharedInstance.cycleModel.segmentIndex =
            (AnalysisDataModel.sharedInstance.cycleModel.segmentIndex + 1) % 3

//        Async.main {
        OperationQueue.main.addOperation {
            self.refreshPieChart()
            self.refreshLegend()
        }
    }

    func invalidateView(note: NSNotification) {
        // Reload data if the view is currently visible.
        if ( self.isViewLoaded && (self.view.window != nil || self.visible) ) {
            self.refreshData()
            self.view.setNeedsDisplay()
        }
    }

    //MARK: ChartViewDelegate
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
    var entryStr = ""
    let model = AnalysisDataModel.sharedInstance.cycleModel
    let hrType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    let scType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
    var array = [(Date, ChartDataEntry)] ()

        let txtFont = UIFont.systemFont(ofSize: 20, weight: UIFontWeightRegular)
        let numberFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)

        var slRange: NSRange! = nil
        var eatRange: NSRange! = nil
        var exRange: NSRange! = nil

        switch model.segmentIndex {
        case 0:
        array = model.cycleSegments.filter { $0.1 == entry }
            if array.count == 1 {
                let date = array[0].0
                entryStr = date.string(format: DateFormat.custom("HH:mm"))
            }

            if let opt = entry.data as? [Int]?, let counts = opt {
                let sleepCount = "\(counts[0])"
                let eatCount = "\(counts[1])"
                let exCount = "\(counts[2])"

                entryStr += "\n◻︎ \(sleepCount)  ◻︎ \(eatCount)  ◻︎ \(exCount)"

                slRange = NSRange(location: 6, length: 2)
                eatRange = NSRange(location: 11 + sleepCount.characters.count, length: 1)
                exRange = NSRange(location: 16 + sleepCount.characters.count + eatCount.characters.count, length: 1)
            }

        case 1:
            array = (model.measureSegments[hrType]!.filter { $0.1 == entry })
            if array.count == 1 {
                let date = array[0].0
                entryStr = date.string(format: DateFormat.custom("HH:mm"))
            }
            if let opt = entry.y as? Double?, let bpm = opt {
                entryStr += "\n" + String(format: "%.3g", bpm) + " bpm"
            }

        case 2:
            array = (model.measureSegments[scType]!.filter { $0.1 == entry })
            if array.count == 1 {
                let date = array[0].0
                entryStr = date.string(format: DateFormat.custom("HH:mm"))
            }
            if let opt = entry.y as? Double?, let steps = opt {
                entryStr += "\n" + String(format: "%.6g", steps) + " steps"
            }

        default:
            break
        }

        let attrs : [String: AnyObject] = [
            NSFontAttributeName: txtFont,
            NSForegroundColorAttributeName: UIColor.white
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
        paragraphStyle.alignment = .center
        aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))

        pieChart.centerAttributedText = aString
        pieChart.drawCenterTextEnabled = true
    }

    func chartValueNothingSelected(chartView: ChartViewBase) {
        pieChart.centerText = ""
        pieChart.drawCenterTextEnabled = false
    }
}
