//
//  ComplicationController.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import ClockKit
import HealthKit

var heightHK, weightHK:HKQuantitySample?
var proteinHK, fatHK, carbHK:HKQuantitySample?
var bmiHK:Double = 22.1
let kUnknownString   = "Unknown"
let HMErrorDomain                        = "HMErrorDomain"

var HKBMIString:String = "24.3"
var weightLocalizedString:String = "151 lb"
var heightLocalizedString:String = "5 ft"
var proteinLocalizedString:String = "50 gms"
typealias HMTypedSampleBlock    = (samples: [HKSampleType: [MCSample]], error: NSError?) -> Void
typealias HMCircadianBlock          = (intervals: [(NSDate, CircadianEvent)], error: NSError?) -> Void
typealias HMCircadianAggregateBlock = (aggregates: [(NSDate, Double)], error: NSError?) -> Void
typealias HMFastingCorrelationBlock = ([(NSDate, Double, MCSample)], NSError?) -> Void
typealias HMSampleBlock         = (samples: [MCSample], error: NSError?) -> Void
enum CircadianEvent {
    case Meal
    case Fast
    case Sleep
    case Exercise
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    let userCalendar = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        let startDate = getStartDateFromUserDefaults()
        let sabbaticalDate = getSabbaticalDate(startDate)
        handler(sabbaticalDate)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        reloadFastingTimeData()
//        print("updated Fasting Time from getCurrentTimelineEntryForComplication")
        var shortText = MetricsStore.sharedInstance.fastingTime
        if complication.family == .UtilitarianSmall || complication.family == .UtilitarianLarge || complication.family == .ModularSmall || complication.family == .ModularLarge || complication.family == .CircularSmall
        {
            let startDate = getStartDateFromUserDefaults()
            let sabbaticalDate = getSabbaticalDate(startDate)
            
            let dateComparisionResult:NSComparisonResult = NSDate().compare(sabbaticalDate)
            if dateComparisionResult == NSComparisonResult.OrderedAscending
            {
                let flags: NSCalendarUnit = [.Year, .Month, .Day]
                let dateComponents = userCalendar.components(flags, fromDate: NSDate(), toDate: sabbaticalDate, options: [])
                let year = dateComponents.year
                let month = dateComponents.month
                let day = dateComponents.day
                
                if (year > 0 )
                {
                    shortText = MetricsStore.sharedInstance.fastingTime
                }
                else if (year <= 0 && month > 0)
                {
                    shortText = MetricsStore.sharedInstance.fastingTime
                }
                else if (year <= 0 && month <= 0 && day > 0)
                {
                    shortText = MetricsStore.sharedInstance.fastingTime
                }
                
            }
            else if dateComparisionResult == NSComparisonResult.OrderedDescending
            {
                shortText = MetricsStore.sharedInstance.fastingTime
            }
            
            shortText = MetricsStore.sharedInstance.fastingTime
            let entry = createComplicationEntry(shortText, date: NSDate(), family: complication.family)
            
//            print("in getCurrentTimelineEntryForComplication: \(entry)")
            handler(entry)
        } else {
            handler(nil)
        }
        
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
//        reloadFastingTimeData()
//        print("updated Fasting Time from getTimelineEntriesForComplication")
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        reloadFastingTimeData()
//        print("updated Fasting Time from getTimelineEntriesForComplication")
        let startDate = getStartDateFromUserDefaults()
        let sabbaticalDate = getSabbaticalDate(startDate)
        let componentDay = userCalendar.components(.Day, fromDate: date, toDate: sabbaticalDate, options: [])
        let days = min(componentDay.day, 100)
        
        let entries = [CLKComplicationTimelineEntry]()
        
