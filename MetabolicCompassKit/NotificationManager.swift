//
//  NotificationManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 11/20/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import GameKit
import HealthKit
import MCCircadianQueries
import SwiftDate
import SwiftyUserDefaults
import SwiftMessages
import GameplayKit

// Constants
public let delayBetweenInAppNotificationsSecs = 2
public let immediateNotificationDelaySecs = 5

public let USNReminderFrequencyKey = "USNReminderFrequency"
public let USNBlackoutTimesKey = "USNBlackoutTimes"

public let NMStreakStartKey = "NMStreakStartKey"
public let NMStreakEndKey = "NMStreakEndKey"
public let NMStreakStateKey = "NMStreakStateKey"
public let NMStreakMaxKey = "NMStreakMaxKey"

public let NMFastingMFWKey = "NMFastingMFWKey"
public let NMFastingDNKey = "NFastingDNKey"

// Datatypes
public enum StreakType: String {
    case Fasting      = "Fasting"
    case Contribution = "Contribution"
}

public enum NotifyType: Int {
    case MatchedLevel
    case MatchedMax
    case ExceededMax
}

public class FastingState: NSObject {

    var dailyMFW: [Date: Double] = [:]
    var daysNotified: [Date: Bool] = [:]

    convenience init(mfw: [Date: Double], notified: [Date: Bool]) {
        self.init()
        self.dailyMFW = mfw
        self.daysNotified = notified
    }
}


// Default blackout times: 10pm - 6am
public func defaultNotificationBlackoutTimes() -> [Date] {
    let today = Date().startOf(component: .day)
    return [today + 22.hours - 1.days, today + 6.hours]
}

// Default reminder frequency in minutes.
public func defaultNotificationReminderFrequency() -> Int {
    return 1440
}

public func getNotificationReminderFrequency() -> Int {
    var reminder: Int! = nil
    if let r = Defaults.object(forKey: USNReminderFrequencyKey) as? Int {
        reminder = r
    } else {
        reminder = defaultNotificationReminderFrequency()
        Defaults.set(reminder, forKey: USNReminderFrequencyKey)
        Defaults.synchronize()
    }
    return reminder!
}

public func getNotificationBlackoutTimes() -> [Date] {
    var blackoutTimes: [Date] = []
    if let t = Defaults.object(forKey: USNBlackoutTimesKey) as? [Date] {
        blackoutTimes = t
    } else {
        blackoutTimes = defaultNotificationBlackoutTimes()
        Defaults.set(blackoutTimes, forKey: USNBlackoutTimesKey)
        Defaults.synchronize()
    }
    return blackoutTimes
}


public class NotificationManager {

    public static let sharedManager = NotificationManager()

    // Fasting threshold (in seconds) for fasting streak definition.
    var fastingThreshold = Double(10 * 60 * 60)

    var streakStarts : [StreakType: Date] = [:]
    var streakEnds   : [StreakType: Date] = [:]

    var streakState  : [StreakType: AnyObject] = [:]
    var streakMax    : [StreakType: Double] = [:]

