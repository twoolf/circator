//
//  RadarViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import CircatorKit
import Charts

class RadarViewController : UIViewController, ChartViewDelegate {

    lazy var healthFormatter : SampleFormatter = { return SampleFormatter() }()

    lazy var radarChart: RadarChartView = {
        let chart = RadarChartView()
        chart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        chart.delegate = self
        chart.descriptionText = ""

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

    // TODO: lookup logistic function parameters for each type, for normalization
    public var logisticParametersByType : [HKSampleType: (Double, Double)] = [:]

    func normalizeType(type: HKSampleType, quantity: Double) {
        guard let (a, b) = logisticParametersByType[type.identifier] else {
            return quantity
        }
        return 1 / (1 + a * exp(-b * quantity))
    }

    // TODO: color NaN values differently to indicate error.
    func reloadData() {
        let indData = (0..<PreviewManager.previewSampleTypes.count).map { i in
            let type = PreviewManager.previewSampleTypes[i]
            let samples = HealthManager.sharedManager.mostRecentSamples[type] ?? [HKSample]()
            let val = healthFormatter.numberFromResults(samples)
            guard !val.isNan else {
                return ChartDataEntry(value: 0.0, xIndex: i)
            }
            return ChartDataEntry(value: normalizeType(type, quantity: val), xIndex: i)
        }

        let popData = (0..<PreviewManager.previewSampleTypes.count).map { i in
            let type = PreviewManager.previewSampleTypes[i]
            let samples = HealthManager.sharedManager.mostRecentAggregates[type]
                            ?? [DerivedQuantity(quantity: nil, quantityType: nil)]
            let val = healthFormatter.numberFromResults(samples)
            guard !val.isNan else {
                return ChartDataEntry(value: 0.0, xIndex: i)
            }
            return ChartDataEntry(value: normalizeType(type, quantity: val), xIndex: i) }

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

        let data = radarChart.data
        data.xVals = PreviewManager.previewSampleTypes.map { type in return HealthManager.healthKitShortNames[type.identifier]! }
        data.dataSets = [indDataSet, popDataSet]
        data.setDrawValues(false)

        radarChart.xAxis.labelTextColor = .whiteColor()
        radarChart.xAxis.labelFont = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        radarChart.yAxis.drawLabelsEnabled = false
        radarChart.notifyDataSetChanged()
        radarChart.invalidate()
    }

}