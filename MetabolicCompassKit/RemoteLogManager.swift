//
//  RemoteLog.swift
//  MCCircadianQueries
//
//  Created by Yanif Ahmad on 1/14/17.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//
/*
import Foundation
import MCCircadianQueries
import Alamofire
import Async
//import LogKit
import SwiftDate
import SwiftyUserDefaults

// Map of filenames to log modules.
private let MCLogModules : [String: String] = [
    // MCCircadianQueries
    "MCHealthManager.swift"         : "HealthManager",

    // MCKit
    "IOSHealthManager.swift"        : "HealthManager",
    "NotificationManager.swift"     : "NotificationManager",
    "PopulationHealthManager.swift" : "PopulationHealthManager",
    "RemoteLogManager.swift"        : "RemoteLogManager",
    "ServiceAPI.swift"              : "API",
    "UploadManager.swift"           : "UploadManager",
    "UserManager.swift"             : "UserManager",

    // MC
    "UserInfoModel.swift"           : "Common",
    "BarChartModel.swift"           : "Charts",

    "AccountManager.swift"          : "Login",
    "ContentManager.swift"          : "Login",
    "LoginModel.swift"              : "Login",
    "RegistrationModel.swift"       : "Login",

    // Activity tracking (add/delete events)
    "AddActivityManager.swift"      : "ActivityTracking",
    "DeleteActivityManager.swift"   : "ActivityTracking",
    "ManageEventMenu.swift"         : "ActivityTracking",
    "ActivityPicker.swift"          : "ActivityTracking",
    "AddEventModel.swift"           : "ActivityTracking",

    // Dashboard (comparison and balance)
    "MainTabController.swift"               : "Dashboard",
    "DashboardComparisonController.swift"   : "Dashboard",
    "RadarViewController.swift"             : "Dashboard",
    "ComparisonDataModel.swift"             : "Dashboard",

    // Cycle view
    "DialViewController.swift"              : "Cycle",
    "CycleDataModel.swift"                  : "Cycle",

    // Body clock view
    "DailyProgressViewController.swift"     : "BodyClock",
    "MetabolicDailyProgressChartView.swift" : "BodyClock",
    "DailyChartModel.swift"                 : "BodyClock",

    // Analysis
    "FastingViewController.swift"           : "Fasting",
    "FastingDataModel.swift"                : "Fasting",

    "CorrelationChartsViewController.swift" : "Correlation",

    "OurStudyViewController.swift"          : "OurStudy",
    "StudyStatsModel.swift"                 : "OurStudy",

    // Settings (profile, user settings, etc)
    "MainSetingsViewController.swift"       : "Settings",
    "ProfileViewController.swift"           : "Settings",
    "PhysiologicalDataViewController.swift" : "Settings",
    "UserSettingsViewController.swift"      : "Settings",
    "ConsentViewController.swift"           : "Settings",
    "ProfileModel.swift"                    : "Settings"
]

// TODO
// Map of log features to log modules.
private let MCLogFeatures : [String: String] = [

    // HealthManager
    "fetchMostRecentSamples"                        : "HealthManager",
    "cache:fetchMostRecentSamples"                  : "HealthManager",

    "fetchSamples"                                  : "HealthManager",
    "status:fetchSamples"                           : "HealthManager",

    "fetchSampleAggregatesOfType"                   : "HealthManager",
    "fetchAggregatesOfType"                         : "HealthManager",

    "cache:getStatisticsOfTypeForPeriod"            : "HealthManager",
    "cache:getDailyStatisticsOfTypeForPeriod"       : "HealthManager",
    "cache:getMinMaxOfTypeForPeriod"                : "HealthManager",

    "fetchCircadianEventIntervals"                  : "HealthManager",
    "cache:fetchCircadianEventIntervals"            : "HealthManager",

    "fetchSampleCollectionDays"                     : "HealthManager",
    "cache:fetchSampleCollectionDays"               : "HealthManager",

    "fetchWeeklyFastingVariability"                 : "HealthManager",
    "fetchDailyFastingVariability"                  : "HealthManager",
    "fetchWeeklyFastState"                          : "HealthManager",
    "fetchWeeklyFastType"                           : "HealthManager",
    "fetchWeeklyEatAndExercise"                     : "HealthManager",

    "anchorQuery"                                   : "HealthManager",
    "clearCache"                                    : "HealthManager",
    "fetchCharts"                                   : "HealthManager",
    "invalidateCache"                               : "HealthManager",
    "parallelCircadian"                             : "HealthManager",
    "registerObservers"                             : "HealthManager",
    "saveActivity"                                  : "HealthManager",

    // UploadManager
    "logEntries"                                    : "UploadManager",
    "entryConstruction"                             : "UploadManager",

    "resetState"                                    : "UploadManager",
    "skip:resetState"                               : "UploadManager",
    "metadata:resetState"                           : "UploadManager",

    "remoteAnchor"                                  : "UploadManager",
    "getNextAnchor"                                 : "UploadManager",

    "uploadStatus"                                  : "UploadManager",
    "uploadProgress"                                : "UploadManager",
    "uploadRetries"                                 : "UploadManager",
    "uploadRealmSync"                               : "UploadManager",

    "uploadExec"                                    : "UploadManager",
    "perf:uploadExec"                               : "UploadManager",
    "serialize:uploadExec"                          : "UploadManager",
    "realm:uploadExec"                              : "UploadManager",

    "deleteSamples"                                 : "UploadManager",

    "uploadObservers"                               : "UploadManager",

    "syncSeqIds"                                    : "UploadManager",
    "status:syncSeqIds"                             : "UploadManager",

    // NotificationManager
    "initManager"                                   : "NotificationManager",

    "FStreak"                                       : "NotificationManager",
    "CStreak"                                       : "NotificationManager",
    "FCStreak"                                      : "NotificationManager",

    "execNotify"                                    : "NotificationManager",
    "cancel:execNotify"                             : "NotificationManager",
    "state:execNotify"                              : "NotificationManager",

    // PopulationManager
    "execPop"                                       : "PopulationHealthManager",
    "cachePop"                                      : "PopulationHealthManager",
    "refreshPop"                                    : "PopulationHealthManager",

    // Login-related
    "loginExec"                                     : "Login",
    "accountExec"                                   : "Login",
    "notifications"                                 : "Login",
    "uploadConsent"                                 : "Login",
    "reachability"                                  : "Login",
    "popLoop"                                       : "Login",

    // Activity tracking
    "appIntegration"                                : "ActivityTracking",
    "freqActivity"                                  : "ActivityTracking",
    "cache:freqActivity"                            : "ActivityTracking",
    "addActivity"                                   : "ActivityTracking",
    "deleteActivity"                                : "ActivityTracking",

    // Dashboard
    "comparison"                                    : "Dashboard",
    "dataSync"                                      : "Dashboard",
    "addActivityView"                               : "Dashboard",

    // Cycle module: no features

    // Body clock
    "dataLoad"                                      : "BodyClock",
    "invalidateCache"                               : "BodyClock",
    "prepareChart"                                  : "BodyClock",

    // Fasting

    // Correlation

    // OurStudy

    // Settings
]

public let RLogExpiryKey = "RLogExpiryKey"
public let RLogDidExpire = "RLogDidExpire"

public class RemoteLogManager {

//    public let log = RemoteLog.sharedInstance

    public static let sharedManager = RemoteLogManager(
        token: "INVALID"
    )

    private let defaultName = "Default"
    private let defaultConfig: [String: AnyObject] = [
        "API"               : LXPriorityLevel.Info.rawValue,
        "RemoteLogManager"  : LXPriorityLevel.Debug.rawValue,

        "Login"             : [
            "default"                       : LXPriorityLevel.Info.rawValue,
            "loginExec"                     : LXPriorityLevel.Debug.rawValue,
            "accountExec"                   : LXPriorityLevel.Debug.rawValue,
        ],

        "HealthManager"     : [
            "default"                       : LXPriorityLevel.Info.rawValue,
            //"anchorQuery"                   : LXPriorityLevel.Debug.rawValue,
            //"invalidateCache"               : LXPriorityLevel.Debug.rawValue,
            //"fetchMostRecentSamples"        : LXPriorityLevel.Debug.rawValue,
            //"cache:fetchMostRecentSamples"  : LXPriorityLevel.Debug.rawValue,
        ],

        "UploadManager"     : [
            "default"                       : LXPriorityLevel.Info.rawValue,
            //"remoteAnchor"                  : LXPriorityLevel.Debug.rawValue,
            //"getNextAnchor"                 : LXPriorityLevel.Debug.rawValue,
            "syncSeqIds"                    : LXPriorityLevel.Debug.rawValue,
            "status:syncSeqIds"             : LXPriorityLevel.Debug.rawValue,
        ],

        "NotificationManager" : [
            "default"                       : LXPriorityLevel.Info.rawValue,

            "initManager"                   : LXPriorityLevel.Debug.rawValue,
            "FStreak"                       : LXPriorityLevel.Debug.rawValue,
            "CStreak"                       : LXPriorityLevel.Debug.rawValue,
            "FCStreak"                      : LXPriorityLevel.Debug.rawValue,
            "execNotify"                    : LXPriorityLevel.Debug.rawValue,
            "cancel:execNotify"             : LXPriorityLevel.Debug.rawValue,
        ],

        "PopulationHealthManager" : [
            "default"                       : LXPriorityLevel.Info.rawValue,
            "execPop"                       : LXPriorityLevel.Debug.rawValue,
        ],

        "Dashboard"             : [
            "default"                       : LXPriorityLevel.Info.rawValue,
            "comparison"                    : LXPriorityLevel.Debug.rawValue,
        ]
    ]

    init(token: String) {
        let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? "<no-id>"
        Async.customQueue(log.configQueue) {
            self.log.setDeviceId(deviceId)
            if self.log.url == nil { self.log.setURL(token); self.log.loadRemote() }

            // Set default config if we have an empty config, or if the config has expired.
            let now = Date()
            let expiry = Defaults.objectForKey(RLogExpiryKey) as? Date ?? now
            if now > expiry { self.resetConfig() }
            else if self.log.configName == MCInitLogConfigName { self.log.setLogConfig(self.defaultName, cfg: self.defaultConfig) }

            self.log.setLogModules(MCLogModules)
        }
    }

    func parseLogConfig(c: [String: AnyObject]) -> [String: AnyObject]? {
        var failed = false

        let nc: [(String, AnyObject)] = c.flatMap({ k,v in
            if let nested = v as? [String:AnyObject] {
                let nv: [(String, AnyObject)] = nested.flatMap({ k2,v2 in
                    if let l2 = v2 as? String, let p2 = self.log.priority(l2) { return (k2, p2.rawValue) }
                    log.debug("Skipping log config entry: \(k), \(k2) => \(v2)")
                    failed = true
                    return nil
                })
                return (k, Dictionary(pairs: nv))
            }
            else if let flat = v as? String, let p = self.log.priority(flat) {
                return (k, p.rawValue)
            }
            log.debug("Skipping log config entry: \(k) => \(v)")
            failed = true
            return nil
        })
        return failed ? nil : Dictionary(pairs: nc)
    }

    public func reconfigure(completion: @escaping (Bool) -> Void) -> Void {
        Service.json(MCRouter.RLogConfig, statusCode: 200..<300, tag: "GRLOG") {
            _, _, result in
            let pullSuccess = result.isSuccess
            if let rv = result.value as? [String: AnyObject], pullSuccess {
                self.log.debug("Log reconfiguration result: \(rv)")
                if let n = rv["name"] as? String,
                    let c = rv["config"] as? [String: AnyObject], let cfg = self.parseLogConfig(c)
                {
                    if let ttl = rv["ttl"] as? Int {
                        let ttlSecs = ttl * 60
                        let expiry = Date() + ttlSecs.seconds
                        self.log.debug("Reconfiguration TTL: \(ttl), date: \(expiry)")
                        Defaults.setObject(expiry, forKey: RLogExpiryKey)
                        NSTimer.scheduledTimerWithTimeInterval(Double(ttlSecs), target: self, selector: #selector(self.resetConfig), userInfo: nil, repeats: false)
                    }
                    self.log.setLogConfig(n, cfg: cfg)
                }
                else {
                    self.log.error("Invalid remote logging config: \(rv)")
                }
            }
            completion(pullSuccess)
        }
    }

    @objc func resetConfig() {
        self.log.debug("Resetting remote log to a default configuration")
        self.log.setLogConfig(self.defaultName, cfg: self.defaultConfig)
        NotificationCenter.defaultCenter().postNotificationName(RLogDidExpire, object: self)
    }
} */