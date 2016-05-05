//
//  MainTabController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class MainTabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
        self.configureTabBar()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Manage", comment: "dashboard manage button"),
                                                                style: .Done,
                                                                target: self,
                                                                action: #selector(didSelectManageButton))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Filters", comment: "dashboard filter button"),
                                                                 style: .Done,
                                                                 target: self,
                                                                 action: #selector(didSelectFiltersButton))
        
        self.navigationItem.title = NSLocalizedString("DASHBOARD", comment: "dashboard screen title")
        
    }
    
    func didSelectFiltersButton(sender: AnyObject) {
        
    }
    
    func didSelectManageButton(sender: AnyObject) {
        
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureTabBar() {
        
        let tabBar: UITabBar = self.tabBar
        
        guard let items = tabBar.items else {
            return
        }
        
        for tabItem in items
        {
            tabItem.image = tabItem.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            tabItem.selectedImage = tabItem.selectedImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
