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
    @available(watchOSApplicationExtension 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    public func sessionDidBecomeInactive(session: WCSession) {
    }
    
    public func sessionDidDeactivate(session: WCSession) {
    }
    lazy var documentsDirectory: String = {
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
    }()
    
    lazy var notificationCenter: NotificationCenter = {
        return NotificationCenter.default
    }()
    
    func applicationDidFinishLaunching() {
        setupWatchConnectivity()
    }
    
 
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session  = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    private func session(session: WCSession,
                 didReceiveUserInfo userInfo: [String : AnyObject]) {
        DispatchQueue.main.async() { () -> Void in
            if let fastingHrs  = userInfo["fastingHrs"]  as? String,
                let _ = userInfo["fastingMins"] as? String {
                print("information transferred: \(fastingHrs)")
            }
        }
    }
    
 

}

