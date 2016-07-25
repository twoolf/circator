//
//  MainTabController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/5/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Async
import MetabolicCompassKit

class MainTabController: UITabBarController, UITabBarControllerDelegate, ManageEventMenuDelegate {

    private var overlayView: UIVisualEffectView? = nil
    private var menu: ManageEventMenu? = nil

    private var lastMenuUseAddedEvents = false
    private var dailyProgressVC: DailyProgressViewController? = nil

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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(userAddedCircadianEvents), name: MEMDidUpdateCircadianEvents, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.addOverlay()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.hidden = true
        self.navigationController?.navigationBar.barStyle = .Black
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
            if self.menu != nil {
                self.menu!.hidden = false
            } else {
                self.userDidLogin()
            }
        }
    }

    func userDidLogout() {
        self.menu!.hidden = true
    }

    func userAddedCircadianEvents() {
        lastMenuUseAddedEvents = true
    }
    

    //MARK: Working with ManageEventMenu
    
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
        
        self.menu = ManageEventMenu(frame: view.bounds, startItem: startItem, items: items)

        self.menu!.delegate = self
        self.menu!.startPoint = CGPointMake(view.frame.width/2, view.frame.size.height - 26.0)
        self.menu!.timeOffset = 0.0
        self.menu!.animationDuration = 0.15
        self.menu!.hidden = !UserManager.sharedManager.hasAccount()
        self.view.window?.rootViewController?.view.addSubview(self.menu!)
    }
    
    // MARK :- Add event blur overlay
    
    func addOverlay () {
        if self.overlayView == nil {
            let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
            overlay.frame = (self.view.window?.rootViewController?.view.bounds)!
            overlay.alpha = 0.9
            overlay.userInteractionEnabled = true
            overlay.hidden = true
            self.view.window?.rootViewController?.view.addSubview(overlay)
            self.overlayView = overlay
            //add title for overlay
            let titleLabel = UILabel(frame:CGRectZero)
            titleLabel.text = "MANAGE EVENTS"
            titleLabel.font = ScreenManager.appFontOfSize(16)
            titleLabel.textColor = UIColor.colorWithHexString("#ffffff", alpha: 0.6)
            titleLabel.textAlignment = .Center
            titleLabel.sizeToFit()
            titleLabel.frame = CGRectMake(0, 35, CGRectGetWidth(overlay.frame), CGRectGetHeight(titleLabel.frame))
            overlay.contentView.addSubview(titleLabel)
            self.addMenuToView()
        }
    }
    
    func hideOverlay() {
        self.overlayView?.hidden = true
    }

    func hideIcons(hide: Bool) {
        self.menu?.hideView(hide)
    }

    // MARK :- ManageEventMenuDelegate implementation
    
    func manageEventMenu(menu: ManageEventMenu, didSelectIndex idx: Int) {
        Async.main(after: 0.4) {
            self.hideIcons(true)
            self.hideOverlay()
            let controller = UIStoryboard(name: "AddEvents", bundle: nil).instantiateViewControllerWithIdentifier("AddMealNavViewController") as! UINavigationController
            let rootController = controller.viewControllers[0] as! AddEventViewController
            switch idx {
                case EventType.Meal.rawValue:
                    rootController.type = .Meal
                case EventType.Exercise.rawValue:
                    rootController.type = .Exercise
                case EventType.Sleep.rawValue:
                    rootController.type = .Sleep
                default:
                    break
            }
            self.selectedViewController?.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    func manageEventMenuWillAnimateOpen(menu: ManageEventMenu) {
        lastMenuUseAddedEvents = false
        self.overlayView?.hidden = false
        hideIcons(false)
    }
    
    func manageEventMenuWillAnimateClose(menu: ManageEventMenu) {

    }

    func manageEventMenuDidFinishAnimationOpen(menu: ManageEventMenu) {

    }

    func manageEventMenuDidFinishAnimationClose(menu: ManageEventMenu) {
        self.hideOverlay()
        hideIcons(true)

        if lastMenuUseAddedEvents {
            initializeDailyProgressVC()
            if dailyProgressVC != nil {
                Async.background(after: 1.0) {
                    self.dailyProgressVC?.contentDidUpdate()
                }
            } else {
                log.warning("No DailyProgressViewController available")
            }
        }
    }

    func initializeDailyProgressVC() {
        if dailyProgressVC == nil {
            for svc in self.selectedViewController!.childViewControllers {
                if let _ = svc as? DashboardTabControllerViewController {
                    for svc2 in svc.childViewControllers {
                        if let _ = svc2 as? UITabBarController {
                            for svc3 in svc2.childViewControllers {
                                if let dpvc = svc3 as? DailyProgressViewController {
                                    dailyProgressVC = dpvc
                                    break
                                }
                            }
                            break
                        }
                    }
                    break
                }
            }
            log.verbose("Daily progress view controller after init: \(dailyProgressVC)")
        }
    }

    //MARK: Deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