    // Fasting streak statistics.
    // Threshold on event value (>10 hrs) and time (2,3,7 days)
    //
    // Semantics:
    //   When do we check the fasting duration?
    //     Midnight? This will truncate the max fasting window.
    //
    //     Our app is the only one adding eating events -- thus it alone defines fasting durations.
    //       Every time we add an eating event, we can calculate the 24h-MFW
    //
    //     How about 24h periods starting at midday?
    //        The idea is to start in the middle of a short fasting period, so that you capture the long ones in a 24h cycle
    //        Most people will eat before & after midday, or start shortly after, minimizing the time lost in the long fasting period
    //        Except shift workers
    //     
    //     Run an adaptive algorithm that searches statistically for the best time to start the day for each individual
    //
    //     We should align this with whatever the CWF metric is using from the HealthManager
    //       For now, let's go with midday!
    //
    // Incr:
    //   let early_notify(event, streak start, streak end, finalize day) =
    //     let fasting interval = event - max(streak end, start of event day)
    //     event day MFW = max(event day MFW, fasting interval)
    //
    //     if event day MFW > fasting streak threshold
    //       if event day is same as streak end day or is the day after streak end day
    //         if finalize day then garbage collect notified flag for all days <= event day
    //         otherwise set event day notified flag
    //
    //         let streak length = end of event day - streak start
    //         schedule next notification based on streak length level (i.e., 2,3,5,7 days, etc)
    //         incr max streak value with streak length
    //
    //       otherwise
    //         // this terminates a streak when we encounter a non-contiguous, valid fasting interval
    //         advance streak start to start of event day
    //
    //       // this advances the streak end, only when we have a valid fasting interval
    //       advance streak end to max(streak end, event end)
    //
    //
    //  // top-level
    //  if we have a new eating event after the streak end
    //     if not event day notified
    //       early_notify(eating event, streak start, streak end, false)
    //
    //  if we have any new event after the streak end
    //     // this handles streak progression by closing out the streak end day,
    //     // only if we have not notified for either the event or streak end day
    //     if event day is the day after the streak end day
    //       if not event day notified and not streak end day notified
    //         early_notify(end of streak end day, streak start, streak end, true)
    //
    // Max: longest historical fasting streak
    //   We also want a nice graphic here
    //
    // State:
    //   daily MFW : [NSDate: Double]
    //   day notified: [NSDate: Bool]


    // Contribution streak statistics.
    // Threshold on event count (>1 entry) and time (2,3,5,7... days)
    //
    // Semantics:
    //   We do not handle events backfilled out-of-order.
    //   This would require us to find the oldest streak start for every out-of-order event.
    //   Thus we notify only on purely non-decreasing tracking
    //
    // Incr:
    //   if event is after the streak end
    //     if event end is in the day after the streak end
    //       schedule next notification based on (event end - streak start) level (i.e., 2,3,5,7 days, etc)
    //       incr max streak value based on (event end - streak start)
    //     else if event end day is 2 or more days after the streak end
    //       advance streak start to max(streak end, event end)
    //     advance streak end to max(streak end, event end)
    //
    // Max: longest historical contribution streak
    //   Can we come up with a nice graphic for this? e.g., fireworks?
    //
    // State: none


    // Planned events.


    // Data collection message cycling
    var notificationGroups: [String: [UILocalNotification]] = [:]

    var initStartOffset = 0
    var initEndOffset = 0
    var initEndDeltaSecs = 0
    var maxDelta = 0.0

    init() {
        inAppMsgMapping = Dictionary(pairs: zip(collectionMsgs, inAppCollectionMsgs).map { $0 })

        SwiftMessages.pauseBetweenMessages = Double(delayBetweenInAppNotificationsSecs)

        if let ss = Defaults.object(forKey: NMStreakStartKey) as? [StreakType: Date] {
            streakStarts = ss
        } else {
            streakStarts[.Fasting] = Date() - initStartOffset.days
            streakStarts[.Contribution] = Date() - initStartOffset.days
            Defaults.set(streakStarts as? AnyObject, forKey: NMStreakStartKey)
            Defaults.synchronize()
        }

        if let se = Defaults.object(forKey: NMStreakEndKey) as? [StreakType: Date] {
            streakEnds = se
        } else {
            streakEnds[.Fasting] = (Date() - initEndOffset.days) + initEndDeltaSecs.seconds
            streakEnds[.Contribution] = (Date() - initEndOffset.days) + initEndDeltaSecs.seconds
            Defaults.set(streakEnds as? AnyObject, forKey: NMStreakEndKey)
            Defaults.synchronize()
        }

        if let ss = Defaults.object(forKey: NMStreakStateKey) as? [StreakType: AnyObject] {
            streakState = ss
        } else {
            streakState[.Fasting] = FastingState()
            Defaults.set(streakState as? AnyObject, forKey: NMStreakStateKey)
            Defaults.synchronize()
        }

        if let sm = Defaults.object(forKey: NMStreakMaxKey) as? [StreakType: Double] {
            streakMax = sm
        } else {
            streakMax[.Fasting] = 0.0 + maxDelta
            streakMax[.Contribution] = 0.0 + maxDelta
            Defaults.set(streakMax as? AnyObject, forKey: NMStreakMaxKey)
            Defaults.synchronize()
        }

/*        log.debug([
            "sstart \(streakStarts)",
            "send \(streakEnds)",
            "sstate mfw \(streakState[.Fasting]!.dailyMFW)",
            "sstate dn \(streakState[.Fasting]!.daysNotified)",
            "smax \(streakMax)"
            ].componentsJoinedByString("\n"), feature: "initManager") */

    }

