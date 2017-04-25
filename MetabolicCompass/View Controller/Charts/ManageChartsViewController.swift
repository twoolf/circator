//
//  ManageChartsViewController.swift
//  MetabolicCompass 
//
//  Created by Artem Usachov on 6/17/16.       
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import HealthKit

class ManageChartsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    private var data: [DashboardMetricsConfigItem] = []
    private let cellIdentifier = "ChartManageCell"
    private var manageData: [HKSampleType] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for type in PreviewManager.manageChartsSampleTypes {
            let active = PreviewManager.chartsSampleTypes.contains(type)
            data.append(DashboardMetricsConfigItem(type: type.identifier, active: active, object: type))
            manageData.append(type)
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isEditing = true
        self.tableView.allowsSelectionDuringEditing = true
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black;
        self.navigationItem.title = NSLocalizedString("MANAGE CHART", comment: "chart screen title")
        let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .plain, target: self, action: #selector(closeAction))
        self.navigationItem.leftBarButtonItem = leftButton
    }
    
    //MARK: Actions
    func closeAction () {
        save()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ManageDashboardCell
        let item = data[indexPath.row]
        cell.showsReorderControl = false
        cell.updateSelectionStatus(selected: item.active, appearanceProvider: appearanceProvider, itemType: item.type)
        return cell
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let obj = tableView.cellForRowAtIndexPath(indexPath as IndexPath) as? ManageDashboardCell
        guard let cell = obj else {
            return
        }
        
        let item = self.data[indexPath.row]
        
        if (item.active && self.selectedItemsCount() == 1) {
            return
        }
        
        item.active = !item.active
        cell.updateSelectionStatus(item.active, appearanceProvider: appearanceProvider, itemType: item.type)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let itemToMove = data[fromIndexPath.row]
        data.remove(at: fromIndexPath.row)
        data.insert(itemToMove, at: toIndexPath.row)
        
        let manageItemToMove = manageData[fromIndexPath.row]
        manageData.remove(at: fromIndexPath.row)
        manageData.insert(manageItemToMove, at: toIndexPath.row)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.showsReorderControl = false
    }
    
    //MARK: Help
    func  selectedItemsCount() -> Int {
        var selected = 0
        for item in self.data {
            if (item.active) {
                selected += 1
            }
        }
        return selected
    }
    
    func save() {
        var samples = [HKSampleType]()
        for item in self.data {
            if (item.active) {
                samples.append(item.object)
            }
        }
        PreviewManager.updateChartsSampleTypes(types: samples)
        PreviewManager.updateManageChartsSampleTypes(types: manageData)
    }
}
