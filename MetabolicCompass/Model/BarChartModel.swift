//
// Created by Artem Usachov on 5/31/16.
// Copyright (c) 2016 SROST. All rights reserved.
//

import Foundation
import Charts
import SwiftDate
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries

enum ChartType {
    case BarChart
    case LineChart
    case ScatterChart
}

class BarChartModel : NSObject {

    var rangeType: HealthManagerStatisticsRangeType = HealthManagerStatisticsRangeType.week
    var typesChartData: [String: ChartData] = [:]
    var _chartDataOperationQueue: OperationQueue = OperationQueue()
    
    private var chartTypeToQuantityType: [String: ChartType] = [HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.basalEnergyBurned.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.stepCount.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.activeEnergyBurned.rawValue : .BarChart,
                                                                HKCategoryTypeIdentifier.sleepAnalysis.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryProtein.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatTotal.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFiber.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietarySugar.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietarySodium.rawValue : .BarChart, //salt
                                                                HKQuantityTypeIdentifier.dietaryCaffeine.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryCholesterol.rawValue: .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.dietaryWater.rawValue : .BarChart,
                                                                HKQuantityTypeIdentifier.bodyMassIndex.rawValue : .LineChart,
                                                                HKQuantityTypeIdentifier.bodyMass.rawValue : .LineChart,
                                                                HKQuantityTypeIdentifier.heartRate.rawValue : .ScatterChart,
                                                                HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : .ScatterChart,
                                                                HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue : .ScatterChart,
                                                                HKQuantityTypeIdentifier.uvExposure.rawValue : .ScatterChart]

