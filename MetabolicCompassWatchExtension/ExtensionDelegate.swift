//
//  ExtensionDelegate.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import WatchConnectivity
import HealthKit

let NotificationPurchasedMovieOnWatch = "PurchasedMovieOnWatch"

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    lazy var documentsDirectory: String = {
        return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
    }()
    
    lazy var notificationCenter: NSNotificationCenter = {
        return NSNotificationCenter.defaultCenter()
    }()
    
    func applicationDidFinishLaunching() {
        setupWatchConnectivity()
        //        setupNotificationCenter()
    }
    
    /*    private func setupNotificationCenter() {
     notificationCenter.addObserverForName(NotificationPurchasedMovieOnWatch, object: nil, queue: nil) { (notification:NSNotification) -> Void in
     self.sendCurrentLabelsToPhone(notification)
     }
     }
     */
    
    /*
     private func sendCurrentLabelsToPhone(notification:NSNotification) {
     if WCSession.isSupported() {
     if let labels = HealthManager.sharedManager.mostRecentSamples[sampleType] {
     do {
     let dictionary = ["label": currentLabels]
     try WCSession.defaultSession().updateApplicationContext(dictionary)
     } catch {
     print("ERROR: \(error)")
     }
     }
     }
     }
     */
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session  = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    func session(session: WCSession,
                 didReceiveUserInfo userInfo: [String : AnyObject]) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let fastingHrs  = userInfo["fastingHrs"]  as? String,
                let fastingMins = userInfo["fastingMins"] as? String {
                print("information transferred: \(fastingHrs)")
            }
        }
    }
    
    /*
     func session(session: WCSession,
     didReceiveApplicationContext
     applicationContext:[String:AnyObject]) {
     if let testDict = applicationContext["testDict"] as? [String] {
     dispatch_async(dispatch_get_main_queue()) { () -> Void in
     WKInterfaceController.reloadRootControllersWithNames(
     ["testDict"], contexts: nil)
     } }
     }
     */
    /*
     func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
     print("Phone->Watch Receiving Context: \(applicationContext)")
     if let currentLabels = applicationContext["labels"] as? [String] {
     HealthManager.
     dispatch_async(dispatch_get_main_queue()) { () -> Void in
     WKInterfaceController.reloadRootControllersWithNames(["labels"], contexts: nil)
     }
     }
     }
     */
}

