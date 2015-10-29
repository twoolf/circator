//
//  ConnectivityManager.swift
//  Circator
//
//  Created by Sihao Lu on 10/29/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import HealthKit
import WatchConnectivity

class ConnectivityManager: NSObject, WCSessionDelegate {
    static let sharedManager = ConnectivityManager()
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        WKInterfaceController.reloadRootControllersWithNames(["BioPreview"], contexts: [applicationContext])
    }
}