//
//  ComplicationDataManager.swift
//  MetabolicCompassWatch Extension
//
//  Created by Olearis on 5/25/18.
//  Copyright © 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import ClockKit
import HealthKit
import SwiftDate
import MCCircadianQueries


class ComplicationDataManager {

    static func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        guard let complications = server.activeComplications, complications.count > 0 else {
            return
        }
        
        for complication in complications  {
            server.reloadTimeline(for: complication)
        }
    }
    
    
    static func reloadData() {
        let weekAgo = Date(timeIntervalSinceNow: -60 * 60 * 24 * 7)
        
        CircadianSamplesManager.sharedInstance.fetchCircadianSamples(startDate: weekAgo, endDate: Date()) { (samples) in
            if !samples.isEmpty {
                var lastEatingInterval : (Date, Date)? = nil
                var maxFastingInterval : (Date, Date)? = nil
                
                var currentFastingIntreval : (Date, Date)? = nil
                
                for sample in samples {
                    if case CircadianEvent.meal(_) = sample.event {
                        if let currentFast = currentFastingIntreval {
                            currentFastingIntreval = (currentFast.0, sample.startDate)
                            if (CircadianSamplesManager.intervalDuration(from: currentFastingIntreval) > CircadianSamplesManager.intervalDuration(from: maxFastingInterval)) {
                                maxFastingInterval = currentFastingIntreval
                            }
                            currentFastingIntreval = nil
                        }
                        
                        if let currentEatingInterval = lastEatingInterval {
                            if sample.endDate > currentEatingInterval.0 {
                                lastEatingInterval = (sample.endDate, Date())
                            }
                        } else {
                            lastEatingInterval = (sample.endDate, Date())
                        }
                    } else {
                        if let currentFast = currentFastingIntreval {
                            currentFastingIntreval = (currentFast.0, sample.endDate)
                        } else {
                            currentFastingIntreval = (sample.startDate, sample.endDate)
                        }
                        if (CircadianSamplesManager.intervalDuration(from: currentFastingIntreval) > CircadianSamplesManager.intervalDuration(from: maxFastingInterval)) {
                            maxFastingInterval = currentFastingIntreval
                        }
                    }
                }
                
                MetricsStore.sharedInstance.lastAteAsDate = lastEatingInterval?.0 ?? Date()
//                MetricsStore.sharedInstance.fastingTime = "- h - m"
//                
//                if let maxInterval = maxFastingInterval {
//                    MetricsStore.sharedInstance.fastingTime = self.timeString(from: maxInterval)
//                }
                
                self.reloadComplications()
            }
        }
    }
    
    
    private static func timeString(from dateInterval: (Date, Date)) -> String {
        let timeInterval = Int(dateInterval.1.timeIntervalSince(dateInterval.0))
        let minutes = (timeInterval / 60) % 60
        let hours = (timeInterval / 3600)
        
        if hours == 0 && minutes == 0 {
            return "- h - m"
        } else {
            return String(format: "%02d h %02d m", hours, minutes)
        }
    }
    
    
}
