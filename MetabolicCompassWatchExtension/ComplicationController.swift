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
        var isGreater = false
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        return isGreater
    }
    
    func isBeforeDate(dateToCompare: NSDate) -> Bool {
        var isLess = false
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        return isLess
    }
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        var isEqualTo = false
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }

        return isEqualTo
    }
    
    func addMinutes(minutesToAdd: Int) -> NSDate {
        let secondsInMinutes: NSTimeInterval = Double(minutesToAdd) * 60
        let dateWithMinutesAdded: NSDate = self.dateByAddingTimeInterval(secondsInMinutes)

        return dateWithMinutesAdded
    }
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    let userCalendar = NSCalendar.currentCalendar()
    let dateFormatter = NSDateFormatter()
    
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
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
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
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
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
        let nextUpdate = NSDate() + 10.minutes
//        Log.Error("called getNextRequestedUpdateDateWithHandler")
        handler(nextUpdate)
    }
    
    func requestedUpdateBudgetExhausted() {
//        Log.Error("Budget exhausted")
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
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


