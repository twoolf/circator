//
//  PlotViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import Charts

class PlotViewController : UIViewController {
    dynamic var plotType = 0
    @IBOutlet var barChartView: BarChartView!
    @IBOutlet var scatterChartView: ScatterChartView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(plotType: Int, nibName: String?, bundle: NSBundle?) {
        super.init(nibName : nibName, bundle : bundle)
        self.plotType = plotType
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Plot \(plotType)"
        setupChart()
    }
    
    func getValue(v: Sample, i: Int) -> Double {
        switch(i) {
        case 0: return v.sleep
        case 1: return v.weight
        case 2: return v.heart_rate
        case 3: return v.total_calories
        case 4: return v.blood_pressure
        default: return 0.0
        }
    }
    
    func setupChart() {
        let realm = try! Realm()
        let n = realm.objects(Sample).count
        if ( plotType < 5 ) {
            var dataEntries: [ChartDataEntry] = []
            for (i, v) in realm.objects(Sample).enumerate() {
                let dataEntry = ChartDataEntry(value: getValue(v, i:plotType), xIndex: i)
                dataEntries.append(dataEntry)
            }
            
            let chartDataSet = ScatterChartDataSet(yVals: dataEntries, label: Sample.attributes()[plotType])
            let chartData = ScatterChartData(xVals: (0..<n).map({String($0)}), dataSet: chartDataSet)
            
            let chartFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            scatterChartView = ScatterChartView(frame: chartFrame)
            scatterChartView.data = chartData
            self.view.addSubview(scatterChartView)
        }
        else if ( plotType == 5 ) {
            var dataEntries: [BarChartDataEntry] = []
            for (i, v) in realm.objects(Sample).enumerate() {
                let dataEntry = BarChartDataEntry(value: v.weight, xIndex: i)
                dataEntries.append(dataEntry)
            }
            
            let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Some Value")
            let chartData = BarChartData(xVals: (0..<n).map({String($0)}), dataSet: chartDataSet)

            let chartFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            barChartView = BarChartView(frame: chartFrame)
            barChartView.data = chartData
            self.view.addSubview(barChartView)
        }
        else if ( plotType == 6 ) {
            var dataEntries: [ChartDataEntry] = []
            for (i, v) in realm.objects(Sample).enumerate() {
                let dataEntry = ChartDataEntry(value: v.weight, xIndex: i)
                dataEntries.append(dataEntry)
            }
            
            let chartDataSet = ScatterChartDataSet(yVals: dataEntries, label: "Some Value")
            let chartData = ScatterChartData(xVals: (0..<n).map({String($0)}), dataSet: chartDataSet)
            
            let chartFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            scatterChartView = ScatterChartView(frame: chartFrame)
            scatterChartView.data = chartData
            self.view.addSubview(scatterChartView)
        }
    }
}