//
//  AppDelegate.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import CircatorKit
import Granola
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func fetchRecentSamples() {
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                return
            }
            HealthManager.sharedManager.fetchMostRecentSamples() { (samples, error) -> Void in
                guard error == nil else {
                    return
                }
                NSNotificationCenter.defaultCenter().postNotificationName(HealthManagerDidUpdateRecentSamplesNotification, object: self)
            }
            let serializer = OMHSerializer()
            HealthManager.sharedManager.startBackgroundGlucoseObserver() { (added, _, _, error) -> Void in
                guard error == nil else {
                    debugPrint(error)
                    return
                }
                do {
                    let jsons = try added.map { (sample) -> [String : AnyObject] in
                        let json = try serializer.jsonForSample(sample)
                        let data = json.dataUsingEncoding(NSUTF8StringEncoding)!
                        let serializedObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String : AnyObject]
                        return serializedObject
                    }
                    print("check on format: \(jsons)")
                    jsons.forEach { json -> () in
                        Alamofire.request(.POST, "http://45.55.194.186:3000/measures", parameters: json, encoding: .JSON).responseString {_, response, result in
                            print(result)
                        }
                    }
                } catch {
                    debugPrint(error)
                }
            }
            HealthManager.sharedManager.startBackgroundWeightObserver() { (added, _, _, error) -> Void in
                guard error == nil else {
                    debugPrint(error)
                    return
                }
                do {
                    let jsons = try added.map { (sample) -> [String : AnyObject] in
                        let json = try serializer.jsonForSample(sample)
                        let data = json.dataUsingEncoding(NSUTF8StringEncoding)!
                        let serializedObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String : AnyObject]
                        return serializedObject
                    }
                    print("check on format: \(jsons)")
                    jsons.forEach { json -> () in
                        Alamofire.request(.POST, "http://45.55.194.186:3000/measures", parameters: json, encoding: .JSON).responseString {_, response, result in
                            print(result)
                        }
                    }
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let themeColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.backgroundColor = UIColor.whiteColor()
        window?.tintColor = themeColor
        let viewController = IntroViewController(nibName: nil, bundle: nil)
        let navController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        fetchRecentSamples()
        
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
        fetchRecentSamples()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

