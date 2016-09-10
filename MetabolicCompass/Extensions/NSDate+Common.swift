//
//  NSDate+Common.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/19/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

extension NSDate {
    func isAfterDate(dateToCompare: NSDate?, by: NSTimeInterval = 0.0) -> Bool {
        if dateToCompare != nil{
            return self.timeIntervalSinceDate(dateToCompare!) > by
        }
        else{
            return true
        }
    }
    
    func isBeforeDate(dateToCompare: NSDate?, by: NSTimeInterval = 0.0) -> Bool {
        if dateToCompare != nil{
            return self.timeIntervalSinceDate(dateToCompare!) > by
        }
        else{
            return false
        }
    }
    
    class func isNowAfterDate(dateToCompare: NSDate?, by: NSTimeInterval = 0.0) -> Bool {
        if dateToCompare != nil{
            return dateToCompare?.timeIntervalSinceNow < -by
        }
        else{
            return true
        }
    }

    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(daysToAdd: Int) -> NSDate {
        let secondsInDays: NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd: Int) -> NSDate {
        let secondsInHours: NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}