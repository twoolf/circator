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
import AKPickerView_Swift

class CorrelationChartsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //MARK: - IB VARS
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func segmentControlChanged(sender: UISegmentedControl) {
        scatterChartContainer.hidden = sender.selectedSegmentIndex > 0
        correlatoinChartContainer.hidden = !scatterChartContainer.hidden
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scatterChartContainer: UIView!
    @IBOutlet weak var correlatoinChartContainer: UIView!
    
    @IBOutlet weak var scatterCh: ScatterChartCollectionCell!
    @IBOutlet weak var correlCh: ScatterChartCollectionCell!
    //MARK: - VARS
    internal var data: [HKSampleType] = PreviewManager.chartsSampleTypes
    private var rangeType = DataRangeType.Week
    private let chartsModel = BarChartModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        scatterCh = NSBundle.mainBundle().loadNibNamed("ScatterChartCollectionCell", owner: self, options: nil).last as? ScatterChartCollectionCell
        correlCh = NSBundle.mainBundle().loadNibNamed("ScatterChartCollectionCell", owner: self, options: nil).last as? ScatterChartCollectionCell
        scatterCh?.frame = correlatoinChartContainer.bounds
        correlCh?.frame = correlatoinChartContainer.bounds

        scatterChartContainer.addSubview(scatterCh!)
        correlatoinChartContainer.addSubview(correlCh!)
        
        updateChartData()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

//MARK: VC Legacy methods: should be moved to super class
    func updateChartsData () {
        activityIndicator.startAnimating()
        chartsModel.getAllDataForCurrentPeriod() {
            self.activityIndicator.stopAnimating()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateChartsData), name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateChartsData), name: HMDidUpdatedChartsData, object: nil)
        updateChartsData()
    }

    //MARK: - TableView datasource + Delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 2 }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(
            "CorrelationCell" + "\(indexPath.row)", forIndexPath: indexPath) as! CorrelationTabeViewCell
        
        let type = pickerData[indexPath.row][pickerView.selectedRowInComponent(0)].identifier
        let image = appearanceProvider.imageForSampleType(pickerData[indexPath.row][pickerView.selectedRowInComponent(0)].identifier, active: true)
        
        cell.healthImageView?.image = image
        cell.titleLabel.text = appearanceProvider.titleForSampleType(type, active: false).string
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.selectedIndexPath == indexPath) {
            self.selectedIndexPath = nil
            assistTextField.resignFirstResponder()
        }
        else {
            self.selectedIndexPath = indexPath
            assistTextField.becomeFirstResponder()
        }
        reloadPickerToCurrentCell(indexPath)
    }
    
    func reloadPickerToCurrentCell(indexPath:NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CorrelationTabeViewCell
        let typeSring = appearanceProvider.typeFromString(cell.titleLabel.text!)
        let row = pickerIdentifiers[indexPath.row].indexOf(typeSring)
        pickerView.selectRow(row!, inComponent: 0, animated: true)
    }
    
    //MARK: picker vars
    
    var pickerData = [[HKSampleType](), [HKSampleType]()]
    var pickerIdentifiers = [[String](), [String]()]

    var appearanceProvider = DashboardMetricsAppearanceProvider()
    
    var selectedIndexPath : NSIndexPath?
    var selectedPickerRows = [0,0]
    
    func hideTextField() {
        assistTextField.resignFirstResponder()
    }
    
    func updateChartTitle() {
        var firstType = pickerData[0][selectedPickerRows[0]].identifier
        firstType = appearanceProvider.titleForSampleType(firstType, active: false).string
        var secondType = pickerData[1][selectedPickerRows[1]].identifier
        secondType = appearanceProvider.titleForSampleType(secondType, active: false).string

        let titleString = firstType + " / " + secondType
        (scatterCh.chartTitleLabel.text, correlCh.chartTitleLabel.text) = (titleString, titleString)
    }
    
    func updateChartData() {
        let model = chartsModel
        
        let type = pickerData[0][pickerView.selectedRowInComponent(0)]
        let typeToShow = type.identifier == HKCorrelationTypeIdentifierBloodPressure ? HKQuantityTypeIdentifierBloodPressureSystolic : type.identifier
        let key = typeToShow + "\((model.rangeType.rawValue))"
        let chartData = model.typesChartData[key]

        if let yMax = chartData?.yMax, yMin = chartData?.yMin where yMax > 0 || yMin > 0 {
            scatterCh.chartView.data = nil
            scatterCh.updateLeftAxisWith(chartData?.yMin, maxValue: chartData?.yMax)
            scatterCh.chartView.data = chartData
            print("chartDatachartDatachartData", chartData)
        }
        
        
        if let yMax = chartData?.yMax, yMin = chartData?.yMin where yMax > 0 || yMin > 0 {
            correlCh.chartView.data = nil
            correlCh.updateLeftAxisWith(chartData?.yMin, maxValue: chartData?.yMax)
            correlCh.chartView.data = chartData
            print("chartDatachartDatachartData", chartData)
        }
//        updateChartsData()
        updateChartTitle()
    }
    
    lazy var assistTextField : UITextField = {
        let tv = UITextField(frame: self.tableView.frame)
        tv.inputView = self.pickerView
        tv.inputAccessoryView = {
            let view = UIToolbar()
            view.frame = CGRectMake(0, 0, 0, 44)
            view.barStyle = .Black
            view.items = [
                UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
                UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(hideTextField))
            ]
            
            return view
            }()
        self.tableView.addSubview(tv)
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
    
//    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
//        <#code#>
//    }

}

extension CorrelationChartsViewController : UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.tableView.reloadRowsAtIndexPaths([self.selectedIndexPath!], withRowAnimation: .None)
        self.selectedPickerRows[self.selectedIndexPath!.row] = row
        updateChartData()
    }
}
