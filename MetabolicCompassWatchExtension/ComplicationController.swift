//
//  ComplicationController.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import ClockKit
import SwiftDate

extension NSDate {
    func isAfterDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isBeforeDate(dateToCompare: NSDate) -> Bool {
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
    
    func addMinutes(minutesToAdd: Int) -> NSDate {
        let secondsInMinutes: NSTimeInterval = Double(minutesToAdd) * 60
        let dateWithMinutesAdded: NSDate = self.dateByAddingTimeInterval(secondsInMinutes)
        
        //Return Result
        return dateWithMinutesAdded
    }
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let userCalendar = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        let end = NSDate.distantFuture()
        handler(end)
        return
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        print("in getCurrentTimelineEntryForComplication : \(MetricsStore.sharedInstance.lastAteAsNSDate)")
        var template: CLKComplicationTemplate? = nil
        
        switch complication.family {
            
        case .ModularSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsNSDate
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKRelativeDateTextProvider(date: endTime, style: .Timer, units: [.Hour, .Minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .ModularLarge:
            let endTime = MetricsStore.sharedInstance.lastAteAsNSDate
            let newTemplate = CLKComplicationTemplateModularLargeStandardBody()
            newTemplate.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Duration : ")
            newTemplate.body1TextProvider = CLKRelativeDateTextProvider(date: endTime, style: .Timer, units: [.Hour, .Minute])
            newTemplate.body2TextProvider = CLKSimpleTextProvider(text: "max daily: " + MetricsStore.sharedInstance.fastingTime)
            newTemplate.body1TextProvider.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.body2TextProvider?.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .UtilitarianSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsNSDate
            let newTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: endTime, style: .Timer, units: [.Hour, .Minute])
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .UtilitarianLarge:
            let endTime = MetricsStore.sharedInstance.lastAteAsNSDate
            let newTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: endTime, style: .Timer, units: [.Hour, .Minute])
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .CircularSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsNSDate
            let newTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: endTime, style: .Timer, units: [.Hour, .Minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        }
        
        handler(CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template!))
    }

    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after the given date
        print("in getTimelineEntriesForComplication : \(MetricsStore.sharedInstance.lastAteAsNSDate)")
        var entries = [CLKComplicationTimelineEntry]()
        
        switch complication.family {
            
        case .ModularSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsNSDate
            let endingTime = endTime + 24.hours
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKRelativeDateTextProvider(date: endTime, style: .Timer, units: [.Hour, .Minute])
                        
            entries.append(CLKComplicationTimelineEntry(date: endingTime, complicationTemplate: newTemplate))

        case .ModularLarge:
            let start = MetricsStore.sharedInstance.lastAteAsNSDate
            let endingTime = start + 24.hours
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.headerTextProvider = CLKSimpleTextProvider(text: "Fasting ... : ")
            template.body1TextProvider = CLKRelativeDateTextProvider(date: start, style: .Timer, units: [.Hour, .Minute])
            template.body2TextProvider = CLKSimpleTextProvider(text: "max daily fasting: " + MetricsStore.sharedInstance.fastingTime)

                        
            template.body1TextProvider.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            template.body2TextProvider?.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
                        
            entries.append(CLKComplicationTimelineEntry(date: endingTime, complicationTemplate: template))

        case .UtilitarianSmall:
            let start = MetricsStore.sharedInstance.lastAteAsNSDate
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKRelativeDateTextProvider(date: start, style: .Timer, units: [.Hour, .Minute])
            template.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            template.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
                    
            entries.append(CLKComplicationTimelineEntry(date: start, complicationTemplate: template))
            
        case .UtilitarianLarge:
            let start = MetricsStore.sharedInstance.lastAteAsNSDate
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKRelativeDateTextProvider(date: start, style: .Timer, units: [.Hour, .Minute])
                    template.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            template.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
                    
            entries.append(CLKComplicationTimelineEntry(date: start, complicationTemplate: template))

        case .CircularSmall:
            let start = MetricsStore.sharedInstance.lastAteAsNSDate
            let newTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: start, style: .Timer, units: [.Hour, .Minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            entries.append(CLKComplicationTimelineEntry(date: start, complicationTemplate: newTemplate))
  
            handler(entries)
        }
    }
   
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        let nextUpdate = NSDate() + 10.minutes
        print("called getNextRequestedUpdateDateWithHandler")
        handler(nextUpdate)
    }
    
