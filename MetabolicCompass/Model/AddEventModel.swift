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
    var countDownPickerTags: [Int] = [3] //default count down pickecr row
    
    var duration: NSTimeInterval = 1800.0
    var eventDate: NSDate = NSDate()
    var mealType: MealType = .Empty
    
    var sleepStartDate: NSDate = NSDate() {
        didSet {
            sleepEndDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Minute, value: 1, toDate: sleepStartDate, options: NSCalendarOptions.WrapComponents)!
        }
    }
    
    var sleepEndDate: NSDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Minute, value: 1, toDate: NSDate(), options: NSCalendarOptions.WrapComponents)! {
        didSet {
            let dayHourMinuteSecond: NSCalendarUnit = [.Hour, .Minute]
            let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: sleepStartDate, toDate: sleepEndDate, options: [])
            let stringDifference = "\(difference.hour)h \(difference.minute)m"
            let attributedString = stringDifference.formatTextWithRegex("[-+]?(\\d*[.,])?\\d+",
                                                                         format: [NSForegroundColorAttributeName: UIColor.whiteColor()],
                                                                         defaultFormat: [NSForegroundColorAttributeName: UIColor.colorWithHexString("#ffffff", alpha: 0.3)!])
            self.delegate?.sleepTimeUpdated(attributedString)
        }
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