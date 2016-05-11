//
//  MainTabController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class MainTabController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        self.configureTabBar()
        
        self.navigationItem.title = NSLocalizedString("DASHBOARD", comment: "dashboard screen title")
        self.delegate = self
        
        self.selectedIndex = 0;
        
        if let viewController = self.selectedViewController
        {
            if let controller = viewController as? DashboardTabControllerViewController
            {
                controller.rootNavigationItem = self.navigationItem
            }
        }
        
        
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

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        
        if let controller = viewController as? DashboardTabControllerViewController
        {
            controller.rootNavigationItem = self.navigationItem
        }
    }
}
