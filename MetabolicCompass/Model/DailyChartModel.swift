//
//  DailyChartModel.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import MetabolicCompassKit
import SwiftDate
import Async
import AwesomeCache
import MCCircadianQueries

@objc protocol DailyChartModelProtocol {
    optional func dataCollectingFinished()
    optional func dailyProgressStatCollected()
}

class DailyProgressDayInfo: NSObject, NSCoding {
    
    static var dayColorsKey = "dayColors"
    static var dayValuesKey = "dayValues"
    
    internal var dayColors: [UIColor] = [UIColor.clearColor()]
    internal var dayValues: [Double] = [24.0]
    
    init(colors: [UIColor], values: [Double]) {
        self.dayColors = colors
        self.dayValues = values
    }
    
    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let colors = aDecoder.decodeObjectForKey(DailyProgressDayInfo.dayColorsKey) as? [UIColor] else { return nil }
        guard let values = aDecoder.decodeObjectForKey(DailyProgressDayInfo.dayValuesKey) as? [Double] else { return nil }
        self.init(colors: colors, values: values)
    }
    
    internal func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(dayColors, forKey: DailyProgressDayInfo.dayColorsKey)
        aCoder.encodeObject(dayValues, forKey: DailyProgressDayInfo.dayValuesKey)
    }
}

typealias MCDailyProgressCache = Cache<DailyProgressDayInfo>

class DailyChartModel : NSObject, UITableViewDataSource {

    /// initializations of these variables creates offsets so plots of event transitions are square waves
    private let stWorkout = 0.0
    private let stSleep = 0.33
    private let stFast = 0.66
    private let stEat = 1.0

    private let dayCellIdentifier = "dayCellIdentifier"
    private let emptyValueString = "- h - m"
    
    var cachedDailyProgress: MCDailyProgressCache
    
    var delegate:DailyChartModelProtocol? = nil
    var chartDataArray: [[Double]] = []
    var chartColorsArray: [[UIColor]] = []
    var fastingText: String = ""
    var lastAteText: String = ""
    var eatingText: String = ""
    var daysTableView: UITableView?

    var highlightFasting: Bool = false

