//
//  NSDate+Common.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/19/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

extension Date {
    func isAfterDate(dateToCompare: Date?, by: TimeInterval = 0.0) -> Bool {
        if dateToCompare != nil{
            return self.timeIntervalSince(dateToCompare!) > by
        }
        else{
            return true
        }
    }
    
    func isBeforeDate(dateToCompare: Date?, by: TimeInterval = 0.0) -> Bool {
        if dateToCompare != nil{
//            return self.timeIntervalSinceDate(dateToCompare!) > by
            return self.timeIntervalSince(dateToCompare!) > by
        }
        else{
            return false
        }
    }
    
    static func isNowAfterDate(dateToCompare: Date?, by: TimeInterval = 0.0) -> Bool {
        if dateToCompare != nil{
            return (dateToCompare?.timeIntervalSinceNow)! < -by
        }
        else{
            return true
        }
    }

    func isGreaterThanDate(dateToCompare: Date) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: Date) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(dateToCompare: Date) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == ComparisonResult.orderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(daysToAdd: Int) -> Date {
        let secondsInDays: TimeInterval = Double(daysToAdd) * 60 * 60 * 24
//        let dateWithDaysAdded: Date = self.dateByAddingTimeInterval(secondsInDays)
        let dateWithDaysAdded: Date = self.addingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd: Int) -> Date {
        let secondsInHours: TimeInterval = Double(hoursToAdd) * 60 * 60
//        let dateWithHoursAdded: Date = self.dateByAddingTimeInterval(secondsInHours)
        let dateWithHoursAdded: Date = self.addingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}
