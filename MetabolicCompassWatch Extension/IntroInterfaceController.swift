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
import MCCircadianQueries


class IntroInterfaceController: WKInterfaceController, WCSessionDelegate {
    // MARK: WKExtensionDelegate
    
    
    @available(watchOSApplicationExtension 2.2, *)
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?){
    }
    
    public func sessionDidBecomeInactive(session: WCSession) {
    }
    
    public func sessionDidDeactivate(session: WCSession) {
    }
    var heightHK, weightHK:HKQuantitySample?
    var proteinHK, fatHK, carbHK:HKQuantitySample?
    var bmiHK:Double = 22.1
    let kUnknownString   = "Unknown"
    let HMErrorDomain                        = "HMErrorDomain"
    
    var HKBMIString:String = "24.3"
    var weightLocalizedString:String = "151 lb"
    var heightLocalizedString:String = "5 ft"
    var proteinLocalizedString:String = "50 gms"
    
    var model: FastingDataModel = FastingDataModel()
    
    typealias HMCircadianAggregateBlock = (_ aggregates: [(Date, Double)], _ error: Error?) -> Void
    
    var session : WCSession!
    
    override init() {
        super.init()
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let displayDate = (applicationContext["dateKey"] as? String)
        
        let defaults = UserDefaults.standard
        defaults.set(displayDate, forKey: "dateKey")
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let dateString = userInfo["dateKey"] as? String {
            
            let defaults = UserDefaults.standard
            defaults.set(dateString, forKey: "dateKey")
            
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        guard let complications = server.activeComplications, complications.count > 0 else {
            //  log.error("hit a zero in reloadComplications")
            return
        }
        
        for complication in complications  {
            server.reloadTimeline(for: complication)
            //      server.extendTimeline(for: complication)
        }
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        
         reloadData()
         reloadComplications()  
    }
    
    func reloadData() {
        let weekAgo = Date(timeIntervalSinceNow: -60 * 60 * 24 * 7)
        
        CircadianSamplesManager.sharedInstance.fetchCircadianSamples(startDate: weekAgo, endDate: Date()) {[weak self] (samples) in
            guard let `self` = self else {return}
            if !samples.isEmpty {
                var lastEatingInterval : (Date, Date)? = nil
                var maxFastingInterval : (Date, Date)? = nil
                
                var currentFastingIntreval : (Date, Date)? = nil
                
                for sample in samples {
                    if case CircadianEvent.meal(_) = sample.event {
                        if let currentFast = currentFastingIntreval {
                            currentFastingIntreval = (currentFast.0, sample.startDate)
                            if (CircadianSamplesManager.intervalDuration(from: currentFastingIntreval) > CircadianSamplesManager.intervalDuration(from: maxFastingInterval)) {
                                maxFastingInterval = currentFastingIntreval
                            }
                            currentFastingIntreval = nil
                        }
                        
                        if let currentEatingInterval = lastEatingInterval {
                            if sample.endDate > currentEatingInterval.0 {
                                lastEatingInterval = (sample.endDate, Date())
                            }
                        } else {
                            lastEatingInterval = (sample.endDate, Date())
                        }
                    } else {
                        if let currentFast = currentFastingIntreval {
                            currentFastingIntreval = (currentFast.0, sample.endDate)
                        } else {
                            currentFastingIntreval = (sample.startDate, sample.endDate)
                        }
                        if (CircadianSamplesManager.intervalDuration(from: currentFastingIntreval) > CircadianSamplesManager.intervalDuration(from: maxFastingInterval)) {
                            maxFastingInterval = currentFastingIntreval
                        }
                    }
                }
                
                MetricsStore.sharedInstance.lastAteAsDate = lastEatingInterval?.0 ?? Date()
                MetricsStore.sharedInstance.fastingTime = "- h - m"
                
                if let maxInterval = maxFastingInterval {
                    MetricsStore.sharedInstance.fastingTime = self.timeString(from: maxInterval)
                }
                
                self.reloadComplications()
            }
        }
    }
    
    private func timeString(from dateInterval: (Date, Date)) -> String {
        let timeInterval = Int(dateInterval.1.timeIntervalSince(dateInterval.0))
        let minutes = (timeInterval / 60) % 60
        let hours = (timeInterval / 3600)
        
        if hours == 0 && minutes == 0 {
            return "- h - m"
        } else {
            return String(format: "%02d h %02d m", hours, minutes)
        }
    }
}


