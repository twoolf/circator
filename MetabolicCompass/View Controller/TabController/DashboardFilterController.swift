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

class DashboardFilterController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    private let headerIdentifier = "DashboardFilterHeaderView"

    private var deselectAll = false

    private let selectedRowsDefaultsKey = "\(UserManager.sharedManager.userId ?? (no_argument as AnyObject) as! String).selectedFilters"
    private let sectionVisibilityDefaultsKey = "\(UserManager.sharedManager.userId ?? (no_argument as AnyObject) as! String).sectionsVisible"

    // A hashtable specifying which row is selected in each section.
    private var selectedRows: [String:AnyObject] = [:]

    private var sectionVisibility: [Bool] = []
    private var sectionGestureRecognizers: [UITapGestureRecognizer?] = []

    var data: [DashboardFilterItem] = [] {
        didSet {
            if sectionVisibility.count != self.data.count {
                sectionVisibility = [Bool](repeating: true, count: self.data.count)
            }
            if sectionGestureRecognizers.count != self.data.count {
                sectionGestureRecognizers = [UITapGestureRecognizer?](repeating: nil, count: self.data.count)
            }
            self.tableView.reloadData()
        }
    }

    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        let rightButton = ScreenManager.sharedInstance.appNavButtonWithTitle(title: "Clear all")
        rightButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .plain, target: self, action: #selector(closeAction))
        
        self.navigationItem.leftBarButtonItem = leftButton
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        
        loadSettings()
        registerViews()
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.navigationController?.navigationBar.barStyle = .black;
        self.navigationController?.navigationBar.tintColor = UIColor.white
        addData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveSettings()
    }

    func registerViews () {
        let headerNib = UINib(nibName: "DashboardFilterHeaderView", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier:  headerIdentifier)
    }

    func loadSettings() {
        if let userSelectedRows = Defaults.object(forKey: selectedRowsDefaultsKey) as? [String: AnyObject] {
            selectedRows = userSelectedRows
        } else {
            log.warning("Clearing defaults for \(selectedRowsDefaultsKey)")
            Defaults.remove(selectedRowsDefaultsKey)
        }

        if let userSectionsVisible = Defaults.object(forKey: sectionVisibilityDefaultsKey) as? [Bool] {
            sectionVisibility = userSectionsVisible
        } else {
            log.warning("Clearing defaults for \(sectionVisibilityDefaultsKey)")
            Defaults.remove(sectionVisibilityDefaultsKey)
        }
    }

    func saveSettings() {
        Defaults.set(selectedRows, forKey: selectedRowsDefaultsKey)
        Defaults.set(sectionVisibility, forKey: sectionVisibilityDefaultsKey)
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
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITableViewDataSource
    private let dashboardFilterCellIdentifier = "DashboardFilterCell"
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sectionVisibility[section] {
            return data[section].items.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: dashboardFilterCellIdentifier, for: indexPath) as! DashboardFilterCell
        let item = self.data[indexPath.section].items[indexPath.row]
        if deselectAll {
            item.selected = false
            if cell.checkBoxButton.isSelected {
                cell.didPressButton(self)
            }
        }
        cell.data = item
        if let selectedRowForSection = selectedRows["\(indexPath.section)"] as? Int {
            if selectedRowForSection == indexPath.row && !cell.checkBoxButton.isSelected { // prevent deselect
                cell.didPressButton(self)
            }
        }
        return cell
    }
    
    //MARK: UITableViewDelegate
    internal func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerIdentifier) as! DashboardFilterHeaderView
        view.captionLabel.text = self.data[section].title

        if sectionGestureRecognizers[section] == nil {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleSectionVisibility))
            tapRecognizer.delegate = self
            tapRecognizer.numberOfTouchesRequired = 1
            tapRecognizer.numberOfTapsRequired = 2
            sectionGestureRecognizers[section] = tapRecognizer
            view.tag = section
            view.addGestureRecognizer(tapRecognizer)
        } else {
            view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
            view.tag = section
            view.addGestureRecognizer(sectionGestureRecognizers[section]!)
        }

        return view;
    }

    internal func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    private func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as? DashboardFilterCell
        let filterItems = self.data[indexPath.section].items
        let selectedItem = filterItems[indexPath.row]//See DashboardFilterCellData
        
        if selectedItem.selected { // item already selected so just remove it and deselect
            cell?.didPressButton(self)
            deselectRow(section: indexPath.section, row: indexPath.row, refresh: true)
        } else {
            // Deselect all other items in this section. This enforces mutually exclusive filters.
            for (index, item) in filterItems.enumerated() {
                if (item.selected && indexPath.row != index) {
//                    let currentlySelectedCell = tableView.cellForRowAtIndexPath(IndexPath(forRow: index, inSection: indexPath.section)) as? DashboardFilterCell
                    let IndexPathToUse = IndexPath(row: index, section: indexPath.section)
                    let currentlySelectedCell = tableView.cellForRow(at: IndexPathToUse)
//                    currentlySelectedCell?.didPressButton(self)
                    deselectRow(section: indexPath.section, row: index)
                }
            }

            selectRow(section: indexPath.section, row: indexPath.row)
            cell?.didPressButton(self)//set cell as selected
        }
    }
    
    // MARK: Helpers
    func toggleSectionVisibility(_ sender: UITapGestureRecognizer) {
        if let section = sender.view?.tag {
            sectionVisibility[section] = !sectionVisibility[section]
            self.tableView.reloadData()
        }
    }

    func selectRow(section: Int, row: Int) {
        selectedRows.updateValue(row as AnyObject, forKey: "\(section)")
        refreshQuery()
    }

    func deselectRow(section: Int, row: Int, refresh: Bool = false) {
        let key = "\(section)"
        if let selectedRowForSection = selectedRows[key] as? Int {
            if selectedRowForSection == row {
                selectedRows.removeValue(forKey: key)
                if refresh { refreshQuery() }
            }
        }
    }

    func refreshQuery() {
        var conjunctDescriptions: [String] = []
        var currentConjuncts : [MCQueryPredicate] = []
        for (key, value) in selectedRows {
            if let section = Int(key), let row = value as? Int {
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
            let title = conjunctDescriptions.joined(separator: " and ")
            let query = Query.ConjunctiveQuery(nil, nil, nil, currentConjuncts)
            QueryManager.sharedManager.addQuery(name: title, query: query)
            QueryManager.sharedManager.selectQuery(index: 0)
        }
    }

    func addData () {
        let specs = (UserManager.sharedManager.useMetricUnits() ? metricFilterSpecs : imperialFilterSpecs) + commonFilterSpecs
        self.data = filterSpecsToItems(specs: specs)
    }


    // Section title, type identifier, ranges
    typealias FilterSpecs = [(String, String, HKUnit?, [(Int, Int, String?)])]

    let commonFilterSpecs: FilterSpecs = [
        ("Body Mass Index", HKQuantityTypeIdentifier.bodyMassIndex.rawValue, nil,
            [(0, 18, "(underweight)"), (18, 25, "(standard)"), (25, 30, "(overweight)"), (30, Int.max, "(obese)")]),

        ("Dietary Energy", HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue, nil,
            [(0, 1000, nil), (1000, 2000, nil), (2000, 3500, nil), (3500, Int.max, nil)]),

        ("Heart Rate", HKQuantityTypeIdentifier.heartRate.rawValue, nil,
            [(0, 50, nil), (50, 65, nil), (65, 80, nil), (80, Int.max, nil)]),

        ("Step Count", HKQuantityTypeIdentifier.stepCount.rawValue, nil,
            [(0, 1000, nil), (1000, 5000, nil), (5000, 10000, nil), (10000, Int.max, nil)]),

        ("Active Energy", HKQuantityTypeIdentifier.activeEnergyBurned.rawValue, nil,
            [(0, 500, nil), (500, 1500, nil), (1500, 3500, nil), (3500, Int.max, nil)]),

        ("Resting Energy", HKQuantityTypeIdentifier.basalEnergyBurned.rawValue, nil,
            [(0, 1000, nil), (1000, 2000, nil), (2000, 3000, nil), (3000, Int.max, nil)]),

        ("Sleep", HKCategoryTypeIdentifier.sleepAnalysis.rawValue, HKUnit.hour(),
            [(0, 5, nil), (5, 7, nil), (7, 9, nil), (9, Int.max, nil)]),

        ("Protein", HKQuantityTypeIdentifier.dietaryProtein.rawValue, nil,
            [(0, 40, nil), (40, 80, nil), (80, 120, nil), (120, Int.max, nil)]),

        ("Fat", HKQuantityTypeIdentifier.dietaryFatTotal.rawValue, nil,
            [(0, 50, nil), (50, 75, nil), (75, 100, nil), (100, Int.max, nil)]),

        ("Carbohydrates", HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue, nil,
            [(0, 200, nil), (200, 300, nil), (300, 400, nil), (400, Int.max, nil)]),

        ("Fiber", HKQuantityTypeIdentifier.dietaryFiber.rawValue, nil,
            [(0, 10, nil), (10, 15, nil), (15, 20, nil), (20, Int.max, nil)]),

        ("Sugar", HKQuantityTypeIdentifier.dietarySugar.rawValue, nil,
            [(0, 50, nil), (50, 110, nil), (110, 180, nil), (180, Int.max, nil)]),

        ("Salt", HKQuantityTypeIdentifier.dietarySodium.rawValue, nil,
            [(0, 1000, nil), (1000, 3000, nil), (3000, 5000, nil), (5000, Int.max, nil)]),

        ("Caffeine", HKQuantityTypeIdentifier.dietaryCaffeine.rawValue, nil,
            [(0, 50, nil), (50, 150, nil), (150, 300, nil), (300, Int.max, nil)]),

        ("Cholesterol", HKQuantityTypeIdentifier.dietaryCholesterol.rawValue, nil,
            [(0, 150, nil), (150, 300, nil), (300, 450, nil), (450, Int.max, nil)]),

        ("Polyunsaturated Fat", HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue, nil,
            [(0, 10, nil), (10, 20, nil), (20, 30, nil), (30, Int.max, nil)]),

        ("Saturated Fat", HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue, nil,
            [(0, 15, nil), (15, 25, nil), (25, 35, nil), (35, Int.max, nil)]),

        ("Monounsaturated Fat", HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue, nil,
            [(0, 20, nil), (20, 30, nil), (30, 40, nil), (40, Int.max, nil)]),

        ("Water", HKQuantityTypeIdentifier.dietaryWater.rawValue, nil,
            [(0, 500, nil), (500, 1500, nil), (1500, 3000, nil), (3000, Int.max, nil)]),

        ("Blood Pressure Systolic",  HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue, nil,
            [(0, 110, nil), (110, 120, nil), (120, 130, nil), (130, Int.max, nil)]),

        ("Blood Pressure Diastolic", HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue, nil,
            [(0, 60, nil), (60, 70, nil), (70, 80, nil), (80, Int.max, nil)])
    ]

    let metricFilterSpecs: FilterSpecs = [
        ("Weight", HKQuantityTypeIdentifier.bodyMass.rawValue, HKUnit.gramUnit(with: .kilo),
            [(0, 40, nil), (40, 65, nil), (65, 90, nil), (90, 1000, nil)]),
    ]

    let imperialFilterSpecs: FilterSpecs = [
        ("Weight", HKQuantityTypeIdentifier.bodyMass.rawValue, HKUnit.pound(),
            [(0, 90, nil), (90, 140, nil), (140, 200, nil), (200, 1000, nil)]),
    ]

    func filterSpecsToItems(specs: FilterSpecs) -> [DashboardFilterItem] {
        return specs.map { (title, typeIdentifier, unit, itemSpecs) in
            return DashboardFilterItem(title: title, items: itemSpecs.map { (lower, upper, label) in
                var itemTitle = ""
                if lower == 0 {
                    itemTitle = "less than \(upper)" + (label == nil ? "" : " \(label!)")
                } else if upper == Int.max {
                    itemTitle = "more than \(lower)" + (label == nil ? "" : " \(label!)")
                } else {
                    itemTitle = "between \(lower)-\(upper)" + (label == nil ? "" : " \(label!)")
                }

                return DashboardFilterCellData(title: itemTitle, hkType: typeIdentifier, hkUnit: unit,
                                               aggrType: Aggregate.AggAvg, lowerBound: lower, upperBound: upper)
            })
        }
    }
}


