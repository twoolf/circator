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

class DashboardManageController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    var data: [DashboardMetricsConfigItem] = []
    
    private var manageData: [HKSampleType] = []
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appNavBarTextColor(),
                                                  NSFontAttributeName : ScreenManager.appNavBarFont()]
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.barStyle = UIBarStyle.black;
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        self.tableView.allowsSelectionDuringEditing = true

        for type in PreviewManager.managePreviewSampleTypes {
            let active = PreviewManager.previewSampleTypes.contains(type)
            data.append(DashboardMetricsConfigItem(type: type.identifier, active: active, object: type))
            manageData.append(type)
        }
        
        self.tableView.isEditing = true
    }
    
    func save() {
        
        var samples = [HKSampleType]()
        
        for item in self.data {
            if (item.active) {
                samples.append(item.object)
            }
        }
        
        PreviewManager.updatePreviewSampleTypes(types: samples)
        PreviewManager.updateManagePreviewSampleTypes(types: manageData)
    }
    
/*    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent;
    } */
    
    @IBAction func onClose(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        save()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
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
        cell.updateSelectionStatus(selected: item.active, appearanceProvider: appearanceProvider, itemType: item.type)
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
    
    private func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let obj = tableView.cellForRow(at: indexPath as IndexPath) as? ManageDashboardCell
        guard let cell = obj else {
            return
        }

        let item = self.data[indexPath.row]
        
        if (item.active && self.selectedItemsCount() == 1) {
            return
        }
        
        item.active = !item.active
        cell.updateSelectionStatus(selected: item.active, appearanceProvider: appearanceProvider, itemType: item.type)
    }

    private func tableView(_ tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    private func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    private func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    private func tableView(_ tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let itemToMove = self.data[fromIndexPath.row]
        self.data.remove(at: fromIndexPath.row)
        self.data.insert(itemToMove, at: toIndexPath.row)
        
        let manageItemToMove = manageData[fromIndexPath.row]
        manageData.remove(at: fromIndexPath.row)
        manageData.insert(manageItemToMove, at: toIndexPath.row)
    }
    
    private func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.showsReorderControl = false
    }
}