        for index in 1...days {
            let dateComparisionResult:NSComparisonResult = NSDate().compare(sabbaticalDate)
            if dateComparisionResult == NSComparisonResult.OrderedAscending
            {
                let entryDate = userCalendar.dateByAddingUnit([.Day], value: index, toDate: date, options: [])!
                
                let flags: NSCalendarUnit = [.Year, .Month, .Day]
                let dateComponents = userCalendar.components(flags, fromDate: entryDate, toDate: sabbaticalDate, options: [])

                let year = dateComponents.year
                let month = dateComponents.month
                let day = dateComponents.day
                
                if (year > 0 )
                {
                    _ = MetricsStore.sharedInstance.fastingTime

                }
                else if (year <= 0 && month > 0)
                {
                    let entryText = MetricsStore.sharedInstance.fastingTime
                }
                else if (year <= 0 && month <= 0 && day > 0)
                {

                    _ = MetricsStore.sharedInstance.fastingTime

                }
            }
        }
        handler(entries)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        handler(NSDate(timeIntervalSinceNow: 5))
//        reloadFastingTimeData()
//        print("updated Fasting Time from getNextRequestedUpdateDateWithHandler")
//        print("getNextRequestedUpdateDateWithHandler called \(NSDate.description())")
    }
    
    func reloadFastingTimeData() {
        typealias Event = (NSDate, Double)
        typealias IEvent = (Double, Double)?
        
        let yesterday = NSDate().dateByAddingTimeInterval(-(24*60.0*60.0))
        let startDate = yesterday
        
        fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                guard error == nil else {
//                    print("Failed to fetch circadian events: \(error)")
                    return
                }
                
                if intervals.isEmpty {
//                    print("series is Empty")
                    
                } else {
                    
                    let vals : [(x: Double, y: Double)] = intervals.map { event in
                        let startTimeInFractionalHours = event.0.timeIntervalSinceDate(startDate) / 3600.0
                        let metabolicStateAsDouble = self.valueOfCircadianEvent(event.1)
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
                    let calendar = NSCalendar.currentCalendar()
                    let todayComponents = calendar.components([.Year, .Month, .Day], fromDate: NSDate())
                    let today = calendar.dateFromComponents(todayComponents)!
                    
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "mm"
                    dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
                    
                    let fastingHrs = Int(floor(stats.2))
                    let todayPlusMins = today.dateByAddingTimeInterval(round((stats.2 % 1.0) * 60.0 * 60.0))
                    let fastingMins = dateFormatter.stringFromDate(todayPlusMins)
                    
//                    print("in EventTimeViewController, fasting hours: \(fastingHrs)")
//                    print("   and fasting minutes: \(fastingMins)")
                    MetricsStore.sharedInstance.fastingTime = "\(fastingHrs):\(fastingMins)"
                    
                }

                
            })
        }
    }
    func fetchCircadianEventIntervals(startDate: NSDate = NSDate().dateByAddingTimeInterval(-(24*60.0*60.0)),
                                      endDate: NSDate = NSDate(),
                                      completion: HMCircadianBlock)
    {
        typealias Event = (NSDate, CircadianEvent)
        typealias IEvent = (Double, CircadianEvent)
        
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]
        
        fetchSamples(typesAndPredicates) { (events, error) -> Void in
            guard error == nil && !events.isEmpty else {
                completion(intervals: [], error: error)
                return
            }
            let extendedEvents = events.flatMap { (ty,vals) -> [Event]? in
                switch ty {
                case is HKWorkoutType:
                    return vals.flatMap { s -> [Event] in
                        let st = s.startDate.laterDate(startDate)
                        let en = s.endDate
                        guard let v = s as? HKWorkout else { return [] }
                        switch v.workoutActivityType {
                        case HKWorkoutActivityType.PreparationAndRecovery:
                            return [(st, .Meal), (en, .Meal)]
                        default:
                            return [(st, .Exercise), (en, .Exercise)]
                        }
                    }
                    
                case is HKCategoryType:
                    guard ty.identifier == HKCategoryTypeIdentifierSleepAnalysis else {
                        return nil
                    }
                    return vals.flatMap { s -> [Event] in
                        let st = s.startDate.laterDate(startDate)
                        let en = s.endDate
                        return [(st, .Sleep), (en, .Sleep)]
                    }
                    
                default:
//                    print("Unexpected type \(ty.identifier) while fetching circadian event intervals")
                    return nil
                }
            }
            
            let sortedEvents = extendedEvents.flatten().sort { (a,b) in return a.0.compare(b.0) == .OrderedAscending }
            let epsilon = 1.0 // in seconds.
            let lastev = sortedEvents.last ?? sortedEvents.first!
            let lst = lastev.0 == endDate ? [] : [(lastev.0, CircadianEvent.Fast), (endDate, CircadianEvent.Fast)]
            
            
            let initialAccumulator : ([Event], Bool, Event!) = ([], true, nil)
            let endpointArray = sortedEvents.reduce(initialAccumulator, combine:
                { (acc, event) in
                    let eventEndpointDate = event.0
                    let eventMetabolicState = event.1
                    
                    let resultArray = acc.0
                    let eventIsIntervalStart = acc.1
                    let prevEvent = acc.2
                    
                    let nextEventAsIntervalStart = !acc.1
                    
                    guard prevEvent != nil else {
                        let skipPrefix = eventEndpointDate == startDate || startDate == NSDate.distantPast()
                        let newResultArray = (skipPrefix ? [event] : [(startDate, CircadianEvent.Fast), (eventEndpointDate, CircadianEvent.Fast), event])
                        return (newResultArray, nextEventAsIntervalStart, event)
                    }
                    
                    let prevEventEndpointDate = prevEvent.0
                    
                    if (eventIsIntervalStart && prevEventEndpointDate == eventEndpointDate) {
                        let newResult = resultArray + [(eventEndpointDate.dateByAddingTimeInterval(1), eventMetabolicState)]
                        return (newResult, nextEventAsIntervalStart, event)
                    } else if eventIsIntervalStart {
                        let fastEventStart = prevEventEndpointDate.dateByAddingTimeInterval(epsilon)
                        let modifiedEventEndpoint = eventEndpointDate.dateByAddingTimeInterval(-epsilon)
                        let fastEventEnd = fastEventStart.compare(modifiedEventEndpoint.dateByAddingTimeInterval(-(24*60.0*60.0))) == .OrderedAscending ?
                            fastEventStart.dateByAddingTimeInterval(24 * 60.0 * 60.0) : modifiedEventEndpoint
                        let newResult = resultArray + [(fastEventStart, .Fast), (fastEventEnd, .Fast), event]
                        return (newResult, nextEventAsIntervalStart, event)
                    } else {
                        
                        return (resultArray + [event], nextEventAsIntervalStart, event)
                    }
            }).0 + lst
            
            completion(intervals: endpointArray, error: error)
        }
    }
    
    func fetchSamples(typesAndPredicates: [HKSampleType: NSPredicate?], completion: HMTypedSampleBlock)
    {
        let group = dispatch_group_create()
        var samplesByType = [HKSampleType: [MCSample]]()
        
        typesAndPredicates.forEach { (type, predicate) -> () in
            dispatch_group_enter(group)
            fetchSamplesOfType(type, predicate: predicate, limit: noLimit) { (samples, error) in
                guard error == nil else {
                    dispatch_group_leave(group)
                    return
                }
                guard samples.isEmpty == false else {
                    dispatch_group_leave(group)
                    return
                }
                samplesByType[type] = samples
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completion(samples: samplesByType, error: nil)
        }
    }
    
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
    
    
    func fetchSamplesOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int = noLimit,
                            sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) {
            (query, samples, error) -> Void in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            completion(samples: samples?.map { $0 as! MCSample } ?? [], error: nil)
        }
        healthKitStore.executeQuery(query)
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        if complication.family == .UtilitarianSmall {
            let smallUtil = CLKComplicationTemplateUtilitarianSmallFlat()
            smallUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.fastingTime)
            handler(smallUtil)
        }
        if complication.family == .UtilitarianLarge {
            let largeUtil = CLKComplicationTemplateUtilitarianLargeFlat()
            largeUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.fastingTime)
            handler(largeUtil)
        }
        if complication.family == .ModularSmall {
            let smallUtil = CLKComplicationTemplateModularSmallSimpleText()
            smallUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.fastingTime)
            handler(smallUtil)
        }
        if complication.family == .ModularLarge {
            let largeUtil = CLKComplicationTemplateModularLargeTallBody()
            largeUtil.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Time")
            largeUtil.bodyTextProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.fastingTime)
            handler(largeUtil)
        }
        
        if complication.family == .CircularSmall {
            let smallUtil = CLKComplicationTemplateCircularSmallSimpleText()
            smallUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.fastingTime)
            handler(smallUtil)
        }
