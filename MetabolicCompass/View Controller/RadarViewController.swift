//
//  RadarViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.   
//

import Foundation
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Charts
import Crashlytics
import SwiftDate
import Async

/**
 This class controls the display of the Radar screen (2nd view of dashboard). The radar screen gives a spider like view of how the users data compares to the population data. Our user input, to this date, suggests that many users prefer this to the numbers on the first view of the dashboard.
 
 - note: use of logistic function (normalizeType) to enable shared plot
 */
class RadarViewController : UIViewController, ChartViewDelegate {

    var logisticParametersByType : [Bool: [String: (Double, Double)]] =
    [ true: [ HKCategoryTypeIdentifier.sleepAnalysis.rawValue              : (6.7,0.328),
              HKQuantityTypeIdentifier.bodyMass.rawValue                   : (88.7,0.0248),
              HKQuantityTypeIdentifier.bodyMassIndex.rawValue              : (28.6,0.0768),
              HKQuantityTypeIdentifier.heartRate.rawValue                  : (69.0,0.0318),
              HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue      : (119.6,0.01837),
              HKQuantityTypeIdentifier.stepCount.rawValue                  : (6000,0.000366),
              HKQuantityTypeIdentifier.activeEnergyBurned.rawValue         : (2750,0.00079899),
              HKQuantityTypeIdentifier.uvExposure.rawValue                 : (12.0,0.183),
              HKWorkoutTypeIdentifier                            : (12.0,0.183),
              HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue      : (2794.5,0.000786),
              HKQuantityTypeIdentifier.dietaryProtein.rawValue             : (106.6,0.0206),
              HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue       : (333.6,0.0067),
              HKQuantityTypeIdentifier.dietarySugar.rawValue               : (149.4,0.0147),
              HKQuantityTypeIdentifier.dietaryFiber.rawValue               : (18.8,0.11687),
              HKQuantityTypeIdentifier.dietaryFatTotal.rawValue            : (102.6,0.2142),
              HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue        : (33.5,0.0656),
              HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue  : (38.2,0.0575),
              HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue  : (21.9,0.10003),
              HKQuantityTypeIdentifier.dietaryCholesterol.rawValue         : (375.5,0.00585),
              HKQuantityTypeIdentifier.dietarySodium.rawValue              : (4463.8,0.0004922),
              HKQuantityTypeIdentifier.dietaryCaffeine.rawValue            : (173.1,0.01269),
              HKQuantityTypeIdentifier.dietaryWater.rawValue               : (1208.5,0.001818)
            ],
     false: [HKCategoryTypeIdentifier.sleepAnalysis.rawValue               : (6.9,0.318),
             HKQuantityTypeIdentifier.bodyMass.rawValue                    : (77.0,0.0285),
             HKQuantityTypeIdentifier.bodyMassIndex.rawValue               : (29.1,0.0755),
             HKQuantityTypeIdentifier.heartRate.rawValue                   : (74,0.02969),
             HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue       : (111.1,0.01978),
             HKQuantityTypeIdentifier.stepCount.rawValue                   : (6000,0.000366),
             HKQuantityTypeIdentifier.activeEnergyBurned.rawValue          : (2750,0.00079899),
             HKQuantityTypeIdentifier.uvExposure.rawValue                  : (12,0.183),
             HKWorkoutTypeIdentifier                             : (12.0,0.183),
             HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue       : (1956.3,0.0011),
             HKQuantityTypeIdentifier.dietaryProtein.rawValue              : (73.5,0.02989),
             HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue        : (246.4,0.0089),
             HKQuantityTypeIdentifier.dietarySugar.rawValue                : (115.4,0.0190),
             HKQuantityTypeIdentifier.dietaryFiber.rawValue                : (15.2,0.14455),
             HKQuantityTypeIdentifier.dietaryFatTotal.rawValue             : (73.5,0.02989),
             HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue         : (24.5,0.08968),
             HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue   : (26.6,0.0826),
             HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue   : (16.1,0.1365),
             HKQuantityTypeIdentifier.dietaryCholesterol.rawValue          : (258,0.008516),
             HKQuantityTypeIdentifier.dietarySodium.rawValue               : (3138.7,0.000700),
             HKQuantityTypeIdentifier.dietaryCaffeine.rawValue             : (137.4,0.01599),
             HKQuantityTypeIdentifier.dietaryWater.rawValue                : (1127.7,0.001948)
        ]]

