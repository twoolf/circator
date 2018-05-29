//
//  ExtensionDelegate.swift
//  MetabolicCompassWatch Extension
//
//  Created by Olena Ostrozhynska on 23.10.17.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    private var connectivityBackgroundTasks: [WKWatchConnectivityRefreshBackgroundTask] = []
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        ComplicationDataManager.applyComplication(data: userInfo)
        reloadComplications()
        if !session.hasContentPending {
            connectivityBackgroundTasks.forEach({ (task) in
                task.setTaskCompletedWithSnapshot(false)
            })
        }
    }

    func applicationDidFinishLaunching() {
    }

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session  = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

   public func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityBackgroundTasks.append(connectivityTask)
                if WCSession.isSupported() {
                    let session  = WCSession.default
                    session.delegate = self
                    if session.activationState != .activated {
                        session.activate()
                    }
                }
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    private func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        guard let complications = server.activeComplications, complications.count > 0 else {
            return
        }
        
        for complication in complications  {
            server.reloadTimeline(for: complication)
        }
    }
}
