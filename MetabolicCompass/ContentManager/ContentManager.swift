//
//  ContentManager.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Async
import HealthKit
import MetabolicCompassKit

class ContentManager: NSObject {
    
    static let ContentDidUpdateNotification = "ContentDidUpdateNotification"
    
    private var aggregateFetchTask : Async? = nil    // Background task to fetch population aggregates.
    var isBackgroundWorkActive = false
    
    internal func initializeBackgroundWork() {
        Async.main() {
            
            if (self.isBackgroundWorkActive) {
                return
            }
            
            self.fetchInitialAggregates()
            self.fetchRecentSamples()
            self.isBackgroundWorkActive = true
            HealthManager.sharedManager.registerObservers()
        }
    }
    
    func stopBackgroundWork() {
        
        Async.main() {
            // Clean up aggregate data fetched via the prior account.
            if let task = self.aggregateFetchTask {
                task.cancel()
                self.aggregateFetchTask = nil
                self.isBackgroundWorkActive = false
            }
        }
    }
    
    func resetBackgroundWork() {
        self.stopBackgroundWork()
        self.initializeBackgroundWork()
    }
    
    func fetchInitialAggregates() {
        aggregateFetchTask = Async.background {
            self.fetchAggregatesPeriodically()
        }
    }
    
    func fetchAggregatesPeriodically() {
        PopulationHealthManager.sharedManager.fetchAggregates()
        let freq = UserManager.sharedManager.getRefreshFrequency()
        aggregateFetchTask = Async.background(after: Double(freq)) {
            self.fetchAggregatesPeriodically()
        }
    }
    
    func fetchRecentSamples() {
        
        AccountManager.shared.withHKCalAuth {
            HealthManager.sharedManager.fetchMostRecentSamples() { (samples, error) -> Void in
                guard error == nil else { return }
                NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
            }
        }
    }
    
}
