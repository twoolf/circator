//
//  AddEventModel.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/7/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

enum MealType: String {
    case Breakfast = "Breakfast"
    case Lunch = "Lunch"
    case Dinner = "Dinner"
    case Snack = "Snack"
}

class AddEventModel: NSObject {
    
    var datePickerTags:[Int] = [2]  //default date picker row
    var countDownPickerTags: [Int] = [3] //default count down pickecr row
    
    var duration: NSTimeInterval = 0.0
    var eventDate: NSDate = NSDate()
    var mealType: MealType = .Breakfast
    
    var sleepStartDate: NSDate? = nil
    var sleepEndDate: NSDate? = nil
    
    func getTextForTimeInterval () -> String {
        let hours = Int(duration/3600.0)
        let minutes = Int((duration - Double((hours * 3600)))/60)
        let minutesString = minutes < 10 ? " 0\(minutes)m" : " \(minutes)m"
        return "\(Int(hours))h" + minutesString
    }
    
    func getTextForTimeLabel() -> String {
        let minutesString = eventDate.minute < 10 ? "0\(eventDate.minute)" : "\(eventDate.minute)"
        return "\((eventDate.hour)):" + minutesString
    }
    
    func getTextForDayLabel() -> String {
        return "\((eventDate.day)) \((eventDate.monthName))"
    }
    
    func datePickerRow(rowIndex: Int) -> Bool {
        return datePickerTags.contains(rowIndex)
    }
    
    func countDownPickerRow(rowIndex: Int) -> Bool {
        return countDownPickerTags.contains(rowIndex)
    }
}
