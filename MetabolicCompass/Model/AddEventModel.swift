//
//  AddEventModel.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/7/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import SwiftDate
import MetabolicCompassKit
import HealthKit
import MCCircadianQueries

let defaultDuration = 1800 // Default event duration is 30 min

class AddEventModel: NSObject {

    var dataWasChanged = false
    var delegate: AddEventModelDelegate? = nil
    var datePickerTags:[Int] = [2]  //default date picker row
    var countDownPickerTags: [Int] = [3,4] //default count down pickecr rows for meal screen

    var duration: TimeInterval = Double(defaultDuration) {
        didSet {
            dataWasChanged = true
        }
    }

    var eventDate: Date = floorDate(date: Date(), granularity: granularity5Mins) - defaultDuration.seconds {//default is current date
        didSet {
            dataWasChanged = true
        }
    }
    
    var mealType: MealType = .Empty {
        didSet {
            if let mealUsualDate = UserManager.sharedManager.getUsualMealTime(mealType: mealType.rawValue) {//if we have usual event date we should prefill it for user
                eventDate = AddEventModel.applyTimeForDate(fromDate: mealUsualDate, toDate: eventDate)
            } else {//reset event date to the default state. Current date
                //it works in case when user selected event with existing usual time and then changed meal type
                eventDate = floorDate(date: Date(), granularity: granularity5Mins)
            }
        }
    }
    
    var sleepStartDate: Date = AddEventModel.getDefaultStartSleepDate() {
        didSet {
            dataWasChanged = true
            self.delegate?.sleepTimeUpdated(updatedTime: getSleepTimeString())
        }
    }
    
    var sleepEndDate: Date =  AddEventModel.getDefaultWokeUpDate() {
        didSet {
            dataWasChanged = true
            self.delegate?.sleepTimeUpdated(updatedTime: getSleepTimeString())
        }
    }

