//
//  DashboardFilterController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import HealthKit
import SwiftyUserDefaults
import Async

class DashboardFilterController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    private var deselectAll = false

    private let selectedRowsDefaultsKey = "\(UserManager.sharedManager.userId).selectedFilters"

    // A hashtable specifying which row is selected in each section.
    private var selectedRows: [String:AnyObject] = [:]

    var data: [DashboardFilterItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        let rightButton = ScreenManager.sharedInstance.appNavButtonWithTitle("Clear all")
        rightButton.addTarget(self, action: #selector(clearAll), forControlEvents: .TouchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .Plain, target: self, action: #selector(closeAction))
        
        self.navigationItem.leftBarButtonItem = leftButton
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        
        if let userSelectedRows = Defaults.objectForKey(selectedRowsDefaultsKey) as? [String: AnyObject] {
            selectedRows = userSelectedRows
        } else {
            log.warning("Clearing saved filter for \(selectedRowsDefaultsKey)")
            Defaults.remove(selectedRowsDefaultsKey)
        }

        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.navigationController?.navigationBar.barStyle = .Black;
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        addData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Defaults.setObject(selectedRows, forKey: selectedRowsDefaultsKey)
        Defaults.synchronize()
    }
    
    //MARK: Actions
    
    func clearAll () {
        deselectAll = true
        selectedRows.removeAll()
        tableView.reloadData()
        refreshQuery()
        Async.main(after: 2.0) { self.deselectAll = false }
    }
    
    func closeAction() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: UITableViewDataSource
    private let dashboardFilterCellIdentifier = "DashboardFilterCell"
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCellWithIdentifier(dashboardFilterCellIdentifier, forIndexPath: indexPath) as! DashboardFilterCell
        let item = self.data[indexPath.section].items[indexPath.row]
        if deselectAll {
            item.selected = false
            if cell.checkBoxButton.selected {
                cell.didPressButton(self)
            }
        }
        cell.data = item
        if let selectedRowForSection = selectedRows["\(indexPath.section)"] as? Int {
            if selectedRowForSection == indexPath.row && !cell.checkBoxButton.selected { // prevent deselect
                cell.didPressButton(self)
            }
        }
        return cell
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("DashboardHeaderCell") as! DashboardFilterHeaderCell
        cell.captionLabel.text = self.data[section].title
        return cell;
    }

    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? DashboardFilterCell
        let filterItems = self.data[indexPath.section].items
        let selectedItem = filterItems[indexPath.row]//See DashboardFilterCellData
        
        if selectedItem.selected { // item already selected so just remove it and deselect
            cell?.didPressButton(self)
            deselectRow(indexPath.section, row: indexPath.row, refresh: true)
        } else {
            // Deselect all other items in this section. This enforces mutually exclusive filters.
            for (index, item) in filterItems.enumerate() {
                if (item.selected && indexPath.row != index) {
                    let currentlySelectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: indexPath.section)) as? DashboardFilterCell
                    currentlySelectedCell?.didPressButton(self)
                    deselectRow(indexPath.section, row: index)
                }
            }

            selectRow(indexPath.section, row: indexPath.row)
            cell?.didPressButton(self)//set cell as selected
        }
    }
    
    //MARK: Help
    func selectRow(section: Int, row: Int) {
        selectedRows.updateValue(row, forKey: "\(section)")
        refreshQuery()
    }

    func deselectRow(section: Int, row: Int, refresh: Bool = false) {
        let key = "\(section)"
        if let selectedRowForSection = selectedRows[key] as? Int {
            if selectedRowForSection == row {
                selectedRows.removeValueForKey(key)
                if refresh { refreshQuery() }
            }
        }
    }

    func refreshQuery() {
        var conjunctDescriptions: [String] = []
        var currentConjuncts : [MCQueryPredicate] = []
        for (key, value) in selectedRows {
            if let section = Int(key), row = value as? Int {
                if let predicate = self.data[section].items[row].predicate {
                    let ctitle = self.data[section].items[row].title
                    conjunctDescriptions.append(ctitle)
                    currentConjuncts.append(predicate)
                } else {
                    log.error("No predicate found for filter at index: \(section) \(row)")
                }
            } else {
                log.error("Invalid key/value pair as filter index: \(key) \(value)")
            }
        }

        QueryManager.sharedManager.clearQueries()

        if !currentConjuncts.isEmpty {
            let title = conjunctDescriptions.joinWithSeparator(" and ")
            let query = Query.ConjunctiveQuery(nil, nil, nil, currentConjuncts)
            QueryManager.sharedManager.addQuery(title, query: query)
            QueryManager.sharedManager.selectQuery(0)
        }
    }

    func addData () {
        let specs = (UserManager.sharedManager.useMetricUnits() ? metricFilterSpecs : imperialFilterSpecs) + commonFilterSpecs
        self.data = filterSpecsToItems(specs)

        if #available(iOS 9.3, *) {
            self.data.append(DashboardFilterItem(title: "Exercise",
                items: [DashboardFilterCellData(title: "under 20 minutes",
                    hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggAvg, lowerBound: 0, upperBound: 20),
                    DashboardFilterCellData(title: "between 20-minutes and 1-hour",
                        hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggAvg, lowerBound: 20, upperBound: 60),
                    DashboardFilterCellData(title: "between 1-hour and 3-hours",
                        hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggAvg, lowerBound: 60, upperBound: 180),
                    DashboardFilterCellData(title: "more than 3-hours",
                        hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggAvg, lowerBound: 180, upperBound: Int.max)]))
        }
    }


    // Section title, type identifier, ranges
    typealias FilterSpecs = [(String, String, [(Int, Int, String?)])]

    let commonFilterSpecs: FilterSpecs = [
        ("Body Mass Index",          HKQuantityTypeIdentifierBodyMassIndex,              [(0, 18, "(underweight)"), (18, 25, "(standard)"), (25, 30, "(overweight)"), (30, Int.max, "(obese)")]),
        ("Dietary Energy",           HKQuantityTypeIdentifierDietaryEnergyConsumed,      [(0, 1000, nil), (1000, 2000, nil), (2000, 3500, nil), (3500, Int.max, nil)]),
        ("Heart Rate",               HKQuantityTypeIdentifierHeartRate,                  [(0, 50, nil), (50, 65, nil), (65, 80, nil), (80, Int.max, nil)]),
        ("Step Count",               HKQuantityTypeIdentifierStepCount,                  [(0, 1000, nil), (1000, 5000, nil), (5000, 10000, nil), (10000, Int.max, nil)]),
        ("Active Energy",            HKQuantityTypeIdentifierActiveEnergyBurned,         [(0, 500, nil), (500, 1500, nil), (1500, 3500, nil), (3500, Int.max, nil)]),
        ("Resting Energy",           HKQuantityTypeIdentifierBasalEnergyBurned,          [(0, 1000, nil), (1000, 2000, nil), (2000, 3000, nil), (3000, Int.max, nil)]),
        ("Sleep",                    HKCategoryTypeIdentifierSleepAnalysis,              [(0, 5, nil), (5, 7, nil), (7, 9, nil), (9, Int.max, nil)]),
        ("Protein",                  HKQuantityTypeIdentifierDietaryProtein,             [(0, 40, nil), (40, 80, nil), (80, 120, nil), (120, Int.max, nil)]),
        ("Fat",                      HKQuantityTypeIdentifierDietaryFatTotal,            [(0, 50, nil), (50, 75, nil), (75, 100, nil), (100, Int.max, nil)]),
        ("Carbohydrates",            HKQuantityTypeIdentifierDietaryCarbohydrates,       [(0, 200, nil), (200, 300, nil), (300, 400, nil), (400, Int.max, nil)]),
        ("Fiber",                    HKQuantityTypeIdentifierDietaryFiber,               [(0, 10, nil), (10, 15, nil), (15, 20, nil), (20, Int.max, nil)]),
        ("Sugar",                    HKQuantityTypeIdentifierDietarySugar,               [(0, 50, nil), (50, 110, nil), (110, 180, nil), (180, Int.max, nil)]),
        ("Salt",                     HKQuantityTypeIdentifierDietarySodium,              [(0, 1000, nil), (1000, 3000, nil), (3000, 5000, nil), (5000, Int.max, nil)]),
        ("Caffeine",                 HKQuantityTypeIdentifierDietaryCaffeine,            [(0, 50, nil), (50, 150, nil), (150, 300, nil), (300, Int.max, nil)]),
        ("Cholesterol",              HKQuantityTypeIdentifierDietaryCholesterol,         [(0, 150, nil), (150, 300, nil), (300, 450, nil), (450, Int.max, nil)]),
        ("Polyunsaturated Fat",      HKQuantityTypeIdentifierDietaryFatPolyunsaturated,  [(0, 10, nil), (10, 20, nil), (20, 30, nil), (30, Int.max, nil)]),
        ("Saturated Fat",            HKQuantityTypeIdentifierDietaryFatSaturated,        [(0, 15, nil), (15, 25, nil), (25, 35, nil), (35, Int.max, nil)]),
        ("Monounsaturated Fat",      HKQuantityTypeIdentifierDietaryFatMonounsaturated,  [(0, 20, nil), (20, 30, nil), (30, 40, nil), (40, Int.max, nil)]),
        ("Water",                    HKQuantityTypeIdentifierDietaryWater,               [(0, 500, nil), (500, 1500, nil), (1500, 3000, nil), (3000, Int.max, nil)]),
        ("Blood Pressure Systolic",  HKQuantityTypeIdentifierBloodPressureSystolic,      [(0, 110, nil), (110, 120, nil), (120, 130, nil), (130, Int.max, nil)]),
        ("Blood Pressure Diastolic", HKQuantityTypeIdentifierBloodPressureDiastolic,     [(0, 60, nil), (60, 70, nil), (70, 80, nil), (80, Int.max, nil)])
    ]

    let metricFilterSpecs: FilterSpecs = [
        ("Weight", HKQuantityTypeIdentifierBodyMass, [(0, 40, nil), (40, 65, nil), (65, 90, nil), (90, Int.max, nil)]),
    ]

    let imperialFilterSpecs: FilterSpecs = [
        ("Weight", HKQuantityTypeIdentifierBodyMass, [(0, 90, nil), (90, 140, nil), (140, 200, nil), (200, Int.max, nil)]),
    ]

    func filterSpecsToItems(specs: FilterSpecs) -> [DashboardFilterItem] {
        return specs.map { (title, typeIdentifier, itemSpecs) in
            return DashboardFilterItem(title: title, items: itemSpecs.map { (lower, upper, label) in
                var itemTitle = ""
                if lower == 0 {
                    itemTitle = "less than \(upper)" + (label == nil ? "" : " \(label!)")
                } else if upper == Int.max {
                    itemTitle = "more than \(lower)" + (label == nil ? "" : " \(label!)")
                } else {
                    itemTitle = "between \(lower)-\(upper)" + (label == nil ? "" : " \(label!)")
                }

                return DashboardFilterCellData(title: itemTitle, hkType: typeIdentifier, aggrType: Aggregate.AggAvg, lowerBound: lower, upperBound: upper)
            })
        }
    }
}


