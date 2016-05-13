//
//  RadarViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MetabolicCompassKit
import Charts
import Crashlytics
import SwiftDate

/**
 This class controls the display of the Radar screen (2nd view of dashboard). The radar screen gives a spider like view of how the users data compares to the population data. Our user input, to this date, suggests that many users prefer this to the numbers on the first view of the dashboard.
 
 - note: use of logistic function (normalizeType) to enable shared plot
 */
class RadarViewController : UIViewController, ChartViewDelegate {

    var logisticParametersByType : [Bool: [String: (Double, Double)]] =
    [ true: [ HKCategoryTypeIdentifierSleepAnalysis              : (6.7,0.328),
              HKQuantityTypeIdentifierBodyMass                   : (88.7,0.0248),
              HKQuantityTypeIdentifierBodyMassIndex              : (28.6,0.0768),
              HKQuantityTypeIdentifierHeartRate                  : (69.0,0.0318),
              HKQuantityTypeIdentifierBloodPressureSystolic      : (119.6,0.01837),
              HKQuantityTypeIdentifierStepCount                  : (6000,0.000366),
              HKQuantityTypeIdentifierActiveEnergyBurned         : (2750,0.00079899),
              HKQuantityTypeIdentifierUVExposure                 : (12.0,0.183),
              HKWorkoutTypeIdentifier                            : (12.0,0.183),
              HKQuantityTypeIdentifierDietaryEnergyConsumed      : (2794.5,0.000786),
              HKQuantityTypeIdentifierDietaryProtein             : (106.6,0.0206),
              HKQuantityTypeIdentifierDietaryCarbohydrates       : (333.6,0.0067),
              HKQuantityTypeIdentifierDietarySugar               : (149.4,0.0147),
              HKQuantityTypeIdentifierDietaryFiber               : (18.8,0.11687),
              HKQuantityTypeIdentifierDietaryFatTotal            : (102.6,0.2142),
              HKQuantityTypeIdentifierDietaryFatSaturated        : (33.5,0.0656),
              HKQuantityTypeIdentifierDietaryFatMonounsaturated  : (38.2,0.0575),
              HKQuantityTypeIdentifierDietaryFatPolyunsaturated  : (21.9,0.10003),
              HKQuantityTypeIdentifierDietaryCholesterol         : (375.5,0.00585),
              HKQuantityTypeIdentifierDietarySodium              : (4463.8,0.0004922),
              HKQuantityTypeIdentifierDietaryCaffeine            : (173.1,0.01269),
              HKQuantityTypeIdentifierDietaryWater               : (1208.5,0.001818)
            ],
     false: [HKCategoryTypeIdentifierSleepAnalysis               : (6.9,0.318),
             HKQuantityTypeIdentifierBodyMass                    : (77.0,0.0285),
             HKQuantityTypeIdentifierBodyMassIndex               : (29.1,0.0755),
             HKQuantityTypeIdentifierHeartRate                   : (74,0.02969),
             HKQuantityTypeIdentifierBloodPressureSystolic       : (111.1,0.01978),
             HKQuantityTypeIdentifierStepCount                   : (6000,0.000366),
             HKQuantityTypeIdentifierActiveEnergyBurned          : (2750,0.00079899),
             HKQuantityTypeIdentifierUVExposure                  : (12,0.183),
             HKWorkoutTypeIdentifier                             : (12.0,0.183),
             HKQuantityTypeIdentifierDietaryEnergyConsumed       : (1956.3,0.0011),
             HKQuantityTypeIdentifierDietaryProtein              : (73.5,0.02989),
             HKQuantityTypeIdentifierDietaryCarbohydrates        : (246.4,0.0089),
             HKQuantityTypeIdentifierDietarySugar                : (115.4,0.0190),
             HKQuantityTypeIdentifierDietaryFiber                : (15.2,0.14455),
             HKQuantityTypeIdentifierDietaryFatTotal             : (73.5,0.02989),
             HKQuantityTypeIdentifierDietaryFatSaturated         : (24.5,0.08968),
             HKQuantityTypeIdentifierDietaryFatMonounsaturated   : (26.6,0.0826),
             HKQuantityTypeIdentifierDietaryFatPolyunsaturated   : (16.1,0.1365),
             HKQuantityTypeIdentifierDietaryCholesterol          : (258,0.008516),
             HKQuantityTypeIdentifierDietarySodium               : (3138.7,0.000700),
             HKQuantityTypeIdentifierDietaryCaffeine             : (137.4,0.01599),
             HKQuantityTypeIdentifierDietaryWater                : (1127.7,0.001948)
        ]]

