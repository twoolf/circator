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

class DailyChartModel : NSObject, UITableViewDataSource {
    /// initializations of these variables creates offsets so plots of event transitions are square waves
    private let stWorkout = 0.0
    private let stSleep = 0.33
    private let stFast = 0.66
    private let stEat = 1.0
    
    private let dayCellIdentifier = "dayCellIdentifier"
    
    var daysTableView: UITableView?
    
    var daysArray: [NSDate] = {
        var lastSevenDays: [NSDate] = []
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let dateComponents = calendar!.components([.Day, .Month, .Year, .Hour, .Minute, .Second] , fromDate: NSDate())
        dateComponents.timeZone = NSTimeZone(name: "GMT")
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
        return lastSevenDays
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
    
    //MARK: UITableViewDataSource
    
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
        var chartDataArray: [[(Double, UIColor)]] = []
        

        Async.background(after: 1) {
            for startOfDay in self.daysArray {
                let endOfDay = self.endOfDay(startOfDay)
                var dayEvents:[(Double, UIColor)] = []
                var previousEventType: CircadianEvent?
                var previousEventDate: NSDate? = nil
                print ("main for _ \(startOfDay) - \(endOfDay)")
                HealthManager.sharedManager.fetchCircadianEventIntervals(startOfDay, endDate: endOfDay, completion: { (intervals, error) in
                    print ("events hadler _ \(startOfDay) - \(endOfDay)")
                    guard error == nil else {
                        log.error("Failed to fetch circadian events: \(error)")
                        return
                    }
                    if intervals.isEmpty {//we have no data to display
                        //we will mark it as fasting and put 24h
                        dayEvents.append((24.0, MetabolicDailyPorgressChartView.fastingColor))
                    } else {
                        for event in intervals {
                            let (eventDate, eventType) = event //assign tuple values to vars
                            if previousEventDate != nil && eventType == previousEventType {//we alredy have a prev event and can calculate how match time it took
                                let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: eventDate)
                                print(eventDuration)
                                dayEvents.append(eventDuration, self.getColorForEventType(eventType))
                            }
                            previousEventDate = eventDate
                            previousEventType = eventType
                        }
                    }
//                    print(dayEvents)
                    print("-----------------------------------")
                    chartDataArray.append(dayEvents)
                })
            }
            Async.main {
//                print(chartDataArray)
            }
        }
    }
    
    func getDifferenceForEvents(previousEventDate:NSDate?, currentEventDate: NSDate) -> Double {
        var eventDuration = 0.0
        let differenceComponets = previousEventDate?.difference(currentEventDate, unitFlags: [.Hour, .Minute])
        let differenceMinutes = Double((differenceComponets?.minute)!)
        let minutes = Double(differenceMinutes / 60.0)//we need to devide by 60 because 60 is 100% (minutes in hour)
        if (differenceComponets?.hour > 0) {//more then 1h
            let hours = Double((differenceComponets?.hour)!)
            eventDuration = hours + minutes
        } else {//less then 1h
            eventDuration = minutes
        }
        return eventDuration
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
        default:
            eventColor = MetabolicDailyPorgressChartView.fastingColor
        }
        return eventColor
    }
    
    //MARK: Working with date
    
    func endOfDay(date: NSDate) -> NSDate {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let components = calendar!.components([.Day, .Year, .Month, .Hour, .Minute, .Second], fromDate: date)
        components.timeZone = NSTimeZone(name: "GMT")
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar!.dateFromComponents(components)!
    }
}