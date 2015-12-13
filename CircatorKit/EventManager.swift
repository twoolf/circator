//
//  EventManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/11/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import EventKit
import WatchConnectivity
import HealthKit

public let EKMStartSessionNotification = "EKMStartSessionNotification"

private let EventManagerAccessKey = "EKAccessKey"
private let EventManagerCounterKey = "EKCounterKey"

struct DiningEventKey : Equatable, Hashable {
    var start : NSDate
    var end : NSDate
    var hashValue : Int {
        get { return start.hashValue ^ end.hashValue }
    }
}

func ==(lhs: DiningEventKey, rhs: DiningEventKey) -> Bool
{
    return lhs.start == rhs.start && lhs.end == rhs.end
}

public class EventManager : NSObject, WCSessionDelegate {
    
    public static let sharedManager = EventManager()

    lazy var eventKitStore: EKEventStore = EKEventStore()
    
    var calendar   : EKCalendar?
    var lastAccess : NSDate
    var hasAccess  : Bool?
    var eventCounter : Int
    
    private override init() {
        self.calendar = nil
        self.lastAccess = NSDate.distantPast()
        self.hasAccess = nil
        self.eventCounter = 0

        super.init()
        self.lastAccess = getLastAccess()
        self.eventCounter = getEventCounter()
        connectWatch()
    }
    
    public func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        
        switch (status) {
        case EKAuthorizationStatus.NotDetermined:
            requestAccessToCalendar()

        case EKAuthorizationStatus.Authorized:
            self.hasAccess = true
            initializeCalendarSession()
        
        case EKAuthorizationStatus.Restricted, EKAuthorizationStatus.Denied:
            self.hasAccess = false
        }
    }
    
    func requestAccessToCalendar() {
        eventKitStore.requestAccessToEntityType(EKEntityType.Event, completion: {
            (accessGranted: Bool, error: NSError?) in
            
            if accessGranted == true {
                self.hasAccess = true
                dispatch_async(dispatch_get_main_queue(), {
                    self.initializeCalendarSession()
                })
            }
        })
    }
    
    func initializeCalendarSession() {
        self.calendar = eventKitStore.defaultCalendarForNewEvents

        // Perform an initial refresh.
        fetchEventsfromCalendar(false)
        
        // Set up the observer for event changes.
        registerCalendarObserver()
    }
    
    func registerCalendarObserver() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "refreshCalendarEvents:",
            name: EKEventStoreChangedNotification,
            object: nil)
    }
    
    @objc func refreshCalendarEvents(notification: NSNotification) {
        fetchEventsfromCalendar(true)
    }
    
    public func fetchEventsfromCalendar(onRefresh : Bool) {
        if let doAccess = hasAccess where doAccess {

            var doCommit = false
            let events = eventKitStore.eventsMatchingPredicate(
                            eventKitStore.predicateForEventsWithStartDate(
                                lastAccess, endDate: NSDate.distantFuture(), calendars: [self.calendar!]))
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"

            var eventIndex : [DiningEventKey:[(Int, String)]] = [:]
            for ev in events {
                if let rng = ev.title.lowercaseString.rangeOfString("food log") {
                    let key = DiningEventKey(start: ev.startDate, end: ev.endDate)

                    var eventId = 0
                    if let enote = ev.notes {
                        if let enid = Int(enote) {
                            eventId = enid
                        }
                    }
                    if ( eventId == 0 ) {
                        eventId = newCounter()
                        ev.notes = String(eventId)
                        do {
                            try eventKitStore.saveEvent(ev, span: EKSpan.ThisEvent, commit: false)
                            doCommit = true
                        } catch {
                            print("Error saving event id: \(error)")
                        }
                    }

                    var edata = ev.title
                    edata.removeRange(rng)
                    if var items = eventIndex[key] {
                        items.append((eventId, edata))
                        eventIndex.updateValue(items, forKey: key)
                    } else {
                        eventIndex.updateValue([(eventId, edata)], forKey: key)
                    }
                }
            }

            HealthManager.sharedManager.fetchPreparationAndRecoveryWorkout { (results, error) in
                for workout in (results as! [HKWorkout]) {
                    let dkey = DiningEventKey(start: workout.startDate, end: workout.endDate)
                    if let d = workout.metadata {
                        if let matches = eventIndex[dkey] {
                            let newItems = matches.filter { (eid) -> Bool in eid.0 != Int(d["EventId"] as! String)! }
                            eventIndex.updateValue(newItems, forKey: dkey)
                        } else {
                            print("No match found for " + (d["EventId"] as! String))
                        }
                    }
                }

                for eitems in eventIndex {
                    for eid in eitems.1 {
                        let sstr = dateFormatter.stringFromDate(eitems.0.start)
                        let estr = dateFormatter.stringFromDate(eitems.0.end)
                        print("Writing food log " + sstr + "->" + estr + " " + eid.1)
                        
                        let emeta = ["EventId":String(eid.0), "Data":eid.1]
                        HealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                            eitems.0.start, endDate: eitems.0.end,
                            distance: 0.0, distanceUnit: HKUnit.meterUnit(), kiloCalories: 0.0,
                            metadata: emeta,
                            completion: { (success, error ) -> Void in
                                if( success ) {
                                    print("Food log event saved")
                                } else if( error != nil ) {
                                    print("error made: \(error)")
                                }
                            }
                        )
                    }
                }
                
                // Commit new event ids.
                if ( doCommit ) {
                    do {
                        try self.eventKitStore.commit()
                        self.setEventCounter()
                    } catch {
                        print("Error committing event ids: \(error)")
                    }
                }
            }

            self.lastAccess = NSDate()
            setLastAccess()
        }
    }
    
    private func getLastAccess() -> NSDate {
        if let access = NSUserDefaults.standardUserDefaults().objectForKey(EventManagerAccessKey) as? NSDate {
            return access
        } else {
            return NSDate.distantPast()
        }
    }

    private func setLastAccess() {
        NSUserDefaults.standardUserDefaults().setValue(lastAccess, forKey: EventManagerAccessKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func newCounter() -> Int {
        self.eventCounter += 1
        return self.eventCounter
    }

    private func getEventCounter() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey(EventManagerCounterKey)
    }
    
    private func setEventCounter() {
        NSUserDefaults.standardUserDefaults().setInteger(eventCounter, forKey: EventManagerCounterKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Apple Watch
    
    func connectWatch() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    

}


