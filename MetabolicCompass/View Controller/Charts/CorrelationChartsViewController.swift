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
    private var rangeType = DataRangeType.Week
    private let scatterChartsModel = BarChartModel()
    private let lineChartsModel = BarChartModel()
    private let TopCorrelationType = DefaultsKey<Int?>("TopCorrelationType")
    private let BottomCorrelationType = DefaultsKey<Int?>("BottomCorrelationType")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedPickerRows[0] = Defaults[TopCorrelationType] != nil ? Defaults[TopCorrelationType]! : -1
        self.selectedPickerRows[1] = Defaults[BottomCorrelationType] != nil ? Defaults[BottomCorrelationType]! : -1
        
        self.pickerView.reloadAllComponents()
        self.tableView.reloadData()
        scatterCh = NSBundle.mainBundle().loadNibNamed("ScatterCorrelcationCell", owner: self, options: nil).last as? ScatterCorrelcationCell
        //disable adding lines between dots. works only if values are repeated 
        (scatterCh.chartView.renderer as! MCScatterChartRenderer).shouldDrawConnectionLines = false
        correlCh = NSBundle.mainBundle().loadNibNamed("TwoLineCorrelcationCell", owner: self, options: nil).last as? TwoLineCorrelcationCell
        scatterChartContainer.addSubview(scatterCh!)
        correlatoinChartContainer.addSubview(correlCh!)
        scatterCh?.frame = correlatoinChartContainer.bounds
        correlCh?.frame = correlatoinChartContainer.bounds
        
        let px = 1 / UIScreen.mainScreen().scale
        let frame = CGRectMake(0, 0, self.tableView.frame.size.width, px)
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
        if (!activityIndicator.isAnimating()) {
            activityIndicator.startAnimating()
        }
        scatterChartsModel.gettAllDataForSpecifiedType(ChartType.ScatterChart) {
            self.lineChartsModel.gettAllDataForSpecifiedType(ChartType.LineChart) {
                self.activityIndicator.stopAnimating()
                self.updateChartData()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateChartDataWithClean), name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateChartsData), name: HMDidUpdatedChartsData, object: nil)

        logContentView()
        updateChartsData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.logContentView(false)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    //MARK: - Answers tracking

    func logContentView(asAppear: Bool = true) {
        var firstType = pickerData[0][selectedPickerRows[0]].identifier
        var secondType = pickerData[1][selectedPickerRows[1]].identifier

        firstType = appearanceProvider.titleForAnalysisChartOfType(firstType).string
        secondType = appearanceProvider.titleForAnalysisChartOfType(secondType).string

        Answers.logContentViewWithName("Correlate",
                                       contentType: "\(asAppear ? "Appear" : "Disappear") \(firstType) vs \(secondType)",
                                       contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
                                       customAttributes: nil)
    }

    //MARK: - TableView datasource + Delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("CorrelationCell" + "\(indexPath.row)", forIndexPath: indexPath) as! CorrelationTabeViewCell
        
        if (self.selectedPickerRows[indexPath.row] >= 0) {
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.selectedIndexPath == indexPath) {
            self.selectedIndexPath = nil
            assistTextField.resignFirstResponder()
        } else {
            self.selectedIndexPath = indexPath
            assistTextField.becomeFirstResponder()
        }
        if (self.selectedPickerRows[indexPath.row] >= 0) {
            reloadPickerToCurrentCell(indexPath)
        }
    }
    
    func reloadPickerToCurrentCell(indexPath:NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CorrelationTabeViewCell
        cell.setSelected(true, animated: true)
        let typeSring = appearanceProvider.typeFromString(cell.titleLabel.text!)
        let row = pickerIdentifiers[indexPath.row].indexOf(typeSring)
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
        firstType = appearanceProvider.titleForAnalysisChartOfType(firstType).string
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
            updateChartDataForChartsModel(scatterChartsModel)
            updateChartDataForChartsModel(lineChartsModel)
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
        correlCh.updateMinMaxTitlesWithValues("", maxValue: "")
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
            let type = pickerDataArray[selectedRow]
            let typeToShow = type.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : type.identifier
            let key = typeToShow + "\((model.rangeType.rawValue))"
            let chartData = model.typesChartData[key]
            if (chartData == nil) {
                resetAllCharts()
                return true
            }
            xValues = (chartData?.xVals)!
            dataSets.append((chartData?.dataSets[0])!)

            let asAvg =
                typeToShow == HKQuantityTypeIdentifierHeartRate ||
                typeToShow == HKQuantityTypeIdentifierUVExposure ||
                typeToShow == HKQuantityTypeIdentifierBloodPressureSystolic

            calcAvg.append(asAvg)
        }
        
        for dSet in dataSets {
            if dSet.entryCount < 1 {//min 1 values should exits in
                resetAllCharts()
                return false
            }
        }
        
        if (model == scatterChartsModel) {
            let chartData = model.scatterChartDataWithMultipleDataSets(xValues, dataSets: dataSets, calcAvg: calcAvg)
            if let yMax = chartData?.yMax, yMin = chartData?.yMin where yMax > 0 || yMin > 0 {
                scatterCh.chartView.data = nil
                scatterCh.updateLeftAxisWith(chartData?.yMin, maxValue: chartData?.yMax, minOffsetFactor: 0.05, maxOffsetFactor: 0.05)
                scatterCh.chartView.data = chartData
                scatterCh.drawLimitLine()
            } else {
                resetAllCharts()
            }
        } else {
            let chartData = model.lineChartWithMultipleDataSets(xValues, dataSets: dataSets, calcAvg: calcAvg)
            if let ds0 = chartData?.dataSets[0], ds1 = chartData?.dataSets[1],
                   yMax = chartData?.yMax, yMin = chartData?.yMin where yMax > 0 || yMin > 0
            {
                correlCh.chartView.data = nil
                correlCh.updateLeftAxisWith(ds0.yMin, maxValue: ds0.yMax, minOffsetFactor: 0.03, maxOffsetFactor: 0.03)
                correlCh.updateRightAxisWith(ds1.yMin, maxValue: ds1.yMax, minOffsetFactor: 0.03, maxOffsetFactor: 0.03)
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
        tv.tintColor = UIColor.clearColor()
        tv.inputView = self.pickerView
        tv.inputAccessoryView = {
            let view = UIToolbar()
            view.translucent = false
            view.barTintColor = self.tableView.backgroundColor
            view.frame = CGRectMake(0, 0, 0, 44)
            view.barStyle = .Black
            let button = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action:  #selector(hideTextField))
            button.tintColor = UIColor.colorWithHexString("#7E8FA6")
            view.tintColor = UIColor.colorWithHexString("#7E8FA6")
            view.items = [
                UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
                button
            ]
            return view
        }()
        self.tableView.addSubview(tv)
        self.tableView.sendSubviewToBack(tv)
        return tv
    }()
    
    lazy var pickerView : UIPickerView = {
        let picker = UIPickerView(frame:CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height * 0.4))
        picker.delegate = self
        picker.dataSource = self
        picker.tintColor = UIColor.whiteColor()
        picker.reloadAllComponents()
        picker.backgroundColor = self.tableView.backgroundColor
        
        for type in PreviewManager.manageChartsSampleTypes {
            if (type.identifier == HKCorrelationTypeIdentifierBloodPressure) {
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
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count = 0
        if let selectedRow = selectedIndexPath?.row {
            count = pickerData[selectedRow].count
        }
        return count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let result = appearanceProvider.titleForSampleType(pickerData[0][row].identifier, active: false)
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
        self.tableView.reloadRowsAtIndexPaths([self.selectedIndexPath!], withRowAnimation: .None)
        updateChartData()
    }
}
