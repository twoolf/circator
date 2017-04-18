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
    @objc optional func dataCollectingFinished()
    @objc optional func dailyProgressStatCollected()
}

class DailyProgressDayInfo: NSObject, NSCoding {
    
    static var dayColorsKey = "dayColors"
    static var dayValuesKey = "dayValues"
    
    internal var dayColors: [UIColor] = [UIColor.clear]
    internal var dayValues: [Double] = [24.0]
    
    init(colors: [UIColor], values: [Double]) {
        self.dayColors = colors
        self.dayValues = values
    }
    
    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let colors = aDecoder.decodeObject(forKey: DailyProgressDayInfo.dayColorsKey) as? [UIColor] else { return nil }
        guard let values = aDecoder.decodeObject(forKey: DailyProgressDayInfo.dayValuesKey) as? [Double] else { return nil }
        self.init(colors: colors, values: values)
    }
    
    internal func encode(with aCoder: NSCoder) {
        aCoder.encode(dayColors, forKey: DailyProgressDayInfo.dayColorsKey)
        aCoder.encode(dayValues, forKey: DailyProgressDayInfo.dayValuesKey)
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
    var chartDataAndColors: [Date: [(Double, UIColor)]] = [:]
    var fastingText: String = ""
    var lastAteText: String = ""
    var eatingText: String = ""
    var daysTableView: UITableView?

    var highlightFasting: Bool = false

    override init() {
        do {
            self.cachedDailyProgress = try MCDailyProgressCache(name: "MCDaylyProgressCache")
        } catch _ {
            fatalError("Unable to create DailyChartModel circadian cache.")
        }
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(invalidateCache), name: NSNotification.Name(rawValue: HMDidUpdateCircadianEvents), object: nil)
    }
    
    var daysArray: [Date] = { return DailyChartModel.getChartDateRange() }()
    
    var daysStringArray: [String] = { return DailyChartModel.getChartDateRangeStrings() }()

    func invalidateCache(note: NSNotification) {
        if let info = note.userInfo, let dates = info[HMCircadianEventsDateUpdateKey] as? Set<Date> {
            if dates.count > 0 {
                for date in dates {
                    let cacheKey = "\(date.month)_\(date.day)_\(date.year)"
                    log.debug("Invalidating daily progress cache for \(cacheKey)", feature: "invalidateCache")
                    cachedDailyProgress.removeObject(forKey: cacheKey)
                }
                prepareChartData()
            }
        }
    }

    func updateRowHeight (){
        self.daysTableView?.rowHeight = self.daysTableView!.frame.height/7.0
        self.daysTableView?.reloadData()
    }

    func registerCells() {
        let dayCellNib = UINib(nibName: "DailyProgressDayTableViewCell", bundle: nil)
        self.daysTableView?.register(dayCellNib, forCellReuseIdentifier: dayCellIdentifier)
    }

    // MARK: -  UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.daysStringArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: dayCellIdentifier) as! DailyProgressDayTableViewCell
        cell.dayLabel.text = self.daysStringArray[indexPath.row]
        cell.dayLabel.textColor = indexPath.row == 0 ? UIColor.colorWithHexString(rgb: "#ffffff", alpha: 1) : UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)
        return cell
    }
    
    //MARK: Working with events data
    
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
    
    func prepareChartData () {
        log.debug("Resetting chart data with \(self.chartDataAndColors.count) values", feature: "prepareChart")
        self.chartDataAndColors = [:]
        getDataForDay(day: nil, lastDay: false)
        
    }

    class func getChartDateRange(endDate: Date? = nil) -> [Date] {
        var lastSevenDays: [Date] = []
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
//        let dateComponents = (endDate ?? Date()).startOf(component: .day).components
        let dateComponents = DateComponents().
        for _ in 0...6 {
            let date = calendar!.dateFromComponents(dateComponents)
            dateComponents.day -= 1;
            if let date = date {
                lastSevenDays.append(date)
            }
        }
        return lastSevenDays.reversed()
    }

    class func getChartDateRangeStrings(endDate: Date? = nil) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM\ndd"

        // Note: we reverse the strings array since days are from recent (top) to oldest (bottom)
        return getChartDateRange(endDate: endDate).map { date in
            let dateString = formatter.string(from: date)
            if date.day % 10 == 1 {
                if date.day == 11 {
//                    return dateString.stringByAppendingString(" th")
                    return dateString.appending(" th")
                } else {
//                    return dateString.stringByAppendingString(" st")
                  return dateString.appending(" st")
                }
            } else if date.day % 10 == 2 {
                if date.day == 12 {
                    return dateString.appending(" th")
                } else {
                    return dateString.appending(" nd")
                }
            } else if date.day % 10 == 3 {
                if date.day == 13 {
                    return dateString.appending(" th")
                } else {
                    return dateString.appending(" rd")
                }
            } else {
                return dateString.appending(" th")
            }
        }.reversed()
    }

    func getStartDate() -> Date? { return self.daysArray.first }
    func getEndDate() -> Date? { return self.daysArray.last }

    func setEndDate(endDate: Date? = nil) {
        self.daysArray = DailyChartModel.getChartDateRange(endDate: endDate)
        self.daysStringArray = DailyChartModel.getChartDateRangeStrings(endDate: endDate)
    }

    func refreshChartDateRange(lastViewDate: Date?) {
        let now = Date()
        if let last = lastViewDate, let end = getEndDate(), last.isInSameDayAsDate(end) && !last.
            self.daysArray = DailyChartModel.getChartDateRange()
            self.daysStringArray = DailyChartModel.getChartDateRangeStrings()
        }
    }

    func getDataForDay(day: Date?, lastDay:Bool) {
        let startDay = day == nil ? self.daysArray.first! : day!
//        let today = startDay.isInToday()
        let today = startDay.isToday

        let dateIndex = self.daysArray.index(of: startDay)
        let cacheKey = "\(startDay.month)_\(startDay.day)_\(startDay.year)"
        let cacheDuration = today ? 5.0 : 60.0 //if it's today we will add cache time for 10 seconds in other cases cache will be saved for 1 minute

//        self.cachedDailyProgress.setObjectForKey(cacheKey, cacheBlock: { (success, error) in
        self.cachedDailyProgress.setObject(forKey: cacheKey, cacheBlock: { (success, error) in
            self.getCircadianEventsForDay(day: startDay, completion: { (dayInfo) in
                success(dayInfo, .seconds(cacheDuration))
            })
        }, completion: { (dayInfoFromCache, loadedFromCache, error) in
            if (dayInfoFromCache != nil) {
                let dataAndColors = zip((dayInfoFromCache?.dayValues)!, (dayInfoFromCache?.dayColors)!).map { $0 }
                self.chartDataAndColors[startDay] = dataAndColors
            }
            if !lastDay { //we still have data to retrieve
                let nextIndex = dateIndex! + 1
                let lastElement = nextIndex == (self.daysArray.count - 1)
                Async.main {
                    self.getDataForDay(self.daysArray[nextIndex], lastDay: lastElement)
                }
            } else {//end of recursion
                for (key, daysData) in self.chartDataAndColors {
                    self.chartDataAndColors[key] = daysData.map { valAndColor in (valAndColor.0, self.selectColor(valAndColor.1)) }
                }

                Async.main {
                    self.delegate?.dataCollectingFinished?()
                }
            }
        })
    }
    
    func getCircadianEventsForDay(day: Date, completion: @escaping (_ dayInfo: DailyProgressDayInfo) -> Void) {
        
//        var endOfDay = date.endOfDay(date: day)
        var endOfDay = Date().endOfDay
        let dayPlus24 = (day.startOf(component: .day) + 24.hours) - 1.seconds

        // Force to 24 hours to handle time zone changes that result in a non-24hr day.
        if dayPlus24 != endOfDay { endOfDay = dayPlus24 }

        var dayEvents:[Double] = []
        var dayColors:[UIColor] = []
        var previousEventType: CircadianEvent?
        var previousEventDate: Date? = nil

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
                            if let prev = previousEventDate {
                                let endEventDate = self.endOfDay(prev)
                                let eventDuration = self.getDifferenceForEvents(prev, currentEventDate: endEventDate)

                                dayEvents.append(eventDuration)
                                dayColors.append(self.getColorForEventType(eventType))
                            } else {
                                log.warning("DCM NO PREV on \(intervals)")
                            }
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
                completion(DailyProgressDayInfo(colors: [UIColor.clearColor()], values: [24.0]))
            })
        }
    }
    
    func getDailyProgress() {
        typealias Event = (Date, Double)
        typealias IEvent = (Double, Double)
        
        /// Fetch all sleep and workout data since yesterday, and then aggregate sleep, exercise and meal events. 
//        let yesterday = 1.days.ago
        let yesterday = Date(timeIntervalSinceNow: -60 * 60 * 24)
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
                        let initialAccumulator : (Double, Double, Double, IEvent?, Bool, Double, Bool) =
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

//                        let today = Date().startOf(.Day, inRegion: Region()) 
                        let today = Date()
                        let lastAte : Date? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds)

                        let eatingTime = roundDate((today + Int(stats.0 * 3600.0).seconds), granularity: granularity1Min)
                        if eatingTime.hour == 0 && eatingTime.minute == 0 {
                            eatingTime = emptyValueString
                        } else {
                            eatingText = eatingTime.toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                        }

                        let fastingHrs = Int(floor(stats.2))
                        let fastingMins = (today + Int(round((stats.2 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
                        fastingText = "\(fastingHrs) h \(fastingMins) m"

                        if let lastAte = lastAte {
                            let components = Date().components - lastAte.components
                            if components.day > 0 {
                                let mins = (today + components.minute.minutes).toString(DateFormat.Custom("mm 'm'"))!
                                lastAteText = "\(components.day * 24 + components.hour) h \(mins)"
                            } else {
                                lastAteText = (today + components).toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                            }
                        } else {
                            lastAteText = emptyValueString
                        }
                        
                        delegate?.dailyProgressStatCollected?()
                    }
                }
            }
        }
    }
    
    func getColorForEventType(eventType: CircadianEvent) -> UIColor {
        var eventColor: UIColor = MetabolicDailyProgressChartView.fastingColor
        switch eventType {
        case .exercise:
            eventColor = toggleHighlightFasting ? MetabolicDailyProgressChartView.mutedExerciseColor : MetabolicDailyProgressChartView.exerciseColor
            break
        case .sleep :
            eventColor = toggleHighlightFasting ? MetabolicDailyProgressChartView.mutedSleepColor : MetabolicDailyProgressChartView.sleepColor
            break
        case .meal :
            eventColor = toggleHighlightFasting ? MetabolicDailyProgressChartView.mutedEatingColor : MetabolicDailyProgressChartView.eatingColor
            break
        default:
            eventColor = toggleHighlightFasting ? MetabolicDailyProgressChartView.highlightFastingColor : MetabolicDailyProgressChartView.fastingColor
        }
        return eventColor
    }
    
    //MARK: Working with date
    
    func getDifferenceForEvents(previousEventDate:Date?, currentEventDate: Date) -> Double {
        var eventDuration = 0.0
        //if we have situation when event started at the end of the previos day and ended on next day
        let dateForCurrentEvent = currentEventDate.day > (previousEventDate?.day)! ? self.endOfDay(previousEventDate!) : currentEventDate
        let differenceComponets = previousEventDate?.difference(dateForCurrentEvent, unitFlags: [.Hour, .Minute])
        let differenceMinutes = Double((differenceComponets?.minute)!)
        let minutes = Double(differenceMinutes / 60.0)//we need to devide by 60 because 60 is 100% (minutes in hour)
        if (differenceComponets?.hour > 0) {//more then 1h
            let hours = Double((differenceComponets?.hour)!)
            eventDuration = hours + minutes
        } else {//less then 1h
            eventDuration = minutes
        }
        return self.roundToPlaces(daoubleToRound: eventDuration, places: 2)
    }
    
    func endOfDay(date: Date) -> Date {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        var components = calendar!.components([.day, .year, .month, .hour, .minute, .second], from: date)
        components.timeZone = NSTimeZone(name: NSTimeZone.localTimeZone().abbreviation ?? "GMT")
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar!.date(from: components)!
    }
    
    func roundToPlaces(daoubleToRound: Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(daoubleToRound * divisor) / divisor
    }

    func selectColor(color: UIColor) -> UIColor {
        if CGColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.mutedExerciseColor.cgColor)
            || CGColorEqualToColor(color.CGColor, MetabolicDailyProgressChartView.exerciseColor.cgColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedExerciseColor : MetabolicDailyProgressChartView.exerciseColor
        }
        if ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.mutedSleepColor.cgColor)
            || cgColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.sleepColor.cgColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedSleepColor : MetabolicDailyProgressChartView.sleepColor
        }
        if ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.mutedEatingColor.cgColor)
            || ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.eatingColor.cgColor)
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedEatingColor : MetabolicDailyProgressChartView.eatingColor
        }
        if ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.highlightFastingColor.cgColor)
            || ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.fastingColor.cgColor)
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
        NotificationCenter.defaultCenter().removeObserver(self)
    }
}
