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
    
    
    internal func initializeBackgroundWork() {
        Async.main() {
            self.fetchInitialAggregates()
            self.fetchRecentSamples()
            HealthManager.sharedManager.registerObservers()
        }
    }
    
    func stopBackgroundWork() {
        // Clean up aggregate data fetched via the prior account.
        if let task = aggregateFetchTask {
            task.cancel()
            aggregateFetchTask = nil
        }
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
            
            Async.main() {
                NSNotificationCenter.defaultCenter().postNotificationName(ContentManager.ContentDidUpdateNotification, object: self)
            }
        }
    }
    
    func fetchRecentSamples() {
        
        AccountManager.shared.withHKCalAuth {
            HealthManager.sharedManager.fetchMostRecentSamples() { (samples, error) -> Void in
                guard error == nil else { return }
                NSNotificationCenter.defaultCenter().postNotificationName(ContentManager.ContentDidUpdateNotification, object: self)
            }
        }
    }
    
}
