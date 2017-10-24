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
//import SwiftyBeaver

class IntroInterfaceController: WKInterfaceController, WCSessionDelegate  {
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
    
    private func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        let displayDate = (applicationContext["dateKey"] as? String)
        
        let defaults = UserDefaults.standard
        defaults.set(displayDate, forKey: "dateKey")
    }
    
    private func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
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
    
    override func didDeactivate() {
        super.didDeactivate()
        FastingDataModel()

        func reloadComplications() {
            let server = CLKComplicationServer.sharedInstance()
            guard let complications = server.activeComplications, complications.count > 0 else {
                //                log.error("hit a zero in reloadComplications")
                return
            }
            
            for complication in complications  {
                server.reloadTimeline(for: complication)
            }
        }
        
        reloadComplications()
        let stWorkout = 0.0
        let stSleep = 0.33
        let stFast = 0.66
        let stEat = 1.0
        
        func valueOfCircadianEvent(e: CircadianEvent) -> Double {
            switch e {
            case .meal:
                return stEat
                
            case .fast:
                return stFast
                
            case .exercise:
                return stWorkout
                
            case .sleep:
                return stSleep
            }
        }
        
        func reloadDataTake2() {
         _ = 0.0
         _ = 0.33
         _ = 0.66
         let stEat = 1.0
         typealias Event = (Date, Double)
         typealias IEvent = (Double, Double)?
         
//         let yesterday = Date().
//         let startDate = yesterday
         let startDate = Date().startOfDay
         
         MCHealthManager.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
         DispatchQueue.main.async(execute: {
         guard error == nil else {
         print("Failed to fetch circadian events: \(String(describing: error))")
         return
         }
         
         if intervals.isEmpty {
         print("series is Empty")
         
         } else {
         
         let vals : [(x: Double, y: Double)] = intervals.map { event in
//         let startTimeInFractionalHours = event.0.timeIntervalSinceDate(startDate) / 3600.0
         let startTimeInFractionalHours = 15.0
         let metabolicStateAsDouble = valueOfCircadianEvent(e: event.1)
         return (x: startTimeInFractionalHours, y: metabolicStateAsDouble)
         }
         
         let initialAccumulator : (Double, Double, Double, IEvent, Bool, Double, Bool) =
         (0.0, 0.0, 0.0, nil, true, 0.0, false)
         
//         let stats = vals.filter { $0.0 >= yesterday.timeIntervalSinceDate(startDate) }
         let stats = vals.filter { $0.0 >= Date().timeIntervalSince(startDate) }
         .reduce(initialAccumulator, { (acc, event) in
         // Named accumulator components
         var newEatingTime = acc.0
         let lastEatingTime = acc.1
         var maxFastingWindow = acc.2
         var currentFastingWindow = acc.5
         
         // Named components from the current event.
         let eventEndpointDate = event.0
         let eventMetabolicState = event.1
         
         let prevEvent = acc.3
         _ = acc.4
         let prevEndpointWasIntervalEnd = !acc.4
         var prevStateWasFasting = acc.6
         let isFasting = eventMetabolicState != stEat
         if prevEndpointWasIntervalEnd {
         let prevEventEndpointDate = prevEvent!.0
         let duration = eventEndpointDate - prevEventEndpointDate
         
         if prevStateWasFasting && isFasting {
         currentFastingWindow += duration
         maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow
         
         } else if isFasting {
         currentFastingWindow = duration
         maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow
         
         } else if eventMetabolicState == stEat {
         newEatingTime += duration
         }
         } else {
         prevStateWasFasting = prevEvent == nil ? false : prevEvent!.1 != stEat
         }
         
         let newLastEatingTime = eventMetabolicState == stEat ? eventEndpointDate : lastEatingTime
         
         // Return a new accumulator.
         return (
         newEatingTime,
         newLastEatingTime,
         maxFastingWindow,
         event,
         prevEndpointWasIntervalEnd,
         currentFastingWindow,
         prevStateWasFasting
         )
         })
         
         let today = Date().startOfDay
         let lastAte : Date? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds )
         if (lastAte != nil) {
         MetricsStore.sharedInstance.lastAteAsDate = lastAte!
         }
         else {
         MetricsStore.sharedInstance.lastAteAsDate = Date()
         }
            
         let fastingHrs = Int(floor(stats.2))
         let fastingMins = (today + Int(round((stats.2 .truncatingRemainder(dividingBy: 1.0)) * 60.0)).minutes).string()
         MetricsStore.sharedInstance.fastingTime = "\(fastingHrs):\(fastingMins)"
         
         let currentFastingHrs = Int(floor(stats.5))
         let currentFastingMins = (today + Int(round((stats.5 .truncatingRemainder(dividingBy: 1.0)) * 60.0)).minutes).string()
         
         MetricsStore.sharedInstance.currentFastingTime = "\(currentFastingHrs):\(currentFastingMins)"
         
         let newLastEatingTimeHrs = Int(floor(stats.1))
         let newLastEatingTimeMins = (today + Int(round((stats.1 .truncatingRemainder(dividingBy: 1.0)) * 60.0)).minutes).string()
         
         MetricsStore.sharedInstance.lastEatingTime = "\(newLastEatingTimeHrs):\(newLastEatingTimeMins)"
         
         }
         
         })
         }
         }
         
         reloadDataTake2()
  
    }
}


