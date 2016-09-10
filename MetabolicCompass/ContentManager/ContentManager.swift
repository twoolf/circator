//
//  ContentManager.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import ReachabilitySwift

class ContentManager: NSObject {

    static let ContentDidUpdateNotification = "ContentDidUpdateNotification"

    private var aggregateFetchTask : Async? = nil    // Background task to fetch population aggregates.
    var isBackgroundWorkActive = false
    var isObservationActive = false

    private var reachability: Reachability! = nil

    override init() {
        do {
            self.reachability = try Reachability.reachabilityForInternetConnection()
            super.init()

            self.reachability.whenReachable = self.handleReachable
            self.reachability.whenUnreachable = self.handleUnreachable
            try self.reachability.startNotifier()
        } catch {
            let msg = "Failed to create reachability detector"
            log.error(msg)
            fatalError(msg)
        }
    }

    internal func initializeBackgroundWork() {
        if (!AccountManager.shared.isLogged() ||
            !AccountManager.shared.isAuthorized) {
            return
        }

        if !reachability.isReachable() {
            log.info("Skipping background work, network unreachable!")
            return
        }

        Async.main() {
            if (self.isBackgroundWorkActive) {
                return
            }

            log.warning("Starting background work")
            self.fetchInitialAggregates()
            self.fetchRecentSamples()
            self.isBackgroundWorkActive = true
            AccountManager.shared.withHKCalAuth {
                IOSHealthManager.sharedManager.collectDataForCharts()
            }
            if !self.isObservationActive {
                UploadManager.sharedManager.registerUploadObservers()
                self.isObservationActive = true
            }
        }
    }

    func stopBackgroundWork() {
        Async.main() {
            // Clean up aggregate data fetched via the prior account.
            if let task = self.aggregateFetchTask {
                log.warning("Stopping background work")
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

    func stopObservation() {
        Async.main() {
            if (!self.isObservationActive) {
                return
            }
            log.warning("Stopping background observers")
            UploadManager.sharedManager.deregisterUploadObservers { (success, error) in
                guard success && error == nil else {
                    log.error(error)
                    return
                }
                log.warning("Stopped background observers")
                self.isObservationActive = false
            }
        }
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
            MCHealthManager.sharedManager.fetchMostRecentSamples(ofTypes: PreviewManager.previewSampleTypes) { (samples, error) -> Void in
                guard error == nil else { return }
                NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
            }
        }
    }

    func handleReachable(reachability: Reachability) {
        log.info("Reachable via \(reachability.isReachableViaWiFi() ? "Wi-fi" : "Cellular")")
        self.initializeBackgroundWork()
    }

    func handleUnreachable(reachability: Reachability) {
        log.info("Network unreachable, disabling connectivity...")
        self.stopObservation()
        self.stopBackgroundWork()
    }

    deinit {
        reachability.stopNotifier()
    }
}
