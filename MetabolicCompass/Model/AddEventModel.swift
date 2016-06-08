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

enum MealType: String {
    case Empty = ""
    case Breakfast = "Breakfast"
    case Lunch = "Lunch"
    case Dinner = "Dinner"
    case Snack = "Snack"
}

class AddEventModel: NSObject {
    var delegate: AddEventModelDelegate? = nil
    var datePickerTags:[Int] = [2]  //default date picker row
    var countDownPickerTags: [Int] = [3,4] //default count down pickecr rows for meal screen
    
    var duration: NSTimeInterval = 1800.0 //default is 30 min
    var eventDate: NSDate = NSDate() //default is current date
    
    var mealType: MealType = .Empty {
        didSet {
            if let mealUsualDate = UserManager.sharedManager.getUsualMealTime(mealType.rawValue) {//if we have usual event date we should prefill it for user
                eventDate = AddEventModel.applyTimeForDate(mealUsualDate, toDate: eventDate)
            } else {//reset event date to the default state. Current date
                //it works in case when user selected event with existing usual time and then changed meal type
                eventDate = NSDate()
            }
        }
    }
    
    var sleepStartDate: NSDate = AddEventModel.getDefaultStartSleepDate() {
        didSet {
            if let whenWokeUp = UserManager.sharedManager.getUsualWokeUpTime(), let goSleepDate = UserManager.sharedManager.getUsualWhenToSleepTime() {
                //we have default values of wokeup and go to sleep
                let dayHourMinuteSecond: NSCalendarUnit = [.Hour, .Minute]
                let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: goSleepDate, toDate: whenWokeUp, options: [])//calculate difference between dates in hours and minutes
                sleepEndDate = sleepStartDate + difference.hour.hours + difference.minute.minutes//add hours and minutes to the currently selected when go to sleep date
            } else {//in case when we have no saved dates for sleep just adding 1 minute to sleepStartDate
                sleepEndDate = sleepStartDate + 1.minutes
            }
            self.delegate?.sleepTimeUpdated(getSleepTimeString())
        }
    }
    
    var sleepEndDate: NSDate =  AddEventModel.getDefaultWokeUpDate() {
        didSet {
            self.delegate?.sleepTimeUpdated(getSleepTimeString())
        }
    }
    
    func getSleepTimeString () -> NSAttributedString {
        let dayHourMinuteSecond: NSCalendarUnit = [.Hour, .Minute]
        let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: sleepStartDate, toDate: sleepEndDate, options: [])
        let hour = difference.hour < 0 ? 0 : difference.hour
        let minutes = difference.minute < 0 ? 0 : difference.minute
        let minutesSting = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let stringDifference = "\(hour)h \(minutesSting)m"
        let defaultFont = ScreenManager.appFontOfSize(24)
        let formatFont = ScreenManager.appFontOfSize(15)
        let attributedString = stringDifference.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                    format: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName : defaultFont],
                                                                    defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!, NSFontAttributeName: formatFont])
        return attributedString
    }
    
    func getStartSleepForDayLabel () -> String {
        return dayStringForDate(sleepStartDate)
    }
    
    func getEndSleepForDayLabel () -> String {
        return dayStringForDate(sleepEndDate)
    }
    
    func getStartSleepTimeString () -> String {
        return timeStringForDate (sleepStartDate)
    }
    
    func getSleepEndTimeString () -> String {
        return timeStringForDate(sleepEndDate)
    }

    func getTextForTimeInterval () -> NSAttributedString {
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        let minutesString = minutes < 10 ? " 0\(minutes)m" : " \(minutes)m"
        let durationText = "\(Int(hours))h" + minutesString
        
        return durationText.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                            format: [NSForegroundColorAttributeName: UIColor.whiteColor()],
                            defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!])
    }
    
    func getTextForTimeLabel() -> String {
        return timeStringForDate(eventDate)
    }
    
    func getTextForDayLabel() -> String {
        return dayStringForDate(eventDate)
    }
    
    func datePickerRow(rowIndex: Int) -> Bool {
        return datePickerTags.contains(rowIndex)
    }
    
    func countDownPickerRow(rowIndex: Int) -> Bool {
        return countDownPickerTags.contains(rowIndex)
    }
    
    func timeStringForDate(date: NSDate) -> String {
        let minutesString = date.minute < 10 ? "0\(date.minute)" : "\(date.minute)"
        return "\((date.hour)):" + minutesString
    }
    
    func dayStringForDate(date: NSDate) -> String {
        return "\((date.day)) \((date.monthName))"
    }
    
    //MARK: Class methods
    
    class func getDefaultStartSleepDate() -> NSDate {
        if let whenToSleepDate = UserManager.sharedManager.getUsualWhenToSleepTime() {//if we have usual time user go to sleep
            //we will apply it as default value for when go to sleep date
            let yesterday = 1.days.ago
            return AddEventModel.applyTimeForDate(whenToSleepDate, toDate: yesterday)
        }
        return NSDate()//if we have no date for usual sleep then just use current date
    }
    
    class func getDefaultWokeUpDate() -> NSDate {
        if let whenWokeUp = UserManager.sharedManager.getUsualWokeUpTime() {
            return AddEventModel.applyTimeForDate(whenWokeUp, toDate: NSDate())
        }
        return NSDate() + 1.minutes
    }
    
    class func applyTimeForDate(fromDate: NSDate, toDate: NSDate) -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: toDate)
        components.hour = fromDate.hour
        components.minute = fromDate.minute
        return calendar.dateFromComponents(components)!
    }
    
    //MARK: Save events
    
    func saveMealEvent(completion:(success: Bool, errorMessage: String?) -> ()) {
        
        if mealType == .Empty {
            completion(success: false, errorMessage: "Please choose meal type")
            return
        }
        
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        
        let startTime = eventDate
        let endTime = startTime + minutes.minutes + hours.hours
        let metaMeals = ["Meal Type": mealType.rawValue]
        validateTimedEvent(startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(success: false, errorMessage: errorMessage)
                return
            }
            HealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                kiloCalories: 0.0, metadata: metaMeals) { (success, error ) -> Void in
                    guard error == nil else {
                        completion(success: false, errorMessage: error.localizedDescription)
                        return
                    }
                    //storing usual data for meal type
                    let mealType = self.mealType.rawValue
                    UserManager.sharedManager.setUsualMealTime(mealType, forDate: startTime)
                    completion(success: true, errorMessage: nil)
                    log.info("Meal saved as workout type")
            }
        }
    }
    
    func saveExerciseEvent(completion:(success: Bool, errorMessage: String?) -> ()) {
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        
        let startTime = eventDate
        let endTime = startTime + minutes.minutes + hours.hours
        validateTimedEvent(startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(success: false, errorMessage: errorMessage)
                return
            }
            HealthManager.sharedManager.saveRunningWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                kiloCalories: 0.0, metadata: [:]) {
                (success, error ) -> Void in
                guard error == nil else {
                    completion(success: false, errorMessage: error.localizedDescription)
                    return
                }
                log.info("Saved as exercise workout type")
                completion(success: true, errorMessage: nil)
            }
        }
    }
    
    func saveSleepEvent(completion:(success: Bool, errorMessage: String?) -> ()) {
        let dayHourMinuteSecond: NSCalendarUnit = [.Hour, .Minute]
        let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: sleepStartDate, toDate: sleepEndDate, options: [])
        
        if difference.hour < 0 || difference.minute < 0 {
            completion(success: false, errorMessage: "\"Woke Up\" time can't be earlier then \"Went to Sleep\" time")
            return
        }
        
        let startTime = sleepStartDate
        let endTime = sleepEndDate
        
        validateTimedEvent(startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(success: false, errorMessage: errorMessage)
                return
            }
            HealthManager.sharedManager.saveSleep(startTime, endDate: endTime, metadata: [:], completion: {
                    (success, error ) -> Void in
                    guard error == nil else {
                        completion(success: false, errorMessage: error.localizedDescription)
                        log.error(error); return
                    }
                    UserManager.sharedManager.setUsualWhenToSleepTime(startTime)
                    UserManager.sharedManager.setUsualWokeUpTime(endTime)
                    log.info("Saved as sleep event")
                    completion(success: true, errorMessage: nil)
            })
        }
    }
    
    //MARK: Validation
    
    func validateTimedEvent(startTime: NSDate, endTime: NSDate, completion: (success: Bool, errorMessage: String?) -> ()) {
        // Fetch all sleep and workout data since yesterday.
        let (yesterday, now) = (1.days.ago, NSDate())
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(yesterday, endDate: now, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]
        
        // Aggregate sleep, exercise and meal events.
        HealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { log.error(error); return }
            let overlaps = samples.reduce(false, combine: { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, combine: { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })
            
            if !overlaps {
                completion(success: true, errorMessage: nil)
            } else {
                completion(success: false, errorMessage: "This event overlaps with another, please try again")
            }
        }
    }
}

protocol AddEventModelDelegate {
    func sleepTimeUpdated(updatedTime: NSAttributedString)
}
