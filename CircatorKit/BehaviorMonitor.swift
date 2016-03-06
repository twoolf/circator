//
//  BehaviorMonitor.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/8/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Fabric
import Crashlytics
import SwiftDate

/**
A helper class defining user behavior events available for tracking via Fabric and Crashlytics Answers.

*/
public class BehaviorMonitor {
    public static let sharedInstance = BehaviorMonitor()

    public func showView(viewName: String, contentType: String) {
        NSLog("in showView for Answers")
        Answers.logContentViewWithName(viewName, contentType: "Show:" + contentType,
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    public func setValue(viewName: String, contentType: String) {
        NSLog("in setValue for Answers")
        Answers.logContentViewWithName(viewName,
            contentType: "Set:" + contentType,
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    public func login(success: Bool) {
        NSLog("in login for Answers")
        Answers.logLoginWithMethod("SPL", success: success, customAttributes: nil)
    }

    public func register(success: Bool) {
        Answers.logSignUpWithMethod("SPR", success: success, customAttributes: nil)
    }
}