    func getSleepTimeString () -> NSAttributedString {
        let dayHourMinuteSecond: NSCalendar.Unit = [.hour, .minute]
        let difference = NSCalendar.currentCalendar.components([.year, .month, .day, .hour, .minute], fromDate: sleepStartDate, toDate: sleepEndDate, options: [])
        let hour = difference.hour < 0 ? 0 : difference.hour
        let minutes = difference.minute < 0 ? 0 : difference.minute
        let minutesSting = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let stringDifference = "\(hour)h \(minutesSting)m"
        let defaultFont = ScreenManager.appFontOfSize(size: 24)
        let formatFont = ScreenManager.appFontOfSize(size: 15)
        let attributedString = stringDifference.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                    format: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName : defaultFont],
                                                                    defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!, NSFontAttributeName: formatFont])
        return attributedString
    }
    
    func getStartSleepForDayLabel () -> String {
        return dayStringForDate(date: sleepStartDate)
    }
    
    func getEndSleepForDayLabel () -> String {
        return dayStringForDate(date: sleepEndDate)
    }
    
    func getStartSleepTimeString () -> String {
        return timeStringForDate (date: sleepStartDate)
    }
    
    func getSleepEndTimeString () -> String {
        return timeStringForDate(date: sleepEndDate)
    }

    func getTextForTimeInterval () -> NSAttributedString {
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        let minutesString = minutes < 10 ? " 0\(minutes)m" : " \(minutes)m"
        let durationText = "\(Int(hours))h" + minutesString
        
        return durationText.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                            format: [NSForegroundColorAttributeName: UIColor.white],
                            defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!])
    }
    
    func getTextForTimeLabel() -> String {
        return timeStringForDate(date: eventDate)
    }
    
    func getTextForDayLabel() -> String {
        return dayStringForDate(date: eventDate)
    }
    
    func datePickerRow(rowIndex: Int) -> Bool {
        return datePickerTags.contains(rowIndex)
    }
    
    func countDownPickerRow(rowIndex: Int) -> Bool {
        return countDownPickerTags.contains(rowIndex)
    }
    
    func timeStringForDate(date: Date) -> String {
        let minutesString = date.minute < 10 ? "0\(date.minute)" : "\(date.minute)"
        return "\((date.hour)):" + minutesString
    }
    
    func dayStringForDate(date: Date) -> String {
        return "\((date.day)) \((date.monthName))"
    }
    
    //MARK: Class methods
    
    class func getDefaultStartSleepDate() -> Date {
        if let whenToSleepDate = UserManager.sharedManager.getUsualWhenToSleepTime() {
            // If we have usual time user go to sleep, we use it as default value
            // If the value is after midday, we treat it as a date/time object for yesterday.
            if whenToSleepDate.hour >= 12 {
                return AddEventModel.applyTimeForDate(fromDate: whenToSleepDate, toDate: Date().addDays(daysToAdd: -1))
            } else {
                return AddEventModel.applyTimeForDate(fromDate: whenToSleepDate, toDate: Date())
            }

        }

        // If we have no date for usual sleep, use a constant.
        return Date().startOf(component: .day) - 1.hours
    }
    
    class func getDefaultWokeUpDate() -> Date {
        if let whenWokeUp = UserManager.sharedManager.getUsualWokeUpTime() {
            return AddEventModel.applyTimeForDate(fromDate: whenWokeUp, toDate: Date())
        }
        // If we have no date for usual sleep, use a constant.
        return getDefaultStartSleepDate() + 7.hours
    }
    
    class func applyTimeForDate(fromDate: Date, toDate: Date) -> Date {
        let calendar = NSCalendar.current
        let components = calendar.components([.year, .month, .day, .hour, .minute], fromDate: toDate)
        components.hour = fromDate.hour
        components.minute = fromDate.minute
        return calendar.dateFromComponents(components)!
    }
    
    //MARK: Save events
    
    func saveMealEvent(completion:@escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        
        if mealType == .Empty {
            completion(false, "Please choose meal type")
            return
        }
        
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        
        let startTime = eventDate
        let endTime = startTime + minutes.minutes + hours.hours
        let metaMeals = ["Meal Type": mealType.rawValue]
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(from: "km"),
                kiloCalories: 0.0, metadata: metaMeals as NSDictionary) { (success, error ) -> Void in
                    guard error == nil else {
                        completion(false, error?.localizedDescription)
                        return
                    }
                    //storing usual data for meal type
                    let mealType = self.mealType.rawValue
                    UserManager.sharedManager.setUsualMealTime(mealType: mealType, forDate: startTime)
                    completion(true, nil)
                    log.info("Meal saved as workout type")
            }
        }
    }
    
    func saveExerciseEvent(completion:@escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        
        let startTime = eventDate
        let endTime = startTime + minutes.minutes + hours.hours
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.saveRunningWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(from: "km"),
                kiloCalories: 0.0, metadata: [:]) {
                (success, error ) -> Void in
                guard error == nil else {
                    completion(false, error?.localizedDescription)
                    return
                }
                log.info("Saved as exercise workout type")
                completion(true, nil)
            }
        }
    }
    
    func saveSleepEvent(completion:@escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        let dayHourMinuteSecond: NSCalendar.Unit = [.month, .day, .hour, .minute]
        let difference = NSCalendar.currentCalendar.components(dayHourMinuteSecond, fromDate: sleepStartDate, toDate: sleepEndDate, options: [])
        if difference.hour < 0 || difference.minute < 0 {
            completion(false, "\"Woke Up\" time can't be earlier then \"Went to Sleep\" time")
            return
        } else if (sleepStartDate.day == sleepEndDate.day && difference.hour == 0 && difference.minute == 0 && difference.month == 0) {
            completion(false, "Total time of sleeping must be at least 1 minute")
            return
        }
        
        let startTime = sleepStartDate
        let endTime = sleepEndDate
        
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.saveSleep(startTime, endDate: endTime, metadata: [:], completion: {
                    (success, error ) -> Void in
                    guard error == nil else {
                        completion(false, error?.localizedDescription)
                        log.error(error!.localizedDescription); return
                    }
                    UserManager.sharedManager.setUsualWhenToSleepTime(date: startTime)
                    UserManager.sharedManager.setUsualWokeUpTime(date: endTime)
                    log.info("Saved as sleep event")
                    completion(true, nil)
            })
        }
    }
    
    //MARK: Validation
    func validateTimedEvent(startTime: Date, endTime: Date, completion: @escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        // Fetch all sleep and workout data since yesterday.
        let sleepTy = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: [])
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]
        
        // Aggregate sleep, exercise and meal events.
        MCHealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { log.error(error!.localizedDescription); return }
            let overlaps = samples.reduce(false, { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })
            if !overlaps {
                completion(true, nil)
            } else {
                completion(false, "This event overlaps with another, please try again")
            }
        }
    }
}

protocol AddEventModelDelegate {
    func sleepTimeUpdated(updatedTime: NSAttributedString)
}
