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

@objc protocol DailyChartModelProtocol {
    optional func dataCollectingFinished()
    optional func dailyProgressStatCollected()
}

class DailyChartModel : NSObject, UITableViewDataSource {
    /// initializations of these variables creates offsets so plots of event transitions are square waves
    private let stWorkout = 0.0
    private let stSleep = 0.33
    private let stFast = 0.66
    private let stEat = 1.0

    private let dayCellIdentifier = "dayCellIdentifier"
    private let emptyValueString = "- h - m"
    
    var delegate:DailyChartModelProtocol? = nil
    var chartDataArray: [[Double]] = []
    var chartColorsArray: [[UIColor]] = []
    var fastingText: String = ""
    var lastAteText: String = ""
    var eatingText: String = ""
    var daysTableView: UITableView?
    
    var daysArray: [NSDate] = {
        var lastSevenDays: [NSDate] = []
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let dateComponents = calendar!.components([.Day, .Month, .Year, .Hour, .Minute, .Second] , fromDate: NSDate())
        dateComponents.timeZone = NSTimeZone(name: NSTimeZone.localTimeZone().abbreviation ?? "GMT")
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        for _ in 0...6 {
            let date = calendar!.dateFromComponents(dateComponents)
            dateComponents.day -= 1;
            if let date = date {
                lastSevenDays.append(date)
            }
        }
        return lastSevenDays.reverse()
    }()
    
    var daysStringArray: [String] = {
        var lastSevenDays: [String] = []
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM\ndd"
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let dateComponents = calendar.components([.Day, .Month] , fromDate: NSDate())
        for _ in 0...6 {
            let date = calendar.dateFromComponents(dateComponents)
            dateComponents.day -= 1;
            if let date = date {
                let dateString = formatter.stringFromDate(date)
                lastSevenDays.append(dateString.stringByAppendingString(" th"))
            }
        }
        return lastSevenDays
    }()

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
        Async.main(after: 0.5) {
            self.chartDataArray = []
            self.chartColorsArray = []
            self.getDataForDay(nil, lastDay: false)
        }
    }
    
    func getDataForDay(day: NSDate?, lastDay:Bool) {
        let startDay = day == nil ? self.daysArray.first! : day!
//        print("===================================")
//        print("getDataForDay \(startDay)")
        let dateIndex = self.daysArray.indexOf(startDay)
        let endOfDay = self.endOfDay(startDay)
        var dayEvents:[Double] = []
        var dayColors:[UIColor] = []
        var previousEventType: CircadianEvent?
        var previousEventDate: NSDate? = nil
        HealthManager.sharedManager.fetchCircadianEventIntervals(startDay, endDate: endOfDay, completion: { (intervals, error) in
//            print("fetchCircadianEventIntervals - \(startDay) - \(endOfDay)")
            guard error == nil else {
                log.error("Failed to fetch circadian events: \(error)")
                return
            }
            if intervals.isEmpty {//we have no data to display
                //we will mark it as fasting and put 24h
                dayEvents.append(24.0)
                dayColors.append(UIColor.clearColor())
            } else {
                for event in intervals {
                    let (eventDate, eventType) = event //assign tuple values to vars
                    if endOfDay.day < eventDate.day {
                        print(previousEventDate)
                        let endEventDate = self.endOfDay(previousEventDate!)
                        let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: endEventDate)
//                        print("\(eventType) - \(eventDuration)")
                        dayEvents.append(eventDuration)
                        dayColors.append(self.getColorForEventType(eventType))
                        break
                    }
                    if previousEventDate != nil && eventType == previousEventType {//we alredy have a prev event and can calculate how match time it took
                        let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: eventDate)
//                        print("\(eventType) - \(eventDuration)")
                        dayEvents.append(eventDuration)
                        dayColors.append(self.getColorForEventType(eventType))
                    }
                    previousEventDate = eventDate
                    previousEventType = eventType
                }
            }
            let lastElement = dateIndex == (self.daysArray.indexOf(self.daysArray.last!)! - 1)
            self.chartDataArray.append(dayEvents)
            self.chartColorsArray.append(dayColors)
            if !lastDay {//we still have data te retrive
                self.getDataForDay(self.daysArray[dateIndex!+1], lastDay: lastElement)
            } else {//end of recursion
                Async.main {
                    self.delegate?.dataCollectingFinished?()
                }
            }
        })
    }
    
    func getDailyProgress() {
        typealias Event = (NSDate, Double)
        typealias IEvent = (Double, Double)
        
        /// Fetch all sleep and workout data since yesterday, and then aggregate sleep, exercise and meal events.
        let yesterday = 1.days.ago
        let startDate = yesterday
        
        HealthManager.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
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
                    let fastingHrs = Int(floor(stats.2))
                    let fastingMins = (today + Int(round((stats.2 % 1.0) * 60.0)).minutes).toString(DateFormat.Custom("mm"))!
    
                    self.fastingText = "\(fastingHrs) h \(fastingMins) m"
                    let eatingTime = (today + Int(stats.0 * 3600.0).seconds)
                    if eatingTime.hour == 0 && eatingTime.minute == 0 {
                        self.eatingText = self.emptyValueString
                    } else {
                        self.eatingText = eatingTime.toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                    }

                    self.lastAteText = lastAte == nil ? self.emptyValueString : lastAte!.toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                    self.delegate?.dailyProgressStatCollected?()
                }
            }
        }
    }
    
    func getColorForEventType(eventType: CircadianEvent) -> UIColor {
        var eventColor: UIColor = MetabolicDailyPorgressChartView.fastingColor
        switch eventType {
        case .Exercise:
            eventColor = MetabolicDailyPorgressChartView.exerciseColor
            break
        case .Sleep :
            eventColor = MetabolicDailyPorgressChartView.sleepColor
            break
        case .Meal :
            eventColor = MetabolicDailyPorgressChartView.eatingColor
            break
        default:
            eventColor = MetabolicDailyPorgressChartView.fastingColor
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
}