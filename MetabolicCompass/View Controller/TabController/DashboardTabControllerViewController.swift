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

    override func viewDidLoad() {
        super.viewDidLoad()

        
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
