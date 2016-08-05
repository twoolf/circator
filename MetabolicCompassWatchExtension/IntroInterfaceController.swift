//
//  IntroInterfaceController.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation
import HealthKit
import SwiftDate
import ClockKit
import QueryHK
import CocoaLumberjack

//let log = SwiftyBeaver.self

class IntroInterfaceController: WKInterfaceController, WCSessionDelegate  {
    
    var heightHK, weightHK:HKQuantitySample?
    var proteinHK, fatHK, carbHK:HKQuantitySample?
    var bmiHK:Double = 22.1
    let kUnknownString   = "Unknown"
    let HMErrorDomain                        = "HMErrorDomain"
    
    var HKBMIString:String = "24.3"
    var weightLocalizedString:String = "151 lb"
    var heightLocalizedString:String = "5 ft"
    var proteinLocalizedString:String = "50 gms"

    typealias HMCircadianAggregateBlock = (aggregates: [(NSDate, Double)], error: NSError?) -> Void

    var session : WCSession!
    
    override init() {
        super.init()
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        let displayDate = (applicationContext["dateKey"] as? String)

        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(displayDate, forKey: "dateKey")
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        if let dateString = userInfo["dateKey"] as? String {

            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(dateString, forKey: "dateKey")
            
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        QueryHK.sharedManager.reloadDataTake2()
        
        func reloadComplications() {
            let server = CLKComplicationServer.sharedInstance()
            guard let complications = server.activeComplications where complications.count > 0 else {
                Log.error("hit a zero in reloadComplications")
                return
            }
            
            for complication in complications  {
                server.reloadTimelineForComplication(complication)
            }
        }
        
        reloadComplications()

 /*       func updateHealthInfo() {
            QueryHK.sharedManager.updateWeight();
            QueryHK.sharedManager.updateHeight();
            QueryHK.sharedManager.updateBMI();
        }
 
        updateHealthInfo() */

        MetricsStore.sharedInstance.weight = weightLocalizedString
        MetricsStore.sharedInstance.BMI = HKBMIString
        MetricsStore.sharedInstance.Fat = "90"
        MetricsStore.sharedInstance.Carbohydrate = "190"
        MetricsStore.sharedInstance.Protein = "290"
    }
}
