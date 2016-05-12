//
//  DashboardTabControllerViewController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DashboardTabControllerViewController: UIViewController {
    
    var containerController: UITabBarController?;
    weak var rootNavigationItem: UINavigationItem? {
        didSet {
//            self.updateNavigationItem()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateNavigationItem()
    }
   
    func updateNavigationItem() {
        
        self.navigationItem.title = NSLocalizedString("DASHBOARD", comment: "dashboard screen title")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Manage", comment: "dashboard manage button"),
                                                               style: .Done,
                                                               target: self,
                                                               action: #selector(didSelectManageButton))
            
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Filters", comment: "dashboard filter button"),
                                                                style: .Done,
                                                                target: self,
                                                                action: #selector(didSelectFiltersButton))
    }
   
    private let filterControllerSegue = "FilterSegue"
    private let manageDashboardControllerSegue = "ManageDashboardSegue"
    
    func didSelectFiltersButton(sender: AnyObject) {
        self.performSegueWithIdentifier(filterControllerSegue, sender: self)
    }
    
    func didSelectManageButton(sender: AnyObject) {
        self.performSegueWithIdentifier(manageDashboardControllerSegue, sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        guard let segmentedControl: UISegmentedControl = sender as? UISegmentedControl else
        {
            return
        }
        
        containerController?.selectedIndex = segmentedControl.selectedSegmentIndex
    }
}