/*    func requestedUpdateDidBegin() {
        print("Complication update is starting")
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.UtilitarianSmall)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.UtilitarianLarge)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.ModularLarge)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.ModularSmall)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.CircularSmall)

    }
    
    func createComplicationEntry(shortText: String, date: NSDate, family: CLKComplicationFamily) -> CLKComplicationTimelineEntry {
        if  family == CLKComplicationFamily.UtilitarianSmall {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.UtilitarianLarge {
            let largeFlat = CLKComplicationTemplateUtilitarianLargeFlat()
            largeFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: largeFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.ModularLarge {
            let largeFlat = CLKComplicationTemplateModularLargeTallBody()
            largeFlat.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Time")
            largeFlat.bodyTextProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: largeFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.ModularSmall {
            let smallFlat = CLKComplicationTemplateModularSmallSimpleText()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        } else  {
            let smallFlat = CLKComplicationTemplateCircularSmallRingText()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        }
        print("added new Complication entry to Entries \(date) and \(shortText)")
        
    }
*/
    
    func requestedUpdateBudgetExhausted() {
        print("Budget exhausted")
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        var template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .ModularSmall:
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKSimpleTextProvider(text: "line2")
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .ModularLarge:
            let newTemplate = CLKComplicationTemplateModularLargeStandardBody()
            newTemplate.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.headerTextProvider = CLKSimpleTextProvider(text: "MCompass")
            newTemplate.body1TextProvider = CLKSimpleTextProvider(text: "Fast Time")
            newTemplate.body2TextProvider = CLKSimpleTextProvider(text: "Eating Time")
            newTemplate.body1TextProvider.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.body2TextProvider?.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .UtilitarianSmall:
            let newTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKSimpleTextProvider(text: "00:00:00")
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .UtilitarianLarge:
            let newTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKSimpleTextProvider(text: "00:00")
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .CircularSmall:
            let newTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            newTemplate.textProvider = CLKSimpleTextProvider(text: "00:00")
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        }
        handler(template)
    }
}