    var logisticTypeAsMale = true

    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var radarChart: MetabolicRadarChartView = {
        let chart = MetabolicRadarChartView()
        chart.renderer = MetabolicChartRender(chart: chart, animator: chart.chartAnimator, viewPortHandler: chart.viewPortHandler)
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
        chart.descriptionText = ""
        chart.rotationEnabled = false
        chart.highlightPerTapEnabled = false

        chart.yAxis.axisMinValue = 0.1
        chart.yAxis.axisRange = 1.0
        chart.yAxis.drawLabelsEnabled = false
        chart.xAxis.drawLabelsEnabled = false
//        chart.webColor = UIColor.colorWithHexString(rgb: "#042652")!
        chart.webAlpha = 1.0

        let legend = chart.legend
        legend.enabled = true
        legend.position = ScreenManager.sharedInstance.radarLegendPosition()
        legend.font = ScreenManager.appFontOfSize(size: 12)
//        legend.textColor = UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!
        legend.xEntrySpace = 50.0
        legend.yEntrySpace = 5.0
        return chart
    }()

    var radarTip: TapTip! = nil
    var radarTipDummyLabel: UILabel! = nil

    var initialImage : UIImage! = nil
    var initialMsg : String! = "HealthKit not authorized"

    var authorized : Bool = false {
        didSet {
            configureViews()
            radarChart.layoutIfNeeded()
            reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidChange), name: NSNotification.Name(rawValue: PMDidUpdateBalanceSampleTypesNotification), object: nil)
        logContentView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        logContentView(asAppear: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.authorized = AccountManager.shared.isHealthKitAuthorized
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        radarChart.layoutIfNeeded()
        reloadData()
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentView(withName: "Balance",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().String(DateFormat.Custom("YYYY-MM-dd:HH")),
                                    contentId: Date().string(),
                                       customAttributes: nil)
    }

    func contentDidChange() {
        Async.main {
            self.reloadData()
        }
    }

    func configureViews() {
        if authorized {
            configureAuthorizedView()
        } else {
            configureUnauthorizedView()
        }
    }

    func configureAuthorizedView() {
        view.subviews.forEach { $0.removeFromSuperview() }
        radarChart.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(radarChart)
        let rcConstraints: [NSLayoutConstraint] = [
            radarChart.topAnchor.constraint(equalTo: view.topAnchor),
            radarChart.leftAnchor.constraint(equalTo: view.leftAnchor),
            radarChart.rightAnchor.constraint(equalTo: view.rightAnchor),
            //radarChart.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            radarChart.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: -ScreenManager.sharedInstance.radarChartBottomIndent())
        ]
        view.addConstraints(rcConstraints)

        radarTipDummyLabel = UILabel()
        radarTipDummyLabel.isUserInteractionEnabled = false
        radarTipDummyLabel.isEnabled = false
        radarTipDummyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(radarTipDummyLabel)
        view.addConstraints([
            view.centerXAnchor.constraint(equalTo: radarTipDummyLabel.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: radarTipDummyLabel.centerYAnchor),
            radarTipDummyLabel.widthAnchor.constraint(equalToConstant: 1),
            radarTipDummyLabel.heightAnchor.constraint(equalToConstant: 1),
            ])

        let desc = "Your Balance chart compares your health metrics relative to each other, and to our study population. A person with average measures across the board would show a uniform shape."
        radarTip = TapTip(forView: radarTipDummyLabel, withinView: view, text: desc, width: 350, numTaps: 2, numTouches: 2, asTop: false)
        radarChart.addGestureRecognizer(radarTip.tapRecognizer)
        radarChart.isUserInteractionEnabled = true
    }

    func configureUnauthorizedView() {
        let iview = UIImageView()
        iview.image = initialImage
        iview.contentMode = .scaleAspectFit
        iview.tintColor = Theme.universityDarkTheme.foregroundColor

        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.lineBreakMode = .byWordWrapping
        lbl.numberOfLines = 0
        lbl.text = initialMsg
        lbl.textColor = Theme.universityDarkTheme.foregroundColor

        iview.translatesAutoresizingMaskIntoConstraints = false
        lbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iview)
        view.addSubview(lbl)

