//
//  ExtensionDelegate.swift
//  MetabolicCompassWatch Extension
//
//  Created by Olena Ostrozhynska on 23.10.17.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import WatchConnectivity

@available(watchOSApplicationExtension 4.0, *)
@available(watchOSApplicationExtension 4.0, *)
@available(watchOSApplicationExtension 4.0, *)
class ExtensionDelegate: NSObject, WKExtensionDelegate {
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//    }
//
//    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
////        print("Did receive user info")
//        MetricsStore.sharedInstance.fastingTime = userInfo["key"] as! String
////        reloadComplications()
//
//        ComplicationDataManager.reloadComplications()
//    }
//
//    func applicationDidFinishLaunching() {
//    }
//
//    override init() {
//        super.init()
//        if WCSession.isSupported() {
//            let session  = WCSession.default
//            session.delegate = self
//            session.activate()
//        }
//    }
//

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
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
