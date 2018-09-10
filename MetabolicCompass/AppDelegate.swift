//
//  AppDelegate.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import GameKit
import MetabolicCompassKit
import MCCircadianQueries
import Fabric
import Crashlytics
import Locksmith
import SwiftDate
import SwiftyUserDefaults
import WatchConnectivity
import Auth0
import SwiftyBeaver
import AWSMobileClient
import UserNotifications

// Init Logs
let log = RemoteLogManager.sharedManager.log
let localLog = SwiftyBeaver.self

@UIApplicationMain
/**
 An overview of the Circator files and their connections follows. First, a reader should realize that MC="Metabolic Compass" and that the abbreviation is common in the code.  Also, Circator was the working name for Metabolic Compass, so the two names are present frequently and refer to this same application. Lastly, to orient those looking at the code, the CircatorKit provides the core functionality needed for the Circator code.  Highlights of that functionality are that all of the HealthKit calls and all of the formatting/unit conversions are done with CircatorKit code, and that the consent flow through ResearchKit along with the account set-up and API calls are in the CircatorKit code.
 */
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate
{
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
        print("in activationDidCompleteWith")
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("in sessionDidBecomeInactive")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("in sessionDidDeactive")
    }
    var window: UIWindow?
    var mainViewController: UIViewController!
    private let firstRunKey = "FirstRun"
    
    func application(_ application: UIApplication,
                              willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool
    {
        print("inside willFinishLaunchingWithOptions")
        return true
    }
    
    func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? ) -> Bool
    {
        // Configure Local and Remote logs, Crashes data collection
        Fabric.with([Crashlytics.self,Answers.self])
        log.info("Using service URL: \(MCRouter.baseURL)")
        
        CacheConfigurations.configureCache()
        
        // Configure SwiftyBeaver
        let console = ConsoleDestination()
        console.format = "$DHH:mm:ss$d $L $M"
        console.useTerminalColors = true
        console.asynchronously = false
        localLog.addDestination(console)
        
        localLog.info("inside didFinishLaunchingWithOptions")
        
        if ((Defaults.object(forKey: firstRunKey) == nil)) {
            UserManager.sharedManager.resetFull()
            Defaults.set("firstrun", forKey: firstRunKey)
            Defaults.synchronize()
        }
        
        // Set up notifications after launching the app.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        AccountManager.shared.resetLocalNotifications()
        recycleNotification()
        UINotifications.configureNotifications()
        
        createShortcutItems()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.blue
        
        // Override point for customization after application launch.
        // Sets background to a blank/empty image
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        
        // Sets shadow (line below the bar) to a blank image
        UINavigationBar.appearance().shadowImage = UIImage()
        
        // Sets the translucent background color
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        
        // Set translucent. (Default value is already true, so this can be removed if desired.)
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: ScreenManager.appTitleTextColor(),
            NSAttributedStringKey.font: ScreenManager.appNavBarFont()
        ]
        
        //set custom back button image
        let backBtnImg = UIImage(named: "back-button")
        
        UINavigationBar.appearance().backIndicatorImage = backBtnImg
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backBtnImg
        
        
        let tabBarStoryboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let tabBarScreen = tabBarStoryboard.instantiateViewController(withIdentifier: "TabBarController") 
        print("set tab bar controller as ui view controller")
        mainViewController = tabBarScreen

        
        let navController  = UINavigationController(rootViewController: mainViewController)
        AccountManager.shared.rootViewController = navController
        
        FontScaleLabel.scaleFactor = ScreenManager.scaleFactor
        FontScaleTextField.scaleFactor = ScreenManager.scaleFactor
        
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        log.debug("right before AccountManager called")
        AccountManager.shared.loginAndInitialize(animated: false)
        
        var launchSuccess = true
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchSuccess = launchShortcutActivity(shortcutItem)
        }
        
        // Add a recycling observer.
        NotificationCenter.default.addObserver(self, selector: #selector(self.recycleNotification), name: NSNotification.Name(rawValue: USNDidUpdateBlackoutNotification), object: nil)
        
        // Add a debugging observer.
        NotificationCenter.default.addObserver(self, selector: #selector(self.errorNotification), name: NSNotification.Name(rawValue: MCRemoteErrorNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.errorNotification), name: NSNotification.Name(rawValue: MCRemoteErrorNotification), object: nil)
        
        launchSuccess = launchSuccess && AWSMobileClient.sharedInstance().interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)
        return launchSuccess
    }
    
    @nonobjc internal func application(_ application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        return checkOrientation(self.window?.rootViewController)
    }
    
    func checkOrientation(_ viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if viewController == nil {
            return .all
        } else if viewController is QueryViewController {
            return .portrait
        } else if viewController is QueryBuilderViewController {
            return .portrait
        } else if viewController is UINavigationController {
            return checkOrientation((viewController as? UINavigationController)!.visibleViewController)
        } else {
            return checkOrientation(viewController!.presentedViewController)
        }
    }
    
    internal func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    internal func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        recycleNotification()
    }
    
    internal func applicationWillEnterForeground(_ application: UIApplication) {
        recycleNotification()
    }
    
    internal func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    internal func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    @nonobjc internal func application(_ application: UIApplication, didRegisterUserNotificationSettings: UIUserNotificationSettings) {
        let enabled = didRegisterUserNotificationSettings.types != []
        log.info("APPDEL Enabling user notifications: \(enabled)")
        Defaults.set(enabled, forKey: AMNotificationsKey)
        Defaults.synchronize()
    }
    
    internal func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        log.info("APPDEL received \(notification)")
        NotificationManager.sharedManager.showInApp(notification: notification)
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        log.debug("Shortcut \"\(shortcutItem.localizedTitle)\" pressed")
        completionHandler(self.launchShortcutActivity(shortcutItem))
    }
    
    func createShortcutItems() {
        let itemSpecs = [
            ("Add a Meal", "com.metaboliccompass.meal", "add-meal-button"),
            ("Add your Sleep", "com.metaboliccompass.sleep", "add-sleep-button"),
            ("Add Exercise", "com.metaboliccompass.exercise", "add-exercises-button")]
        
        UIApplication.shared.shortcutItems =  itemSpecs.map { (title, type, iconName) in
            let icon = UIApplicationShortcutIcon(templateImageName: iconName)
            return UIMutableApplicationShortcutItem(type: type, localizedTitle: title, localizedSubtitle: nil, icon: icon, userInfo: nil)
        }
    }
    
    func launchShortcutActivity(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        let storyboard = UIStoryboard(name: "AddEvents", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "AddMealNavViewController") as! UINavigationController
        let addController = controller.viewControllers[0] as! AddEventViewController
        
        if shortcutItem.type == "com.metaboliccompass.meal" {
            addController.type = .Meal
        }
        else if shortcutItem.type == "com.metaboliccompass.sleep" {
            addController.type = .Sleep
        }
        else if shortcutItem.type == "com.metaboliccompass.exercise" {
            addController.type = .Exercise
        }
        else {
            return false
        }
        
        OperationQueue.main.addOperation {
            [weak self] in
            self?.window?.rootViewController?.present(controller, animated: true, completion: nil)
        }
            return true

    }
    
    @objc func recycleNotification() {
        NotificationManager.sharedManager.onRecycleEvent()
    }
    
   @objc public func errorNotification(_ notification: NSNotification) {
        if let info = notification.userInfo, let event = info["event"] as? String, let attrs = info["attrs"] as? [String: AnyObject]
        {
            Answers.logCustomEvent(withName: event, customAttributes: attrs)
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
   public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return Auth0.resumeAuth(url, options: options)
    }
}

