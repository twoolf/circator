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

class DashboardFilterController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    private var selectedRows: [String: Int] = [:]
    private let selectedRowsDefaultsKey = "\(UserManager.sharedManager.userId).selectedFilters"
    var data: [DashboardFilterItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func onClose(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        Defaults.removeObjectForKey(selectedRowsDefaultsKey)
        if let userSelectedRows = Defaults.objectForKey(selectedRowsDefaultsKey) as? NSDictionary {
            selectedRows = userSelectedRows as! [String : Int]
        }
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.navigationController?.navigationBar.barStyle = .Black;
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        self.data = [DashboardFilterItem(title: "Weight",
                        items: [DashboardFilterCellData(title: "Under 90", 
                                                        hkType: HKQuantityTypeIdentifierBodyMass, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 90),
                                DashboardFilterCellData(title: "Between 90-140", 
                                                        hkType: HKQuantityTypeIdentifierBodyMass, aggrType: Aggregate.AggAvg, lowerBound: 90, upperBound: 140),
                                DashboardFilterCellData(title: "Between 140-200", 
                                                        hkType: HKQuantityTypeIdentifierBodyMass, aggrType: Aggregate.AggAvg, lowerBound: 140, upperBound: 200),
                                DashboardFilterCellData(title: "More than 200", 
                                                        hkType: HKQuantityTypeIdentifierBodyMass, aggrType: Aggregate.AggMin, lowerBound: 200, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Body Mass Index",
                        items: [DashboardFilterCellData(title: "Under 18(underweight)", 
                                                        hkType: HKQuantityTypeIdentifierBodyMassIndex, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 18),
                                DashboardFilterCellData(title: "Between 18-25(standard)", 
                                                        hkType: HKQuantityTypeIdentifierBodyMassIndex, aggrType: Aggregate.AggAvg, lowerBound: 18, upperBound: 25),
                                DashboardFilterCellData(title: "Between 25-30(overweight)", 
                                                        hkType: HKQuantityTypeIdentifierBodyMassIndex, aggrType: Aggregate.AggAvg, lowerBound: 25, upperBound: 30),
                                DashboardFilterCellData(title: "More than 30(obese)", 
                                                        hkType: HKQuantityTypeIdentifierBodyMassIndex, aggrType: Aggregate.AggMin, lowerBound: 30, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Dietary energy",
                        items: [DashboardFilterCellData(title: "Less than 1000", 
                                                        hkType: HKQuantityTypeIdentifierDietaryEnergyConsumed, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
                                DashboardFilterCellData(title: "Between 1000-2000", 
                                                        hkType: HKQuantityTypeIdentifierDietaryEnergyConsumed, aggrType: Aggregate.AggAvg, lowerBound: 1000, upperBound: 2000),
                                DashboardFilterCellData(title: "Between 2000-3500", 
                                                        hkType: HKQuantityTypeIdentifierDietaryEnergyConsumed, aggrType: Aggregate.AggAvg, lowerBound: 2000, upperBound: 3500),
                                DashboardFilterCellData(title: "More than 3500", 
                                                        hkType: HKQuantityTypeIdentifierDietaryEnergyConsumed, aggrType: Aggregate.AggMin, lowerBound: 3500, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Heartrate",
                        items: [DashboardFilterCellData(title: "Under 50", 
                                                        hkType: HKQuantityTypeIdentifierHeartRate, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 50),
                                DashboardFilterCellData(title: "Between 50-65", 
                                                        hkType: HKQuantityTypeIdentifierHeartRate, aggrType: Aggregate.AggAvg, lowerBound: 50, upperBound: 65),
                                DashboardFilterCellData(title: "Between 65-80", 
                                                        hkType: HKQuantityTypeIdentifierHeartRate, aggrType: Aggregate.AggAvg, lowerBound: 65, upperBound: 80),
                                DashboardFilterCellData(title: "Greater than 80", 
                                                        hkType: HKQuantityTypeIdentifierHeartRate, aggrType: Aggregate.AggMin, lowerBound: 80, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Step Count",
                        items: [DashboardFilterCellData(title: "Less than 1000", 
                                                        hkType: HKQuantityTypeIdentifierStepCount, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
                                DashboardFilterCellData(title: "Between 1000-5000", 
                                                        hkType: HKQuantityTypeIdentifierStepCount, aggrType: Aggregate.AggAvg, lowerBound: 1000, upperBound: 5000),
                                DashboardFilterCellData(title: "Between 5000-10000", 
                                                        hkType: HKQuantityTypeIdentifierStepCount, aggrType: Aggregate.AggAvg, lowerBound: 5000, upperBound: 10000),
                                DashboardFilterCellData(title: "More than 10000", 
                                                        hkType: HKQuantityTypeIdentifierStepCount, aggrType: Aggregate.AggMax, lowerBound: 10000, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Active Energy",
                        items: [DashboardFilterCellData(title: "Less than 1000", 
                                                        hkType: HKQuantityTypeIdentifierActiveEnergyBurned, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
                                DashboardFilterCellData(title: "Between 500-1500", 
                                                        hkType: HKQuantityTypeIdentifierActiveEnergyBurned, aggrType: Aggregate.AggAvg, lowerBound: 500, upperBound: 1500),
                                DashboardFilterCellData(title: "Between 1500-3500", 
                                                        hkType: HKQuantityTypeIdentifierActiveEnergyBurned, aggrType: Aggregate.AggAvg, lowerBound: 1500, upperBound: 3500),
                                DashboardFilterCellData(title: "More than 3500", 
                                                        hkType: HKQuantityTypeIdentifierActiveEnergyBurned, aggrType: Aggregate.AggMin, lowerBound: 3500, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Resting Energy",
                        items: [DashboardFilterCellData(title: "Less than 1000", 
                                                        hkType: HKQuantityTypeIdentifierBasalEnergyBurned, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
                                DashboardFilterCellData(title: "Between 1000-2000", 
                                                        hkType: HKQuantityTypeIdentifierBasalEnergyBurned, aggrType: Aggregate.AggAvg, lowerBound: 1000, upperBound: 2000),
                                DashboardFilterCellData(title: "Between 2000-3000", 
                                                        hkType: HKQuantityTypeIdentifierBasalEnergyBurned, aggrType: Aggregate.AggMax, lowerBound: 2000, upperBound: 3000),
                                DashboardFilterCellData(title: "More than 3000", 
                                                        hkType: HKQuantityTypeIdentifierBasalEnergyBurned, aggrType: Aggregate.AggMin, lowerBound: 3000, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Sleep",
                        items: [DashboardFilterCellData(title: "Less than 5", 
                                                        hkType: HKCategoryTypeIdentifierSleepAnalysis, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 5),
                                DashboardFilterCellData(title: "Between 5-7", 
                                                        hkType: HKCategoryTypeIdentifierSleepAnalysis, aggrType: Aggregate.AggAvg, lowerBound: 5, upperBound: 7),
                                DashboardFilterCellData(title: "Between 7-9", 
                                                        hkType: HKCategoryTypeIdentifierSleepAnalysis, aggrType: Aggregate.AggAvg, lowerBound: 7, upperBound: 9),
                                DashboardFilterCellData(title: "More than 9", 
                                                        hkType: HKCategoryTypeIdentifierSleepAnalysis, aggrType: Aggregate.AggMin, lowerBound: 9, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Protein",
                        items: [DashboardFilterCellData(title: "Less than 40",
                                                        hkType: HKQuantityTypeIdentifierDietaryProtein, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 40),
                                DashboardFilterCellData(title: "Between 40-80",
                                                        hkType: HKQuantityTypeIdentifierDietaryProtein, aggrType: Aggregate.AggAvg, lowerBound: 40, upperBound: 80),
                                DashboardFilterCellData(title: "Between 80-120",
                                                        hkType: HKQuantityTypeIdentifierDietaryProtein, aggrType: Aggregate.AggAvg, lowerBound: 80, upperBound: 120),
                                DashboardFilterCellData(title: "More than 120",
                                                        hkType: HKQuantityTypeIdentifierDietaryProtein, aggrType: Aggregate.AggMin, lowerBound: 120, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Fat",
                        items: [DashboardFilterCellData(title: "Under 50",
                                                        hkType: HKQuantityTypeIdentifierDietaryFatTotal, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 50),
                                DashboardFilterCellData(title: "Between 50-75",
                                                        hkType: HKQuantityTypeIdentifierDietaryFatTotal, aggrType: Aggregate.AggAvg, lowerBound: 50, upperBound: 75),
                                DashboardFilterCellData(title: "Between 75-100",
                                                        hkType: HKQuantityTypeIdentifierDietaryFatTotal, aggrType: Aggregate.AggAvg, lowerBound: 75, upperBound: 100),
                                DashboardFilterCellData(title: "More than 100",
                                                        hkType: HKQuantityTypeIdentifierDietaryFatTotal, aggrType: Aggregate.AggMin, lowerBound: 100, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Carbohydrates",
                        items: [DashboardFilterCellData(title: "Less than 200",
                                                        hkType: HKQuantityTypeIdentifierDietaryCarbohydrates, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 200),
                                DashboardFilterCellData(title: "Between 200-300",
                                                        hkType: HKQuantityTypeIdentifierDietaryCarbohydrates, aggrType: Aggregate.AggMax, lowerBound: 200, upperBound: 300),
                                DashboardFilterCellData(title: "Between 300-400",
                                                        hkType: HKQuantityTypeIdentifierDietaryCarbohydrates, aggrType: Aggregate.AggMax, lowerBound: 300, upperBound: 400),
                                DashboardFilterCellData(title: "More than 400",
                                                        hkType: HKQuantityTypeIdentifierDietaryCarbohydrates, aggrType: Aggregate.AggMin, lowerBound: 400, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Fiber",
                        items: [DashboardFilterCellData(title: "Under 10",
                                                        hkType: HKQuantityTypeIdentifierDietaryFiber, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 10),
                                DashboardFilterCellData(title: "Between 10-15",
                                                        hkType: HKQuantityTypeIdentifierDietaryFiber, aggrType: Aggregate.AggAvg, lowerBound: 10, upperBound: 15),
                                DashboardFilterCellData(title: "Between 15-20",
                                                        hkType: HKQuantityTypeIdentifierDietaryFiber, aggrType: Aggregate.AggAvg, lowerBound: 15, upperBound: 20),
                                DashboardFilterCellData(title: "More than 20",
                                                        hkType: HKQuantityTypeIdentifierDietaryFiber, aggrType: Aggregate.AggMin, lowerBound: 20, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Sugar",
                        items: [DashboardFilterCellData(title: "Less than 50",
                                                        hkType: HKQuantityTypeIdentifierDietarySugar, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 50),
                                DashboardFilterCellData(title: "Between 50-110",
                                                        hkType: HKQuantityTypeIdentifierDietarySugar, aggrType: Aggregate.AggAvg, lowerBound: 50, upperBound: 110),
                                DashboardFilterCellData(title: "Between 110-180",
                                                        hkType: HKQuantityTypeIdentifierDietarySugar, aggrType: Aggregate.AggAvg, lowerBound: 110, upperBound: 180),
                                DashboardFilterCellData(title: "More than 180",
                                                        hkType: HKQuantityTypeIdentifierDietarySugar, aggrType: Aggregate.AggMin, lowerBound: 180, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Salt",
                        items: [DashboardFilterCellData(title: "Less than 1000",
                                                        hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
                                DashboardFilterCellData(title: "Between 1000-3000",
                                                        hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggAvg, lowerBound: 1000, upperBound: 3000),
                                DashboardFilterCellData(title: "Between 3000-5000",
                                                        hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggAvg, lowerBound: 3000, upperBound: 5000),
                                DashboardFilterCellData(title: "More than 5000",
                                                        hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 5000, upperBound: Int.max)]),

                     DashboardFilterItem(title: "Caffeine",
                        items: [DashboardFilterCellData(title: "Less than 50",
                                                        hkType: HKQuantityTypeIdentifierDietaryCaffeine, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 50),
                                DashboardFilterCellData(title: "Between 50-150",
                                                        hkType: HKQuantityTypeIdentifierDietaryCaffeine, aggrType: Aggregate.AggAvg, lowerBound: 50, upperBound: 150),
                                DashboardFilterCellData(title: "Between 150-300",
                                                        hkType: HKQuantityTypeIdentifierDietaryCaffeine, aggrType: Aggregate.AggAvg, lowerBound: 150, upperBound: 300),
                                DashboardFilterCellData(title: "More than 300",
                                                        hkType: HKQuantityTypeIdentifierDietaryCaffeine, aggrType: Aggregate.AggMin, lowerBound: 300, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Cholesterol",
                        items: [DashboardFilterCellData(title: "Less than 150",
                                                        hkType: HKQuantityTypeIdentifierDietaryCholesterol, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 150),
                                DashboardFilterCellData(title: "Between 150-300",
                                                        hkType: HKQuantityTypeIdentifierDietaryCholesterol, aggrType: Aggregate.AggAvg, lowerBound: 150, upperBound: 300),
                                DashboardFilterCellData(title: "Between 300-450",
                                                        hkType: HKQuantityTypeIdentifierDietaryCholesterol, aggrType: Aggregate.AggAvg, lowerBound: 300, upperBound: 450),
                                DashboardFilterCellData(title: "More than 450",
                                                        hkType: HKQuantityTypeIdentifierDietaryCholesterol, aggrType: Aggregate.AggMin, lowerBound: 450, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Polyunsaturated Fat",
                        items: [DashboardFilterCellData(title: "Less than 10", hkType: HKQuantityTypeIdentifierDietaryFatPolyunsaturated, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 10),
                                DashboardFilterCellData(title: "Between 10-20", hkType: HKQuantityTypeIdentifierDietaryFatPolyunsaturated, aggrType: Aggregate.AggAvg, lowerBound: 10, upperBound: 20),
                                DashboardFilterCellData(title: "Between 20-30", hkType: HKQuantityTypeIdentifierDietaryFatPolyunsaturated, aggrType: Aggregate.AggAvg, lowerBound: 20, upperBound: 30),
                                DashboardFilterCellData(title: "More than 30", hkType: HKQuantityTypeIdentifierDietaryFatPolyunsaturated, aggrType: Aggregate.AggMax, lowerBound: 30, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Saturated Fat",
                        items: [DashboardFilterCellData(title: "Less than 15", hkType: HKQuantityTypeIdentifierDietaryFatSaturated, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 15),
                                DashboardFilterCellData(title: "Between 15-25", hkType: HKQuantityTypeIdentifierDietaryFatSaturated, aggrType: Aggregate.AggAvg, lowerBound: 15, upperBound: 25),
                                DashboardFilterCellData(title: "Between 25-35", hkType: HKQuantityTypeIdentifierDietaryFatSaturated, aggrType: Aggregate.AggAvg, lowerBound: 25, upperBound: 35),
                                DashboardFilterCellData(title: "More than 35", hkType: HKQuantityTypeIdentifierDietaryFatSaturated, aggrType: Aggregate.AggMin, lowerBound: 35, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Monounsaturated Fat",
                        items: [DashboardFilterCellData(title: "Less than 20", hkType: HKQuantityTypeIdentifierDietaryFatMonounsaturated, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 20),
                            DashboardFilterCellData(title: "Between 20-30", hkType: HKQuantityTypeIdentifierDietaryFatMonounsaturated, aggrType: Aggregate.AggAvg, lowerBound: 20, upperBound: 30),
                            DashboardFilterCellData(title: "Between 30-40", hkType: HKQuantityTypeIdentifierDietaryFatMonounsaturated, aggrType: Aggregate.AggAvg, lowerBound: 30, upperBound: 40),
                            DashboardFilterCellData(title: "More than 40", hkType: HKQuantityTypeIdentifierDietaryFatMonounsaturated, aggrType: Aggregate.AggMin, lowerBound: 40, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Water",
                        items: [DashboardFilterCellData(title: "Less than 500", hkType: HKQuantityTypeIdentifierDietaryWater, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 500),
                            DashboardFilterCellData(title: "Between 500-1500", hkType: HKQuantityTypeIdentifierDietaryWater, aggrType: Aggregate.AggAvg, lowerBound: 500, upperBound: 1500),
                            DashboardFilterCellData(title: "Between 1500-3000", hkType: HKQuantityTypeIdentifierDietaryWater, aggrType: Aggregate.AggAvg, lowerBound: 1500, upperBound: 3000),
                            DashboardFilterCellData(title: "More than 3000", hkType: HKQuantityTypeIdentifierDietaryWater, aggrType: Aggregate.AggMin, lowerBound: 3000, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Blood pressure Systolic",
                        items: [DashboardFilterCellData(title: "Less than 110", hkType: HKQuantityTypeIdentifierBloodPressureSystolic, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 110),
                            DashboardFilterCellData(title: "Between 110-120", hkType: HKQuantityTypeIdentifierBloodPressureSystolic, aggrType: Aggregate.AggAvg, lowerBound: 110, upperBound: 120),
                            DashboardFilterCellData(title: "Between 120-130", hkType: HKQuantityTypeIdentifierBloodPressureSystolic, aggrType: Aggregate.AggAvg, lowerBound: 120, upperBound: 130),
                            DashboardFilterCellData(title: "More than 130", hkType: HKQuantityTypeIdentifierBloodPressureSystolic, aggrType: Aggregate.AggMin, lowerBound: 130, upperBound: Int.max)]),
                     
                     DashboardFilterItem(title: "Blood pressure Diastolic",
                        items: [DashboardFilterCellData(title: "Less than 60", hkType: HKQuantityTypeIdentifierBloodPressureDiastolic, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 60),
                            DashboardFilterCellData(title: "Between 60-70", hkType: HKQuantityTypeIdentifierBloodPressureDiastolic, aggrType: Aggregate.AggAvg, lowerBound: 60, upperBound: 70),
                            DashboardFilterCellData(title: "Between 70-80", hkType: HKQuantityTypeIdentifierBloodPressureDiastolic, aggrType: Aggregate.AggAvg, lowerBound: 70, upperBound: 80),
                            DashboardFilterCellData(title: "More than 80", hkType: HKQuantityTypeIdentifierBloodPressureDiastolic, aggrType: Aggregate.AggMin, lowerBound: 80, upperBound: Int.max)]),
                     
//                     DashboardFilterItem(title: "Fasting Duration",
//                        items: [DashboardFilterCellData(title: "Less than 8", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
//                            DashboardFilterCellData(title: "Between 8 and 12", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
//                            DashboardFilterCellData(title: "Between 12 and 16", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
//                            DashboardFilterCellData(title: "More than 16", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000)]),
//                     
//                     DashboardFilterItem(title: "Eating Duration",
//                        items: [DashboardFilterCellData(title: "Less than 8", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
//                            DashboardFilterCellData(title: "Between 8 and 12", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
//                            DashboardFilterCellData(title: "Between 12 and 16", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000),
//                            DashboardFilterCellData(title: "More than 16", hkType: HKQuantityTypeIdentifierDietarySodium, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 1000)]),
            
                    ]
        
        if #available(iOS 9.3, *) {
            self.data.append(DashboardFilterItem(title: "Exercise",
                items: [DashboardFilterCellData(title: "Under 20 minutes",
                                                hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggMax, lowerBound: 0, upperBound: 20),
                        DashboardFilterCellData(title: "Between 20-minutes and 1-hour",
                                                hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggAvg, lowerBound: 20, upperBound: 60),
                        DashboardFilterCellData(title: "Between 1-hour and 3-hours",
                                                hkType: HKQuantityTypeIdentifierAppleExerciseTime, aggrType: Aggregate.AggAvg, lowerBound: 60, upperBound: 180)]))
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Defaults.setObject(selectedRows, forKey: selectedRowsDefaultsKey)
        Defaults.synchronize()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].items.count
    }

    private let dashboardFilterCellIdentifier = "DashboardFilterCell"

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell  = tableView.dequeueReusableCellWithIdentifier(dashboardFilterCellIdentifier, forIndexPath: indexPath) as! DashboardFilterCell
        let item = self.data[indexPath.section].items[indexPath.row]
        cell.data = item
        if let _ = selectedRows["\(indexPath.section).\(indexPath.row)"] {
            if !cell.checkBoxButton.selected {//pervent deselect
                cell.didPressButton(self)
            }
        }
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("DashboardHeaderCell") as! DashboardFilterHeaderCell
        cell.captionLabel.text = self.data[section].title
        return cell;
    }

    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as? DashboardFilterCell
        let filterItems = self.data[indexPath.section].items
        let selectedItem = filterItems[indexPath.row]//See DashboardFilterCellData
        
        if selectedItem.selected {//item alerady selected so just remove it and deselect
            cell?.didPressButton(self)
            let selectedKey = String("\(indexPath.section).\(indexPath.row)")
            removeItemForKey(selectedKey)
            return
        } else {
            for (index, item) in filterItems.enumerate() {
                if (item.selected && indexPath.row != index) {
                    let currentlySelectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: indexPath.section)) as? DashboardFilterCell
                    currentlySelectedCell?.didPressButton(self)
                    let selectedKey = String("\(indexPath.section).\(index)")
                    removeItemForKey(selectedKey)
                }
            }
        }
        if let predicate = selectedItem.predicate {//get predicate based of selected item
            selectedRows["\(indexPath.section).\(indexPath.row)"] = QueryManager.sharedManager.getQueries().count//add item to selected rows and it's index
//            let query = Query.ConjunctiveQuery(nil, nil, nil, [predicate])//cereate query
//            QueryManager.sharedManager.addQuery("\(selectedItem.title)", query: query)//add query to query manager
        }
        cell?.didPressButton(self)//set cell as selected
    }
    
    func removeItemForKey(key: String) {
        if let queryIndex = selectedRows[key] {//removing query at index
//            QueryManager.sharedManager.removeQuery(queryIndex)
        }
        selectedRows.removeValueForKey(key)
    }
}


