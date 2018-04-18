//
//  ComplicationController.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import ClockKit
import SwiftDate

extension Date {
    func isAfterDate(dateToCompare: Date) -> Bool {
        var isGreater = false
        if self.compare(dateToCompare as Date) == ComparisonResult.orderedDescending {
            isGreater = true
        }
        return isGreater
    }
    
    func isBeforeDate(dateToCompare: Date) -> Bool {
        var isLess = false
        if self.compare(dateToCompare as Date) == ComparisonResult.orderedAscending {
            isLess = true
        }
        
        return isLess
    }
    
    func equalToDate(dateToCompare: Date) -> Bool {
        var isEqualTo = false
        
        if self.compare(dateToCompare as Date) == ComparisonResult.orderedSame {
            isEqualTo = true
        }
        
        return isEqualTo
    }
    
    func addMinutes(minutesToAdd: Int) -> Date {
        let secondsInMinutes: TimeInterval = Double(minutesToAdd) * 60
        let dateWithMinutesAdded: Date = self.addingTimeInterval(secondsInMinutes)
        return dateWithMinutesAdded as Date
    }
}

class ComplicationController: NSObject, CLKComplicationDataSource {
 
    public func requestedUpdateDidBegin() {
        
    }

    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                               withHandler handler: @escaping (CLKComplicationTemplate?) -> Void){
        var template: CLKComplicationTemplate? = nil
        switch complication.family {
        case .modularSmall:
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKSimpleTextProvider(text: "line2")
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .modularLarge:
            let newTemplate = CLKComplicationTemplateModularLargeStandardBody()
            newTemplate.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.headerTextProvider = CLKSimpleTextProvider(text: "MCompass")
            newTemplate.body1TextProvider = CLKSimpleTextProvider(text: "Fast Time")
            newTemplate.body2TextProvider = CLKSimpleTextProvider(text: "Eating Time")
            newTemplate.body1TextProvider.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.body2TextProvider?.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .utilitarianSmall:
            let newTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKSimpleTextProvider(text: "00:00:00")
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .utilitarianLarge:
            let newTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKSimpleTextProvider(text: "00:00")
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        case .circularSmall:
            let newTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            newTemplate.textProvider = CLKSimpleTextProvider(text: "00:00")
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        default:
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKSimpleTextProvider(text: "line2")
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        }
        handler(template)
    }
    
    public func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Swift.Void) {
        handler([.forward])
    }

    let userCalendar = Calendar.current
    let dateFormatter = DateFormatter()

    public func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Swift.Void) {
        handler(Date() as Date)
    }
    
    public func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Swift.Void) {
        let end = Date.distantFuture
        handler(end)
        return
    }
    
    public func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Swift.Void) {
        handler(.showOnLockScreen)
    }
    
     public func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Swift.Void) {
        var template: CLKComplicationTemplate? = nil
        
        switch complication.family {
            
        case .modularSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .modularLarge:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateModularLargeStandardBody()
            newTemplate.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.headerTextProvider = CLKSimpleTextProvider(text: "Fasting Duration : ")
            newTemplate.body1TextProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            newTemplate.body2TextProvider = CLKSimpleTextProvider(text: "max daily: " + MetricsStore.sharedInstance.fastingTime)
            newTemplate.body1TextProvider.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.body2TextProvider?.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .utilitarianSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .utilitarianLarge:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            newTemplate.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            newTemplate.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            newTemplate.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
            
        case .circularSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        default:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            template = newTemplate
        }
        
        handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template!))
    }

   public func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Swift.Void) {
        handler(nil)
    }
    
    public func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Swift.Void) {
        var entries = [CLKComplicationTimelineEntry]()
        
        switch complication.family {
            
        case .modularSmall:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let endingTime = endTime.addMinutes(minutesToAdd: 1440)
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
                        
            entries.append(CLKComplicationTimelineEntry(date: endingTime, complicationTemplate: newTemplate))

        case .modularLarge:
            let start = MetricsStore.sharedInstance.lastAteAsDate
            let endingTime = start.addMinutes(minutesToAdd: 1440)
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.headerTextProvider = CLKSimpleTextProvider(text: "Fasting ... : ")
            template.body1TextProvider = CLKRelativeDateTextProvider(date: start as Date, style: .timer, units: [.hour, .minute])
            template.body2TextProvider = CLKSimpleTextProvider(text: "max daily fasting: " + MetricsStore.sharedInstance.fastingTime)

                        
            template.body1TextProvider.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            template.body2TextProvider?.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
                        
            entries.append(CLKComplicationTimelineEntry(date: endingTime, complicationTemplate: template))

        case .utilitarianSmall:
            let start = MetricsStore.sharedInstance.lastAteAsDate
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKRelativeDateTextProvider(date: start as Date, style: .timer, units: [.hour, .minute])
            template.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            template.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
                    
            entries.append(CLKComplicationTimelineEntry(date: start as Date, complicationTemplate: template))
            
        case .utilitarianLarge:
            let start = MetricsStore.sharedInstance.lastAteAsDate
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKRelativeDateTextProvider(date: start as Date, style: .timer, units: [.hour, .minute])
                    template.imageProvider?.tintColor = UIColor(red:0.58, green:0.93, blue:0, alpha:1)
            template.textProvider.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
                    
            entries.append(CLKComplicationTimelineEntry(date: start as Date, complicationTemplate: template))

        case .circularSmall:
            let start = MetricsStore.sharedInstance.lastAteAsDate
            let newTemplate = CLKComplicationTemplateCircularSmallSimpleText()
            newTemplate.textProvider = CLKRelativeDateTextProvider(date: start as Date, style: .timer, units: [.hour, .minute])
            newTemplate.tintColor = UIColor(red:0, green:0.85, blue:0.76, alpha:1)
            entries.append(CLKComplicationTimelineEntry(date: start as Date, complicationTemplate: newTemplate))
  
            handler(entries)
        default:
            let endTime = MetricsStore.sharedInstance.lastAteAsDate
            let endingTime = endTime.addMinutes(minutesToAdd: 1440)
            let newTemplate = CLKComplicationTemplateModularSmallStackText()
            newTemplate.line1TextProvider = CLKSimpleTextProvider(text: "fast")
            newTemplate.line2TextProvider = CLKRelativeDateTextProvider(date: endTime as Date, style: .timer, units: [.hour, .minute])
            
            entries.append(CLKComplicationTimelineEntry(date: endingTime, complicationTemplate: newTemplate))
        }
    }

    
    public func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Swift.Void) {
//        let nextUpdate = Date() + 10.minutes
//        let nextUpdate = Date().addingTimeInterval(10.minutes)
          let nextUpdate = Date().addMinutes(minutesToAdd: 10)
        handler(nextUpdate)
    }
}


