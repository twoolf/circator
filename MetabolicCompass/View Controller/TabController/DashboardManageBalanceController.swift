//
//  DashboardManageBalanceController.swift
//  MetabolicCompass 
//
//  Created by Inaiur on 5/13/16. 
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import Async

class DashboardManageBalanceController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    let selectController: BalanceSampleListController = {
        let storyboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "BalanceSampleListController") as! BalanceSampleListController
        controller.modalPresentationStyle = .overCurrentContext
        return controller
    }()
    
    var data: [DashboardMetricsConfigItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    private let cellIdentifier = "DashboardManageCell"
    
    //MARK: View life circle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appNavBarTextColor(),
//                                                  NSFontAttributeName : ScreenManager.appNavBarFont()]
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.barStyle = UIBarStyle.black;
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        
        self.refreshContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(contentDidChange), name: NSNotification.Name(rawValue: PMDidUpdateBalanceSampleTypesNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Working with content
    
    func refreshContent () {
        self.data = []
        for type in PreviewManager.balanceSampleTypes {
            self.data.append(DashboardMetricsConfigItem(type: type.identifier, active: true, object: type))
        }
        self.tableView.reloadData()
    }
    
    func contentDidChange() {
        Async.main {
            self.refreshContent()
        }
    }
    
    func save() {
        
//        var samples = [HKSampleType]()
//        
//        for item in self.data {
//            if (item.active) {
//                samples.append(item.object)
//            }
//        }
//        
//        PreviewManager.updatePreviewSampleTypes(samples)
    }
    
    //MARK: controller methods
/*    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent;
    } */
    
    //MARK: Actions
    @IBAction func onClose(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        save()
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as! ManageBalanceCell
        let item = self.data[indexPath.row]
        cell.leftImage.image = appearanceProvider.imageForSampleType(sampleType: item.type, active: true)
        cell.titleLabel.text = appearanceProvider.titleForSampleType(sampleType: item.type, active: true).string
        cell.sampleTypesIndex = indexPath.row
        cell.data = item
        return cell;
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath as IndexPath) as! ManageBalanceCell
        self.selectController.selectdType = selectedCell.data.object
        self.selectController.parentCell  = selectedCell
        self.present(self.selectController, animated: true, completion: nil)
    }
}
