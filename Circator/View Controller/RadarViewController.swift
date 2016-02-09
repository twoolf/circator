//
//  RadarViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import CircatorKit
import Charts

class RadarViewController : UIViewController, ChartViewDelegate {

    var logisticParametersByType : [Bool: [String: (Double, Double)]] =
    [ true: [[HKCategoryTypeIdentifierSleepAnalysis:(6.5,0.338)],
            [HKQuantityTypeIdentifierBodyMass:(215.0,0.0102)],
            [HKQuantityTypeIdentifierBodyMassIndex:(25.0,0.08789)],
            [HKQuantityTypeIdentifierHeartRate:(80.0,0.0275)],
            [HKQuantityTypeIdentifierBloodPressureSystolic:(120.0,0.0183)],
            [HKQuantityTypeIdentifierStepCount:(6000,0.000366)],
            [HKQuantityTypeIdentifierActiveEnergyBurned:(2750,0.00079899)],
            [HKQuantityTypeIdentifierUVExposure:(12.0,0.183)],
            [HKWorkoutTypeIdentifier:(12.0,0.183)],
            [HKWorkoutTypeIdentifier:(12.0,0.183)],
            [HKQuantityTypeIdentifierDietaryEnergyConsumed:(2757,0.000797)],
            [HKQuantityTypeIdentifierDietaryProtein:(88.3,0.02488)],
            [HKQuantityTypeIdentifierDietaryCarbohydrates:(327,0.0067)],
            [HKQuantityTypeIdentifierDietarySugar:(143.3,0.01533)],
        [HKQuantityTypeIdentifierDietaryFiber:(20.6,0.10666)],
        [HKQuantityTypeIdentifierDietaryFatTotal:(103.2,0.2129)],
        [HKQuantityTypeIdentifierDietaryFatSaturated:(33.4,0.0658)],
        [HKQuantityTypeIdentifierDietaryFatMonounsaturated:(36.9,0.05955)],
        [HKQuantityTypeIdentifierDietaryFatPolyunsaturated:(24.3,0.0904)],
        [HKQuantityTypeIdentifierDietaryCholesterol:(352,0.00624)],
        [HKQuantityTypeIdentifierDietarySodium:(4560.7,0.00048177)],
        [HKQuantityTypeIdentifierDietaryCaffeine:(166.4,0.0132)],
        [HKQuantityTypeIdentifierDietaryWater:(5.0,0.43944)]
        ],
     false: [[HKCategoryTypeIdentifierSleepAnalysis:(6.5,0.338)],
            [HKQuantityTypeIdentifierBodyMass:(215,0.0102)],
            [HKQuantityTypeIdentifierBodyMassIndex:(25,0.08789)],
            [HKQuantityTypeIdentifierHeartRate:(80,0.0275)],
            [HKQuantityTypeIdentifierBloodPressureSystolic:(120,0.0183)],
            [HKQuantityTypeIdentifierStepCount:(6000,0.000366)],
            [HKQuantityTypeIdentifierActiveEnergyBurned:(2750,0.00079899)],
            [HKQuantityTypeIdentifierUVExposure:(12,0.183)],
            [HKWorkoutTypeIdentifier:(12.0,0.183)],
            [HKWorkoutTypeIdentifier:(12.0,0.183)],
            [HKQuantityTypeIdentifierDietaryEnergyConsumed:(1957.0,0.0011)],
            [HKQuantityTypeIdentifierDietaryProtein:(71.3,0.0308)],
            [HKQuantityTypeIdentifierDietaryCarbohydrates:(246.3,0.0089)],
            [HKQuantityTypeIdentifierDietarySugar:(112.0,0.0196)],
           [HKQuantityTypeIdentifierDietaryFiber:(16.2,0.1356)],
           [HKQuantityTypeIdentifierDietaryFatTotal:(73.1,0.3058)],
        [HKQuantityTypeIdentifierDietaryFatSaturated:(23.9,0.091934)],
        [HKQuantityTypeIdentifierDietaryFatMonounsaturated:(25.7,0.0855)],
        [HKQuantityTypeIdentifierDietaryFatPolyunsaturated:(17.4,0.1263)],
         [HKQuantityTypeIdentifierDietaryCholesterol:(235.7,0.009322)],
            [HKQuantityTypeIdentifierDietarySodium:(3187.3,0.000689)],
            [HKQuantityTypeIdentifierDietaryCaffeine:(142.7,0.015398)],
            [HKQuantityTypeIdentifierDietaryWater:(4.7,0.46795)]
        ]]
        

    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var radarChart: RadarChartView = {
        let chart = RadarChartView()
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
        chart.descriptionText = ""
        chart.rotationEnabled = false
        chart.yAxis.axisMinimum = 0.0
        chart.yAxis.axisMaximum = 1.0

        let legend = chart.legend
        legend.enabled = true
        legend.position = ChartLegend.ChartLegendPosition.RightOfChartInside
        legend.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        legend.textColor = .whiteColor()
        legend.xEntrySpace = 7.0
        legend.yEntrySpace = 5.0
        return chart
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        radarChart.layoutIfNeeded()
        reloadData()
    }