    var logisticTypeAsMale = true

    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var radarChart: RadarChartView = {
        let chart = RadarChartView()
        
        chart.renderer = MetabolicChartRender(chart: chart, animator: chart.chartAnimator, viewPortHandler: chart.viewPortHandler)
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
        chart.descriptionText = ""
        chart.rotationEnabled = false
        chart.yAxis.axisMinValue = 0.05
//        chart.yAxis.axisMaxValue = 1.2
        chart.yAxis.axisRange = 1.0
//        chart.drawWeb = false
        chart.yAxis.drawLabelsEnabled = false
        chart.xAxis.drawLabelsEnabled = false
        
        
//        chart.yAxis.customAxisMax = 1.0
//        chart.yAxis.customAxisMin = 0.2

        let legend = chart.legend
        legend.enabled = true
        legend.position = ScreenManager.sharedInstance.radarLegendPosition()
        legend.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        legend.textColor = .whiteColor()
        legend.xEntrySpace = 7.0
        legend.yEntrySpace = 5.0
        return chart
    }()

    var initialImage : UIImage! = nil
    var initialMsg : String! = "HealthKit not authorized"

    var authorized : Bool = false {
        didSet {
            configureViews()
            radarChart.layoutIfNeeded()
            reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.authorized = AccountManager.shared.isHealthKitAuthorized
        
        Answers.logContentViewWithName("Radar",
            contentType: "",
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        configureViews()
        radarChart.layoutIfNeeded()
        reloadData()
    }

    func configureViews() {
        if authorized {
            view.subviews.forEach { $0.removeFromSuperview() }
            radarChart.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(radarChart)
            let rcConstraints: [NSLayoutConstraint] = [
                radarChart.topAnchor.constraintEqualToAnchor(view.topAnchor),
                radarChart.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
                radarChart.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor),
                radarChart.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
            ]
            view.addConstraints(rcConstraints)
        } else {
            configureUnauthorizedView()
        }
    }

    func configureUnauthorizedView() {
        let iview = UIImageView()
        iview.image = initialImage
        iview.contentMode = .ScaleAspectFit
        iview.tintColor = Theme.universityDarkTheme.foregroundColor

        let lbl = UILabel()
        lbl.textAlignment = .Center
        lbl.lineBreakMode = .ByWordWrapping
        lbl.numberOfLines = 0
        lbl.text = initialMsg
        lbl.textColor = Theme.universityDarkTheme.foregroundColor

        iview.translatesAutoresizingMaskIntoConstraints = false
        lbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iview)
        view.addSubview(lbl)

        let constraints: [NSLayoutConstraint] = [
            iview.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            iview.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor, constant: -50),
            lbl.topAnchor.constraintEqualToAnchor(iview.bottomAnchor),
            lbl.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            iview.widthAnchor.constraintEqualToConstant(100),
            iview.heightAnchor.constraintEqualToConstant(100),
            lbl.widthAnchor.constraintEqualToAnchor(view.widthAnchor, constant: -50)
        ]
        view.addConstraints(constraints)
    }

    // MARK: - Radar chart

    func normalizeType(type: HKSampleType, quantity: Double) -> Double {
        if let sex = HealthManager.sharedManager.getBiologicalSex(),
               paramdict = logisticParametersByType[sex.biologicalSex == HKBiologicalSex.Male],
               (x0, k) = paramdict[type.identifier]
        {
//            print ("quantity \(quantity) and value: to check \(1 / (1 + exp(-k * (quantity - x0))))  ")
            return min(1.0,(1 / (1 + exp(-k * (quantity - x0)))) + 0.2)
        }
        return 1 / (1 + exp(-quantity))
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()

    func indEntry(i: Int) -> MetabolicDataEntry {
        let type = PreviewManager.previewSampleTypes[i]
        let samples = HealthManager.sharedManager.mostRecentSamples[type] ?? []
        let val = healthFormatter.numberFromSamples(samples)
        guard !val.isNaN else {
            return MetabolicDataEntry(value: 0.8, xIndex: i,
                                      pointColor: appearanceProvider.colorForSampleType(type.identifier, active: true),
                                      image: appearanceProvider.imageForSampleType(type.identifier, active: true))
        }
        let nval = normalizeType(type, quantity: val)
        print("type \(type), i \(i)")
        return MetabolicDataEntry(value: nval, xIndex: i,
                                  pointColor: appearanceProvider.colorForSampleType(type.identifier, active: true),
                                  image: appearanceProvider.imageForSampleType(type.identifier, active: true))
    }

    func popEntry(i: Int) -> MetabolicDataEntry {
        let type = PreviewManager.previewSampleTypes[i]
        let samples = PopulationHealthManager.sharedManager.mostRecentAggregates[type] ?? []
        let val = healthFormatter.numberFromSamples(samples)
        guard !val.isNaN else {
            return MetabolicDataEntry(value: 0.8, xIndex: i,
                                      pointColor: appearanceProvider.colorForSampleType(type.identifier, active: true),
                                      image: appearanceProvider.imageForSampleType(type.identifier, active: true))
        }
        let nval = normalizeType(type, quantity: val)
        return MetabolicDataEntry(value: nval, xIndex: i,
                                  pointColor: appearanceProvider.colorForSampleType(type.identifier, active: true),
                                  image: appearanceProvider.imageForSampleType(type.identifier, active: true))
    }

    func reloadData() {
        let indData = (0..<PreviewManager.previewSampleTypes.count).map(indEntry)
        let popData = (0..<PreviewManager.previewSampleTypes.count).map(popEntry)

        let indDataSet = MetabolicChartDataSet(yVals: indData, label: NSLocalizedString("Individual", comment: "Individual"))
        indDataSet.fillColor = UIColor.colorWithHexString("#427DC9", alpha: 1.0)!
        indDataSet.setColor(indDataSet.fillColor)
        indDataSet.drawFilledEnabled = true
        indDataSet.lineWidth = 1.0
        indDataSet.fillAlpha = 0.75
        indDataSet.showPoints = true
        indDataSet.highlightColor = UIColor.clearColor()
        indDataSet.highlightCircleFillColor = UIColor.redColor()
        indDataSet.highlightCircleStrokeColor = UIColor.whiteColor()
        indDataSet.highlightCircleStrokeWidth = 1
        indDataSet.highlightCircleInnerRadius = 0
        indDataSet.highlightCircleOuterRadius = 5
        indDataSet.drawHighlightCircleEnabled = false
        
        let popDataSet = MetabolicChartDataSet(yVals: popData, label: NSLocalizedString("Population", comment: "Population"))
        popDataSet.fillColor = UIColor.lightGrayColor()
        popDataSet.setColor(popDataSet.fillColor.colorWithAlphaComponent(0.75))
        popDataSet.drawFilledEnabled = true
        popDataSet.lineWidth = 1.0
        popDataSet.fillAlpha = 0.5
        popDataSet.drawHighlightCircleEnabled = false
        
        
        let xVals = PreviewManager.previewSampleTypes.map { type in
                        return HMConstants.sharedInstance.healthKitShortNames[type.identifier]! }

        let data = RadarChartData(xVals: xVals, dataSets: [popDataSet, indDataSet])
        data.setDrawValues(false)
        radarChart.data = data

        radarChart.highlightValue(xIndex: 0, dataSetIndex: 1, callDelegate: false)
        radarChart.xAxis.labelTextColor = .whiteColor()
        radarChart.xAxis.labelFont = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        radarChart.yAxis.drawLabelsEnabled = false
        radarChart.notifyDataSetChanged()
        radarChart.valuesToHighlight()
    }

}