    public func reset() {
        streakStarts[.Fasting] = Date()
        streakStarts[.Contribution] = Date()

        streakEnds[.Fasting] = Date()
        streakEnds[.Contribution] = Date()

        streakState[.Fasting] = FastingState()

        streakMax[.Fasting] = 0.0
        streakMax[.Contribution] = 0.0

        sync()
    }

    public func sync() {
        Defaults.set(streakStarts as? AnyObject, forKey: NMStreakStartKey)
        Defaults.set(streakEnds as? AnyObject, forKey: NMStreakEndKey)
        Defaults.set(streakState as? AnyObject, forKey: NMStreakStateKey)
        Defaults.set(streakMax as? AnyObject, forKey: NMStreakMaxKey)
        Defaults.synchronize()
    }


    public func showInApp(notification: UILocalNotification) {
        var msg = notification.alertBody ?? ""
        if let inAppMsg = inAppMsgMapping[msg] {
            msg = inAppMsg
        }

        let view = MessageView.viewFromNib(layout: .CardView)
        view.configureTheme(.info)
        view.configureContent(title: notification.alertTitle ?? "Metabolic Compass", body: msg)
        view.button?.isHidden = true

        var viewConfig = SwiftMessages.Config()
        viewConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        viewConfig.duration = .seconds(seconds: 5)

        //log.info("NTMGR SHOW \(notification)")
        SwiftMessages.show(config: viewConfig, view: view)
    }

    // Main entry trigger for circadian-event driven notification scheduling.

