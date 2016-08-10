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
import MCcircadianQueries
//import SwiftyBeaver

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
    
    var model: FastingDataModel = FastingDataModel()
    
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
        FastingDataModel()
        print("updated fasting data model")

        func reloadComplications() {
            let server = CLKComplicationServer.sharedInstance()
            guard let complications = server.activeComplications where complications.count > 0 else {
                //                log.error("hit a zero in reloadComplications")
                return
            }
            
            for complication in complications  {
                server.reloadTimelineForComplication(complication)
            }
        }
        
        reloadComplications()
        let stWorkout = 0.0
        let stSleep = 0.33
        let stFast = 0.66
        let stEat = 1.0
        
        func valueOfCircadianEvent(e: CircadianEvent) -> Double {
            switch e {
            case .Meal:
                return stEat
                
            case .Fast:
                return stFast
                
            case .Exercise:
                return stWorkout
                
            case .Sleep:
                return stSleep
            }
        }
        
        func reloadDataTake2() {
         let stWorkout = 0.0
         let stSleep = 0.33
         let stFast = 0.66
         let stEat = 1.0
         typealias Event = (NSDate, Double)
         typealias IEvent = (Double, Double)?
         
         let yesterday = 1.days.ago
         let startDate = yesterday
         
         MCcircadianQueries.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
         dispatch_async(dispatch_get_main_queue(), {
         guard error == nil else {
         print("Failed to fetch circadian events: \(error)")
         return
         }
         
         if intervals.isEmpty {
         print("series is Empty")
         
         } else {
         
         let vals : [(x: Double, y: Double)] = intervals.map { event in
         let startTimeInFractionalHours = event.0.timeIntervalSinceDate(startDate) / 3600.0
         let metabolicStateAsDouble = valueOfCircadianEvent(event.1)
         return (x: startTimeInFractionalHours, y: metabolicStateAsDouble)
         }
         
         let initialAccumulator : (Double, Double, Double, IEvent, Bool, Double, Bool) =
         (0.0, 0.0, 0.0, nil, true, 0.0, false)
         
         let stats = vals.filter { $0.0 >= yesterday.timeIntervalSinceDate(startDate) }
         .reduce(initialAccumulator, combine:
         { (acc, event) in
         // Named accumulator components
         var newEatingTime = acc.0
         let lastEatingTime = acc.1
         var maxFastingWindow = acc.2
         var currentFastingWindow = acc.5
         
         // Named components from the current event.
         let eventEndpointDate = event.0
         let eventMetabolicState = event.1
         
         let prevEvent = acc.3
         let prevEndpointWasIntervalStart = acc.4
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
         
         let today = NSDate().startOf(.Day, inRegion: Region())
         let lastAte : NSDate? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds )
         print("stored lastAteAsNSDate \(lastAte)")
         if (lastAte != nil) {
         MetricsStore.sharedInstance.lastAteAsNSDate = lastAte!
         }
         else {
         MetricsStore.sharedInstance.lastAteAsNSDate = NSDate()
         }
         
         let fastingHrs = Int(floor(stats.2))
         let fastingMins = (today + Int(round((stats.2 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
         //self.fastingLabel.text = "\(fastingHrs):\(fastingMins)"
         print("in IntroInterfaceController, fasting hours: \(fastingHrs)")
         print("   and fasting minutes: \(fastingMins)")
         MetricsStore.sharedInstance.fastingTime = "\(fastingHrs):\(fastingMins)"
         
         let currentFastingHrs = Int(floor(stats.5))
         let currentFastingMins = (today + Int(round((stats.5 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
         
         print("current fasting hours: \(currentFastingHrs)")
         print("   and current fasting minutes: \(currentFastingMins)")
         MetricsStore.sharedInstance.currentFastingTime = "\(currentFastingHrs):\(currentFastingMins)"
         
         let newLastEatingTimeHrs = Int(floor(stats.1))
         let newLastEatingTimeMins = (today + Int(round((stats.1 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
         
         print("last eating time: \(newLastEatingTimeHrs)")
         print("   and last eating time minutes: \(newLastEatingTimeMins)")
         MetricsStore.sharedInstance.lastEatingTime = "\(newLastEatingTimeHrs):\(newLastEatingTimeMins)"
         
         
         //self.eatingLabel.text  = (today + Int(stats.0 * 3600.0).seconds).toString(DateFormat.Custom("HH:mm"))!
         //self.lastAteLabel.text = lastAte == nil ? "N/A" : lastAte!.toString(DateFormat.Custom("HH:mm"))!
         }
         //self.mealChart.setNeedsDisplay()
         
         })
         }
         }
         
         reloadDataTake2()
        
        /*       func updateHealthInfo() {
         MCcircadianQueries.sharedManager.updateWeight();
         MCcircadianQueries.sharedManager.updateHeight();
         MCcircadianQueries.sharedManager.updateBMI();
         }
         
         updateHealthInfo()
         MetricsStore.sharedInstance.weight = weightLocalizedString
         MetricsStore.sharedInstance.BMI = HKBMIString
         MetricsStore.sharedInstance.Fat = "90"
         MetricsStore.sharedInstance.Carbohydrate = "190"
         MetricsStore.sharedInstance.Protein = "290" */
    }
}