//        print("in getPlaceholderTemplateForComplication \(MetricsStore.sharedInstance.fastingTime)")
    }
    
    func createComplicationEntry(shortText: String, date: NSDate, family: CLKComplicationFamily) -> CLKComplicationTimelineEntry {
        if  family == CLKComplicationFamily.UtilitarianSmall {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.UtilitarianLarge {
            let largeFlat = CLKComplicationTemplateUtilitarianLargeFlat()
            largeFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: largeFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.ModularLarge {
          let largeFlat = CLKComplicationTemplateModularLargeTallBody()
            largeFlat.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Time")
            largeFlat.bodyTextProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: largeFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.ModularSmall {
            let smallFlat = CLKComplicationTemplateModularSmallSimpleText()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        } else  {
            let smallFlat = CLKComplicationTemplateCircularSmallRingText()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        }
//        print("added new Complication entry to Entries \(date) and \(shortText)")
        
    }
    
    func requestedUpdateDidBegin() {
//        print("Complication update is starting")
        
        createComplicationEntry(MetricsStore.sharedInstance.fastingTime, date: NSDate(),family: CLKComplicationFamily.UtilitarianSmall)
        
        createComplicationEntry(MetricsStore.sharedInstance.fastingTime, date: NSDate(),family: CLKComplicationFamily.UtilitarianLarge)
        
        createComplicationEntry(MetricsStore.sharedInstance.fastingTime, date: NSDate(),family: CLKComplicationFamily.ModularLarge)
        
        createComplicationEntry(MetricsStore.sharedInstance.fastingTime, date: NSDate(),family: CLKComplicationFamily.ModularSmall)
        
        createComplicationEntry(MetricsStore.sharedInstance.fastingTime, date: NSDate(),family: CLKComplicationFamily.CircularSmall)
        
        let server=CLKComplicationServer.sharedInstance()
        
        for comp in (server.activeComplications)! {
            server.reloadTimelineForComplication(comp)
//            print("Timeline has been reloaded")
        }
    }
    
    func requestedUpdateBudgetExhausted() {
//        print("Budget exhausted")
    }
    
    func getSabbaticalDate(startDate: NSDate) -> NSDate {
        dateFormatter.calendar = userCalendar
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let sevenYears: NSDateComponents = NSDateComponents()
        sevenYears.setValue(7, forComponent: NSCalendarUnit.Year);
        
        var sabbaticalDate = userCalendar.dateByAddingComponents(sevenYears, toDate: startDate, options: NSCalendarOptions(rawValue: 0))
        
        while sabbaticalDate!.timeIntervalSinceNow.isSignMinus {
            sabbaticalDate = userCalendar.dateByAddingComponents(sevenYears, toDate: sabbaticalDate!, options: NSCalendarOptions(rawValue: 0))
        }
        
        return sabbaticalDate!
    }
    
    func getStartDateFromUserDefaults() -> NSDate {
        let defaults = NSUserDefaults.standardUserDefaults()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var startDate = NSDate()
        
        if let dateString = defaults.stringForKey("dateKey")
        {
            startDate = dateFormatter.dateFromString(dateString)!
        }
        
        return startDate
    }
}