    //MARK: Data for YEAR
    func getChartDataForYear(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {

        let xVals = getYearTitles()
        var yVals: [ChartDataEntry] = []
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: .year)
        } else {
            yVals = convertStatisticsValues(stisticsValues: values, forRange: .year, type: type, create: {x, y, type in
                return BarChartDataEntry.init(x: x, y: y)
            })
        }
        return getChartDataFor(xVals: xVals, yVals: yVals, type: type) as! ChartData
    }

    //MARK: Data for MONTH
    func getChartDataForMonth(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        let xVals = getMonthTitles()
        var yVals = convertStatisticsValues(stisticsValues: values, forRange: .month, type: type, create: {x, y, type in
            return BarChartDataEntry.init(x: x, y: y)
        })
        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: .month)
        }

        return getChartDataFor(xVals: xVals, yVals: yVals, type: type) as! ChartData
    }

    //MARK: Data for WEEK
    func getChartDataForWeek(type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        let xVals = getWeekTitles()

        var yVals = convertStatisticsValues(stisticsValues: values, forRange: .week, type: type, create: {x, y, type in
            switch type {
            case .BarChart:
                return BarChartDataEntry.init(x: x, y: y, data: xVals as AnyObject)
            case .LineChart:
            return ChartDataEntry.init(x: x, y: y)
            case .ScatterChart:
            return ChartDataEntry.init(x: x, y: y)
            }
        })

        if let minValues = minValues {
            yVals = getYValuesForScatterChart(minValues: minValues, maxValues: values, period: .week)
        }
        let noZeroFormatter = NumberFormatter()
        noZeroFormatter.zeroSymbol = ""
        switch type {
        case .LineChart:
        let lineSet = LineChartDataSet.init(values: yVals, label: "Check")
        lineSet.setColor(UIColor.red)
        lineSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
        return LineChartData(dataSet: lineSet)
        case .ScatterChart:
        let scatterSet = ScatterChartDataSet.init(values: yVals, label: "Check")
        scatterSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
        scatterSet.setColor(UIColor.green)
        return ScatterChartData.init(dataSet: scatterSet)
        case .BarChart:
        let barSet = BarChartDataSet.init(values: yVals, label: "Check")
        barSet.valueFormatter = DefaultValueFormatter(formatter: noZeroFormatter)
        barSet.setColor(UIColor.orange)
        return BarChartData.init(dataSet: barSet)
        }
    }

    //MARK: Prepare chart data
    func convertStatisticsValues(stisticsValues: [Double],
                                 forRange range: HealthManagerStatisticsRangeType,
                                           type: ChartType,
                                         create: ((Double, Double, ChartType) -> ChartDataEntry)) -> [ChartDataEntry] {
        var yVals: [ChartDataEntry] = []
        for (index, value) in stisticsValues.enumerated() {
            let entry = create(Double(index), value, type)
            switch type {
            case .LineChart, .ScatterChart:
                if value != 0 {
                    yVals.append(entry)
                }
            case .BarChart:
                yVals.append(entry)
            }
        }
        return yVals
    }

    func getChartDataForRange(range: HealthManagerStatisticsRangeType, type: ChartType, values: [Double], minValues: [Double]?) -> ChartData {
        switch range {
            case .week:
                return self.getChartDataForWeek(type: type, values: values, minValues: minValues)
            case .month:
            return BarChartData()
              //  return self.getChartDataForMonth(type: type, values: values, minValues: minValues)
            case .year:
            return BarChartData()
              //  return self.getChartDataForYear(type: type, values: values, minValues: minValues)
        }
    }

    func getYValuesForScatterChart (minValues: [Double], maxValues: [Double], period: HealthManagerStatisticsRangeType) -> [ChartDataEntry] {
        let xVals = getWeekTitles()
        var yVals: [ChartDataEntry] = []
        for (index, minValue) in minValues.enumerated() {
            let maxValue = maxValues[index]
            if maxValue > 0 && minValue > 0 {
                yVals.append(ChartDataEntry(x: Double(index), y: minValue, data: xVals as AnyObject))
            } else if maxValue > 0 {
                yVals.append(ChartDataEntry(x: Double(index), y: maxValue, data: xVals as AnyObject))
            } else {
                yVals.append(ChartDataEntry(x: Double(index), y: 0.0, data: xVals as AnyObject))
            }
        }
        return yVals
    }
    


    func getChartDataFor(xVals: [String], yVals: [ChartDataEntry], type: ChartType) -> AnyObject {
        switch type {
            case .BarChart:
                return BarChartDataSet.init(values: yVals, label: "MyCheck")
            case .LineChart:
                return LineChartDataSet.init(values: yVals, label: "MyCheck")
            case .ScatterChart:
                return ScatterChartDataSet.init(values: yVals, label: "MyCheck")
        }
    }

    func getBloodPressureChartData(range: HealthManagerStatisticsRangeType,
                             systolicMax: [Double],
                             systolicMin: [Double],
                            diastolicMax: [Double],
                            diastolicMin: [Double]) -> ScatterChartData {
        let systolicWeekData = getYValuesForScatterChart(minValues: systolicMin, maxValues: systolicMax, period: range)
        let diastolicWeekData = getYValuesForScatterChart(minValues: diastolicMin, maxValues: diastolicMax, period: range)
        let systolicSet = ScatterChartDataSet(values: systolicWeekData, label: "check3")
        let diastolicSet = ScatterChartDataSet(values: diastolicWeekData, label: "check3")
        var array = [ScatterChartDataSet]()
        array.append(systolicSet)
        array.append(diastolicSet)
        return ScatterChartData.init(dataSets: array)
    }

    func barChartDataWith(xVals: [String], yVals: [BarChartDataEntry]) -> BarChartDataSet {
        let daysDataSet = BarChartDataSet(values: yVals, label: "")
        daysDataSet.barBorderWidth = 0.1
        daysDataSet.colors = [UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.8)!]
        daysDataSet.drawValuesEnabled = false
        return daysDataSet
    }

    func lineChartDataWith(xVals: [String], yVals: [ChartDataEntry]) -> LineChartDataSet {
        let lineChartDataSet = LineChartDataSet(values: yVals, label: "")
        lineChartDataSet.colors = [UIColor.white.withAlphaComponent(0.3)]
        lineChartDataSet.circleRadius = 3.0
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.circleHoleRadius = 1.5
        lineChartDataSet.circleHoleColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        lineChartDataSet.circleColors = [UIColor.white]
        lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
        lineChartDataSet.drawVerticalHighlightIndicatorEnabled = false
        return lineChartDataSet
    }

    func scatterChartDataWith(xVals: [String], yVals:[ChartDataEntry], dataSetType: DataSetType = DataSetType.HeartRate) -> ScatterChartData {

        let dataSet = MCScatterChartDataSet(values: yVals, label: "")
        dataSet.dataSetType = dataSetType
        dataSet.colors = [UIColor.white]
        dataSet.drawValuesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.drawVerticalHighlightIndicatorEnabled = false
        let chartData = ScatterChartData(dataSets: [dataSet])
        return chartData
    }

    func scatterChartDataWith(xVals: [String], yVals1:[ChartDataEntry], yVals2:[ChartDataEntry]) -> ScatterChartData {

        let dataSet1 = MCScatterChartDataSet(values: yVals1, label: "")
        dataSet1.dataSetType = .BloodPressureTop
        dataSet1.colors = [UIColor.white]
        dataSet1.drawValuesEnabled = false
        dataSet1.drawHorizontalHighlightIndicatorEnabled = false
        dataSet1.drawVerticalHighlightIndicatorEnabled = false

        let dataSet2 = MCScatterChartDataSet(values: yVals2, label: "")
        dataSet2.dataSetType = .BloodPressureBottom
        dataSet2.colors = [UIColor.white]
        dataSet2.drawValuesEnabled = false
        dataSet2.drawHorizontalHighlightIndicatorEnabled = false
        dataSet2.drawVerticalHighlightIndicatorEnabled = false
        let chartData = ScatterChartData(dataSets: [dataSet1])
        return chartData
    }
    
    //TODO: Maybe we should remove this function 
    //Don't know for what this function exists. Can't find usage in the project.
