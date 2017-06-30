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

enum MealType: String {
    case Empty = ""
    case Breakfast = "Breakfast"
    case Lunch = "Lunch"
    case Dinner = "Dinner"
    case Snack = "Snack"
}

open class AddEventModel: NSObject {
    var dataWasChanged = false
    var delegate: AddEventModelDelegate? = nil
    var datePickerTags:[Int] = [2]  //default date picker row
    var countDownPickerTags: [Int] = [3,4] //default count down pickecr rows for meal screen
    var duration: TimeInterval = 1800.0 {//default is 30 min
        didSet {
            dataWasChanged = true
        }
    }
    var eventDate: Date = Date() {//default is current date
        didSet {
            dataWasChanged = true
        }
    }
    
    var mealType: MealType = .Empty {
        didSet {
            if let mealUsualDate = UserManager.sharedManager.getUsualMealTime(mealType: mealType.rawValue) {//if we have usual event date we should prefill it for user
                eventDate = AddEventModel.applyTimeForDate(mealUsualDate as Date, toDate: eventDate)
            } else {//reset event date to the default state. Current date
                //it works in case when user selected event with existing usual time and then changed meal type
                eventDate = Date()
            }
        }
    }
    
    var sleepStartDate: Date = AddEventModel.getDefaultStartSleepDate() {
        didSet {
            //            if let whenWokeUp = UserManager.sharedManager.getUsualWokeUpTime(), let goSleepDate = UserManager.sharedManager.getUsualWhenToSleepTime() {
            //                //we have default values of wokeup and go to sleep
            //                let dayHourMinuteSecond: NSCalendarUnit = [.Hour, .Minute]
            //                let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: goSleepDate, toDate: whenWokeUp, options: [])//calculate difference between dates in hours and minutes
            //                sleepEndDate = sleepStartDate + difference.hour.hours + difference.minute.minutes//add hours and minutes to the currently selected when go to sleep date
            //            } else {//in case when we have no saved dates for sleep just adding 1 minute to sleepStartDate
            //                sleepEndDate = sleepStartDate + 1.minutes
            //            }
            dataWasChanged = true
            self.delegate?.sleepTimeUpdated(getSleepTimeString())
        }
    }
    
    var sleepEndDate: Date =  AddEventModel.getDefaultWokeUpDate() {
        didSet {
            dataWasChanged = true
            self.delegate?.sleepTimeUpdated(getSleepTimeString())
        }
    }
    
    func getSleepTimeString () -> NSAttributedString {
        let _: NSCalendar.Unit = [.hour, .minute]
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.hour, .minute])
        let difference = calendar.dateComponents(unitFlags, from: sleepStartDate, to: sleepEndDate)

        let hour = difference.hour! < 0 ? 0 : difference.hour
        let minutes = difference.minute! < 0 ? 0 : difference.minute
        let minutesSting = minutes! < 10 ? "0\(minutes ?? no_argument as AnyObject as! Int)" : "\(String(describing: minutes))"
        let stringDifference = "\(hour ?? no_argument as AnyObject as! Int)h \(minutesSting)m"
        let defaultFont = ScreenManager.appFontOfSize(size: 24)
        let formatFont = ScreenManager.appFontOfSize(size: 15)
        let attributedString = stringDifference.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                                                                    format: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName : defaultFont],
                                                                    defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!, NSFontAttributeName: formatFont])
        return attributedString
    }
    
    func getStartSleepForDayLabel () -> String {
        return dayStringForDate(date: sleepStartDate)
    }
    
    func getEndSleepForDayLabel () -> String {
        return dayStringForDate(date: sleepEndDate)
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
        
        return durationText.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                                                format: [NSForegroundColorAttributeName: UIColor.white],
                                                defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!])
    }
    
    func getTextForTimeLabel() -> String {
        return timeStringForDate(eventDate)
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
    
    func timeStringForDate(_ date: Date) -> String {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.hour, .minute])
        let timeStringComponents = calendar.dateComponents(unitFlags, from: date)
        let minutesString = timeStringComponents.minute! < 10 ? "0\(timeStringComponents.minute!)" : "\(timeStringComponents.minute!)"
        return "\((timeStringComponents.hour!)):" + minutesString
    }
    
    func dayStringForDate(date: Date) -> String {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.month, .day])
        let timeStringComponents = calendar.dateComponents(unitFlags, from: date)
        return "\((timeStringComponents.day) ?? no_argument as AnyObject as! Int) \((timeStringComponents.month) ?? no_argument as AnyObject as! Int)"
    }
    
    //MARK: Class methods
    
    class func getDefaultStartSleepDate() -> Date {
        if let whenToSleepDate = UserManager.sharedManager.getUsualWhenToSleepTime() {//if we have usual time user go to sleep
            //we will apply it as default value for when go to sleep date
            let yesterday = Date(timeInterval: -1, since: Date())
            return AddEventModel.applyTimeForDate(whenToSleepDate, toDate: yesterday)
        }
        return Date()//if we have no date for usual sleep then just use current date
    }
    
    class func getDefaultWokeUpDate() -> Date {
        if let whenWokeUp = UserManager.sharedManager.getUsualWokeUpTime() {
            return AddEventModel.applyTimeForDate(whenWokeUp, toDate: Date())
        }
        return Date()
    }
    
    class func applyTimeForDate(_ fromDate: Date, toDate: Date) -> Date {
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.year, .month, .day, .hour, .minute])
        let timeStringComponents = calendar.dateComponents(unitFlags, from: Date())
        return calendar.date(byAdding: timeStringComponents, to: Date())!
    }
    
    //MARK: Save events
    
    func saveMealEvent(completion:@escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        
        if mealType == .Empty {
            completion(false, "Please choose meal type")
            return
        }
        
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        let seconds = Double(minutes*60)
        let calendar = NSCalendar.current
        let startTime = eventDate
        let endTime = Date(timeInterval: seconds, since: startTime)
        let metaMeals = ["Meal Type": mealType.rawValue]
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime as Date, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(from: "km"),
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
        let seconds = Double(minutes*60)
        
        let startTime = eventDate
        let endTime = Date(timeInterval: seconds, since: startTime)
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                completion(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.saveRunningWorkout(
                startTime as Date, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(from: "km"),
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
        let _: NSCalendar.Unit = [.month, .day, .hour, .minute]
        
        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.month, .day, .hour, .minute])
        let difference = calendar.dateComponents(unitFlags, from: sleepStartDate, to: sleepEndDate)
        
        if difference.hour! < 0 || difference.minute! < 0 {
            completion(false, "\"Woke Up\" time can't be earlier then \"Went to Sleep\" time")
            return
        } else if (difference.month! <= 0 && difference.day! <= 0 && difference.hour! <= 0 && difference.minute! <= 1) {
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
                    log.error(error as! String); return
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
            guard error == nil else { log.error("error"); return }
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
    func sleepTimeUpdated(_ updatedTime: NSAttributedString)
}
