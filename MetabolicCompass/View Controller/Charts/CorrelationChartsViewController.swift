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
    private let lineChartsModel = BarChartModel()
    let TopCorrelationType = DefaultsKey<Int?>("TopCorrelationType")
    let BottomCorrelationType = DefaultsKey<Int?>("BottomCorrelationType")

    var pickerView : UIPickerView {
        let picker = UIPickerView(frame:CGRect(0,0, self.view.frame.size.width, self.view.frame.size.height * 0.4))
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = UIColor.white
        picker.reloadAllComponents()
        picker.backgroundColor = self.tableView.backgroundColor

        for type in PreviewManager.manageChartsSampleTypes {
//            pickerData[0].removeAll()
//            pickerData[1].removeAll()
//            pickerIdentifiers[0].removeAll()
//            pickerIdentifiers[1].removeAll()
            if (type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue) {
                continue
            }
            self.pickerData[0].append(type)
            self.pickerData[1].append(type)
            self.pickerIdentifiers[0].append(type.identifier)
            self.pickerIdentifiers[1].append(type.identifier)
        }
        return picker
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedPickerRows[0] = Defaults[TopCorrelationType] != nil ? Defaults[TopCorrelationType]! : -1
        self.selectedPickerRows[1] = Defaults[BottomCorrelationType] != nil ? Defaults[BottomCorrelationType]! : -1
        self.pickerView.reloadAllComponents()
        self.tableView.reloadData()
        scatterCh = Bundle.main.loadNibNamed("ScatterCorrelcationCell", owner: self, options: nil)!.last as? ScatterCorrelcationCell
        //disable adding lines between dots. works only if values are repeated
        //(scatterCh.chartView.renderer as! MCScatterChartRenderer).shouldDrawConnectionLines = false
        correlCh = Bundle.main.loadNibNamed("TwoLineCorrelcationCell", owner: self, options: nil)!.last as? TwoLineCorrelcationCell
        scatterChartContainer.addSubview(scatterCh!)
        correlatoinChartContainer.addSubview(correlCh!)
        scatterCh?.frame = correlatoinChartContainer.bounds
        correlCh?.frame = correlatoinChartContainer.bounds
        
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(0, 0, self.tableView.frame.size.width, px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
    }
    
    
    func updateChartDataWithClean() {
        scatterChartsModel.typesChartData = [:]
        lineChartsModel.typesChartData = [:]
        IOSHealthManager.sharedManager.cleanCache()
        IOSHealthManager.sharedManager.collectDataForCharts()
        activityIndicator.startAnimating()
    }
    
    func updateChartsData () {
        if (!activityIndicator.isAnimating) {
            activityIndicator.startAnimating()
        }
        scatterChartsModel.gettAllDataForSpecifiedType(chartType: ChartType.ScatterChart) {
            self.lineChartsModel.gettAllDataForSpecifiedType(chartType: ChartType.LineChart) {
                self.activityIndicator.stopAnimating()
                self.updateChartData()
            }
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateChartDataWithClean), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateChartsData), name: NSNotification.Name(rawValue: HMDidUpdatedChartsData), object: nil)
        
        logContentView()
        updateChartsData()
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.logContentView(asAppear: false)
        NotificationCenter.default.removeObserver(self)
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "CorrelationCell" + "\(indexPath.row)", for: indexPath) as! CorrelationTabeViewCell
        
        if (self.selectedPickerRows[indexPath.row] >= 0) {
            if self.selectedPickerRows[indexPath.row] > self.pickerData[indexPath.row].count - 1 {
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
      
        if (self.selectedIndexPath == indexPath) {
            self.selectedIndexPath = nil
            assistTextField.resignFirstResponder()
        } else {
            self.selectedIndexPath = indexPath
            assistTextField.becomeFirstResponder()
        }
        if (self.selectedPickerRows[indexPath.row] >= 0) {
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
    
    //MARK: picker vars
    
    var pickerData = [[HKSampleType](), [HKSampleType]()]
    var pickerIdentifiers = [[String](), [String]()]
    
    var appearanceProvider = DashboardMetricsAppearanceProvider()
    
    var selectedIndexPath : IndexPath?
    var selectedPickerRows = [-1,-1]
    
    func hideTextField() {
        assistTextField.resignFirstResponder()
    }
    
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
    
    func updateChartTitle() {
        if selectedPickerRows[0] > pickerData[1].count - 1 {return}
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
            updateChartDataForChartsModel(model: scatterChartsModel)
            updateChartDataForChartsModel(model: lineChartsModel)
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
    
    func updateChartDataForChartsModel(model: BarChartModel) -> Bool {
        
        var dataSets = [IChartDataSet]()
        var calcAvg = [Bool]()
        
        var xValues = [String?]()
        
        for selectedRow in selectedPickerRows {
            if selectedRow == -1 {
                resetAllCharts()
                return false
            }
            let pickerDataArray = pickerData[0]
            if selectedRow > pickerDataArray.count - 1 {return false}
            let type = pickerDataArray[selectedRow]
            let typeToShow = type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : type.identifier
            let key = typeToShow + "\((model.rangeType.rawValue))"
            let chartData = model.typesChartData[key]
            if (chartData == nil) {
                resetAllCharts()
                return true
            }
            correlCh.chartView.data = chartData
            scatterCh.chartView.data = chartData
//            xValues = (chartData?.dataSets)! as! [String?]
            xValues = []
            dataSets.append((chartData?.dataSets[0])!)
            
            let asAvg =
                typeToShow == HKQuantityTypeIdentifier.heartRate.rawValue ||
                    typeToShow == HKQuantityTypeIdentifier.uvExposure.rawValue ||
                    typeToShow == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue
            
            calcAvg.append(asAvg)
        }
        
        for dSet in dataSets {
            if dSet.entryCount < 1 {//min 1 values should exits in
                resetAllCharts()
                return false
            }
        }
        
        if (model == scatterChartsModel) {
            let chartData = model.scatterChartDataWithMultipleDataSets(xVals: xValues, dataSets: dataSets, calcAvg: calcAvg)
/*            if let yMax = chartData.yMax, let yMin = chartData.yMin, yMax > 0 || yMin > 0 {
                scatterCh.chartView.data = nil
                scatterCh.updateLeftAxisWith(minValue: chartData.yMin, maxValue: chartData.yMax, minOffsetFactor: 0.05, maxOffsetFactor: 0.05)
//                scatterCh.chartView.data = chartData
                scatterCh.drawLimitLine()
            } else {
                resetAllCharts()
            }
        } else {
            let chartData = model.lineChartWithMultipleDataSets(xVals: xValues, dataSets: dataSets, calcAvg: calcAvg)
            if let ds0 = chartData.dataSets[0], let ds1 = chartData.dataSets[1],
                let yMax = chartData.yMax, let yMin = chartData.yMin, yMax > 0 || yMin > 0
            {
                correlCh.chartView.data = nil
                correlCh.updateLeftAxisWith(ds0.yMin, maxValue: ds0.yMax, minOffsetFactor: 0.03, maxOffsetFactor: 0.03)
                correlCh.updateRightAxisWith(ds1.yMin, maxValue: ds1.yMax, minOffsetFactor: 0.03, maxOffsetFactor: 0.03)
                correlCh.drawLimitLine()
//                correlCh.chartView.data = chartData
            } else {
                resetAllCharts()
            }
        } */
        return false
    }
    
    var _ : UITextField = {
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
    
        return false

}

//MARK: - PICKER VIEW datasource + Delegate
/*extension CorrelationChartsViewController : UIPickerViewDataSource {
    
    // returns the number of 'columns' to display.
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count = 0
        if let selectedRow = selectedIndexPath?.row {
            count = pickerData[selectedRow].count
        }
        return count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let result = appearanceProvider.titleForSampleType(sampleType: pickerData[0][row].identifier, active: false)
        return result
    }
}

extension CorrelationChartsViewController : UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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
} */
/*
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

class CorrelationChartsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //MARK: - IB VARS
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scatterChartContainer: UIView!
    @IBOutlet weak var correlatoinChartContainer: UIView!
    @IBOutlet weak var scatterCh: ScatterCorrelcationCell!
    @IBOutlet weak var correlCh: TwoLineCorrelcationCell!
    
    //MARK: - VARS
    internal var data: [HKSampleType] = PreviewManager.chartsSampleTypes
    var rangeType = DataRangeType.Week
    let scatterChartsModel = DailyChartModel()
    let lineChartsModel = DailyChartModel()
    let TopCorrelationType = DefaultsKey<Int?>("TopCorrelationType")
    let BottomCorrelationType = DefaultsKey<Int?>("BottomCorrelationType")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedPickerRows[0] = Defaults[TopCorrelationType] != nil ? Defaults[TopCorrelationType]! : -1
        self.selectedPickerRows[1] = Defaults[BottomCorrelationType] != nil ? Defaults[BottomCorrelationType]! : -1
        
        self.pickerView.reloadAllComponents()
        self.tableView.reloadData()
        scatterCh = Bundle.main.loadNibNamed("ScatterCorrelcationCell", owner: self, options: nil)!.last as? ScatterCorrelcationCell
        //disable adding lines between dots. works only if values are repeated 
        (scatterCh.chartView.renderer as! MCScatterChartRenderer).shouldDrawConnectionLines = false
        correlCh = Bundle.main.loadNibNamed("TwoLineCorrelcationCell", owner: self, options: nil)!.last as? TwoLineCorrelcationCell
        scatterChartContainer.addSubview(scatterCh!)
        correlatoinChartContainer.addSubview(correlCh!)
        scatterCh?.frame = correlatoinChartContainer.bounds
        correlCh?.frame = correlatoinChartContainer.bounds
        
        let px = 1 / UIScreen.main.scale
        let frame = CGRect(0, 0, self.tableView.frame.size.width, px)
        let line: UIView = UIView(frame: frame)
        self.tableView.tableHeaderView = line
        line.backgroundColor = self.tableView.separatorColor
    }
    
    
    func updateChartDataWithClean() {
//        scatterChartsModel.typesChartData = [:]
//        lineChartsModel.typesChartData = [:]
        IOSHealthManager.sharedManager.cleanCache()
        IOSHealthManager.sharedManager.collectDataForCharts()
        activityIndicator.startAnimating()
    }
    
    func updateChartsData () {
        if (!activityIndicator.isAnimating) {
            activityIndicator.startAnimating()
        }
//        scatterChartsModel.gettAllDataForSpecifiedType(chartType: ChartType.ScatterChart) {
//            self.lineChartsModel.gettAllDataForSpecifiedType(chartType: ChartType.LineChart) {
                self.activityIndicator.stopAnimating()
                self.updateChartData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(updateChartDataWithClean), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateChartsData), name: NSNotification.Name(rawValue: HMDidUpdatedChartsData), object: nil)

        logContentView()
        updateChartsData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
        self.logContentView(asAppear: false)
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: - Answers tracking

    func logContentView(asAppear: Bool = true) {
        var contentType: String = asAppear ? "Appear" : "Disappear"

        if selectedPickerRows.count > 0 && pickerData.count > 0 {
            if selectedPickerRows[0] >= 0 && pickerData[0].count > selectedPickerRows[0] {
                let typ = appearanceProvider.titleForAnalysisChartOfType(sampleType: pickerData[0][selectedPickerRows[0]].identifier).string
                contentType += " \(typ)"
            }
        }

        if selectedPickerRows.count > 1 && pickerData.count > 1 {
            if selectedPickerRows[1] >= 0 && pickerData[1].count > selectedPickerRows[1] {
                let typ = appearanceProvider.titleForAnalysisChartOfType(sampleType: pickerData[1][selectedPickerRows[1]].identifier).string
                contentType += " vs \(typ)"
            }
        }

        Answers.logContentView(withName: "Correlate",
                                       contentType: "\(contentType)",
//                                       contentId: Date().string(DateFormat.custom("YYYY-MM-dd:HH")),
            contentId: Date().string(),
                                       customAttributes: nil)
    }

    //MARK: - TableView datasource + Delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "CorrelationCell" + "\(indexPath.row)", for: indexPath as IndexPath) as! CorrelationTabeViewCell
        
        if (self.selectedPickerRows[indexPath.row] >= 0) {
            let type = pickerData[indexPath.row][self.selectedPickerRows[indexPath.row]].identifier
            let image = appearanceProvider.imageForSampleType(sampleType: pickerData[indexPath.row][self.selectedPickerRows[indexPath.row]].identifier, active: true)
            cell.healthImageView?.image = image
            cell.titleLabel.text = appearanceProvider.titleForSampleType(sampleType: type, active: false).string
        } else {
            cell.titleLabel.text = "Choose metric"
            cell.healthImageView?.image = nil
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.selectedIndexPath == indexPath) {
            self.selectedIndexPath = nil
            assistTextField.resignFirstResponder()
        } else {
            self.selectedIndexPath = indexPath
            assistTextField.becomeFirstResponder()
        }
        if (self.selectedPickerRows[indexPath.row] >= 0) {
            reloadPickerToCurrentCell(indexPath: indexPath)
        }
    }
    
    func reloadPickerToCurrentCell(indexPath:NSIndexPath) {
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! CorrelationTabeViewCell
        cell.setSelected(selected: true, animated: true)
        let typeSring = appearanceProvider.typeFromString(string: cell.titleLabel.text!)
        let row = pickerIdentifiers[indexPath.row].index(of: typeSring)
        pickerView.selectRow(row!, inComponent: 0, animated: true)
    }
    
    //MARK: picker vars 
    
    var pickerData = [[HKSampleType](), [HKSampleType]()]
    var pickerIdentifiers = [[String](), [String]()]

    var appearanceProvider = DashboardMetricsAppearanceProvider()
    
    var selectedIndexPath : NSIndexPath?
    var selectedPickerRows = [-1,-1]
    
    func hideTextField() {
        assistTextField.resignFirstResponder()
    }
    
    func updateChartTitle() {
        var firstType = pickerData[0][selectedPickerRows[0]].identifier
        firstType = appearanceProvider.titleForAnalysisChartOfType(sampleType: firstType).string
        var secondType = pickerData[1][selectedPickerRows[1]].identifier
        secondType = appearanceProvider.titleForAnalysisChartOfType(sampleType: secondType).string

        let titleString = firstType
        (scatterCh.chartTitleLabel.text, correlCh.chartTitleLabel.text) = (secondType, titleString)
        (scatterCh.subtitleLabel.text, correlCh.subtitleLabel.text) = (titleString, secondType)
    }
    
    func updateChartData() {
        if ((self.selectedPickerRows[0] >= 0) && (self.selectedPickerRows[1] >= 0)) {
            scatterCh.chartView.noDataText = "No data available"
            correlCh.chartView.noDataText = "No data available"
            updateChartDataForChartsModel(model: scatterChartsModel)
            updateChartDataForChartsModel(model: lineChartsModel)
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

    func updateChartDataForChartsModel(model: DailyChartModel) -> Bool {

        var dataSets = [IChartDataSet]()
        var calcAvg = [Bool]()

        var xValues = [String?]()
        
        for selectedRow in selectedPickerRows {
            if selectedRow == -1 {
                resetAllCharts()
                return false
            }
            let pickerDataArray = pickerData[0]
            let type = pickerDataArray[selectedRow]
            let typeToShow = type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : type.identifier
//            let key = typeToShow + "\((model.rangeType.rawValue))"
            let chartData = model.typesChartData[key]
            if (chartData == nil) {
                resetAllCharts()
                return true
            }
//            xValues = (chartData?.xVals)!
            xValues = (chartData?.dataSets)! as! [String]
            dataSets.append((chartData?.dataSets[0])!)

            let asAvg =
                typeToShow == HKQuantityTypeIdentifier.heartRate.rawValue ||
                typeToShow == HKQuantityTypeIdentifier.uvExposure.rawValue ||
                typeToShow == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue

            calcAvg.append(asAvg)
        }
        
        for dSet in dataSets {
            if dSet.entryCount < 1 {//min 1 values should exits in
                resetAllCharts()
                return false
            }
        }
        
        if (model == DailyChartsModel) {
            let chartData = model.scatterChartDataWithMultipleDataSets(xVals: xValues, dataSets: dataSets, calcAvg: calcAvg)
            if let yMax = chartData?.yMax, let yMin = chartData?.yMin, yMax > 0 || yMin > 0 {
                scatterCh.chartView.data = nil
                scatterCh.updateLeftAxisWith(minValue: chartData?.yMin, maxValue: chartData?.yMax, minOffsetFactor: 0.05, maxOffsetFactor: 0.05)
                scatterCh.chartView.data = chartData
                scatterCh.drawLimitLine()
            } else {
                resetAllCharts()
            }
        } else {
            let chartData = model.lineChartWithMultipleDataSets(xVals: xValues, dataSets: dataSets, calcAvg: calcAvg)
            if let ds0 = chartData?.dataSets[0], let ds1 = chartData?.dataSets[1],
                   let yMax = chartData?.yMax, let yMin = chartData?.yMin, yMax > 0 || yMin > 0
            {
                correlCh.chartView.data = nil
                correlCh.updateLeftAxisWith(minValue: ds0.yMin, maxValue: ds0.yMax, minOffsetFactor: 0.03, maxOffsetFactor: 0.03)
                correlCh.updateRightAxisWith(minValue: ds1.yMin, maxValue: ds1.yMax, minOffsetFactor: 0.03, maxOffsetFactor: 0.03)
                correlCh.drawLimitLine()
                correlCh.chartView.data = chartData
            } else {
                resetAllCharts()
            }
        }
        return false
    }
    
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
            let button = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action:  #selector(hideTextField))
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
    
    lazy var pickerView : UIPickerView = {
        let picker = UIPickerView(frame:CGRect(0,0, self.view.frame.size.width, self.view.frame.size.height * 0.4))
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = UIColor.white
        picker.reloadAllComponents()
        picker.backgroundColor = self.tableView.backgroundColor
        
        for type in PreviewManager.manageChartsSampleTypes {
            if (type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue) {
                continue
            }
            self.pickerData[0].append(type)
            self.pickerData[1].append(type)
            self.pickerIdentifiers[0].append(type.identifier)
            self.pickerIdentifiers[1].append(type.identifier)
        }
        return picker
    }()
}

//MARK: - PICKER VIEW datasource + Delegate

extension CorrelationChartsViewController : UIPickerViewDataSource {
    
    // returns the number of 'columns' to display.
    func numberOfComponents(in inpickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count = 0
        if let selectedRow = selectedIndexPath?.row {
            count = pickerData[selectedRow].count
        }
        return count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let result = appearanceProvider.titleForSampleType(sampleType: pickerData[0][row].identifier, active: false)
        return result
    }
}

extension CorrelationChartsViewController : UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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
} */
}

extension CorrelationChartsViewController : UIPickerViewDataSource {

    // returns the number of 'columns' to display.
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // returns the # of rows in each component..

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

