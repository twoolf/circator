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
import ARSLineProgress

class MainTabController: UITabBarController, UITabBarControllerDelegate, ManageEventMenuDelegate {
    
    private var manageEventOverlayView: UIVisualEffectView? = nil
    private var manageEventMenu: ManageEventMenu? = nil
    
    private var syncOverlayView: UIVisualEffectView? = nil
    private var syncMode: Bool = false
    private var syncInitial: CGFloat = 0
    private var syncCounter: CGFloat = 0
    
    private var syncCheckpoint: CGFloat = 0
    private var syncTerminator: Async? = nil
    
    private var lastMenuUseAddedEvents = false
    private var dailyProgressVC: DailyProgressViewController? = nil
    
    //MARK: View life cycle
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.userDidLogin), name: NSNotification.Name(rawValue: UMDidLoginNotifiaction), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.userDidLogout), name: NSNotification.Name(rawValue: UMDidLogoutNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.userAddedCircadianEvents), name: NSNotification.Name(rawValue: MEMDidUpdateCircadianEvents), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.syncBegan), name: NSNotification.Name(rawValue: SyncBeganNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.syncEnded), name: NSNotification.Name(rawValue: SyncEndedNotification), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addSyncOverlay()
        self.addManageEventOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.navigationBar.barStyle = .black
    }
    
    /*    func preferredStatusBarStyle() -> UIStatusBarStyle {
     return .lightContent;
     } */
    
    func configureTabBar() {
        
        let tabBar: UITabBar = self.tabBar
        guard let items = tabBar.items else {
            return
        }
        
        for tabItem in items {
            tabItem.image = tabItem.image?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            tabItem.selectedImage = tabItem.selectedImage?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        }
    }
    
    //MARK: UITabBarControllerDelegate
     func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        if let controller = viewController as? DashboardTabControllerViewController {
            controller.rootNavigationItem = self.navigationItem
        }
    }
    
     func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController is UIPageViewController {
            return false
        }
        return true
    }
    
    // MARK :- Notifications
    @objc func userDidLogin() {
        Async.main(after: 0.5) {
            if self.manageEventMenu != nil {
                self.manageEventMenu!.isHidden = false
            } else {
                self.userDidLogin()
            }
        }
    }
    
    @objc func userDidLogout() {
        self.manageEventMenu!.isHidden = true
    }
    
    @objc func userAddedCircadianEvents() {
        lastMenuUseAddedEvents = true
    }
    
    // MARK :- Remote sync overlay
    func addSyncOverlay () {
        if self.syncOverlayView == nil {
            let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            overlay.frame = (self.view.window?.rootViewController?.view.bounds)!
            overlay.alpha = 0.9
            overlay.isUserInteractionEnabled = true
            overlay.isHidden = true
            self.view.window?.rootViewController?.view.addSubview(overlay)
            self.syncOverlayView = overlay
            
            // Add overlay title
            let titleLabel = UILabel()
            titleLabel.text = "DATA SYNC"
            titleLabel.font = ScreenManager.appFontOfSize(size: 16)
            titleLabel.textColor = UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.6)
            titleLabel.textAlignment = .center
            titleLabel.sizeToFit()
            titleLabel.frame = CGRect(0, 35, overlay.frame.width, titleLabel.frame.height)
            overlay.contentView.addSubview(titleLabel)
            
            let descLabel = UILabel()
            descLabel.text = "Please wait while we upload your health data"
            descLabel.font = ScreenManager.appFontOfSize(size: 14)
            descLabel.textColor = UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.6)
            descLabel.textAlignment = .center
            descLabel.sizeToFit()
            descLabel.frame = CGRect(0, 50 + titleLabel.frame.height, overlay.frame.width, descLabel.frame.height)
            overlay.contentView.addSubview(descLabel)
        }
    }
    
    @objc func syncBegan(notification: NSNotification) {
        if let dict = notification.userInfo, let initial = dict["count"] as? Int {
            if !syncMode {
                NotificationCenter.default.addObserver(self, selector: #selector(self.syncProgress), name: NSNotification.Name(rawValue: SyncProgressNotification), object: nil)
            }
            syncMode = true
            syncInitial = CGFloat(initial)
            syncCounter = syncInitial
            
            syncCheckpoint = syncCounter
            syncTerminator = Async.background(after: 60.0) {
                let progress = (self.syncCheckpoint - self.syncCounter) / self.syncCheckpoint
                if progress < 0.001 { self.syncCancel() }
            }
            
            Async.main {
                if let hidden = self.syncOverlayView?.isHidden, hidden {
                    self.syncOverlayView!.isHidden = false
                    self.syncOverlayView!.setNeedsDisplay()
                    ARSLineProgress.showWithProgress(initialValue: 0.01, onView: self.syncOverlayView!.contentView)
                }
            }
            log.debug("DATA SYNC starting", feature: "dataSync")
        }
        else {
            log.error("DATA SYNC No initial upload size found", feature: "dataSync")
        }
    }
    
    func syncCancel() {
        Async.main(after: 3.0) {
            if let hidden = self.syncOverlayView?.isHidden, !hidden {
                self.syncOverlayView!.isHidden = true
                self.syncOverlayView!.setNeedsDisplay()
            }
        }
        UINotifications.genericError(vc: self, msg: "Data syncing was too slow, we will continue it in the background.")
    }
    
    @objc func syncEnded() {
        if syncMode {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: SyncProgressNotification), object: nil)
        }
        syncMode = false
        syncInitial = 0.0
        syncCounter = 0.0
        ARSLineProgress.showSuccess()
        Async.main(after: 3.0) {
            if let hidden = self.syncOverlayView?.isHidden, !hidden {
                self.syncOverlayView!.isHidden = true
                self.syncOverlayView!.setNeedsDisplay()
            }
        }
        log.debug("DATA SYNC finished", feature: "dataSync")
    }
    
    @objc func syncProgress(notification: NSNotification) {
        if let dict = notification.userInfo, let c = dict["count"] as? Int {
            let counter = CGFloat(c)
            if counter > syncInitial {
                syncInitial = counter
            }
            syncCounter = counter
            
            let progress = max(0.01, 100.0 * (syncInitial - syncCounter) / syncInitial)
            ARSLineProgress.updateWithProgress(progress)
            log.debug("DATA SYNC progress \(progress)", feature: "dataSync")
            
            syncCheckpoint = syncCounter
            syncTerminator?.cancel()
            syncTerminator = Async.background(after: 60.0) {
                let progress = (self.syncCheckpoint - self.syncCounter) / self.syncCheckpoint
                if progress < 0.001 { self.syncCancel() }
            }
        }
    }
    
    // MARK :- Manage event overlay
    
    func addManageEventOverlay () {
        if self.manageEventOverlayView == nil {
            let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            overlay.frame = (self.view.window?.rootViewController?.view.bounds)!
            overlay.alpha = 0.9
            overlay.isUserInteractionEnabled = true
            overlay.isHidden = true
            self.view.window?.rootViewController?.view.addSubview(overlay)
            self.manageEventOverlayView = overlay
            //add title for overlay
            let titleLabel = UILabel()
            titleLabel.text = "YOUR CIRCADIAN RHYTHM"
            titleLabel.font = ScreenManager.appFontOfSize(size: 16)
            titleLabel.textColor = UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.6)
            titleLabel.textAlignment = .center
            titleLabel.sizeToFit()
            titleLabel.frame = CGRect(0, 35, overlay.frame.width, titleLabel.frame.height)
            overlay.contentView.addSubview(titleLabel)
            self.addMenuToView()
        }
    }
    
    func hideManageEventOverlay() {
        self.manageEventOverlayView?.isHidden = true
    }
    
    func hideManageEventIcons(hide: Bool) {
        self.manageEventMenu?.hideView(hide)
    }
    
    // MARK:- ManageEventMenu construction
    func addMenuToView () {
        let addExercisesImage = UIImage(named:"icon-add-exercises")!
        let addExercisesItem = PathMenuItem(image: addExercisesImage, highlightedImage: nil, contentImage: nil, contentText: "Exercise")
        
        let addMealImage = UIImage(named:"icon-add-food")!
        let addMealItem = PathMenuItem(image: addMealImage, highlightedImage: nil, contentImage: nil, contentText: "Meals")
        
        let addSleepImage = UIImage(named:"icon-add-sleep")!
        let addSleepItem = PathMenuItem(image: addSleepImage, highlightedImage: nil, contentImage: nil, contentText: "Sleep")
        
        
        let items = [addMealItem, addExercisesItem, addSleepItem]
        
        let startItem = PathMenuItem(image: UIImage(named: "button-dashboard-add-data")!,
                                     highlightedImage: UIImage(named: "button-dashboard-add-data"),
                                     contentImage: UIImage(named: "button-dashboard-add-data"),
                                     highlightedContentImage: UIImage(named: "button-dashboard-add-data"))

        let manageEventMenu = ManageEventMenu(frame: view.bounds, startItem: startItem, items: items)

        manageEventMenu.delegate = self
        manageEventMenu.startPoint = CGPoint(view.frame.width/2, view.frame.size.height - 26.0)
        manageEventMenu.timeOffset = 0.0
        manageEventMenu.animationDuration = 0.15
   //     self.manageEventMenu!.isHidden = !UserManager.sharedManager.hasAccount()
        manageEventMenu.isHidden = false
        self.manageEventMenu = manageEventMenu
        self.view.window?.rootViewController?.view.addSubview(manageEventMenu)
    }
    
    // MARK :- ManageEventMenuDelegate implementation
    
    func manageEventMenu(menu: ManageEventMenu, didSelectIndex idx: Int) {
        OperationQueue.main.addOperation {
            self.hideManageEventIcons(hide: true)
            self.hideManageEventOverlay()
            let controller = UIStoryboard(name: "AddEvents", bundle: nil).instantiateViewController(withIdentifier: "AddMealNavViewController") as! UINavigationController
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
            self.selectedViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    func manageEventMenuWillAnimateOpen(menu: ManageEventMenu) {
        lastMenuUseAddedEvents = false
        self.manageEventOverlayView?.isHidden = false
        hideManageEventIcons(hide: false)
    }
    
    func manageEventMenuWillAnimateClose(menu: ManageEventMenu) {
        
    }
    
    func manageEventMenuDidFinishAnimationOpen(menu: ManageEventMenu) {
        self.manageEventMenu?.logContentView()
    }
    
    func manageEventMenuDidFinishAnimationClose(menu: ManageEventMenu) {
        self.hideManageEventOverlay()
        hideManageEventIcons(hide: true)
        
        if lastMenuUseAddedEvents {
            initializeDailyProgressVC()
            if dailyProgressVC != nil {
                Async.background(after: 1.0) {
                    self.dailyProgressVC?.contentDidUpdate()
                }
            } else {
                log.warning("No DailyProgressViewController available", feature: "addActivityView")
            }
        }
        self.manageEventMenu?.logContentView(false)
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
            log.debug("Daily progress view controller after init: \(dailyProgressVC ?? no_argument as AnyObject)", feature: "addActivityView")
        }
    }
    
    //MARK: Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
