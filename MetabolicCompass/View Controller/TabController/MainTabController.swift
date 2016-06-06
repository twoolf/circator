//
//  MainTabController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import PathMenu
import Async
import MetabolicCompassKit

class MainTabController: UITabBarController, UITabBarControllerDelegate, PathMenuDelegate {

    private var overlayView: UIVisualEffectView? = nil
    private var menu: PathMenu? = nil
    
    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureTabBar()
        self.delegate = self
        self.selectedIndex = 0;
        
        if let viewController = self.selectedViewController {
            if let controller = viewController as? DashboardTabControllerViewController {
                controller.rootNavigationItem = self.navigationItem
            }
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(userDidLogin), name: UMDidLoginNotifiaction, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(userDidLogout), name: UMDidLogoutNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.addOverlay()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.hidden = true
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    func configureTabBar() {
        
        let tabBar: UITabBar = self.tabBar
        guard let items = tabBar.items else {
            return
        }
        
        for tabItem in items {
            tabItem.image = tabItem.image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            tabItem.selectedImage = tabItem.selectedImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        }
    }
    
    //MARK: UITabBarControllerDelegate
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        
        if let controller = viewController as? DashboardTabControllerViewController {
            controller.rootNavigationItem = self.navigationItem
        }
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController is UIPageViewController {
            return false
        }
        return true
    }
    
    //MARK: Notifications
    func userDidLogin() {
        Async.main(after: 0.5) {
            self.menu!.hidden = false
        }
    }
    
    func userDidLogout() {
        self.menu!.hidden = true
    }
    
    //MARK: Workign with PathMenu
    
    func addMenuToView () {

        let addExercisesImage = UIImage(named:"add-exercises-button")!
        let addExercisesItem = PathMenuItem(image: addExercisesImage, highlightedImage: nil, contentImage: nil)

        let addMealImage = UIImage(named:"add-meal-button")!
        let addMealItem = PathMenuItem(image: addMealImage, highlightedImage: nil, contentImage: nil)

        let addSleepImage = UIImage(named:"add-sleep-button")!
        let addSleepItem = PathMenuItem(image: addSleepImage, highlightedImage: nil, contentImage: nil)
        
        let items = [addMealItem, addExercisesItem, addSleepItem]
        
        let startItem = PathMenuItem(image: UIImage(named: "button-dashboard-add-data")!,
                                     highlightedImage: UIImage(named: "button-dashboard-add-data"),
                                     contentImage: UIImage(named: "button-dashboard-add-data"),
                                     highlightedContentImage: UIImage(named: "button-dashboard-add-data"))
        
        self.menu = PathMenu(frame: view.bounds, startItem: startItem, items: items)

        self.menu!.delegate = self
        self.menu!.startPoint     = CGPointMake(view.frame.width/2, view.frame.size.height - 26.0)
        self.menu!.menuWholeAngle = CGFloat(M_PI) - CGFloat(M_PI/5)
        self.menu!.rotateAngle    = -CGFloat(M_PI_2) + CGFloat(M_PI/5) * 1/2
        self.menu!.timeOffset     = 0.0
        self.menu!.farRadius      = 110.0
        self.menu!.nearRadius     = 90.0
        self.menu!.endRadius      = 100.0
        self.menu!.animationDuration = 0.5
        self.menu!.hidden = !UserManager.sharedManager.hasAccount()
        self.view.window?.rootViewController?.view.addSubview(self.menu!)
    }
    
    //MARK: Working with overlayView
    
    func addOverlay () {
        if self.overlayView == nil {
            let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
            overlay.frame = (self.view.window?.rootViewController?.view.bounds)!
            overlay.alpha = 0.8
            overlay.userInteractionEnabled = true
            overlay.hidden = true
            self.view.window?.rootViewController?.view.addSubview(overlay)
            self.overlayView = overlay
            self.addMenuToView()
        }
    }
    
    func hideOverlay() {
        self.overlayView?.hidden = true
    }
    
    func hideIcons(hide: Bool) {
        for manuItem in self.menu!.menuItems {
            manuItem.hidden = hide
        }
    }
    
    //MARK: PathMenuDelegate
    
    func pathMenu(menu: PathMenu, didSelectIndex idx: Int) {
        Async.main(after: 0.4) { 
            self.hideIcons(true)
            self.hideOverlay()
        }
    }
    
    func pathMenuWillAnimateOpen(menu: PathMenu) {
        self.overlayView?.hidden = false
        hideIcons(false)
    }
    
    func pathMenuWillAnimateClose(menu: PathMenu) {
        
    }
    
    func pathMenuDidFinishAnimationOpen(menu: PathMenu) {
        
    }
    
    func pathMenuDidFinishAnimationClose(menu: PathMenu) {
        self.hideOverlay()
        hideIcons(true)
    }
    
    //MARK: Deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
