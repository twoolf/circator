//
//  AppDelegate.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import CircatorKit
import SwiftyBeaver
import Fabric
import Crashlytics

let log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainViewController: IntroViewController!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        configureLogging()
        Fabric.with([Crashlytics.self,Answers.self])

        // Override point for customization after application launch.
        let themeColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.backgroundColor = UIColor.whiteColor()
        window?.tintColor = themeColor
        mainViewController = IntroViewController(nibName: nil, bundle: nil)
        let navController = UINavigationController(rootViewController: mainViewController)

        window?.rootViewController = navController
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        mainViewController.fetchRecentSamples()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func configureLogging() {
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()
        console.detailOutput = true
        console.colored = false
        console.minLevel = .Info

        let paths : [String : SwiftyBeaver.Level] = ["ServiceAPI":.Verbose, "HealthManager":.Verbose]
        let pathfuns : [String : (String, SwiftyBeaver.Level)] = [:]

        for (p,l) in paths { console.addMinLevelFilter(l, path: p) }
        for (p,(f,l)) in pathfuns { console.addMinLevelFilter(l, path: p, function: f) }

        log.addDestination(console)
    }
}

