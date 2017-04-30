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
//import LogKit

// let log = RemoteLogManager.sharedManager.log

@UIApplicationMain
/**
An overview of the Circator files and their connections follows. First, a reader should realize that MC="Metabolic Compass" and that the abbreviation is common in the code.  Also, Circator was the working name for Metabolic Compass, so the two names are present frequently and refer to this same application. Lastly, to orient those looking at the code, the CircatorKit provides the core functionality needed for the Circator code.  Highlights of that functionality are that all of the HealthKit calls and all of the formatting/unit conversions are done with CircatorKit code, and that the consent flow through ResearchKit along with the account set-up and API calls are in the CircatorKit code.

*/
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate
{
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    var window: UIWindow?
    var mainViewController: UIViewController!
    private let firstRunKey = "FirstRun"

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        Fabric.with([Crashlytics.self,Answers.self])

//        log.info("Using service URL: \(MCRouter.baseURL)")

        if ((Defaults.object(forKey: firstRunKey) == nil)) {
            UserManager.sharedManager.resetFull()
            Defaults.set("firstrun", forKey: firstRunKey)
            Defaults.synchronize()
        }

        // Set up notifications after launching the app.
        UIApplication.shared.cancelAllLocalNotifications()
        AccountManager.shared.resetLocalNotifications()
        recycleNotification()
        UINotifications.configureNotifications()

        createShortcutItems()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white

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
            NSForegroundColorAttributeName: ScreenManager.appTitleTextColor(),
            NSFontAttributeName: ScreenManager.appNavBarFont()
        ]

        //set custom back button image
        let backBtnImg = UIImage(named: "back-button")

        UINavigationBar.appearance().backIndicatorImage = backBtnImg
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backBtnImg


        let tabBarStoryboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let tabBarScreen = tabBarStoryboard.instantiateViewController(withIdentifier: "TabBarController")
        mainViewController = tabBarScreen

        let navController  = UINavigationController(rootViewController: mainViewController)
        AccountManager.shared.rootViewController = navController

        FontScaleLabel.scaleFactor = ScreenManager.scaleFactor
        FontScaleTextField.scaleFactor = ScreenManager.scaleFactor

        window?.rootViewController = navController
        window?.makeKeyAndVisible()

        var launchSuccess = true
//        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
//        let shortcutItem = UIApplicationLaunchOptionsKey
//        var launchSuccess = launchShortcutActivity(shortcutItem: shortcutItem)
        

        // Add a recycling observer.
        NotificationCenter.default.addObserver(self, selector: #selector(self.recycleNotification), name: NSNotification.Name(rawValue: USNDidUpdateBlackoutNotification), object: nil)

        // Add a debugging observer.
//        NotificationCenter.default.addObserver(self, selector: #selector(self.errorNotification(_:)), name: MCRemoteErrorNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorNotification(notification:)), name: NSNotification.Name(rawValue: MCRemoteErrorNotification), object: nil)

        return launchSuccess
    }

    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        //return checkOrientation(self.window?.rootViewController)
        return UIInterfaceOrientationMask.portrait
    }

    func checkOrientation(viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if viewController == nil {
            return .all
        } else if viewController is QueryViewController {
            return .portrait
        } else if viewController is QueryBuilderViewController {
            return .portrait
        } else if viewController is UINavigationController {
            return checkOrientation(viewController: (viewController as? UINavigationController)!.visibleViewController)
        } else {
            return checkOrientation(viewController: viewController!.presentedViewController)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        recycleNotification()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        recycleNotification()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings: UIUserNotificationSettings) {
        let enabled = didRegisterUserNotificationSettings.types != .none
//        log.info("APPDEL Enabling user notifications: \(enabled)")
        Defaults.set(enabled, forKey: AMNotificationsKey)
        Defaults.synchronize()
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
//        log.info("APPDEL received \(notification)")
        NotificationManager.sharedManager.showInApp(notification: notification)
    }

    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
//        log.debug("Shortcut \"\(shortcutItem.localizedTitle)\" pressed")
        completionHandler(self.launchShortcutActivity(shortcutItem: shortcutItem))
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

    func launchShortcutActivity(shortcutItem: UIApplicationShortcutItem) -> Bool {
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

        window?.rootViewController?.present(controller, animated: true, completion: nil)
        return true
    }

    func recycleNotification() {
        NotificationManager.sharedManager.onRecycleEvent()
    }

    func errorNotification(notification: NSNotification) {
        if let info = notification.userInfo, let event = info["event"] as? String, let attrs = info["attrs"] as? [String: AnyObject]
        {
            Answers.logCustomEvent(withName: event, customAttributes: attrs)
        }
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
}