        let constraints: [NSLayoutConstraint] = [
            iview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iview.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            lbl.topAnchor.constraint(equalTo: iview.bottomAnchor),
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iview.widthAnchor.constraint(equalToConstant: 100),
            iview.heightAnchor.constraint(equalToConstant: 100),
            lbl.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -50)
        ]
        view.addConstraints(constraints)
    }

    // MARK: - Radar chart

    func normalizeType(type: HKSampleType, quantity: Double) -> Double {
        if let sex = MCHealthManager.sharedManager.getBiologicalSex(),
               let paramdict = logisticParametersByType[sex.biologicalSex == HKBiologicalSex.male],
               let (x0, k) = paramdict[type.identifier]
        {
            return min(1.0,(1 / (1 + exp(-k * (quantity - x0)))) + 0.2)
        }
        return 1 / (1 + exp(-quantity))
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()

    func indEntry(i: Int) -> MetabolicDataEntry {
        let type = PreviewManager.balanceSampleTypes[i]
        let samples = ComparisonDataModel.sharedManager.recentSamples[type] ?? []
        let val = healthFormatter.numberFromSamples(samples: samples)
        guard !val.isNaN else {
            return MetabolicDataEntry(value: 0.8, xIndex: i,
                                      pointColor: appearanceProvider.colorForSampleType(sampleType: type.identifier, active: true),
                                      image: appearanceProvider.imageForSampleType(sampleType: type.identifier, active: true))
        }
        let nval = normalizeType(type: type, quantity: val)
        return MetabolicDataEntry(value: nval, xIndex: i,
                                  pointColor: appearanceProvider.colorForSampleType(sampleType: type.identifier, active: true),
                                  image: appearanceProvider.imageForSampleType(sampleType: type.identifier, active: true))
    }

    func popEntry(i: Int) -> MetabolicDataEntry {
        let type = PreviewManager.balanceSampleTypes[i]
        let samples = ComparisonDataModel.sharedManager.recentAggregates[type] ?? []
        let val = healthFormatter.numberFromSamples(samples: samples)
        guard !val.isNaN else {
            return MetabolicDataEntry(value: 0.8, xIndex: i,
                                      pointColor: appearanceProvider.colorForSampleType(sampleType: type.identifier, active: true),
                                      image: appearanceProvider.imageForSampleType(sampleType: type.identifier, active: true))
        }
        let nval = normalizeType(type: type, quantity: val)
        return MetabolicDataEntry(value: nval, xIndex: i,
                                  pointColor: appearanceProvider.colorForSampleType(sampleType: type.identifier, active: true),
                                  image: appearanceProvider.imageForSampleType(sampleType: type.identifier, active: true))
    }

    func reloadData() {
        let sampleTypeRange = 0..<(min(PreviewManager.balanceSampleTypes.count, 8))
        let sampleTypes = sampleTypeRange.map { PreviewManager.balanceSampleTypes[$0] }

        let indData = sampleTypeRange.map(indEntry)
        let popData = sampleTypeRange.map(popEntry)

        let indDataSet = MetabolicChartDataSet(values: indData, label: NSLocalizedString("Individual value", comment: "Individual"))
//        indDataSet.fillColor = UIColor.colorWithHexString(rgb: "#427DC9", alpha: 1.0)!
        indDataSet.setColor(indDataSet.fillColor)
        indDataSet.drawFilledEnabled = true
        indDataSet.lineWidth = 1.0
        indDataSet.fillAlpha = 0.5
        indDataSet.showPoints = true
        indDataSet.highlightColor = UIColor.clear
        indDataSet.highlightCircleFillColor = UIColor.red
        indDataSet.highlightCircleStrokeColor = UIColor.white
        indDataSet.highlightCircleStrokeWidth = 1
        indDataSet.highlightCircleInnerRadius = 0
        indDataSet.highlightCircleOuterRadius = 5
        indDataSet.drawHighlightCircleEnabled = false
        
        let popDataSet = MetabolicChartDataSet(values: popData, label: NSLocalizedString("Population value", comment: "Population"))
        popDataSet.fillColor = UIColor.lightGray
        popDataSet.setColor(popDataSet.fillColor.withAlphaComponent(0.75))
        popDataSet.drawFilledEnabled = true
        popDataSet.lineWidth = 1.0
        popDataSet.fillAlpha = 0.5
        popDataSet.drawHighlightCircleEnabled = false
        
        
        let xVals = sampleTypes.map { type in return HMConstants.sharedInstance.healthKitShortNames[type.identifier]! }

//        let data = RadarChartDataEntry(xValues: Double(xVals), data: [indDataSet, popDataSet])
//        data.setDrawValues(false)
//        radarChart.data = data

//        radarChart.highlightValue(xIndex: 0, dataSetIndex: 0, callDelegate: false)
        radarChart.xAxis.labelTextColor = .white
        radarChart.xAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
        radarChart.yAxis.drawLabelsEnabled = false
        radarChart.notifyDataSetChanged()
        radarChart.valuesToHighlight()
    }

}