/*    func scatterChartDataWithMultipleEntries(xVals: [String], yVals:[[ChartDataEntry]], types: [DataSetType?]) -> ScatterChartData {
        
        assert(xVals.count != yVals.count, "Data input is invalid, x and y value arrays count should be equal")

        var dataSets = [MCScatterChartDataSet]()
        
        var i = 0
        while i <= yVals.count {
            let dataSet1 = MCScatterChartDataSet(values: yVals[i], label: "")
            dataSet1.colors = i % 2 == 0 ? [UIColor.white] : [UIColor.red]
            if types[i] != nil { dataSet1.dataSetType = types[i]! }
            dataSet1.drawValuesEnabled = false
            dataSets.append(dataSet1)
            i += 1
        }
        
//        let chartData = ScatterChartData(xVals: xVals, dataSets: dataSets)
//        let chartData = scatterChartDataWith(xVals: xVals, yVals: dataSets)
        let chartData = ScatterChartData(dataSets: [dataSets])
        return chartData
    } */
    
    // Parameters:
    // - calcAvg1/2 indicates that for a dataset, we should compute an average for any stacked BarChartDataEntry prior to
    //   processing for the scatter chart. By default, a BarChartEntry computes a sum for stacked chart entries.
    func scatterChartDataWithMultipleDataSets(xVals: [String?], dataSets:[IChartDataSet], calcAvg: [Bool])
        -> ScatterChartDataSet
    {
        var xValues : [String] = Array()
        //dataSets[0] yAxis
        //dataSets[1] xAxis
        let finalDataSet = MCScatterChartDataSet()
        finalDataSet.dataSetType = .HeartRate
        finalDataSet.colors = [UIColor.white]
        finalDataSet.drawValuesEnabled = false
        finalDataSet.drawHorizontalHighlightIndicatorEnabled = false
        finalDataSet.drawVerticalHighlightIndicatorEnabled = false
        
        //create xAxis labels
        if let dSet1 = dataSets[0] as? ChartDataSet, let dSet2 = dataSets[1] as? ChartDataSet {
            let cleanDSet1 = dSet1.values.map({ $0.hash }).filter({ _ in dSet1.entryCount > 0 })
            let cleanDSet2 = dSet2.values.map({ $0.hash }).filter({ _ in dSet2.entryCount > 0 })
//            let cleanDSet1 = dSet1.y.map({ $0.xIndex }).filter({ !dSet1.yValForXIndex($0).isNaN })
//            let cleanDSet2 = dSet2.y.map({ $0.xIndex }).filter({ !dSet2.yValForXIndex($0).isNaN })
//            let sortedIndices = Set<Int>(cleanDSet1).intersect(cleanDSet2).sort { $0.0 < $0.1 }
//            let sortedIndices = Set<Int>(cleanDSet1).intersect(cleanDSet2).sort { $0.0 < $0.1 }
            
            let _ : (ChartDataSet, Int) -> ChartDataEntry? = { (dset, idx) in
//                let entry = dset.entryForXIndex(idx)
                let entry = dset.entryForIndex(idx)
                //log.info("SCATTER MODEL lookup \(idx) \(dset.yVals.map { $0.xIndex}) \(entry)")
//                return entry == nil ? entry : (entry!.xIndex == idx ? entry : nil)
                return entry == nil ? entry : (entry!.hashValue == idx ? entry : nil)
            }
            
            let averageEntry : (ChartDataEntry) -> ChartDataEntry = { entry in
                switch entry {
                case is BarChartDataEntry:
                    let e = entry as! BarChartDataEntry
                    if (e.yValues?.count ?? 0) > 0 {
//                    if (e.values?.count ?? 0) > 0 {
                        let sumCount = e.yValues!.reduce((0.0, 0.0), { (acc, x) in (acc.0 + x, acc.1 + 1) })
                        let avg = sumCount.1 > 0 ? (sumCount.0 / sumCount.1) : 0
//                        return BarChartDataEntry(values: [avg], xIndex: e.xIndex)
                        return BarChartDataEntry(x: Double(e.x), yValues: [avg])
                    } else {
                        return entry
                    }
                    
                default:
                    return entry
                }
            }
            
//            let yVals1 = sortedIndices.flatMap { lookupXIndex(dSet1, $0) }
//            let yVals2 = sortedIndices.flatMap { lookupXIndex(dSet2, $0) }
//            dSet1 = ChartDataSet(yVals: calcAvg[0] ? yVals1.map(averageEntry) : yVals1)
//            dSet2 = ChartDataSet(yVals: calcAvg[1] ? yVals2.map(averageEntry) : yVals2)
            
            //log.info("SCATTER MODEL common dataset sizes: \(dSet1.yVals.count) \(dSet2.yVals.count)")
            //log.info("SCATTER MODEL common datasets: \(dSet1.yVals) \(dSet2.yVals)")
            //sort values in the right way
 //           dSet1.yVals.sortInPlace({ $0.0.value < $0.1.value })
            
            //prepare xAxis labels
 /*           let xDoubleVals: Set<Double> = Set<Double>(dSet1.yVals.flatMap({ yValue in
                let currentYValue = dSet2.yValForXIndex(yValue.xIndex)
                if !currentYValue.isNaN {
                    let numberIsDecimal = yValue.value - floor(yValue.value) > 0.001
                    return numberIsDecimal ? Double(round(10*yValue.value)/10) : Double(Int(yValue.value))
                }
                //log.info("SCATTER MODEL found nan for labelling \(yValue) \(dSet2.yVals)")
                return nil
            })) */
            
//            xValues = xDoubleVals.sort({ $0.0 < $0.1 }).map({ "\($0)" })
            
/*            let groupByYValue: [Double: [Double]] = dSet1.yVals.reduce([:], combine: { (acc, entry1) in
                var nacc = acc
                let entry2 = dSet2.yValForXIndex(entry1.xIndex)
                if !entry2.isNaN {
                    nacc.updateValue(((nacc[entry1.value] ?? []) + [entry2]), forKey: entry1.value)
                } else {
                    //log.info("SCATTER MODEL found nan for \(entry1) \(dSet2.yVals)")
                }
                return nacc
            }) */
 //           let sortedByYValue = groupByYValue.sort { $0.0.0 < $0.1.0 }
            
            //log.info("SCATTER MODEL corr entries \(sortedByYValue)")
/*            sortedByYValue.enumerate().forEach { (index, yAndXVals) in
                let values = yAndXVals.1
                if values.count > 0 {
                    finalDataSet.addEntry(BarChartDataEntry(values: values, xIndex: index + 1))
                } else {
                    //log.info("SCATTER MODEL no entries for \(yAndXVals)")
                }
            }*/
        }
        
        //log.info("SCATTER MODEL final dataset \(xValues.count) \(finalDataSet.entryCount)")
        var newValues : [String] = Array()
        newValues.append("")//gap from the left side
        newValues += xValues
        newValues.append("")//gap from the right side
//        let chartData = ScatterChartData(xVals: newValues, dataSets: [finalDataSet])
 //       let chartData = ScatterChartData(xVals: newValues, dataSets: dataSets)
        let dSet1 = dataSets[0]
        let chartData = ScatterChartDataSet(values: (dSet1 as! [ChartDataEntry]))
        return chartData
    }
    
    func lineChartWithMultipleDataSets(xVals: [String?], dataSets:[IChartDataSet], calcAvg: [Bool]) -> LineChartDataSet {
        let averageEntry : (ChartDataEntry) -> ChartDataEntry = { entry in
            switch entry {
            case is BarChartDataEntry:
                let e = entry as! BarChartDataEntry
                if (e.yValues?.count ?? 0) > 0 {
//                if (e.values?.count ?? 0) > 0 {
                    let sumCount = e.yValues!.reduce((0.0, 0.0), { (acc, x) in (acc.0 + x, acc.1 + 1) })
                    let avg = sumCount.1 > 0 ? (sumCount.0 / sumCount.1) : 0
//                    return BarChartDataEntry(values: [avg], xIndex: e.xIndex)
                    return BarChartDataEntry(x: Double(e.hashValue), yValues: [avg])
                } else {
                    return entry
                }
                
            default:
                return entry
            }
        }
        
        let lineChartDataSetWith : ([ChartDataEntry]) -> LineChartDataSet = { yVals in
            let lineChartDataSet = LineChartDataSet(values: yVals, label: "")
            lineChartDataSet.colors = [UIColor.white.withAlphaComponent(0.3)]
            lineChartDataSet.circleRadius = 3.0
            lineChartDataSet.drawValuesEnabled = false
            lineChartDataSet.circleHoleRadius = 1.5
            lineChartDataSet.circleHoleColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            lineChartDataSet.circleColors = [UIColor.white]
            lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
            lineChartDataSet.drawVerticalHighlightIndicatorEnabled = false
            return lineChartDataSet
        }
        
        var ds0: LineChartDataSet = dataSets[0] as! LineChartDataSet
        var ds1: LineChartDataSet = dataSets[1] as! LineChartDataSet
        
//        if calcAvg[0] { ds0 = lineChartDataSetWith(ds0.yValues.map(averageEntry)) }
        if calcAvg[0] { ds0 = lineChartDataSetWith(ds0.values.map(averageEntry)) }
        ds0.axisDependency = .left
        ds0.colors = [UIColor.white]
        
        if calcAvg[1] { ds1 = lineChartDataSetWith(ds1.values.map(averageEntry)) }
        ds1.axisDependency = .right
        ds1.colors = [UIColor.red]
        
//        let chartData = ChartDataEntry(x: Double(xVals), y: [ds0, ds1] )
//        let chartData = ChartDataSet(values: [ds0, ds1])
//        let chartData = ChartDataEntry(x: ds0[0], y: ds1[0])
        return ds0
    }
    
 /*   // Parameters:
    // - calcAvg1/2 indicates that for a dataset, we should compute an average for any stacked BarChartDataEntry prior to
    //   processing for the scatter chart. By default, a BarChartEntry computes a sum for stacked chart entries.
    func scatterChartDataWithMultipleDataSets(xVals: [String?], dataSets:[IChartDataSet], calcAvg: [Bool])
        -> ScatterChartData?
    {
        var xValues : [String] = Array()
        //dataSets[0] yAxis
        //dataSets[1] xAxis
        let finalDataSet = MCScatterChartDataSet()
        finalDataSet.dataSetType = .HeartRate
        finalDataSet.colors = [UIColor.white]
        finalDataSet.drawValuesEnabled = false
        finalDataSet.drawHorizontalHighlightIndicatorEnabled = false
        finalDataSet.drawVerticalHighlightIndicatorEnabled = false
        
        //create xAxis labels
        if var dSet1 = dataSets[0] as? ChartDataSet, var dSet2 = dataSets[1] as? ChartDataSet {
//            let cleanDSet1 = dSet1.yVals.map({ $0.xIndex }).filter({ !dSet1.yValForXIndex($0).isNaN })
//            let cleanDSet2 = dSet2.yVals.map({ $0.xIndex }).filter({ !dSet2.yValForXIndex($0).isNaN })
//            let sortedIndices = Set<Int>(cleanDSet1).intersect(cleanDSet2).sort { $0.0 < $0.1 }

            let lookupXIndex : (ChartDataSet, Int) -> ChartDataEntry? = { (dset, idx) in
//                let entry = dset.entryForXIndex(idx)
                //log.info("SCATTER MODEL lookup \(idx) \(dset.yVals.map { $0.xIndex}) \(entry)")
//                return entry == nil ? entry : (entry!.xIndex == idx ? entry : nil)
            }

            let averageEntry : (ChartDataEntry) -> ChartDataEntry = { entry in
                switch entry {
                case is BarChartDataEntry:
                    let e = entry as! BarChartDataEntry
//                    if (e.values?.count ?? 0) > 0 {
//                        let sumCount = e.values!.reduce((0.0, 0.0), combine: { (acc, x) in (acc.0 + x, acc.1 + 1) })
//                        let avg = sumCount.1 > 0 ? (sumCount.0 / sumCount.1) : 0
//                        return BarChartDataEntry(values: [avg], xIndex: e.xIndex)
//                    } else {
                        return entry
                    }

//                default:
                    return entry
                }
            }

//            let yVals1 = sortedIndices.flatMap { lookupXIndex(dSet1, $0) }
//            let yVals2 = sortedIndices.flatMap { lookupXIndex(dSet2, $0) }
//            dSet1 = ChartDataSet(yVals: calcAvg[0] ? yVals1.map(averageEntry) : yVals1)
//            dSet2 = ChartDataSet(yVals: calcAvg[1] ? yVals2.map(averageEntry) : yVals2)

            //log.info("SCATTER MODEL common dataset sizes: \(dSet1.yVals.count) \(dSet2.yVals.count)")
            //log.info("SCATTER MODEL common datasets: \(dSet1.yVals) \(dSet2.yVals)")

            //sort values in the right way
//            dSet1.yVals.sortInPlace({ $0.0.value < $0.1.value })
//            dSet1.y.sortInPlace({ $0.0.value < $0.1.value })
//            dSet1.values.sortInPlace({ $0.0.value < $0.1.value })
//            dSet1.values.sort(by: { $0.0.x < $0.1.x })

            //prepare xAxis labels
//            let xDoubleVals: Set<Double> = Set<Double>(dSet1.yVals.flatMap({ yValue in
//            let xDoubleVals: Set<Double> = Set<Double>(dSet1.values.flatMap({ yValue in
//                let currentYValue = dSet2.yValForXIndex(yValue.xIndex)
//                let currentYValue = dSet2.entryForIndex(Int(yValue.x))
                if !currentYValue.isNaN {
//                    let numberIsDecimal = yValue.value - floor(yValue.value) > 0.001
//                    return numberIsDecimal ? Double(round(10*yValue.value)/10) : Double(Int(yValue.value))
                }
                //log.info("SCATTER MODEL found nan for labelling \(yValue) \(dSet2.yVals)")
                return nil
//            }

            xValues = xDoubleVals.sorted(by: { $0.0 < $0.1 }).map({ "\($0)" })

//            let groupByYValue: [Double: [Double]] = dSet1.values.reduce([:], { (acc, entry1) in
//                var nacc = acc
//                let entry2 = dSet2.yValForXIndex(entry1.xIndex)
//                let entry2 = dSet2.entryForIndex(Int(entry1.x))
                if !entry2.isNaN {
                    nacc.updateValue(((nacc[entry1.value] ?? []) + [entry2]), forKey: entry1.value)
                } else {
                    //log.info("SCATTER MODEL found nan for \(entry1) \(dSet2.yVals)")
                }
                return nacc
//            })
//            let sortedByYValue = groupByYValue.sorted { $0.0.0 < $0.1.0 }

            //log.info("SCATTER MODEL corr entries \(sortedByYValue)")

            sortedByYValue.enumerated().forEach { (index, yAndXVals) in
                let values = yAndXVals.1
                if values.count > 0 {
//                    finalDataSet.addEntry(BarChartDataEntry(values: values, xIndex: index + 1))
                    finalDataSet.addEntry(BarChartDataEntry(x: Double(index+1), y: values.0))
                } else {
                    //log.info("SCATTER MODEL no entries for \(yAndXVals)")
                }
            }
        }

        //log.info("SCATTER MODEL final dataset \(xValues.count) \(finalDataSet.entryCount)")

        var newValues : [String] = Array()
        newValues.append("")//gap from the left side
        newValues += xValues
        newValues.append("")//gap from the right side 
//        let chartData = ScatterChartData(xVals: newValues, dataSets: [finalDataSet])
        let chartData = scatterChartDataWithMultipleDataSets(xVals: newValues, dataSets: [finalDataSet], calcAvg: calcAvg)
        return chartData
    }
    
    func lineChartWithMultipleDataSets(xVals: [String?], dataSets:[IChartDataSet], calcAvg: [Bool]) -> LineChartData? {
        let averageEntry : (ChartDataEntry) -> LineChartData = { entry in
            switch entry {
            case is BarChartDataEntry:
                let e = entry as! BarChartDataEntry
                if (e.yValues?.count ?? 0) > 0 {
                    let sumCount = e.yValues!.reduce((0.0, 0.0), { (acc, x) in (acc.0 + x, acc.1 + 1) })
                    let avg = sumCount.1 > 0 ? (sumCount.0 / sumCount.1) : 0
//                    return BarChartDataEntry(yValues: [avg], xValues: e.x)
                    return BarChartDataEntry(x: e.x, y: avg)
                } else {
                    return entry
                }

            default:
                return entry
            }
        }

        let lineChartDataSetWith : ([ChartDataEntry]) -> LineChartDataSet = { yVals in
            let lineChartDataSet = LineChartDataSet(values: yVals, label: "")
            lineChartDataSet.colors = [UIColor.white.withAlphaComponent(0.3)]
            lineChartDataSet.circleRadius = 3.0
            lineChartDataSet.drawValuesEnabled = false
            lineChartDataSet.circleHoleRadius = 1.5
            lineChartDataSet.circleHoleColor = UIColor(colorLiteralRed: 51.0/255.0, green: 138.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            lineChartDataSet.circleColors = [UIColor.white]
            lineChartDataSet.drawHorizontalHighlightIndicatorEnabled = false
            lineChartDataSet.drawVerticalHighlightIndicatorEnabled = false
            return lineChartDataSet
        }

        var ds0: LineChartDataSet = dataSets[0] as! LineChartDataSet
        var ds1: LineChartDataSet = dataSets[1] as! LineChartDataSet

        if calcAvg[0] { ds0 = lineChartDataSetWith(ds0.values.map(averageEntry)) }
        ds0.axisDependency = .left
        ds0.colors = [UIColor.white]

        if calcAvg[1] { ds1 = lineChartDataSetWith(ds1.values.map(averageEntry)) }
        ds1.axisDependency = .right
        ds1.colors = [UIColor.red]

//        let chartData = LineChartData(xVals: xVals, dataSets: [ds0, ds1])
//        let chartData = BarChartDataEntry(xVals: xVals as! [String], yVals: [ds0, ds1])
//        let chartData = chartDataSet(values: [ds0, ds1], label: "check2")
        let chartData = LineChartDataSet(values: ds0)
        return chartData
    } */

    // MARK :- Get all data for type
    
    func getAllDataForCurrentPeriodForSample(qType : HKSampleType,  _chartType: ChartType?, completion: @escaping (Bool) -> Void) {
        
        let type = qType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : qType.identifier
        let chartType = _chartType == nil ? chartTypeForQuantityTypeIdentifier(qType: type) : _chartType
        let key = type + "\(self.rangeType.rawValue)"
        
        log.warning("Getting chart data for \(type)")
        
        if type == HKQuantityTypeIdentifier.heartRate.rawValue || type == HKQuantityTypeIdentifier.uvExposure.rawValue {
            // We should get max and min values. because for this type we are using scatter chart
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                let array = values.map {$0.map {$0.isNaN ? 0.0 : $0} }
                if array.count > 0 {
                    self.typesChartData[key] = self.getChartDataForRange(range: self.rangeType, type: chartType!, values: array[0], minValues: array[1])
                }
                completion(array.count > 0)
            }
        } else if type == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
            // We should also get data for HKQuantityTypeIdentifierBloodPressureDiastolic
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: type))!, inPeriod: self.rangeType) { obj in
                let values = obj as! [[Double]]
                let array = values.map {$0.map {$0.isNaN ? 0.0 : $0} }
                if array.count > 0 {
                    self.typesChartData[key] = self.getBloodPressureChartData(range: self.rangeType,
                                                                   systolicMax: array[0],
                                                                   systolicMin: array[1],
                                                                  diastolicMax: array[2],
                                                                  diastolicMin: array[3])
                }
                completion(array.count > 0)
            }
        } else {
            IOSHealthManager.sharedManager.getChartDataForQuantity(sampleType: qType, inPeriod: self.rangeType) { obj in
                let values = obj as! [Double]
                let arrray = values.map {$0.isNaN ? 0.0 : $0}
                if arrray.count > 0 {
                    self.typesChartData[key] = self.getChartDataForRange(range: self.rangeType, type: chartType!, values: arrray, minValues: nil)
                }
                completion(arrray.count > 0)
            }
        }
    }
    
    func gettAllDataForSpecifiedType(chartType: ChartType, completion: @escaping () -> Void) {
        resetOperation()
        let chartGroup = DispatchGroup()
        for qType in PreviewManager.chartsSampleTypes {
            chartGroup.enter()
            _chartDataOperationQueue.addOperation({
                self.getAllDataForCurrentPeriodForSample(qType: qType, _chartType: chartType) { _ in
                    chartGroup.leave()
                }
            })
        }
        chartGroup.notify(qos: DispatchQoS.background, queue: DispatchQueue.main) {
            self.addCompletionForOperationQueue(completion: completion)
        }
    }
    
    func getAllDataForCurrentPeriod(completion: @escaping () -> Void) {
        //always reset current operation queue before start new one
        resetOperation()
        let chartGroup = DispatchGroup()
        let stepType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let weightType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let heartType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let bloodType = HKSampleType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!
        let sleepType = HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let energyType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let polisaturatedType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)
        let dietaryFatType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)
        let proteinType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)

        for qType in PreviewManager.chartsSampleTypes {
  //          if qType == heartType {
            chartGroup.enter()
            _chartDataOperationQueue.addOperation({ 
                self.getAllDataForCurrentPeriodForSample(qType: qType, _chartType: nil) { _ in
                    chartGroup.leave()
                }
            })
 //       }
    }
        chartGroup.notify(qos: DispatchQoS.background, queue: DispatchQueue.main) {
            self.addCompletionForOperationQueue(completion: completion)
        }
    }

    // MARK :- Chart titles for X

    func getWeekTitles () -> [String] {
        let currentDate = Date()
        let weekAgoDate = currentDate - 7.days
        var weekTitles: [String] = []
        var prevMonthDates: [Date] = []
        var currentMonthDates: [Date] = []

 //       weekTitles.append("")//create a gap for the left side

        for index in 1...7 {
            let day = weekAgoDate + index.days
            if day.month < currentDate.month {
                prevMonthDates.append(day)
            } else {
                currentMonthDates.append(day)
            }
        }

        for (index, date) in prevMonthDates.enumerated() {
            weekTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }

        for (index, date) in currentMonthDates.enumerated() {
            weekTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }

 //       weekTitles.append("")//create a gap for the right side
        return weekTitles
    }

    func getMonthTitles () -> [String] {
        var monthTitles: [String] = []
        let currentDate = Date()
        let numberOfDays = 31//max number of days in one month
        let monthAgoDate = currentDate - numberOfDays.days
        var prevMonthDates: [Date] = []
        var currentMonthDates: [Date] = []

        //empty labels for left gap
        monthTitles.append("")
        monthTitles.append("")
        monthTitles.append("")

        for index in 1...numberOfDays {
            let day = monthAgoDate + index.days
            if day.month < currentDate.month {
                prevMonthDates.append(day)
            } else {
                currentMonthDates.append(day)
            }
        }

        for (index, date) in prevMonthDates.enumerated() {
            monthTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }

        for (index, date) in currentMonthDates.enumerated() {
            monthTitles.append(convertDateToWeekString(date: date, forIndex: index))
        }

        //empty labels for right gap
        monthTitles.append("")
        monthTitles.append("")
        monthTitles.append("")

        return monthTitles
    }

    func getYearTitles() -> [String] {
        let numOfMonth = 13
        let currentDate = Date()
        let dateYearAgo = currentDate - 1.years
        var prevYearMonthes: [Date] = []
        var currentYearMonthes: [Date] = []
        var yearTitles: [String] = []

        yearTitles.append(" ")//space for gap

        for index in 0...(numOfMonth-1) {
            let date = dateYearAgo + index.months
            date.year < currentDate.year ? prevYearMonthes.append(date) : currentYearMonthes.append(date)
        }

        for (index, date) in prevYearMonthes.enumerated() {
            yearTitles.append(convertDateToYearString(date: date, forIndex: index))
        }

        for (index, date) in currentYearMonthes.enumerated() {
            yearTitles.append(convertDateToYearString(date: date, forIndex: index))
        }

        yearTitles.append(" ")//space for gap

        return yearTitles
    }

    //MARK: Help
    func chartTypeForQuantityTypeIdentifier(qType: String) -> ChartType {
        if let chartType = chartTypeToQuantityType[qType] {
            return chartType
        }
        return .BarChart
    }

    func convertDateToYearString(date: Date, forIndex index: Int) -> String {
        let month = date.month
        let monthPlusThree = month + 3
//        let cutRange = month.startIndex ..< month.startIndex.advancedBy(3)
//        let cutRange = month.startIndex ..< month.index(offsetBy: 3)
        let cutRange = month ..< monthPlusThree
//        let monthName = month.length > 3 ? month.substringWithRange(cutRange) : month

        if index == 0 {
//            return monthName + " \(date.year)"
            return Date().monthName
        }

        return Date().monthName
    }

    func convertDateToWeekString(date: Date, forIndex index: Int) -> String {
        if index == 0 {
            let month = date.monthName
//            let cutRange = month.startIndex ..< month.startIndex.advancedBy(3)
 //           _ = month ..< (month + 3)
//            let monthName = date(getMonthTitles() > 3 ? month.substringWithRange(cutRange) : month
            return "\(date.day) \(month)"
        }
        return "\(date.day)"
    }
    
    func addCompletionForOperationQueue(completion: @escaping () -> Void) {
        _chartDataOperationQueue.operations.onFinish(block: {
            OperationQueue.main.addOperation({
                completion()
            })
        })
    }
    
    func resetOperation() {
        _chartDataOperationQueue.cancelAllOperations()
        _chartDataOperationQueue = OperationQueue()
    }
}
