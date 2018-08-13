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
//import AwesomeCache
import MCCircadianQueries

@objc protocol DailyChartModelProtocol {
    @objc optional func dataCollectingFinished()
    @objc optional func dailyProgressStatCollected()
}

open class DailyProgressDayInfo: NSObject, CachableObject {
    
    static var dayColorsKey = "dayColors"
    static var dayValuesKey = "dayValues"
    
    internal var dayColors: [UIColor] = [UIColor.clear]
    internal var dayValues: [Double] = [24.0]
    
    override init() {
        super.init()
    }

    init(colors: [UIColor], values: [Double]) {
        self.dayColors = colors
        self.dayValues = values
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        guard let colors = aDecoder.decodeObject(forKey: DailyProgressDayInfo.dayColorsKey) as? [UIColor] else { return nil }
        guard let values = aDecoder.decodeObject(forKey: DailyProgressDayInfo.dayValuesKey) as? [Double] else { return nil }
        self.init(colors: colors, values: values)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(dayColors, forKey: DailyProgressDayInfo.dayColorsKey)
        aCoder.encode(dayValues, forKey: DailyProgressDayInfo.dayValuesKey)
    }
}

typealias MCDailyProgressCache = Cache<DailyProgressDayInfo>

open class DailyChartModel : NSObject, UITableViewDataSource {

    /// initializations of these variables creates offsets so plots of event transitions are square waves

    private let dayCellIdentifier = "dayCellIdentifier"
    private let emptyValueString = "- h - m"
    
    var cachedDailyProgress: MCDailyProgressCache
    
    var delegate:DailyChartModelProtocol? = nil
    var chartDataAndColors: [Date: [(Double, UIColor)]] = [:]
    var fastingText: String = ""
    var lastAteText: String = ""
    var eatingText: String = ""
    var daysTableView: UITableView?

    public var highlightFasting: Bool = false

    var chartDataArray: [[Double]] = []
    var chartColorsArray: [[UIColor]] = []