/*import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    let userCalendar = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        //        let startDate = NSDate()
        let startDate = getStartDateFromUserDefaults()
        let sabbaticalDate = getSabbaticalDate(startDate)
        handler(sabbaticalDate)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        func refreshComplication(time_min: Int) {
            let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), Int64(time_min) * 60 * Int64(NSEC_PER_SEC))
            dispatch_after(time, dispatch_get_main_queue()) {
                let complicationServer = CLKComplicationServer.sharedInstance()
                for complication in complicationServer.activeComplications! {
                    complicationServer.reloadTimelineForComplication(complication)
                }
            }  
        }
        refreshComplication(1)
//        IntroInterfaceController.reloadDataTake2()
        var shortText = MetricsStore.sharedInstance.currentFastingTime
        var chkTime = NSDate()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        var chkText = dateFormatter.stringFromDate(chkTime)
        print("refreshed complication in getCurrentTimelineEntryForComplication \(chkText)")
        if complication.family == .UtilitarianSmall || complication.family == .UtilitarianLarge || complication.family == .ModularSmall || complication.family == .ModularLarge || complication.family == .CircularSmall
        {
            //            let startDate = NSDate()
            let startDate = getStartDateFromUserDefaults()
            let sabbaticalDate = getSabbaticalDate(startDate)
            
            let dateComparisionResult:NSComparisonResult = NSDate().compare(sabbaticalDate)
            if dateComparisionResult == NSComparisonResult.OrderedAscending
            {
                // current date is earlier than the end date
                
                // figure out how many days, months and years remain until sabbatical
                let flags: NSCalendarUnit = [.Year, .Month, .Day]
                let dateComponents = userCalendar.components(flags, fromDate: NSDate(), toDate: sabbaticalDate, options: [])
                let year = dateComponents.year
                let month = dateComponents.month
                let day = dateComponents.day
                
                // create string to display remaining time
                if (year > 0 )
                {
                    shortText = MetricsStore.sharedInstance.currentFastingTime
                }
                else if (year <= 0 && month > 0)
                {
                    shortText = MetricsStore.sharedInstance.currentFastingTime
                }
                else if (year <= 0 && month <= 0 && day > 0)
                {
                    shortText = MetricsStore.sharedInstance.currentFastingTime
                }
                
            }
            else if dateComparisionResult == NSComparisonResult.OrderedDescending
            {
                // Current date is greater than end date.
                shortText = MetricsStore.sharedInstance.currentFastingTime
            }
            
            // create current timeline entry
            shortText = MetricsStore.sharedInstance.currentFastingTime
            let entry = createComplicationEntry(shortText, date: NSDate(), family: complication.family)
            
            print("in getCurrentTimelineEntryForComplication: \(entry)")
            handler(entry)
        } else {
            handler(nil)
        }
        
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        
        //        let startDate = NSDate()
        let startDate = getStartDateFromUserDefaults()
        let sabbaticalDate = getSabbaticalDate(startDate)
        let componentDay = userCalendar.components(.Day, fromDate: date, toDate: sabbaticalDate, options: [])
        let days = min(componentDay.day, 100)
        
        let entries = [CLKComplicationTimelineEntry]()
        
        // create an entry in array for each day remaining
        for index in 1...days {
            let dateComparisionResult:NSComparisonResult = NSDate().compare(sabbaticalDate)
            if dateComparisionResult == NSComparisonResult.OrderedAscending
            {
                // entryDate is the date of the timeline entry for the complication
                let entryDate = userCalendar.dateByAddingUnit([.Day], value: index, toDate: date, options: [])!
                
                let flags: NSCalendarUnit = [.Year, .Month, .Day]
                let dateComponents = userCalendar.components(flags, fromDate: entryDate, toDate: sabbaticalDate, options: [])
                
                // number of years, months, days from the timeline entry until sabbatical date
                let year = dateComponents.year
                let month = dateComponents.month
                let day = dateComponents.day
                
                if (year > 0 )
                {
                    //                    let entryText = String(format: "%d Y | %d M", year, month)
                    _ = MetricsStore.sharedInstance.currentFastingTime
                    //                    let entry = createComplicationEntry(entryText, date: entryDate, family: complication.family)
                    //                    entries.append(entry)
                }
                else if (year <= 0 && month > 0)
                {
                    //                    let entryText = String(format: "%d M | &d D", month, day)
                    let entryText = MetricsStore.sharedInstance.currentFastingTime
                    //                    let entry = createComplicationEntry(entryText, date: entryDate, family: complication.family)
                    //                    entries.append(entry)
                }
                else if (year <= 0 && month <= 0 && day > 0)
                {
                    //                    let entryText = String(format: "%d Days", day)
                    _ = MetricsStore.sharedInstance.currentFastingTime
                    //                    let entry = createComplicationEntry(entryText, date: entryDate, family: complication.family)
                    //                    entries.append(entry)
                }
            }
        }
        //        print("current values for entries: \(entries)")
        handler(entries)
    }
    
    // MARK: - Update Scheduling
    
    /*    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
     // Call the handler with the date when you would next like to be given the opportunity to update your complication content
     handler(nil)
     }
     */
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        handler(NSDate(timeIntervalSinceNow: 5))
        print("getNextRequestedUpdateDateWithHandler called \(NSDate.description())")
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        if complication.family == .UtilitarianSmall {
            let smallUtil = CLKComplicationTemplateUtilitarianSmallFlat()
            smallUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.currentFastingTime)
            handler(smallUtil)
        }
        if complication.family == .UtilitarianLarge {
            let largeUtil = CLKComplicationTemplateUtilitarianLargeFlat()
            largeUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.currentFastingTime)
            handler(largeUtil)
        }
        if complication.family == .ModularSmall {
            let smallUtil = CLKComplicationTemplateModularSmallSimpleText()
            smallUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.currentFastingTime)
            handler(smallUtil)
        }
        if complication.family == .ModularLarge {
            let largeUtil = CLKComplicationTemplateModularLargeTallBody()
            largeUtil.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Time")
            largeUtil.bodyTextProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.currentFastingTime)
            handler(largeUtil)
        }
        
        if complication.family == .CircularSmall {
            let smallUtil = CLKComplicationTemplateCircularSmallSimpleText()
            smallUtil.textProvider = CLKSimpleTextProvider(text: MetricsStore.sharedInstance.currentFastingTime)
            handler(smallUtil)
        }
        print("in getPlaceholderTemplateForComplication \(MetricsStore.sharedInstance.currentFastingTime)")
    }
    
    func createComplicationEntry(shortText: String, date: NSDate, family: CLKComplicationFamily) -> CLKComplicationTimelineEntry {
        if  family == CLKComplicationFamily.UtilitarianSmall {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.UtilitarianLarge {
            let largeFlat = CLKComplicationTemplateUtilitarianLargeFlat()
            largeFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: largeFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.ModularLarge {
          let largeFlat = CLKComplicationTemplateModularLargeTallBody()
            largeFlat.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Time")
            largeFlat.bodyTextProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: largeFlat)
            return(newEntry)
        } else if family == CLKComplicationFamily.ModularSmall {
            let smallFlat = CLKComplicationTemplateModularSmallSimpleText()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        } else  {
            let smallFlat = CLKComplicationTemplateCircularSmallRingText()
            smallFlat.textProvider = CLKSimpleTextProvider(text: shortText)
            let newEntry = CLKComplicationTimelineEntry(date: date, complicationTemplate: smallFlat)
            return(newEntry)
        }
        print("added new Complication entry to Entries \(date) and \(shortText)")
        
    }
    
    func requestedUpdateDidBegin() {
        print("Complication update is starting")
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.UtilitarianSmall)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.UtilitarianLarge)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.ModularLarge)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.ModularSmall)
        
        createComplicationEntry(MetricsStore.sharedInstance.currentFastingTime, date: NSDate(),family: CLKComplicationFamily.CircularSmall)
        
