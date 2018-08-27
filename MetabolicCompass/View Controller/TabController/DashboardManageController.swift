//
//  DashboardManageController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries

class DashboardManageController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    var data: [DashboardMetricsConfigItem] = []
    
    private var manageData: [HKSampleType] = []
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    private var initialSelectedCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : ScreenManager.sharedInstance.appNavBarTextColor(),
                                                  NSAttributedStringKey.font : ScreenManager.appNavBarFont()]
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.barStyle = UIBarStyle.black;
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        self.tableView.allowsSelectionDuringEditing = true

        self.initialSelectedCount = 0
        for type in PreviewManager.managePreviewSampleTypes {
            let active = PreviewManager.previewSampleTypes.contains(type)
            if active {
                self.initialSelectedCount += 1
            }
            data.append(DashboardMetricsConfigItem(type: type.identifier, active: active, object: type))
            manageData.append(type)
        }
        
        self.tableView.isEditing = true
    }
    
    func save() {
        
        let samples: [HKSampleType] =
        self.data.flatMap { item in
            item.active ? item.object : nil
        }
        
        guard samples.count != self.initialSelectedCount else {
            return
        }
        
        PreviewManager.updatePreviewSampleTypes(types: samples)
        PreviewManager.updateManagePreviewSampleTypes(types: self.manageData)
    }
    
/*    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent;
    } */
    
    @IBAction func onClose(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        save()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    private let cellIdentifier = "DashboardManageCell"
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as! ManageDashboardCell
        let item = self.data[indexPath.row]
        cell.showsReorderControl = false
        cell.updateSelectionStatus(item.active, appearanceProvider: appearanceProvider, itemType: item.type)
        return cell;
    }
    
    func  selectedItemsCount() -> Int {
        var selected = 0
        
        for item in self.data {
            if (item.active) {
                selected += 1
            }
        }
        
        return selected
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let obj = tableView.cellForRow(at: indexPath as IndexPath) as? ManageDashboardCell
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

    internal func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    internal func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    internal func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    internal func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let itemToMove = self.data[fromIndexPath.row]
        self.data.remove(at: fromIndexPath.row)
        self.data.insert(itemToMove, at: toIndexPath.row)
        
        let manageItemToMove = manageData[fromIndexPath.row]
        manageData.remove(at: fromIndexPath.row)
        manageData.insert(manageItemToMove, at: toIndexPath.row)
    }
    
    internal func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.showsReorderControl = false
    }
}