    override init() {
        do {
            self.cachedDailyProgress = try MCDailyProgressCache(name: "MCDaylyProgressCache")
        } catch _ {
            fatalError("Unable to create DailyChartModel circadian cache.")
        }
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.invalidateCache), name: NSNotification.Name(rawValue: HMDidUpdateCircadianEvents), object: nil)
    }
    
    var daysArray: [Date] = { return DailyChartModel.getChartDateRange() }()
    
    var daysStringArray: [String] = { return DailyChartModel.getChartDateRangeStrings() }()

    @objc public func invalidateCache(_ note: NSNotification) {
        if let info = note.userInfo, let dates = info[HMCircadianEventsDateUpdateKey] as? Set<Date> {
            if dates.count > 0 {
                for date in dates {
                    let cacheKey = "\(date.month)_\(date.day)_\(date.year)"
                    cachedDailyProgress.removeObject(forKey: cacheKey)
                }
                prepareChartData()
            }
        }
    }

    public func updateRowHeight (){
        self.daysTableView?.rowHeight = self.daysTableView!.frame.height/7.0
        self.daysTableView?.reloadData()
    }

    public func registerCells() {
        let dayCellNib = UINib(nibName: "DailyProgressDayTableViewCell", bundle: nil)
        self.daysTableView?.register(dayCellNib, forCellReuseIdentifier: dayCellIdentifier)
    }

    // MARK: -  UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.daysStringArray.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: dayCellIdentifier) as! DailyProgressDayTableViewCell
        cell.dayLabel.text = self.daysStringArray[indexPath.row]
        cell.dayLabel.textColor = indexPath.row == 0 ? UIColor.colorWithHexString(rgb: "#ffffff", alpha: 1) : UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)
        return cell
    }
    
    //MARK: Working with events data
    
    public func prepareChartData () {
        Async.main(after: 0.5) {
            self.chartDataAndColors = [:]
            self.delegate?.dataCollectingFinished?()
//            self.getDataForDay(day: nil, lastDay: false)
        }
    }

    open class func getChartDateRange(endDate: Date? = nil) -> [Date] {
        var lastSevenDays: [Date] = []
        var calendar = Calendar.current
        calendar.timeZone = .current
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate ?? Date())
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        for _ in 0...6 {
            let date = calendar.date(from: dateComponents)
            dateComponents.day = dateComponents.day! - 1
            if let date = date {
                lastSevenDays.append(date)
            }
        }
        return lastSevenDays.reversed()
    }

    open class func getChartDateRangeStrings(endDate: Date? = nil) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM\ndd"

        // Note: we reverse the strings array since days are from recent (top) to oldest (bottom)
        return getChartDateRange(endDate: endDate).map { date in
            let dateString = formatter.string(from: date)
            if date.day % 10 == 1 {
                if date.day == 11 {
                    return dateString.appending(" th")
                } else {
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

    public func getStartDate() -> Date? { return self.daysArray.first }
    public func getEndDate() -> Date? { return self.daysArray.last }

    public func setEndDate(_ endDate: Date? = nil) {
        self.daysArray = DailyChartModel.getChartDateRange(endDate: endDate)
        self.daysStringArray = DailyChartModel.getChartDateRangeStrings(endDate: endDate)
    }

    public func refreshChartDateRange(_ lastViewDate: Date?) {
        self.daysArray = DailyChartModel.getChartDateRange()
        self.daysStringArray = DailyChartModel.getChartDateRangeStrings()
    }

//    public func getDataForDay(day: Date?, lastDay:Bool) {
//        let startDay = day == nil ? self.daysArray.first! : day!
//        let today = startDay.isToday
//
//        let dateIndex = self.daysArray.index(of: startDay)
//        let cacheKey = "\(startDay.month)_\(startDay.day)_\(startDay.year)"
//        let cacheDuration = today ? 5.0 : 60.0 //if it's today we will add cache time for 10 seconds in other cases cache will be saved for 1 minute
//        self.cachedDailyProgress.setObject(forKey: cacheKey, cacheBlock: { (success, error) in
//            self.getCircadianEventsForDay(startDay, completion: { (dayInfo) in
//                success(dayInfo, .seconds(cacheDuration))
//            })
//        }, completion: { (dayInfoFromCache, loadedFromCache, error) in
//            if (dayInfoFromCache != nil) {
//                let dataAndColors = zip((dayInfoFromCache?.dayValues)!, (dayInfoFromCache?.dayColors)!).map { $0 }
//                self.chartDataAndColors[startDay] = dataAndColors
//            }
//            if !lastDay { //we still have data to retrieve
//                let nextIndex = dateIndex! + 1
//                let lastElement = nextIndex == (self.daysArray.count - 1)
//                OperationQueue.main.addOperation {
//                    self.getDataForDay(day: self.daysArray[nextIndex], lastDay: lastElement)
//                }
//            } else {//end of recursion
//                for (key, daysData) in self.chartDataAndColors {
//                    self.chartDataAndColors[key] = daysData.map { valAndColor in (valAndColor.0, self.selectColor(color: valAndColor.1)) }
//                }
//                OperationQueue.main.addOperation {
//                    self.delegate?.dataCollectingFinished?()
//                }
//            }
//        })
//    }
    
    public func getCircadianEventsForDay(_ day: Date, completion: @escaping (_ dayInfo: DailyProgressDayInfo) -> Void) {
        var endOfDay = day.endOfDay
        let dayPlus24 = (day.startOf(component: .day) + 24.hours) - 1.seconds

        // Force to 24 hours to handle time zone changes that result in a non-24hr day.
        if dayPlus24 != endOfDay { endOfDay = dayPlus24 }

        var dayEvents:[Double] = []
        var dayColors:[UIColor] = []
        var previousEventType: CircadianEvent?
        var previousEventDate: Date? = nil


        Async.userInteractive {
            MCHealthManager.sharedManager.fetchCircadianEventIntervals(day, endDate: endOfDay, completion: { (intervals, error) in
                guard error == nil else {
                    log.error("Failed to fetch circadian events: \(String(describing: error))")
                    return
                }
                self.fetchSamples() { [weak self] callbackIntervals in
                    if !callbackIntervals.isEmpty {
                        for event in callbackIntervals {
                            let (eventDate, eventType) = event //assign tuple values to vars
                            if endOfDay.day < eventDate.day {
                                if let prev = previousEventDate {
                                    let endEventDate = self?.endOfDay(prev)
                                    let eventDuration = self?.getDifferenceForEvents(prev, currentEventDate: endEventDate!)

                                    dayEvents.append(eventDuration!)
                                    dayColors.append((self?.getColorForEventType(eventType))!)
                                } else {
                                    log.warning("DCM NO PREV on \(intervals)")
                                }
                                break
                            }
                            if previousEventDate != nil && eventType == previousEventType {//we alredy have a prev event and can calculate how match time it took
                                let eventDuration = self?.getDifferenceForEvents(previousEventDate, currentEventDate: eventDate)

                                dayEvents.append(eventDuration!)
                                dayColors.append((self?.getColorForEventType(eventType))!)
                            }
                            previousEventDate = eventDate
                            previousEventType = eventType
                        }
                        let dayInfo = DailyProgressDayInfo(colors: dayColors, values: dayEvents)
                        completion(dayInfo)
                        return
                    }
                    completion(DailyProgressDayInfo(colors: [UIColor.clear], values: [24.0]))
                }
            })
        }
    }
    
    public func getDailyProgress() {
        /// Fetch all sleep and workout data since midnight and then calculate daily eating time.
        let startDate = Date().startOfDay
        let group = DispatchGroup()
        
        group.enter()
        Async.userInteractive {
            CircadianSamplesManager.sharedInstance.fetchCircadianSamples(startDate: startDate, endDate: Date()) {[weak self] (samples) in
                guard let `self` = self else {return}
                
                if samples.isEmpty {
                    self.eatingText = self.emptyValueString
                } else {
                    var eatingInterval : (Date, Date)? = nil
                    for sample in samples {
                        if case CircadianEvent.meal(_) = sample.event {
                            if let currentInterval = eatingInterval {
                                eatingInterval = (currentInterval.0, sample.endDate)
                            } else {
                                eatingInterval = (sample.startDate, sample.endDate)
                            }
                        }
                    }

                    self.eatingText = self.timeString(from: eatingInterval)
                    group.leave()
                }
            }
        }
        
        let weekAgo = Date(timeIntervalSinceNow: -60 * 60 * 24 * 7)
        
        group.enter()
        Async.userInteractive {
            CircadianSamplesManager.sharedInstance.fetchCircadianSamples(startDate: weekAgo, endDate: Date()) {[weak self] (samples) in
                guard let `self` = self else {return}
                if samples.isEmpty {
                    self.lastAteText = self.emptyValueString
                    self.fastingText = self.emptyValueString
                } else {
                    var lastEatingInterval : (Date, Date)? = nil
                    var maxFastingInterval : (Date, Date)? = nil
                    
                    var currentFastingIntreval : (Date, Date)? = nil
                    
                    for sample in samples {
                        if case CircadianEvent.meal(_) = sample.event {
                            if let currentFast = currentFastingIntreval {
                                currentFastingIntreval = (currentFast.0, sample.startDate)
                                if (CircadianSamplesManager.intervalDuration(from: currentFastingIntreval) > CircadianSamplesManager.intervalDuration(from: maxFastingInterval)) {
                                    maxFastingInterval = currentFastingIntreval
                                }
                                currentFastingIntreval = nil
                            }
                            
                            if let currentEatingInterval = lastEatingInterval {
                                if sample.endDate > currentEatingInterval.0 {
                                    lastEatingInterval = (sample.endDate, Date())
                                }
                            } else {
                                lastEatingInterval = (sample.endDate, Date())
                            }
                        } else {
                            if let currentFast = currentFastingIntreval {
                                currentFastingIntreval = (currentFast.0, sample.endDate)
                            } else {
                                currentFastingIntreval = (sample.startDate, sample.endDate)
                            }
                            if (CircadianSamplesManager.intervalDuration(from: currentFastingIntreval) > CircadianSamplesManager.intervalDuration(from: maxFastingInterval)) {
                                maxFastingInterval = currentFastingIntreval
                            }
                        }
                    }
                    
                    self.lastAteText = self.timeString(from: lastEatingInterval)
                    self.fastingText = self.timeString(from: maxFastingInterval)
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.delegate?.dailyProgressStatCollected?()
        }
    }    
    
    private func timeString(from dateInterval: (Date, Date)?) -> String {
        if let dateInterval = dateInterval {
            let timeInterval = Int(dateInterval.1.timeIntervalSince(dateInterval.0))
            let minutes = (timeInterval / 60) % 60
            let hours = (timeInterval / 3600)
            
            if hours == 0 && minutes == 0 {
                return self.emptyValueString
            } else {
                return String(format: "%02d h %02d m", hours, minutes)
            }
        } else {
            return self.emptyValueString
        }
    }
    
    public func getColorForEventType(_ eventType: CircadianEvent) -> UIColor {
        var eventColor: UIColor = MetabolicDailyProgressChartView.fastingColor
        switch eventType {
        case .exercise:
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.mutedExerciseColor : MetabolicDailyProgressChartView.exerciseColor
            break
        case .sleep :
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.mutedSleepColor : MetabolicDailyProgressChartView.sleepColor
            break
        case .meal :
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.mutedEatingColor : MetabolicDailyProgressChartView.eatingColor
            break
        default:
            eventColor = highlightFasting ? MetabolicDailyProgressChartView.highlightFastingColor : MetabolicDailyProgressChartView.fastingColor
        }
        return eventColor
    }
    
    //MARK: Working with date
    
    public func getDifferenceForEvents(_ previousEventDate: Date?, currentEventDate: Date) -> Double {
        var eventDuration = 0.0
        //if we have situation when event started at the end of the previos day and ended on next day
        let dateForCurrentEvent = currentEventDate.day > (previousEventDate?.day)! ? self.endOfDay(previousEventDate!) : currentEventDate
        let differenceComponets = Calendar.current.dateComponents([.hour, .minute], from: previousEventDate!, to: dateForCurrentEvent)
        let differenceMinutes = Double(differenceComponets.minute!)
        let minutes = Double(differenceMinutes / 60.0)//we need to devide by 60 because 60 is 100% (minutes in hour)
        if (differenceComponets.hour! > 0) { //more then 1h
            let hours = Double((differenceComponets.hour)!)
            eventDuration = hours + minutes
        } else { //less then 1h
            eventDuration = minutes
        }
        return self.roundToPlaces(eventDuration, places: 2)
    }
    
    public func endOfDay(_ date: Date) -> Date {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        var components = calendar!.components([.day, .year, .month, .hour, .minute, .second], from: date)
//        components.timeZone = NSTimeZone(name: NSTimeZone.localTimeZone.abbreviation)
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar!.date(from: components)!
    }
    
    public func roundToPlaces(_ daoubleToRound: Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(daoubleToRound * divisor) / divisor
    }

    public func selectColor(color: UIColor) -> UIColor {
//        if ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.mutedExerciseColor.cgColor)
        if color == MetabolicDailyProgressChartView.mutedExerciseColor
//            || ColorEqualToColor(color.cgColor, MetabolicDailyProgressChartView.exerciseColor.cgColor)
            || color == MetabolicDailyProgressChartView.exerciseColor
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedExerciseColor : MetabolicDailyProgressChartView.exerciseColor
        }
/*        if color == MetabolicDailyProgressChartView.mutedSleepColor
            || color == MetabolicDailyProgressChartView.sleepColor
        {
            return toggleHighlightFasting ? MetabolicDailyProgressChartView.mutedSleepColor : MetabolicDailyProgressChartView.sleepColor
        } */
        if color == MetabolicDailyProgressChartView.mutedEatingColor
            || color == MetabolicDailyProgressChartView.eatingColor
        {
            return highlightFasting ? MetabolicDailyProgressChartView.mutedEatingColor : MetabolicDailyProgressChartView.eatingColor
        }
        if color == MetabolicDailyProgressChartView.highlightFastingColor
            || color == MetabolicDailyProgressChartView.fastingColor
        {
            return highlightFasting ? MetabolicDailyProgressChartView.highlightFastingColor : MetabolicDailyProgressChartView.fastingColor
        }
        return color
    }

    open func toggleHighlightFasting() {
        highlightFasting = !highlightFasting
    }

    //MARK: Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func fetchSamples(completion: @escaping ([(Date, CircadianEvent)]) -> ()) {
        let healthStore = HKHealthStore()
        let now = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
        let components = calendar!.components([.day, .year, .month, .hour, .minute, .second], from: now)

        guard let endDate = calendar?.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }

        let startDate = calendar?.date(byAdding: .day, value: -7, to: endDate, options: [])
//        let sampleType = HKWorkoutType.workoutType()
        let sampleType = HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        var intervals:[(Date, CircadianEvent)] = []
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in

            guard let samples = results as? [MCSample] else {
                fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(error?.localizedDescription)");
            }

        intervals = samples.map{ sample in
                var event: CircadianEvent
                if sample.hkType?.identifier == "HKWorkoutTypeIdentifier" {
                    let type: HKWorkoutActivityType = .preparationAndRecovery
                    event = .exercise(exerciseType:type)
                } else {
                    event = .sleep
                }
                return (sample.startDate, event)
            }
            completion (intervals)
        }
        healthStore.execute(query)
    }


    func prepareDataForChart(completion: @escaping ([Date: [(Double, UIColor)]]) -> ()) {
        var dict: [Date: [(Double, UIColor)]] = [:]
        let group = DispatchGroup()
        self.daysArray.forEach{ day in
            let startDate = day.startOfDay
            let endDate = day.endOfDay
            group.enter()
            
            CircadianSamplesManager.sharedInstance.fetchCircadianSamples(startDate: startDate, endDate: endDate, completion: { (circadianSamples) in
                dict[day] = circadianSamples.map  {sample in
                    return (sample.duration, self.getColorForEventType(sample.event))
                }
                group.leave()
            })
        }

        group.notify(queue: .main) {
           completion(dict)
        }
    }
}


