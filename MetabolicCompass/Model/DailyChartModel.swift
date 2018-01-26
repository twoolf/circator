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

open class DailyProgressDayInfo: NSObject, NSCoding {
    
    static var dayColorsKey = "dayColors"
    static var dayValuesKey = "dayValues"
    
    internal var dayColors: [UIColor] = [UIColor.clear]
    internal var dayValues: [Double] = [24.0]

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
    
    public func valueOfCircadianEvent(_ e: CircadianEvent) -> Double {
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
    
    public func prepareChartData () {
        Async.main(after: 0.5) {
            self.chartDataAndColors = [:]
            self.getDataForDay(day: nil, lastDay: false)
        }
    }

    open class func getChartDateRange(endDate: Date? = nil) -> [Date] {
        var lastSevenDays: [Date] = []
        var calendar = Calendar.current
        calendar.timeZone = .current
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
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

    public func getDataForDay(day: Date?, lastDay:Bool) {
//        let startDay = day == nil ? self.daysArray.first! : day!
//        let dateIndex = self.daysArray.index(of: startDay)
//        let endOfDay = self.endOfDay(startDay)
//        var dayEvents:[Double] = []
//        var dayColors:[UIColor] = []
//        var previousEventType: CircadianEvent?
//        var previousEventDate: Date? = nil
//        MCHealthManager.sharedManager.fetchCircadianEventIntervals(startDay, endDate: endOfDay, completion: { (intervals, error) in
//            guard error == nil else {
//                log.error("Failed to fetch circadian events: \(error)")
//                return
//            }
//            if intervals.isEmpty {//we have no data to display
//                //we will mark it as fasting and put 24h
//                dayEvents.append(24.0)
//                dayColors.append(UIColor.clear)
//            } else {
//                for event in intervals {
//                    let (eventDate, eventType) = event //assign tuple values to vars
//                    if endOfDay.day < eventDate.day {
//                        print(previousEventDate)
//                        let endEventDate = self.endOfDay(previousEventDate!)
//                        let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: endEventDate)
//                        //                        print("\(eventType) - \(eventDuration)")
//                        dayEvents.append(eventDuration)
//                        dayColors.append(self.getColorForEventType(eventType))
//                        break
//                    }
//                    if previousEventDate != nil && eventType == previousEventType {//we alredy have a prev event and can calculate how match time it took
//                        let eventDuration = self.getDifferenceForEvents(previousEventDate, currentEventDate: eventDate)
//                        //                        print("\(eventType) - \(eventDuration)")
//                        dayEvents.append(eventDuration)
//                        dayColors.append(self.getColorForEventType(eventType))
//                    }
//                    previousEventDate = eventDate
//                    previousEventType = eventType
//                }
//            }
//            let lastElement = dateIndex == (self.daysArray.index(of: self.daysArray.last!)! - 1)
//            self.chartDataArray.append(dayEvents)
//            self.chartColorsArray.append(dayColors)
//            if !lastDay {//we still have data te retrive
//                self.getDataForDay(day: self.daysArray[dateIndex!+1], lastDay: lastElement)
//            } else {//end of recursion
//                Async.main {
//                    self.delegate?.dataCollectingFinished?()
//                }
//            }
//        })

        let startDay = day == nil ? self.daysArray.first! : day!
        let today = startDay.isToday

        let dateIndex = self.daysArray.index(of: startDay)
        let cacheKey = "\(startDay.month)_\(startDay.day)_\(startDay.year)"
        let cacheDuration = today ? 5.0 : 60.0 //if it's today we will add cache time for 10 seconds in other cases cache will be saved for 1 minute
        self.cachedDailyProgress.setObject(forKey: cacheKey, cacheBlock: { (success, error) in
            self.getCircadianEventsForDay(startDay, completion: { (dayInfo) in
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
                OperationQueue.main.addOperation {
                    self.getDataForDay(day: self.daysArray[nextIndex], lastDay: lastElement)
                }
            } else {//end of recursion
                for (key, daysData) in self.chartDataAndColors {
                    self.chartDataAndColors[key] = daysData.map { valAndColor in (valAndColor.0, self.selectColor(color: valAndColor.1)) }
                }
                OperationQueue.main.addOperation {
                    self.delegate?.dataCollectingFinished?()
                }
            }
        })
    }
    
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
                    log.error("Failed to fetch circadian events: \(error)")
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
        typealias Event = (Date, Double)
        typealias IEvent = (Double, Double)
        
        /// Fetch all sleep and workout data since yesterday, and then aggregate sleep, exercise and meal events.
        let yesterday = Date(timeIntervalSinceNow: -60 * 60 * 24)
        let startDate = yesterday

        Async.userInteractive {
            MCHealthManager.sharedManager.fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
                Async.main {
                    guard error == nil else {
                        log.error("Failed to fetch circadian events: \(error ?? (no_argument as AnyObject) as! Error)")
                        return
                    }
                    var fetchIntervals:[(Date, CircadianEvent)] = []
                    self.fetchSamples() { [weak self] callbackIntervals in
                        fetchIntervals = callbackIntervals
                        if fetchIntervals.isEmpty {
                            self?.fastingText = (self?.emptyValueString)!
                            self?.eatingText = (self?.emptyValueString)!
                            self?.lastAteText = (self?.emptyValueString)!
                            self?.delegate?.dailyProgressStatCollected?()
                        } else {
                            let vals : [(x: Double, y: Double)] = fetchIntervals.map { event in
                                let date =  event.0
                                let start = date.startOfDay
                                let startTimeInFractionalHours = event.0.timeIntervalSince(start) / 3600.0
                                let metabolicStateAsDouble = self?.valueOfCircadianEvent(event.1)
                                return (x: startTimeInFractionalHours , y: Double(metabolicStateAsDouble!))
                            }

                            let initialAccumulator : (Double, Double, Double, IEvent?, Bool, Double, Bool) =
                                (0.0, 0.0, 0.0, nil, true, 0.0, false)

                            let stats = vals.filter { $0.0 >= yesterday.julianDay} .reduce(initialAccumulator, { (acc, event) in
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
                                let isFasting = eventMetabolicState != self?.stEat

                                // If this endpoint starts a new event interval, update the accumulator.
                                if prevEndpointWasIntervalEnd {
                                    let prevEventEndpointDate = prevEvent?.0
                                    let duration = eventEndpointDate - prevEventEndpointDate!

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

                                    } else if eventMetabolicState == self?.stEat {
                                        // Otherwise if we are eating, we increment the total time spent eating.
                                        newEatingTime += duration
                                    }
                                } else {
                                    prevStateWasFasting = prevEvent == nil ? false : prevEvent?.1 != self?.stEat
                                }

                                let newLastEatingTime = eventMetabolicState == self?.stEat ? eventEndpointDate : lastEatingTime

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
                            let today = Date()
                            let lastAte : Date? = stats.1 == 0 ? nil : ( startDate + Int(round(stats.1 * 3600.0)).seconds)

                            let eatingTime = roundDate(date: (today + Int(stats.0 * 3600.0).seconds), granularity: granularity1Min)
                            if eatingTime.hour == 0 && eatingTime.minute == 0 {
                                self?.eatingText = (self?.emptyValueString)!
                            } else {
                                self?.eatingText = eatingTime.string(format: DateFormat.custom("HH 'h' mm 'm'"))
                            }

                            let fastingHrs = Int(floor(stats.2))
                            let fastingMins = (today + Int(round((stats.2) * 60.0)).minutes).string(format: DateFormat.custom("mm"))
                            _ = "\(fastingHrs) h \(fastingMins) m"

                            if let lastAte = lastAte {
                                let components = DateComponents().ago(from: lastAte)!
                                if components.day > 0 {
                                    let mins = (today + components.minute.minutes).string()
                                    self?.lastAteText = "\(components.day * 24 + components.hour) h \(mins)"
                                } else {
                                    //                                self.lastAteText = (today + components).toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                                    //                                self.lastAteText = (today).toString(DateFormat.Custom("HH 'h' mm 'm'"))!
                                }
                            } else {
                                self?.lastAteText = (self?.emptyValueString)!
                            }
                            self?.delegate?.dailyProgressStatCollected?()
                        }
                    }

                }
            }
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
  //      let sampleType = HKWorkoutType.workoutType()
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

    func fetchMCSamples(startDate: Date, endDate:Date, completion: @escaping ([MCSample]) -> ()) {
        var allSamples: ([MCSample]) = []
        let healthStore = HKHealthStore()
        let sleepType = HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let workoutType = HKWorkoutType.workoutType()
        let sampleTypes = [sleepType, workoutType]
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let group = DispatchGroup()
        sampleTypes.forEach{ type in
            group.enter()
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
                query, results, error in
                guard let samples = results as? [MCSample] else {
                    fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(error?.localizedDescription)");
                }
                allSamples = allSamples + samples
                group.leave()
            }
            healthStore.execute(query)
        }

        group.notify(queue: .main) {
            completion(allSamples)
        }
    }

    func prepareDataForChart(completion: @escaping ([Date: [(Double, UIColor)]]) -> ()) {
        var dict: [Date: [(Double, UIColor)]] = [:]
        let group = DispatchGroup()
        self.daysArray.forEach{ day in
            let startDate = day.startOfDay
            let endDate = day.endOfDay
            group.enter()
            self.fetchMCSamples(startDate: startDate, endDate: endDate)  { samples in
                var values: [(Double, UIColor)] = []
                values = samples.map  {sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    var color = UIColor.clear
                    if sample.hkType?.identifier == HKWorkoutType.workoutType().identifier {
                        if let workoutType = sample as? HKWorkout {
                            if workoutType.metadata?["Meal Type"] != nil {
                                color = .red
                            } else {
                                color = .green
                            }
                        }
                    } else {
                        color = .blue
                    }
                     return (duration, color)
                }
                dict[day] = values
                group.leave()
            }
        }

        group.notify(queue: .main) {
           completion(dict)
        }

    }
}