    func configureViews() {
        radarChart.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(radarChart)
        let rcConstraints: [NSLayoutConstraint] = [
            radarChart.topAnchor.constraintEqualToAnchor(view.topAnchor),
            radarChart.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            radarChart.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor),
            radarChart.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        ]
        view.addConstraints(rcConstraints)
    }

    // MARK: - Radar chart

    func normalizeType(type: HKSampleType, quantity: Double) -> Double {
        if let (a, b) = logisticParametersByType[type.identifier] {
            return 1 / (1 + a * exp(-b * quantity))
        }
        return 1 / (1 + exp(-quantity))
    }

    func indEntry(i: Int) -> ChartDataEntry {
        let type = PreviewManager.previewSampleTypes[i]
        let samples = HealthManager.sharedManager.mostRecentSamples[type] ?? [HKSample]()
        let val = healthFormatter.numberFromResults(samples)
        guard !val.isNaN else {
            return ChartDataEntry(value: 1.0, xIndex: i)
        }
        let nval = normalizeType(type, quantity: val)
        return ChartDataEntry(value: nval, xIndex: i)
    }

    func popEntry(i: Int) -> ChartDataEntry {
        let type = PreviewManager.previewSampleTypes[i]
        let samples = PopulationHealthManager.sharedManager.mostRecentAggregates[type]
            ?? [DerivedQuantity(quantity: nil, quantityType: nil)]
        let val = healthFormatter.numberFromResults(samples)
        guard !val.isNaN else {
            return ChartDataEntry(value: 1.0, xIndex: i)
        }
        let nval = normalizeType(type, quantity: val)
        return ChartDataEntry(value: nval, xIndex: i)
    }

    // TODO: color NaN values differently to indicate error.
    func reloadData() {
        let indData = (0..<PreviewManager.previewSampleTypes.count).map(indEntry)
        let popData = (0..<PreviewManager.previewSampleTypes.count).map(popEntry)

        let indDataSet = RadarChartDataSet(yVals: indData, label: "Individual")
        indDataSet.fillColor = .redColor()
        indDataSet.setColor(.redColor())
        indDataSet.drawFilledEnabled = true
        indDataSet.lineWidth = 2.0

        let popDataSet = RadarChartDataSet(yVals: popData, label: "Population")
        popDataSet.fillColor = .greenColor()
        popDataSet.setColor(.greenColor())
        popDataSet.drawFilledEnabled = true
        popDataSet.lineWidth = 2.0

        let xVals = PreviewManager.previewSampleTypes.map { type in
                        return HealthManager.healthKitShortNames[type.identifier]! }

        let data = RadarChartData(xVals: xVals, dataSets: [indDataSet, popDataSet])
        data.setDrawValues(false)
        radarChart.data = data

        radarChart.xAxis.labelTextColor = .whiteColor()
        radarChart.xAxis.labelFont = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        radarChart.yAxis.drawLabelsEnabled = false
        radarChart.notifyDataSetChanged()
    }

}