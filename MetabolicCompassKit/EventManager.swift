//
//  EventManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/11/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import EventKit
import HealthKit
import WatchConnectivity
import SwiftyUserDefaults
import MCCircadianQueries

public let EKMStartSessionNotification = "EKMStartSessionNotification"

private let EMAccessKey  = DefaultsKey<Date?>("EKAccessKey")
private let EMCounterKey = DefaultsKey<Int>("EKCounterKey")

struct DiningEventKey : Equatable, Hashable {
    var start : Date
    var end : Date
    var hashValue : Int {
        get { return start.hashValue ^ end.hashValue }
    }
}

func ==(lhs: DiningEventKey, rhs: DiningEventKey) -> Bool
{
    return lhs.start == rhs.start && lhs.end == rhs.end
}

/**
 lets us pull scheduled/repeated events into the dashboard
 
 - note: can be scheduled by Siri with use of hotwords
 - remark: used with IntroViewController and RepeatedEventsController
 */
public class EventManager : NSObject, WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }


    @available(iOS 9.3, *)
    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: Error?){
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    public static let sharedManager = EventManager()

    lazy var eventKitStore: EKEventStore = EKEventStore()

    var calendar   : EKCalendar?
    var lastAccess : Date
    var pending    : Bool
    var hasAccess  : Bool?
    var eventCounter : Int

    private override init() {
        self.calendar = nil
        self.lastAccess = Date.distantPast
        self.pending = false
        self.hasAccess = nil
        self.eventCounter = 0

        super.init()
        self.lastAccess = getLastAccess()
        self.eventCounter = getEventCounter()
        connectWatch()
    }

    public func checkCalendarAuthorizationStatus(completion: @escaping ((Void) -> Void)) {
        if self.pending { return }
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)

        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            self.pending = true
            requestAccessToCalendar(completion: completion)

        case EKAuthorizationStatus.authorized:
            self.hasAccess = true
            initializeCalendarSession(completion: completion)

        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            self.hasAccess = false
            completion()
        }
    }

    func requestAccessToCalendar(completion: @escaping ((Void) -> Void)) {
        eventKitStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted, error) in

            guard error == nil else {
                log.error("Calendar access error: \(error)")
                return
            }

            if accessGranted == true {
                self.hasAccess = true
                DispatchQueue.main.async(execute: {
                    self.initializeCalendarSession(completion: completion)
                })
            }
        })
    }

    func initializeCalendarSession(completion: ((Void) -> Void)) {
        self.calendar = eventKitStore.defaultCalendarForNewEvents

        // Perform an initial refresh.
        fetchEventsfromCalendar(onRefresh: false)

        // Set up the observer for event changes.
        registerCalendarObserver()

        // Initialization completed, reset.
        self.pending = false

        completion()
    }

    func registerCalendarObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: "refreshCalendarEvents:",
            name: NSNotification.Name.EKEventStoreChanged,
            object: nil)
    }

    @objc func refreshCalendarEvents(notification: NSNotification) {
        fetchEventsfromCalendar(onRefresh: true)
    }

    public func fetchEventsfromCalendar(onRefresh : Bool) {
        if let doAccess = hasAccess, doAccess {

            var doCommit = false
            let events = eventKitStore.events(
                matching: eventKitStore.predicateForEvents(
                    withStart: lastAccess as Date, end: Date.distantFuture, calendars: [self.calendar!]))

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            dateFormatter.amSymbol = "AM"
            dateFormatter.pmSymbol = "PM"

            var eventIndex : [DiningEventKey:[(Int, String)]] = [:]
            for ev in events {
                let hotword = UserManager.sharedManager.getHotWords()
//                if let rng = ev.title.lowercaseString.rangeOfString(hotword)
                    if let rng = ev.title.range(of: hotword)
                {
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
                            try eventKitStore.save(ev, span: EKSpan.thisEvent, commit: false)
                            doCommit = true
                        } catch {
                            log.error("Error saving event id: \(error)")
                        }
                    }

                    var edata = ev.title
                    edata.removeSubrange(rng)
                    if var items = eventIndex[key] {
                        items.append((eventId, edata))
                        eventIndex.updateValue(items, forKey: key)
                    } else {
                        eventIndex.updateValue([(eventId, edata)], forKey: key)
                    }
                }
            }

            MCHealthManager.sharedManager.fetchPreparationAndRecoveryWorkout(false) { (results, error) in
                for workout in (results.map { $0 as! HKWorkout }) {
                    let dkey = DiningEventKey(start: workout.startDate, end: workout.endDate)
                    if let d = workout.metadata {
                        if let matches = eventIndex[dkey] {
                            let newItems = matches.filter { (eid) -> Bool in eid.0 != Int(d["EventId"] as! String)! }
                            eventIndex.updateValue(newItems, forKey: dkey)
                        }
                    }
                }

                for eitems in eventIndex {
                    for eid in eitems.1 {
                        let sstr = dateFormatter.string(from: eitems.0.start)
                        let estr = dateFormatter.string(from: eitems.0.end)
                        log.debug("Writing food log " + sstr + "->" + estr + " " + eid.1)

                        let emeta = ["Source":"Calendar","EventId":String(eid.0), "Data":eid.1]
                        MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                            eitems.0.start as Date, endDate: eitems.0.end,
                            distance: 0.0, distanceUnit: HKUnit.meter(), kiloCalories: 0.0,
                            metadata: emeta as NSDictionary,
                            completion: { (success, error ) -> Void in
                                guard error == nil else {
                                    log.error(error!.localizedDescription)
                                    return
                                }
                                log.debug("Food log event saved")
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
                        log.error("Error committing event ids: \(error)")
                    }
                }
            }

            self.lastAccess = Date()
            setLastAccess()
        }
    }

    private func getLastAccess() -> Date {
        if let access = Defaults[EMAccessKey] {
            return access
        } else {
            return Date.distantPast
        }
    }

    private func setLastAccess() {
        Defaults[EMAccessKey] = lastAccess
        Defaults.synchronize()
    }

    private func newCounter() -> Int {
        self.eventCounter += 1
        return self.eventCounter
    }

    private func getEventCounter() -> Int {
        return Defaults[EMCounterKey]
    }

    private func setEventCounter() {
        Defaults[EMCounterKey] = eventCounter
        Defaults.synchronize()
    }

    // MARK: - Apple Watch

    func connectWatch() {
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
}


