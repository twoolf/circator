//
//  CorrelationChartsViewController.swift
//  MetabolicCompass
//
//  Created by Rostislav Roginevich on 7/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Charts
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Crashlytics
import SwiftDate
import AKPickerView_Swift
import SwiftyUserDefaults
import Async

open class CorrelationChartsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: - IB VARS
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scatterChartContainer: UIView!
    @IBOutlet weak var correlatoinChartContainer: UIView!
    @IBOutlet weak var scatterCh: ScatterCorrelcationCell!
    @IBOutlet weak var correlCh: TwoLineCorrelcationCell!

    //MARK: - VARS
    internal var data: [HKSampleType] = PreviewManager.chartsSampleTypes
    private var rangeType = DataRangeType.Week
    private let scatterChartsModel = BarChartModel()
    private let lineChartsModelTop = BarChartModel()
    private let lineChartsModelBottom = BarChartModel()
    let TopCorrelationType = DefaultsKey<Int?>("TopCorrelationType")
    let BottomCorrelationType = DefaultsKey<Int?>("BottomCorrelationType")
    var chartDataOperationQueue: OperationQueue = OperationQueue()

    var pickerView: UIPickerView {
        let picker = UIPickerView(frame:CGRect(0,0, view.frame.size.width, view.frame.size.height * 0.4))
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = UIColor.white
        picker.reloadAllComponents()
        picker.backgroundColor = tableView.backgroundColor
        return picker
    }

    var pickerData = [[HKSampleType](), [HKSampleType]()]
    var pickerIdentifiers = [[String](), [String]()]
    var appearanceProvider = DashboardMetricsAppearanceProvider()
    var selectedIndexPath: IndexPath?
    var selectedPickerRows = [-1,-1]

    lazy var assistTextField : UITextField = {
        let tv = UITextField(frame: self.tableView.frame)
        tv.tintColor = UIColor.clear
        tv.inputView = self.pickerView
        tv.inputAccessoryView = {
            let view = UIToolbar()
            view.isTranslucent = false
            view.barTintColor = self.tableView.backgroundColor
            view.frame = CGRect(0, 0, 0, 44)
            view.barStyle = .black
            let button = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action:  #selector(self.hideTextField))
            button.tintColor = UIColor.colorWithHexString(rgb: "#7E8FA6")
            view.tintColor = UIColor.colorWithHexString(rgb: "#7E8FA6")
            view.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                button
            ]
            return view
        }()
        self.tableView.addSubview(tv)
        self.tableView.sendSubview(toBack: tv)
        return tv
    }()

    override open func viewDidLoad() {
        super.viewDidLoad()
        for type in PreviewManager.manageChartsSampleTypes {
            if (type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue) {
                continue
            }
            pickerData[0].append(type)
            pickerData[1].append(type)
            pickerIdentifiers[0].append(type.identifier)
            pickerIdentifiers[1].append(type.identifier)
        }
        selectedPickerRows[0] = Defaults[TopCorrelationType] != nil ? Defaults[TopCorrelationType]! : -1
        selectedPickerRows[1] = Defaults[BottomCorrelationType] != nil ? Defaults[BottomCorrelationType]! : -1
        pickerView.reloadAllComponents()
        tableView.reloadData()
        scatterCh = Bundle.main.loadNibNamed("ScatterCorrelcationCell", owner: self, options: nil)!.last as? ScatterCorrelcationCell
        correlCh = Bundle.main.loadNibNamed("TwoLineCorrelcationCell", owner: self, options: nil)!.last as? TwoLineCorrelcationCell
        scatterChartContainer.addSubview(scatterCh)
        correlatoinChartContainer.addSubview(correlCh)
        scatterCh.frame = correlatoinChartContainer.bounds
        correlCh.frame = correlatoinChartContainer.bounds

        let xValues = scatterChartsModel.titlesFor(range: (scatterChartsModel.rangeType))
        let chartFormatter = LineChartFormatter(labels: xValues)
        let xAxis = XAxis()
        xAxis.valueFormatter = chartFormatter
        correlCh.chartView.xAxis.valueFormatter = xAxis.valueFormatter

        let px = 1 / UIScreen.main.scale
        let frame = CGRect(0, 0, self.tableView.frame.size.width, px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = tableView.separatorColor

        correlCh.secondaryChartMinValueLabel.text = ""
        correlCh.secondaryChartMaxValueLabel.text = ""

    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateChartDataWithClean), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateChartsData), name: NSNotification.Name(rawValue: HMDidUpdatedChartsData), object: nil)
        logContentView()
        updateChartsData()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logContentView(asAppear: false)
        NotificationCenter.default.removeObserver(self)
    }

    func updateChartDataWithClean() {
        scatterChartsModel.typesChartData = [:]
        lineChartsModelTop.typesChartData = [:]
        lineChartsModelBottom.typesChartData = [:]
        IOSHealthManager.sharedManager.cleanCache()
        IOSHealthManager.sharedManager.collectDataForCharts()
        updateChartsData ()
    }

    func updateChartsData () {
        if (!activityIndicator.isAnimating) {
            activityIndicator.startAnimating()
        }

        let chartGroup = DispatchGroup()
        chartGroup.enter()
        chartDataOperationQueue.addOperation({
            self.lineChartsModelTop.gettAllDataForSpecifiedType(chartType: ChartType.LineChart) {
                chartGroup.leave()
            }
        })

        chartGroup.enter()
        chartDataOperationQueue.addOperation({
            self.lineChartsModelBottom.gettAllDataForSpecifiedType(chartType: ChartType.LineChart) {
                chartGroup.leave()
            }
        })

        chartGroup.enter()
        chartDataOperationQueue.addOperation({
            self.scatterChartsModel.gettAllDataForSpecifiedType(chartType: ChartType.ScatterChart) {
                chartGroup.leave()
            }
        })

        chartGroup.notify(qos: DispatchQoS.background, queue: DispatchQueue.main) {
            self.activityIndicator.stopAnimating()
            self.updateChartData()
        }
    }

    //MARK: - Answers tracking
    func logContentView(asAppear: Bool = true) {
        var contentType: String = asAppear ? "Appear" : "Disappear"
        if selectedPickerRows.count > 0 && pickerData.count > 0 {
            if selectedPickerRows[0] >= 0 && pickerData[0].count > selectedPickerRows[0] {
                let typ = appearanceProvider.titleForAnalysisChartOfType(pickerData[0][selectedPickerRows[0]].identifier).string
                contentType += " \(typ)"
            }
        }
        if selectedPickerRows.count > 1 && pickerData.count > 1 {
            if selectedPickerRows[1] >= 0 && pickerData[1].count > selectedPickerRows[1] {
                let typ = appearanceProvider.titleForAnalysisChartOfType(pickerData[1][selectedPickerRows[1]].identifier).string
                contentType += " vs \(typ)"
            }
        }

        Answers.logContentView(withName: "Correlate",
                            contentType: "\(contentType)",
            contentId: Date().weekdayName,
            customAttributes: nil)
    }

    //MARK: - TableView datasource + Delegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CorrelationCell" + "\(indexPath.row)", for: indexPath) as! CorrelationTabeViewCell
        if (selectedPickerRows[indexPath.row] >= 0) {
            if selectedPickerRows[indexPath.row] > pickerData[indexPath.row].count - 1 {
                return cell
            }
            let type = pickerData[indexPath.row][self.selectedPickerRows[indexPath.row]].identifier
            let image = appearanceProvider.imageForSampleType(pickerData[indexPath.row][self.selectedPickerRows[indexPath.row]].identifier, active: true)
            cell.healthImageView?.image = image
            cell.titleLabel.text = appearanceProvider.titleForSampleType(type, active: false).string
        } else {
            cell.titleLabel.text = "Choose metric"
            cell.healthImageView?.image = nil
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (selectedIndexPath == indexPath) {
            selectedIndexPath = nil
            assistTextField.resignFirstResponder()
        } else {
            selectedIndexPath = indexPath
            assistTextField.becomeFirstResponder()
        }
        if (selectedPickerRows[indexPath.row] >= 0) {
            reloadPickerToCurrentCell(indexPath: indexPath)
        }
    }

    func reloadPickerToCurrentCell(indexPath:IndexPath) {
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! CorrelationTabeViewCell
        cell.setSelected(true, animated: true)
        let typeSring = appearanceProvider.typeFromString(cell.titleLabel.text!)
        guard let row = pickerIdentifiers[indexPath.row].index(of: typeSring) else {return}
        pickerView.selectRow(row, inComponent: 0, animated: true)
    }

    func hideTextField() {
        assistTextField.resignFirstResponder()
    }

    func updateChartTitle() {
        var firstType = pickerData[0][selectedPickerRows[0]].identifier
        firstType = appearanceProvider.titleForAnalysisChartOfType(firstType).string
        if selectedPickerRows[1] > pickerData[1].count - 1 {return}
        var secondType = pickerData[1][selectedPickerRows[1]].identifier
        secondType = appearanceProvider.titleForAnalysisChartOfType(secondType).string

        let titleString = firstType
        (scatterCh.chartTitleLabel.text, correlCh.chartTitleLabel.text) = (secondType, titleString)
        (scatterCh.subtitleLabel.text, correlCh.subtitleLabel.text) = (titleString, secondType)
    }

    func updateChartData() {
        if ((self.selectedPickerRows[0] >= 0) && (self.selectedPickerRows[1] >= 0)) {
            scatterCh.chartView.noDataText = "No data available"
            correlCh.chartView.noDataText = "No data available"
            let pickerDataArray = pickerData[0]

            let lineTopType = pickerDataArray[selectedPickerRows[0]]
            let lineBottomType = pickerDataArray[selectedPickerRows[1]]
            let scatterType = pickerDataArray[selectedPickerRows[1]]

            let lineTopTypeToShow = lineTopType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : lineTopType.identifier
            let lineBottomTypeToShow = lineBottomType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : lineBottomType.identifier
            let scatterTypeShow = scatterType.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : scatterType.identifier


            let lineTopKey = lineTopTypeToShow + "\((lineChartsModelTop.rangeType.rawValue))"
            let lineBottomKey = lineBottomTypeToShow + "\((lineChartsModelBottom.rangeType.rawValue))"
            let scatterKey = scatterTypeShow + "\((scatterChartsModel.rangeType.rawValue))"

            let lineTopChartData = lineChartsModelTop.typesChartData[lineTopKey]
            let lineBottomChartData = lineChartsModelBottom.typesChartData[lineBottomKey]
            let scatterChartData = scatterChartsModel.typesChartData[scatterKey]



            guard let lineTopChartSet = lineTopChartData?.dataSets[0] else { return }
            lineTopChartSet.setColor(UIColor.green)
            guard let lineBottomChartSet = lineBottomChartData?.dataSets[0] else { return }
            let lineChartData = LineChartData.init(dataSets: [lineTopChartSet, lineBottomChartSet])
            correlCh.chartView.data = lineChartData
            scatterCh.chartView.data = scatterChartData

            let xVals = xValsForScatterChart(data: lineTopChartSet as! ChartDataSet)
            let chartFormatter = ScatterChartFormatter(labels: xVals)
            let xAxis = XAxis()
            xAxis.valueFormatter = chartFormatter
            scatterCh.chartView.xAxis.valueFormatter = xAxis.valueFormatter


            updateChartTitle()
        } else {
            scatterCh.chartView.noDataText = "Choose both metrics"
            correlCh.chartView.noDataText = "Choose both metrics"
            resetAllCharts()
            return
        }
    }

    func resetAllCharts() {
        scatterCh.chartView.data = nil
        correlCh.chartView.data = nil
        correlCh.updateMinMaxTitlesWithValues(minValue: "", maxValue: "")
        correlCh.chartMinValueLabel.text = ""
        correlCh.chartMaxValueLabel.text = ""

        scatterCh.chartMinValueLabel.text = ""
        scatterCh.chartMaxValueLabel.text = ""
    }

    func xValsForScatterChart(data: ChartDataSet) -> [String] {
        if data.entryCount == 0 {
            return Array(repeating: "", count: 7)
        }

        var values: [Double:Double] = [:]
        let entriesRange = 0..<data.entryCount
        entriesRange.forEach { index in
            let entry = data.entryForIndex(index)!
            values[entry.x] = entry.y
        }

        let range = 0...6
        return range.map { index in
            let y = values[Double(index)]
            return y.map { String($0) } ?? ""
        }
    }
}

