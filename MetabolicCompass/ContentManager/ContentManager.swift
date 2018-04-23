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
    var isDeviceSyncActive = false

    private var reachability: Reachability! = nil

    override init() {
        do {
//            self.reachability = try Reachability.reachabilityForInternetConnection()
            self.reachability = Reachability()
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

        if !reachability.isReachable {
            log.debug("Skipping background work, network unreachable!", feature: "reachability")
            return
        }

//        Async.main() {
        OperationQueue.main.addOperation {
            if (self.isBackgroundWorkActive) {
                return
            }

            log.debug("Starting background work", feature: "accountExec")
            self.isBackgroundWorkActive = true

            self.fetchInitialAggregates()

            ComparisonDataModel.sharedManager.updateIndividualData(types: PreviewManager.previewSampleTypes) { _ in
                AccountManager.shared.withHKCalAuth {
                    log.debug("Prefetching charts", feature: "accountExec")
                    IOSHealthManager.sharedManager.collectDataForCharts()
                }
            }

            if !self.isObservationActive {
                log.debug("Registering upload observers", feature: "accountExec")
                UploadManager.sharedManager.registerUploadObservers()
                self.isObservationActive = true
            }

            if !self.isDeviceSyncActive {
                log.debug("Starting seqid sync loop", feature: "accountExec")
                UploadManager.sharedManager.syncDeviceMeasuresPeriodically()
                self.isDeviceSyncActive = true
            }
        }
    }

    func stopBackgroundWork() {
//        Async.main() {
        OperationQueue.main.addOperation {
            // Clean up aggregate data fetched via the prior account.
            if let task = self.aggregateFetchTask {
                log.debug("Stopping background work", feature: "accountExec")
                task.cancel()
                self.aggregateFetchTask = nil
                self.isBackgroundWorkActive = false
            }
        }
    }

    func stopObservation() {
 //       Async.main() {
        OperationQueue.main.addOperation {
            if (!self.isObservationActive) {
                return
            }
            log.debug("Stopping background observers", feature: "accountExec")
            UploadManager.sharedManager.deregisterUploadObservers { (success, error) in
                guard success && error == nil else {
                    log.error(error!.localizedDescription)
                    return
                }
                log.debug("Stopped background observers", feature: "accountExec")
                self.isObservationActive = false
            }
        }
    }

    func fetchInitialAggregates() {
        if let task = aggregateFetchTask { task.cancel() }
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
                log.warning("Could not ensure an access token while fetching aggregates, trying later...", feature: "popLoop")
            } else {
                let populationTypes = PreviewManager.previewSampleTypes
                PopulationHealthManager.sharedManager.fetchAggregates(previewTypes: populationTypes) { error in
                    guard error == nil else { return }
                    ComparisonDataModel.sharedManager.updatePopulationData(types: populationTypes)
                }
            }
            let freq = UserManager.sharedManager.getRefreshFrequency()
            self.aggregateFetchTask = Async.background(after: Double(freq)) {
                self.fetchAggregatesPeriodically()
            }
        }
    }

    func handleReachable(reachability: Reachability) {
        log.debug("Reachable via \(reachability.isReachableViaWiFi ? "Wi-fi" : "Cellular")", feature: "reachability")
        self.initializeBackgroundWork()
    }

    func handleUnreachable(reachability: Reachability) {
        log.debug("Network unreachable, disabling connectivity...", feature: "reachability")
        self.stopObservation()
        self.stopBackgroundWork()
    }

    deinit {
        reachability.stopNotifier()
    }
}
