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
    var isObservationActive = false

    internal func initializeBackgroundWork() {
        if (!AccountManager.shared.isLogged() ||
            !AccountManager.shared.isAuthorized) {
            return
        }

        Async.main() {
            if (self.isBackgroundWorkActive) {
                return
            }
            self.fetchInitialAggregates()
            self.fetchRecentSamples()
            self.isBackgroundWorkActive = true
            if !self.isObservationActive {
                HealthManager.sharedManager.registerObservers()
                self.isObservationActive = true
            }
            AccountManager.shared.withHKCalAuth {
                HealthManager.sharedManager.collectDataForCharts()
            }
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
        UserManager.sharedManager.ensureAccessToken { error in
            // Do not fetch any aggregates if we do not have a valid access token.
            // Regardless, we try to fetch the aggregates again, with the next request also
            // attempting to ensure a valid access token even if we did not get one this time.
            if error {
                log.warning("Could not ensure an access token while fetching aggregates, trying later...")
            } else {
                PopulationHealthManager.sharedManager.fetchAggregates()
            }
            let freq = UserManager.sharedManager.getRefreshFrequency()
            self.aggregateFetchTask = Async.background(after: Double(freq)) {
                self.fetchAggregatesPeriodically()
            }
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