extension CorrelationChartsViewController: UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count = 0
        if let selectedRow = selectedIndexPath?.row {
            count = pickerData[selectedRow].count
        }
        return count
    }

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let result = appearanceProvider.titleForSampleType(pickerData[0][row].identifier, active: false)
        return result
    }
}

extension CorrelationChartsViewController : UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedPickerRows[self.selectedIndexPath!.row] = row
        if (self.selectedIndexPath!.row > 0) {
            Defaults[BottomCorrelationType] = row
        }
        else {
            Defaults[TopCorrelationType] = row
        }
        self.tableView.reloadRows(at: [self.selectedIndexPath! as IndexPath], with: .none)
        updateChartData()
    }
}

private class LineChartFormatter: NSObject, IAxisValueFormatter {

    var labels: [String] = []
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let val = Double(round(100 * value) / 100)
        var ind: Int?
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            ind = Int(val)
        }
        guard let index = ind else {
            return ""
        }
        return labels[index]
    }

    init(labels: [String]) {
        super.init()
        self.labels = labels
    }
}

private class ScatterChartFormatter: NSObject, IAxisValueFormatter {

    var labels: [String] = []
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard  let index = axis?.entries.index(of: value) else {return ""}
        return labels[index]
    }

    init(labels: [String]) {
        super.init()
        self.labels = labels
    }
}
