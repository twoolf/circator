//
//  StudyStatsModel.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 10/8/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

public class StudyStatsModel: NSObject {
    public var activeUsers: Int = -1
    public var userRank: Int = -1
    public var contributionStreak: Int = -1
    public var ringValues: [(Double, Double)] = []
    public var fullDays: Int = -1
    public var partialDays: Int = -1

    public convenience init(ringIndexKeys: [String], studystats: [String:AnyObject]) {
        self.init()

        let getInt : String -> Int = { key in
            if let u = studystats[key] as? Int {
                return u
            } else if let s = studystats[key] as? String, u = Int(s) {
                return u
            } else {
                return -1
            }
        }

        self.activeUsers        = getInt("active_users")
        self.userRank           = getInt("user_rank")
        self.contributionStreak = getInt("contribution_streak")
        self.fullDays           = getInt("full_days")
        self.partialDays        = getInt("partial_days")

        self.ringValues = ringIndexKeys.enumerate().map { (index, key) in
            var value: Double! = nil
            if let v = studystats[key] as? Double {
                value = v
            } else if let s = studystats[key] as? String, v = Double(s) {
                value = v
            }

            if value == nil {
                return (-1,-1)
            } else {
                if index == 1 { value = value * 100.0 }
                let target = pow(10, ceil(log10(value)))
                return (value, target)
            }
        }
    }

    func logModel() {
        log.info("activeUsers: \(activeUsers)")
        log.info("userRank: \(userRank)")
        log.info("contributionStreak: \(contributionStreak)")
        log.info("fullDays: \(fullDays)")
        log.info("partialDays: \(partialDays)")
        log.info("ringValues: \(ringValues)")
    }
}