    public func onCircadianEvents(events: [HKSample]) {
        if let newest = events.sorted(by: { $0.0.startDate > $0.1.startDate }).first {
            var cEvent: CircadianEvent! = nil
            if let mt = newest.metadata?["Meal Type"] as? String {
                cEvent = .meal(mealType: MealType(rawValue: mt)!)
            }
            else if newest.sampleType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
                cEvent = .sleep
            }
            else if newest.sampleType.identifier == HKWorkoutTypeIdentifier {
                if let wk = newest as? HKWorkout {
                    cEvent = .exercise(exerciseType: wk.workoutActivityType)
                }
            }

            if cEvent != nil {
                onCircadianEvent(startDate: newest.startDate, endDate: newest.endDate, event: cEvent)
            }
        }
    }

    public func onCircadianEvent(startDate: Date, endDate: Date, event: CircadianEvent) {

        // Maintain fasting streak.
        switch event {
        case .meal(_):
//            log.debug("B1(a) \(startDate) \(streakEnds[.Fasting])", feature: "FStreak")

            if let fstStart = streakStarts[.Fasting],
                    let fstEnd = streakEnds[.Fasting],
                    let fstState = streakState[.Fasting] as? FastingState, startDate >= fstEnd
            {
                let eventDayNotified = fstState.daysNotified[startDate.startOf(component: .day)] ?? false

                log.debug("B1(b) evdn \(eventDayNotified)", "FStreak")

                if !eventDayNotified {
                    incrFastingStreak(startDate: startDate, endDate: endDate, streakStart: fstStart, streakEnd: fstEnd, fastingState: fstState, finalize: false)
                }
            }

        default:
            break
        }

        log.debug("B2(a) \(startDate) \(streakEnds[.Fasting])", "FCStreak")

        if let fstStart = streakStarts[.Fasting],
            let fstEnd = streakEnds[.Fasting],
            let fstState = streakState[.Fasting] as? FastingState, startDate >= fstEnd && self.isDayAfter(a: fstEnd, b: startDate)
        {
            let eventDayNotified = fstState.daysNotified[startDate.startOf(component: .day)] ?? false
            let streakEndDayNotified = fstState.daysNotified[fstEnd.startOf(component: .day)] ?? false

            log.debug("B2(b) evsedn \(eventDayNotified) \(streakEndDayNotified)", "FStreak")

            if !eventDayNotified && !streakEndDayNotified {
                incrFastingStreak(startDate: startDate, endDate: endDate, streakStart: fstStart, streakEnd: fstEnd, fastingState: fstState, finalize: true)
            }
        }


        // Maintain contribution streak.
        incrContributionStreak(startDate: startDate, endDate: endDate)

        sync()
    }


    func incrFastingStreak(startDate: Date, endDate: Date, streakStart: Date, streakEnd: Date,
                           fastingState: FastingState, finalize: Bool)
    {
        let eventDay = startDate.startOf(component: .day)

        let fastingLength = startDate.timeIntervalSince(max(streakEnd as Date, self.fastingDayStart(date: startDate) as Date))
        let rmaxFasting = max(fastingState.dailyMFW[eventDay] ?? 0.0, fastingLength)
        fastingState.dailyMFW[eventDay] = rmaxFasting

        log.debug("FIncr \(finalize) \(eventDay) \(fastingLength) \(rmaxFasting) \(fastingThreshold)", "FStreak")
//        log.debug("FIncr \(finalize) \(eventDay.isInSameDayAsDate(streakEnd)) \(self.isDayAfter(streakEnd, b: startDate))", "FStreak")
        log.debug("FIncr \(finalize) \(eventDay.isInSameDayOf(date: startDate)) \(self.isDayAfter(a: streakEnd, b: startDate))", "FStreak")

        if rmaxFasting > fastingThreshold {
            if eventDay.isInSameDayOf(date: streakEnd) || self.isDayAfter(a: streakEnd, b: startDate) {

                if finalize {
                    fastingState.daysNotified = Dictionary(pairs: fastingState.daysNotified.filter { $0.0 <= eventDay })
                }
                else {
                    fastingState.daysNotified[eventDay] = true
                }

//                let streakLength = floor(eventDay.endOf(component: .day).timeIntervalSinceDate(streakStart) / (24 * 60 * 60))
                let streakLength = floor(eventDay.endOf(component: .day).timeIntervalSince(streakStart) / (24 * 60 * 60))
                let rmax = streakMax[.Fasting] ?? 0.0

                let notifyType: NotifyType = streakLength >= rmax ? (streakLength == rmax ? .MatchedMax : .ExceededMax) : .MatchedLevel

                streakMax[.Fasting] = max(rmax, streakLength)
                self.notifyFastingStreak(streakLength: streakLength, notifyType: notifyType)
            }
            else {
                streakStarts[.Fasting] = endDate.startOf(component: .day)
            }
            streakEnds[.Fasting] = endDate
        }
    }

    func incrContributionStreak(startDate: Date, endDate: Date) {
        log.debug("CIncr \(startDate) \(streakEnds[.Contribution]) \(self.isDayAfter(a: streakEnds[.Contribution]!, b: startDate))", "CStreak")

        if let cstStart = streakStarts[.Contribution], let cstEnd = streakEnds[.Contribution], startDate >= cstEnd {
            if self.isDayAfter(a: cstEnd, b: startDate) {
//                let streakLength = floor(endDate.endOf(component: .day).timeIntervalSinceDate(cstStart) / (24 * 60 * 60))
                let streakLength = floor(endDate.endOf(component: .day).timeIntervalSince(cstStart)) / (24 * 60 * 60)
                let rmax = streakMax[.Contribution] ?? 0.0

                let notifyType: NotifyType = streakLength >= rmax ? (streakLength == rmax ? .MatchedMax : .ExceededMax) : .MatchedLevel

                streakMax[.Contribution] = max(rmax, streakLength)
                self.notifyContributionStreak(streakLength: streakLength, notifyType: notifyType)
            }
            else if self.isMoreThanDayAfter(a: cstEnd, b: startDate) {
                streakStarts[.Contribution] = endDate.startOf(component: .day)
            }

            streakEnds[.Contribution] = endDate
        }
    }

    // App background/foreground re-entry.

    public func onRecycleEvent() {
        enqueueNotification(notificationId: "CollectData", messages: collectionMsgs)
    }

    // Helpers.

    func mkNotification(date: Date, freq: NSCalendar.Unit?, body: String, action: String = "enter your circadian events") -> UILocalNotification {
        let notification = UILocalNotification()
        notification.fireDate = date as Date
        notification.alertBody = body
        notification.alertAction = action
        notification.soundName = UILocalNotificationDefaultSoundName
        if let freq = freq { notification.repeatInterval = freq }

        return notification
    }

    func fastingDayStart(date: Date) -> Date {
        return date.startOf(component: .day)
    }

    func isDayAfter(a: Date, b: Date) -> Bool {
//        return a.isInSameDayAsDate(b - 1.days)
        return a.isInSameDayOf(date: b - 1.days)
    }

    func isMoreThanDayAfter(a: Date, b: Date) -> Bool {
        return a.endOf(component: .day) + 1.days < b
    }
    
    func notifyFastingStreak(streakLength: Double, notifyType: NotifyType) {
        doNotify(streakType: .Fasting, streakLength: streakLength, buckets: self.fastingStreakBuckets, notifyType: notifyType)
    }

    func notifyContributionStreak(streakLength: Double, notifyType: NotifyType) {
        doNotify(streakType: .Contribution, streakLength: streakLength, buckets: self.contributionStreakBuckets, notifyType: notifyType)
    }

    func doNotify(streakType: StreakType, streakLength: Double, buckets: [(Double, String, String)], notifyType: NotifyType) {
        var rankIndex = buckets.index { $0.0 >= streakLength }
        if rankIndex == nil { rankIndex = buckets.count }
        rankIndex = max(0, rankIndex! - 1)

        var (_, _, msg) = buckets[rankIndex!]

        switch streakType {
        case .Fasting:
            msg = "You've fasted for \(msg) straight"
        case .Contribution:
            msg = "You've tracked for \(msg) straight"
        }

        switch notifyType {
        case .MatchedLevel:
            msg = matchedLevelMsg(msg: msg)

        case .MatchedMax:
            msg = matchedMaxMsg(msg: msg)

        case .ExceededMax:
            msg = exceededMaxMsg(msg: msg)

        }

        let notificationId = streakType == .Fasting ? "FStreak" : "CStreak"
        log.debug("Notify \(notificationId) \(notifyType) \(streakLength) \(rankIndex) \(buckets.index { $0.0 >= streakLength }) \(msg)", notificationId)

        enqueueNotification(notificationId: notificationId, messages: [msg], immediate: true)
    }

    func notificationIntervals(now: Date) -> [(Date, Date)] {
        let blackoutTimes = getNotificationBlackoutTimes()

        let todayStart = now.startOf(component: .day)
        let todayEnd = now.endOf(component: .day)

        let blackoutStartToday = todayStart + blackoutTimes[0].hour.hours + blackoutTimes[0].minute.minutes
        let blackoutEndToday = todayStart + blackoutTimes[1].hour.hours + blackoutTimes[1].minute.minutes

        let validToday = blackoutStartToday < blackoutEndToday ?
            [(todayStart, blackoutStartToday), (blackoutEndToday, todayEnd)]
            : [(blackoutEndToday, blackoutStartToday)]

        return validToday
    }

    func immediateNotification(messages: [String], action: String? = nil) {
        let now = Date()
        let validToday = notificationIntervals(now: now)

        let fire = validToday.index { $0.0 < now && now < $0.1 }

//        let idx = GKRandomSource.sharedRandom().nextIntWithUpperBound(messages.count)
        let idx = GKRandomSource.sharedRandom().nextInt(upperBound: messages.count)
        let body = messages[idx]

        var notification: UILocalNotification! = nil
        if let action = action {
            notification = mkNotification(date: now + immediateNotificationDelaySecs.seconds, freq: nil, body: body, action: action)
        } else {
            notification = mkNotification(date: now + immediateNotificationDelaySecs.seconds, freq: nil, body: body)
        }

        if fire != nil {
//            log.debug("L-notify for \(notification.fireDate?.toString())", "execNotify")
            UIApplication.shared.scheduleLocalNotification(notification)
        } else {
            log.warning("Skip immediate notification during blackout period: \(body)", "execNotify")
        }
    }

    // Periodic notifications.
    // This cancels all notifications scheduled for the notification id before reissuing.
    func repeatedNotification(notificationId: String, frequencyInMinutes: Int, messages: [String], action: String? = nil) {
        let now = Date()
        let todayEnd = now.endOf(component: .day)

        let validToday = notificationIntervals(now: now)
        let validTmw = validToday.map { ($0.0 + 1.days, $0.1 + 1.days) }

        let overlaps: (Date, Bool, (Date, Date)) -> Bool = { (date, acc, rng) in
            acc || (rng.0 < date && date < rng.1)
        }

        if let nGroup = notificationGroups[notificationId] {
            nGroup.forEach { notification in
                UIApplication.shared.cancelLocalNotification(notification)
//                log.info("Cancelled l-notify for \(notification.fireDate?.toString()) repeating \(notification.repeatInterval)", "cancel:execNotify")
            }
            notificationGroups[notificationId] = []
        }

        // For debugging.
        logCurrentNotifications(feature: "state:execNotify")

        let frequencyInHours = frequencyInMinutes / 60

        var noteDate   : Date! = nil
        var noteEnd    : Date! = nil
        var repeatUnit : NSCalendar.Unit? = nil
//        var repeatUnit : Calendar.Unit! = nil
        var dateStep   : DateComponents! = nil
        var skipBlackoutCheck = false

        if frequencyInMinutes < 60 {
            dateStep = Int(frequencyInMinutes).minutes as DateComponents!
            noteDate = now + dateStep
            noteEnd = noteDate + 1.hours
            repeatUnit = .hour
        }
        else if frequencyInMinutes < 1440 {
            dateStep = Int(frequencyInHours).hours as DateComponents!
            noteDate = now + dateStep
            noteEnd = noteDate + 1.days
            repeatUnit = .day
        }
        else {
            dateStep = Int(frequencyInHours/24).days as DateComponents!
            noteDate = now
            noteEnd = noteDate + 1.weeks
            if !validToday.reduce(false, { (acc, rng) in overlaps(noteDate, acc, rng) }) {
//                let idx = GKRandomSource.sharedRandom().nextIntWithUpperBound(validToday.count)
                let idx = GKRandomSource.sharedRandom().nextInt(upperBound: validToday.count)
                let rangeSecs = validToday[idx].1.timeIntervalSinceReferenceDate - validToday[idx].0.timeIntervalSinceReferenceDate
                noteDate = validToday[idx].0 + Int(drand48() * rangeSecs).seconds
            }

            noteDate = noteDate + dateStep
            repeatUnit = .weekOfYear
            skipBlackoutCheck = true
        }

        while noteDate < noteEnd {
            if skipBlackoutCheck ||
                (( noteDate < todayEnd && validToday.reduce(false, { (acc, rng) in overlaps(noteDate, acc, rng) }) )
                    || (noteDate > todayEnd && validTmw.reduce(false, { (acc, rng) in overlaps(noteDate, acc, rng) }) ))
            {
//                let idx = GKRandomSource.sharedRandom().nextIntWithUpperBound(messages.count)
                let idx = GKRandomSource.sharedRandom().nextInt(upperBound: messages.count)
                let body = messages[idx]
                let notification = mkNotification(date: noteDate, freq: repeatUnit, body: body)

                if var group = notificationGroups[notificationId] {
                    group.append(notification)
                    notificationGroups.updateValue(group, forKey: notificationId)
                } else {
                    notificationGroups[notificationId] = [notification]
                }

                UIApplication.shared.scheduleLocalNotification(notification)
//                log.debug("Scheduled l-notify for \(notification.fireDate?.toString()) repeating \(repeatUnit)", "execNotify")
            }
            noteDate = noteDate + dateStep
        }

        // For debugging.
        logCurrentNotifications(feature: "state:execNotify")
    }

    func enqueueNotification(notificationId: String, messages: [String], action: String? = nil, immediate: Bool = false) {
        if let settings = UIApplication.shared.currentUserNotificationSettings {
            if settings.types != .none {
                if immediate {
                    immediateNotification(messages: messages, action: action)
                }
                else {
                    let frequencyInMinutes = getNotificationReminderFrequency()
                    if frequencyInMinutes > 0 {
                        repeatedNotification(notificationId: notificationId, frequencyInMinutes: frequencyInMinutes, messages: messages, action: action)
                    } else {
                        log.debug("Skipping notification, user requested silence", "execNotify")
                    }
                }
            } else {
                log.warning("User has disabled notifications", "execNotify")
            }
        } else {
            log.error("Unable to retrieve notifications settings.", "execNotify")
        }
    }

    func logCurrentNotifications(feature: String) {
        if let ns = UIApplication.shared.scheduledLocalNotifications {
            ns.forEach { n in
//                log.debug("CL-notify \(n.fireDate?.toString() ?? "<none>") repeating \(n.repeatInterval)", feature)
            }
        }
    }


    // Fasting streak levels.
    let fastingStreakBuckets: [(Double, String, String)] = [
        (2,    "icon-rock",              "two days"),
        (3,    "icon-quill",             "three days"),
        (5,    "icon-typewriter",        "five days"),
        (7,    "icon-polaroid",          "one week"),
        (10,   "icon-pendulum",          "ten days"),
        (14,   "icon-metronome",         "two weeks"),
        (21,   "icon-grandfather-clock", "three weeks"),
        (30,   "icon-sherlock",          "one month"),
        (60,   "icon-robot",             "two months"),
        (90,   "icon-satellite",         "three months"),
        (180,  "icon-neo",               "six months"),
        (365,  "icon-eye",               "one year"),
    ]

    // Contribution streak levels.
    let contributionStreakBuckets: [(Double, String, String)] = [
        (2,    "icon-rock",              "two days"),
        (3,    "icon-quill",             "three days"),
        (5,    "icon-typewriter",        "five days"),
        (7,    "icon-polaroid",          "one week"),
        (10,   "icon-pendulum",          "ten days"),
        (14,   "icon-metronome",         "two weeks"),
        (21,   "icon-grandfather-clock", "three weeks"),
        (30,   "icon-sherlock",          "one month"),
        (60,   "icon-robot",             "two months"),
        (90,   "icon-satellite",         "three months"),
        (180,  "icon-neo",               "six months"),
        (365,  "icon-eye",               "one year"),
    ]

    let matchedLevelPrefixes = [
        "You're on a roll!",
        "Great job!",
        "You've hit your stride!",
        "And the streak goes on!",
    ]

    func matchedLevelMsg(msg: String) -> String {
//        let idx = GKRandomSource.sharedRandom().nextIntWithUpperBound(matchedLevelPrefixes.count)
        let idx = GKRandomSource.sharedRandom().nextInt(upperBound: matchedLevelPrefixes.count)
        return "\(matchedLevelPrefixes[idx]) \(msg)!"

    }

    let exceededPrefixes = [
        "Congratulations, you've hit a personal best!",
        "You've reached a new high!",
        "You're blazing a new streak, this is the best you've ever done!"
    ]

    func exceededMaxMsg(msg: String) -> String {
//        let idx = GKRandomSource.sharedRandom().nextIntWithUpperBound(exceededPrefixes.count)
        let idx = GKRandomSource.sharedRandom().nextInt(upperBound: exceededPrefixes.count)
        return "\(exceededPrefixes[idx]) \(msg)!"
    }

    func matchedMaxMsg(msg: String) -> String {
//        let idx = GKRandomSource.sharedRandom().nextIntWithUpperBound(3)
        let idx = GKRandomSource.sharedRandom().nextInt(upperBound: 3)
        switch idx {
        case 0:
            return "\(msg), matching your personal best! Keep going to beat it!"
        case 1:
            return "You're so close to reaching a new best! \(msg)!"
        default:
            return "This is your best ever streak! \(msg)"
        }
    }

    var collectionMsgs = [
        "We greatly value your input in Metabolic Compass. Would you like to contribute to medical research now?",
        "Help us study metabolic patterns by tracking your sleeping, eating and exercise timings in Metabolic Compass!",
        "We haven't seen you in a while, take a moment to pitch in on our Metabolic Compass research study."
    ]

    var inAppCollectionMsgs = [
        "We greatly value your input in Metabolic Compass. Would you like to contribute to medical research now?",
        "Help us study metabolic patterns by tracking your sleeping, eating and exercise timings in Metabolic Compass!",
        "We're pleased to see you using Metabolic Compass! Take a moment to log your activites for our research study."
    ]

    var inAppMsgMapping: [String: String] = [:]
}
