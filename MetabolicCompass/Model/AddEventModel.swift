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
    var eventDateWasChanged = false
    var delegate: AddEventModelDelegate? = nil
    var datePickerTags:[Int] = [2]  //default date picker row
    var countDownPickerTags: [Int] = [3,4] //default count down pickecr rows for meal screen
    var duration: TimeInterval = 1800.0 {//default is 30 min
        didSet {
            dataWasChanged = true
        }
    }
    
    var roundedDuration : Double {
        return Double(Int(duration/60) * 60)
    }
    
    var eventDate: Date = Date() {//default is current date
        didSet {
            dataWasChanged = true
            eventDateWasChanged = true
        }
    }
    
    var mealType: MealType = .Empty {
        didSet {
            guard !eventDateWasChanged else {
                return
            }
            if let mealUsualDate = UserManager.sharedManager.getUsualMealTime(mealType: mealType.rawValue) {//if we have usual event date we should prefill it for user
                eventDate = AddEventModel.applyTimeForDate(mealUsualDate, toDate: eventDate)
                eventDateWasChanged = false
            } else {//reset event date to the default state. Current date
                //it works in case when user selected event with existing usual time and then changed meal type
                eventDate = Date()
                eventDateWasChanged = false
            }
        }
    }
    
    var sleepStartDate: Date = AddEventModel.getDefaultStartSleepDate() {
        didSet {
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

        let hour : Int = difference.hour! < 0 ? 0 : (difference.hour ?? 0)
        let minutes : Int = difference.minute! < 0 ? 0 : (difference.minute ?? 0)
        let stringDifference = String(format: "%dh %.2dm", hour, minutes)
        let defaultFont = ScreenManager.appFontOfSize(size: 24)
        let formatFont = ScreenManager.appFontOfSize(size: 15)
        let attributedString = stringDifference.formatTextWithRegex(regex: "[-+]?(\\d*[.,])?\\d+",
                                                                    format: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font : defaultFont],
                                                                    defaultFormat: [NSAttributedStringKey.foregroundColor: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!, NSAttributedStringKey.font: formatFont])
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
                                                format: [NSAttributedStringKey.foregroundColor: UIColor.white],
                                        defaultFormat: [NSAttributedStringKey.foregroundColor: UIColor.colorWithHexString(rgb: "#ffffff", alpha: 0.3)!])
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
        let formatter  = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        
        return formatter.string(from: date)
    }
    
    //MARK: Class methods
    
    class func getDefaultStartSleepDate() -> Date {
        if let whenToSleepDate = UserManager.sharedManager.getUsualWhenToSleepTime() {//if we have usual time user go to sleep
            //we will apply it as default value for when go to sleep date
            let yesterday = Date() - 1.day
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
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: toDate)
        components.hour = fromDate.hour
        components.minute = fromDate.minute
        return calendar.date(from: components) ?? toDate
    }
    
    //MARK: Save events
    
    func saveMealEvent(completion:@escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        
        if mealType == .Empty {
            completion(false, "Please choose meal type")
            return
        }
        
        let startTime = eventDate
        let endTime = Date(timeInterval: roundedDuration, since: startTime)
        
        
        MCAppHealthManager.shared.addMeal(startTime: startTime, endTime: endTime, mealType: mealType.rawValue, callback: completion)
    }
    
    func saveExerciseEvent(completion:@escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        let startTime = eventDate
        let endTime = Date(timeInterval: roundedDuration, since: startTime)
        
        MCAppHealthManager.shared.addExercise(workoutType: .running, startTime: startTime, endTime: endTime, callback: completion)
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
        
        MCAppHealthManager.shared.addSleep(startTime:  sleepStartDate, endTime:  sleepEndDate, callback: completion)
    }
}

protocol AddEventModelDelegate {
    func sleepTimeUpdated(_ updatedTime: NSAttributedString)
}
