//
//  DashboardTabControllerViewController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardTabControllerViewController: UIViewController {
    
    enum DashboardType: Int {
        case Comparison = 0
        case Balance
        case DailyProgress
    }
    
    @IBOutlet weak var segmentedControll: UISegmentedControl!
    weak var rootNavigationItem: UINavigationItem?
    var containerController: UITabBarController?;
    private var leftNavButton: UIBarButtonItem? = nil
    private var rightNavButton: UIBarButtonItem? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateNavigationItem()
    }
   
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func updateNavigationItem() {
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barStyle = .Black;
        
        self.navigationItem.title = NSLocalizedString("DASHBOARD", comment: "dashboard screen title")
        
        let manageButton = ScreenManager.sharedInstance.appNavButtonWithTitle(NSLocalizedString("Manage", comment: "dashboard manage button"))
        manageButton.addTarget(self, action: #selector(didSelectManageButton), forControlEvents: .TouchUpInside)
        self.leftNavButton = UIBarButtonItem(customView: manageButton)
        
        let filtersButton = ScreenManager.sharedInstance.appNavButtonWithTitle(NSLocalizedString("Filters", comment: "dashboard filter button"))
        filtersButton.addTarget(self, action: #selector(didSelectFiltersButton), forControlEvents: .TouchUpInside)
        self.rightNavButton = UIBarButtonItem(customView: filtersButton)
        
        navigationItem.leftBarButtonItem = self.leftNavButton
        navigationItem.rightBarButtonItem = self.rightNavButton
    }
   
    private let filterControllerSegue          = "FilterSegue"
    private let manageDashboardControllerSegue = "ManageDashboardSegue"
    private let manageBalanceControllerSegue   = "ManageBalanceSegue"
    
    func didSelectFiltersButton(sender: AnyObject) {
        self.performSegueWithIdentifier(filterControllerSegue, sender: self)
    }
    
    func manageSegueForIndex (index: NSInteger) -> String {
        switch index {
        case 0:
            return manageDashboardControllerSegue
        case 1:
            return manageBalanceControllerSegue
        default:
            return ""
        }
        
    }
    
    func didSelectManageButton(sender: AnyObject) {
        self.performSegueWithIdentifier(self.manageSegueForIndex(self.segmentedControll.selectedSegmentIndex), sender: self)
    }
    
    private let dashboardSegueIdentifier = "DashboardSegue"
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if (segue.identifier == dashboardSegueIdentifier)
        {
            containerController = segue.destinationViewController as? UITabBarController;
        }
    }

    @IBAction func didSelectDashboardType(sender: AnyObject) {
        guard let segmentedControl: UISegmentedControl = sender as? UISegmentedControl else {
            return
        }
        
        let hideRightButton = segmentedControl.selectedSegmentIndex == DashboardType.DailyProgress.rawValue || segmentedControl.selectedSegmentIndex == DashboardType.Balance.rawValue
        
        navigationItem.leftBarButtonItem = segmentedControl.selectedSegmentIndex == DashboardType.DailyProgress.rawValue ? nil : self.leftNavButton
        navigationItem.rightBarButtonItem = hideRightButton ? nil : self.rightNavButton
        containerController?.selectedIndex = segmentedControl.selectedSegmentIndex
    }
}