/*        let server=CLKComplicationServer.sharedInstance()
        
        for comp in (server.activeComplications)! {
            server.reloadTimelineForComplication(comp)
            print("Timeline has been reloaded")
        } */
    }
    
    func requestedUpdateBudgetExhausted() {
        print("Budget exhausted")
    }
    
    func getSabbaticalDate(startDate: NSDate) -> NSDate {
        // set up date formatter
        dateFormatter.calendar = userCalendar
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // create variable to hold 7 years
        let sevenYears: NSDateComponents = NSDateComponents()
        sevenYears.setValue(7, forComponent: NSCalendarUnit.Year);
        
        // add 7 years to our start date to calculate the date of our sabbatical
        var sabbaticalDate = userCalendar.dateByAddingComponents(sevenYears, toDate: startDate, options: NSCalendarOptions(rawValue: 0))
        
        // since we get a sabbatical every 7 years, add 7 years until sabbaticalDate is in the future
        while sabbaticalDate!.timeIntervalSinceNow.isSignMinus {
            sabbaticalDate = userCalendar.dateByAddingComponents(sevenYears, toDate: sabbaticalDate!, options: NSCalendarOptions(rawValue: 0))
        }
        
        return sabbaticalDate!
    }
    
    func getStartDateFromUserDefaults() -> NSDate {
        let defaults = NSUserDefaults.standardUserDefaults()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var startDate = NSDate()
        
        if let dateString = defaults.stringForKey("dateKey")
        {
            startDate = dateFormatter.dateFromString(dateString)!
        }
        
        return startDate
    }
} */
