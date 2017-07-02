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
        case Dial
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
   
    private func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
    
    func updateNavigationItem() {
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barStyle = .black;
        
        self.navigationItem.title = NSLocalizedString("DASHBOARD", comment: "dashboard screen title")
        
        let manageButton = ScreenManager.sharedInstance.appNavButtonWithTitle(title: NSLocalizedString("Manage", comment: "dashboard manage button"))
        manageButton.addTarget(self, action: #selector(self.didSelectManageButton), for: .touchUpInside)
        self.leftNavButton = UIBarButtonItem(customView: manageButton)
        
        let filtersButton = ScreenManager.sharedInstance.appNavButtonWithTitle(title: NSLocalizedString("Filters", comment: "dashboard filter button"))
        filtersButton.addTarget(self, action: #selector(self.didSelectFiltersButton), for: .touchUpInside)
        self.rightNavButton = UIBarButtonItem(customView: filtersButton)
        
        navigationItem.leftBarButtonItem = self.leftNavButton
        navigationItem.rightBarButtonItem = self.rightNavButton
    }
   
    private let filterControllerSegue          = "FilterSegue"
    private let manageDashboardControllerSegue = "ManageDashboardSegue"
    private let manageBalanceControllerSegue   = "ManageBalanceSegue"
    
    func didSelectFiltersButton(_ sender: AnyObject) {
        OperationQueue.main.addOperation {
            [weak self] in self?.performSegue(withIdentifier: (self?.filterControllerSegue)!, sender: self)

        }
    }
    
    func manageSegueForIndex (_ index: NSInteger) -> String {
        switch index {
        case 0:
            return manageDashboardControllerSegue
        case 1:
            return manageBalanceControllerSegue
        default:
            return ""
        }
        
    }
    
    func didSelectManageButton(_ sender: AnyObject) {
        OperationQueue.main.addOperation {
            [weak self] in
            self?.performSegue(withIdentifier: (self?.manageSegueForIndex((self?.segmentedControll.selectedSegmentIndex)!))!, sender: self)
        }
    }
    
    private let dashboardSegueIdentifier = "DashboardSegue"
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if (segue.identifier == dashboardSegueIdentifier)
        {
            containerController = segue.destination as? UITabBarController;
        }
    }

    @IBAction func didSelectDashboardType(_ sender: AnyObject) {
        guard let segmentedControl: UISegmentedControl = sender as? UISegmentedControl else {
            return
        }
        
        let hideRightButton = segmentedControl.selectedSegmentIndex == DashboardType.DailyProgress.rawValue
                                || segmentedControl.selectedSegmentIndex == DashboardType.Balance.rawValue
                                || segmentedControl.selectedSegmentIndex == DashboardType.Dial.rawValue
        
        navigationItem.leftBarButtonItem = (segmentedControl.selectedSegmentIndex == DashboardType.DailyProgress.rawValue || segmentedControl.selectedSegmentIndex == DashboardType.Dial.rawValue) ? nil : self.leftNavButton
        navigationItem.rightBarButtonItem = hideRightButton ? nil : self.rightNavButton
        containerController?.selectedIndex = segmentedControl.selectedSegmentIndex
    }
}