    override init() {
        do {
            self.cachedDailyProgress = try MCDailyProgressCache(name: "MCDaylyProgressCache")
        } catch _ {
            fatalError("Unable to create HealthManager aggregate cache.")
        }
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(invalidateCache), name: HMDidUpdateCircadianEvents, object: nil)
    }
    
    var daysArray: [NSDate] = { return DailyChartModel.getChartDateRange() }()
    
    var daysStringArray: [String] = { return DailyChartModel.getChartDateRangeStrings() }()

    func invalidateCache(note: NSNotification) {
        if let info = note.userInfo, dates = info[HMCircadianEventsDateUpdateKey] as? Set<NSDate> {
            if dates.count > 0 {
                for date in dates {
                    let cacheKey = "\(date.month)_\(date.day)_\(date.year)"
                    log.info("Invalidating daily progress cache for \(cacheKey)")
                    cachedDailyProgress.removeObjectForKey(cacheKey)
                }
                prepareChartData()
            }
        }
    }

    func updateRowHeight (){
        self.daysTableView?.rowHeight = CGRectGetHeight(self.daysTableView!.frame)/7.0
        self.daysTableView?.reloadData()
    }

    func registerCells() {
        let dayCellNib = UINib(nibName: "DailyProgressDayTableViewCell", bundle: nil)
        self.daysTableView?.registerNib(dayCellNib, forCellReuseIdentifier: dayCellIdentifier)
    }

    // MARK: -  UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.daysStringArray.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(dayCellIdentifier) as! DailyProgressDayTableViewCell
        cell.dayLabel.text = self.daysStringArray[indexPath.row]
        cell.dayLabel.textColor = indexPath.row == 0 ? UIColor.colorWithHexString("#ffffff", alpha: 1) : UIColor.colorWithHexString("#ffffff", alpha: 0.3)
        return cell
    }
    
    //MARK: Working with events data
    
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
    
    func prepareChartData () {
        self.chartDataArray = []
        self.chartColorsArray = []
        self.getDataForDay(nil, lastDay: false)
    }

    class func getChartDateRange(endDate: NSDate? = nil) -> [NSDate] {
        var lastSevenDays: [NSDate] = []
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let dateComponents = (endDate ?? NSDate()).startOf(.Day).components
        for _ in 0...6 {
            let date = calendar!.dateFromComponents(dateComponents)
            dateComponents.day -= 1;
            if let date = date {
                lastSevenDays.append(date)
            }
        }
        return lastSevenDays.reverse()
    }

    class func getChartDateRangeStrings(endDate: NSDate? = nil) -> [String] {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM\ndd"

        // Note: we reverse the strings array since days are from recent (top) to oldest (bottom)
        return getChartDateRange(endDate).map { date in
            let dateString = formatter.stringFromDate(date)
            if date.day % 10 == 1 {
                if date.day == 11 {
                    return dateString.stringByAppendingString(" th")
                } else {
                    return dateString.stringByAppendingString(" st")
                }
            } else if date.day % 10 == 2 {
                if date.day == 12 {
                    return dateString.stringByAppendingString(" th")
                } else {
                    return dateString.stringByAppendingString(" nd")
                }
            } else if date.day % 10 == 3 {
                if date.day == 13 {
                    return dateString.stringByAppendingString(" th")
                } else {
                    return dateString.stringByAppendingString(" rd")
                }
            } else {
                return dateString.stringByAppendingString(" th")
            }
        }.reverse()
    }

    func getStartDate() -> NSDate? { return self.daysArray.first }
    func getEndDate() -> NSDate? { return self.daysArray.last }

    func setEndDate(endDate: NSDate? = nil) {
        self.daysArray = DailyChartModel.getChartDateRange(endDate)
        self.daysStringArray = DailyChartModel.getChartDateRangeStrings(endDate)
    }

    func getDataForDay(day: NSDate?, lastDay:Bool) {
        let startDay = day == nil ? self.daysArray.first! : day!
        let today = startDay.isInToday()

        let dateIndex = self.daysArray.indexOf(startDay)
        let cacheKey = "\(startDay.month)_\(startDay.day)_\(startDay.year)"
        let cacheDuration = today ? 5.0 : 60.0 //if it's today we will add cache time for 10 seconds in other cases cache will be saved for 1 minute

        self.cachedDailyProgress.setObjectForKey(cacheKey, cacheBlock: { (success, error) in
            self.getCircadianEventsForDay(startDay, completion: { (dayInfo) in
                success(dayInfo, .Seconds(cacheDuration))
            })
        }, completion: { (dayInfoFromCache, loadedFromCache, error) in
            if (dayInfoFromCache != nil) {
                self.chartColorsArray.append((dayInfoFromCache?.dayColors)!)
                self.chartDataArray.append((dayInfoFromCache?.dayValues)!)
            }
            if !lastDay { //we still have data to retrieve
                let nextIndex = dateIndex! + 1
                let lastElement = nextIndex == (self.daysArray.count - 1)
                Async.main {
                    self.getDataForDay(self.daysArray[nextIndex], lastDay: lastElement)
                }
            } else {//end of recursion
                self.chartColorsArray = self.chartColorsArray.map { return $0.map(self.selectColor) }

                Async.main {
                    self.delegate?.dataCollectingFinished?()
                }
            }
        })
    }
    
    func getCircadianEventsForDay(day: NSDate, completion: (dayInfo: DailyProgressDayInfo) -> Void) {
        
        let endOfDay = self.endOfDay(day)
        var dayEvents:[Double] = []
        var dayColors:[UIColor] = []
        var previousEventType: CircadianEvent?
        var previousEventDate: NSDate? = nil

        // Run the query in a user interactive thread to prioritize the data model update over
        // any concurrent observer queries (i.e., when resuming the app from the background).
        Async.userInteractive {
            MCHealthManager.sharedManager.fetchCircadianEventIntervals(day, endDate: endOfDay, completion: { (intervals, error) in
                guard error == nil else {
                    log.error("Failed to fetch circadian events: \(error)")
                    return
                }
                if !intervals.isEmpty {
                    for event in intervals {
                        let (eventDate, eventType) = event //assign tuple values to vars
                        if endOfDay.day < eventDate.day {
                            print(previousEventDate)
                            let endEventDate = self.endOfDay(previousEventDate!)
                            let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: endEventDate)

                            dayEvents.append(eventDuration)
                            dayColors.append(self.getColorForEventType(eventType))
                            break
                        }
                        if previousEventDate != nil && eventType == previousEventType {//we alredy have a prev event and can calculate how match time it took
                            let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: eventDate)

                            dayEvents.append(eventDuration)
                            dayColors.append(self.getColorForEventType(eventType))
                        }
                        previousEventDate = eventDate
                        previousEventType = eventType
                    }
                    let dayInfo = DailyProgressDayInfo(colors: dayColors, values: dayEvents)
                    completion(dayInfo: dayInfo)
                    return
                }
                completion(dayInfo: DailyProgressDayInfo(colors: [UIColor.clearColor()], values: [24.0]))
            })
        }
    }
    
    func getDailyProgress() {
        typealias Event = (NSDate, Double)
        typealias IEvent = (Double, Double)
        
        /// Fetch all sleep and workout data since yesterday, and then aggregate sleep, exercise and meal events.
        let yesterday = 1.days.ago
        let startDate = yesterday

        Async.userInteractive {
            MCHealthManager.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
                Async.main {
                    guard error == nil else {
                        log.error("Failed to fetch circadian events: \(error)")
                        return
                    }
                    if intervals.isEmpty {
                        self.fastingText = self.emptyValueString
                        self.eatingText = self.emptyValueString
                        self.lastAteText = self.emptyValueString
                        self.delegate?.dailyProgressStatCollected?()
                    } else {
                        // Create an array of circadian events for charting as x-y values
                        // for the charting library.
                        //
                        // Each input event is a pair of NSDate and metabolic state (i.e.,
                        // whether you are eating/fasting/sleeping/exercising).
                        //
                        // Conceptually, circadian events are intervals with a starting date
                        // and ending date. We represent these endpoints (i.e., starting vs ending)
                        // as consecutive array elements. For example the following array represents
                        // an eating event (as two array elements) following by a sleeping event
                        // (also as two array elements):
                        //
                        // [('2016-01-01 20:00', .Meal), ('2016-01-01 20:45', .Meal),
                        //  ('2016-01-01 23:00', .Sleep), ('2016-01-02 07:00', .Sleep)]
                        //
                        // In the output, x-values indicate when the event occurred relative
                        // to a date 24 hours ago (i.e., 24-x hours ago)
                        // That is, an x-value of:
                        // a) 1.5 indicates the event occurred 22.5 hours ago
                        // b) 3.0 indicates the event occurred 21.0 hours ago
                        //
                        // y-values are a double value indicating the y-offset corresponding
                        // to a eat/sleep/fast/exercise value where:
                        // workout = 0.0, sleep = 0.33, fast = 0.66, eat = 1.0
                        //
                        let vals : [(x: Double, y: Double)] = intervals.map { event in
                            let startTimeInFractionalHours = event.0.timeIntervalSinceDate(startDate) / 3600.0
                            let metabolicStateAsDouble = self.valueOfCircadianEvent(event.1)
                            return (x: startTimeInFractionalHours, y: metabolicStateAsDouble)
                        }

                        // Calculate circadian event statistics based on the above array of events.
                        // Again recall that this is an array of event endpoints, where each pair of
                        // consecutive elements defines a single event interval.
                        //
                        // This aggregates/folds over the array, updating an accumulator with the following fields:
                        //
                        // i. a running sum of eating time
                        // ii. the last eating time
                        // iii. the max fasting window
                        //
                        // Computing these statistics require information from the previous events in the array,
                        // so we also include the following fields in the accumulator:
                        //
                        // iv. the previous event
                        // v. a bool indicating whether the current event starts an interval
                        // vi. the accumulated fasting window
                        // vii. a bool indicating if we are in an accumulating fasting interval
                        //
                        let initialAccumulator : (Double, Double, Double, IEvent!, Bool, Double, Bool) =
                            (0.0, 0.0, 0.0, nil, true, 0.0, false)

                        let stats = vals.filter { $0.0 >= yesterday.timeIntervalSinceDate(startDate) } .reduce(initialAccumulator, combine:
                            { (acc, event) in
                                // Named accumulator components
                                var newEatingTime = acc.0
                                let lastEatingTime = acc.1
                                var maxFastingWindow = acc.2
                                var currentFastingWindow = acc.5

                                // Named components from the current event.
                                let eventEndpointDate = event.0
                                let eventMetabolicState = event.1

                                // Information from previous event endpoint.
                                let prevEvent = acc.3
                                //                                let prevEndpointWasIntervalStart = acc.4
                                let prevEndpointWasIntervalEnd = !acc.4
                                var prevStateWasFasting = acc.6

                                // Define the fasting state as any non-eating state
                                let isFasting = eventMetabolicState != self.stEat

                                // If this endpoint starts a new event interval, update the accumulator.
                                if prevEndpointWasIntervalEnd {
                                    let prevEventEndpointDate = prevEvent.0
                                    let duration = eventEndpointDate - prevEventEndpointDate

                                    if prevStateWasFasting && isFasting {
                                        // If we were fasting in the previous event, and are also fasting in this
                                        // event, we extend the currently ongoing fasting period.

                                        // Increment the current fasting window.
                                        currentFastingWindow += duration

                                        // Revise the max fasting window if the current fasting window is now larger.
                                        maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow

                                    } else if isFasting {
                                        // Otherwise if we started fasting in this event, we reset
                                        // the current fasting period.

                                        // Reset the current fasting window
                                        currentFastingWindow = duration

                                        // Revise the max fasting window if the current fasting window is now larger.
                                        maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow

                                    } else if eventMetabolicState == self.stEat {
                                        // Otherwise if we are eating, we increment the total time spent eating.
                                        newEatingTime += duration
                                    }
                                } else {
                                    prevStateWasFasting = prevEvent == nil ? false : prevEvent.1 != self.stEat
                                }

                                let newLastEatingTime = eventMetabolicState == self.stEat ? eventEndpointDate : lastEatingTime

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
                        let lastAte : NSDate? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds)

                        let eatingTime = roundDate((today + Int(stats.0 * 3600.0).seconds), granularity: granularity1Min)
                        if eatingTime.hour == 0 && eatingTime.minute == 0 {
                            self.eatingText = self.emptyValueString
                        } else {
                            self.eatingText = eatingTime.toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                        }

                        let fastingHrs = Int(floor(stats.2))
                        let fastingMins = (today + Int(round((stats.2 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
                        self.fastingText = "\(fastingHrs) h \(fastingMins) m"

                        if let lastAte = lastAte {
                            let components = NSDate().components - lastAte.components
                            if components.day > 0 {
                                let mins = (today + components.minute.minutes).toString(DateFormat.Custom("mm 'm'"))!
                                self.lastAteText = "\(components.day * 24 + components.hour) h \(mins)"
                            } else {
                                self.lastAteText = (today + components).toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                            }
                        } else {
                            self.lastAteText = self.emptyValueString
                        }
                        
                        self.delegate?.dailyProgressStatCollected?()
                    }
                }
            }
        }
    }
    
    func getColorForEventType(eventType: CircadianEvent) -> UIColor {
        var eventColor: UIColor = MetabolicDailyProgressChartView.fastingColor
        switch eventType {
        case .Exercise:
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.mutedExerciseColor : MetabolicDailyProgressChartView.exerciseColor
            break
        case .Sleep :
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.mutedSleepColor : MetabolicDailyProgressChartView.sleepColor
            break
        case .Meal :
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.mutedEatingColor : MetabolicDailyProgressChartView.eatingColor
            break
        default:
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.highlightFastingColor : MetabolicDailyProgressChartView.fastingColor
        }
        return eventColor
    }
    
    //MARK: Working with date
    
    func getDifferenceForEvents(previousEventDate:NSDate?, currentEventDate: NSDate) -> Double {
        var eventDuration = 0.0
        //if we have situation when event started at the end of the previos day and ended on next day
        let dateForCurrentEvent = currentEventDate.day > previousEventDate?.day ? self.endOfDay(previousEventDate!) : currentEventDate
        let differenceComponets = previousEventDate?.difference(dateForCurrentEvent, unitFlags: [.Hour, .Minute])
        let differenceMinutes = Double((differenceComponets?.minute)!)
        let minutes = Double(differenceMinutes / 60.0)//we need to devide by 60 because 60 is 100% (minutes in hour)
        if (differenceComponets?.hour > 0) {//more then 1h
            let hours = Double((differenceComponets?.hour)!)
            eventDuration = hours + minutes
        } else {//less then 1h
            eventDuration = minutes
        }
        return self.roundToPlaces(eventDuration, places: 2)
    }
    
    func endOfDay(date: NSDate) -> NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let components = calendar!.components([.Day, .Year, .Month, .Hour, .Minute, .Second], fromDate: date)
        components.timeZone = NSTimeZone(name: NSTimeZone.localTimeZone().abbreviation ?? "GMT")
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar!.dateFromComponents(components)!
    }
    
    func roundToPlaces(daoubleToRound: Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(daoubleToRound * divisor) / divisor
    }

    func selectColor(color: UIColor) -> UIColor {
        if CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.mutedExerciseColor.CGColor)
            || CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.exerciseColor.CGColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedExerciseColor : MetabolicDailyProgressChartView.exerciseColor
        }
        if CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.mutedSleepColor.CGColor)
            || CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.sleepColor.CGColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedSleepColor : MetabolicDailyProgressChartView.sleepColor
        }
        if CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.mutedEatingColor.CGColor)
            || CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.eatingColor.CGColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedEatingColor : MetabolicDailyProgressChartView.eatingColor
        }
        if CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.highlightFastingColor.CGColor)
            || CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.fastingColor.CGColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.highlightFastingColor : MetabolicDailyProgressChartView.fastingColor
        }
        return color
    }

    func toggleHighlightFasting() {
        self.highlightFasting = !self.highlightFasting
    }

    //MARK: Deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}