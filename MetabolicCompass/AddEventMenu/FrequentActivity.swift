//
//  FrequentActivity.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation

class FrequentActivity: NSObject, NSCoding {
    var desc: String
    var start: NSDate
    var duration: Double

    static var descKey = "desc"
    static var startKey = "st"
    static var durationKey = "dur"

    init(desc: String, start: NSDate, duration: Double) {
        self.desc = desc
        self.start = start
        self.duration = duration
    }

    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let desc = aDecoder.decodeObjectForKey(FrequentActivity.descKey) as? String else { return nil }
        guard let start = aDecoder.decodeObjectForKey(FrequentActivity.startKey) as? NSDate else { return nil }
        let duration = aDecoder.decodeDoubleForKey(FrequentActivity.durationKey)
        self.init(desc: desc, start: start, duration: duration)
    }

    internal func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.desc, forKey: FrequentActivity.descKey)
        aCoder.encodeObject(self.start, forKey: FrequentActivity.startKey)
        aCoder.encodeDouble(self.duration, forKey: FrequentActivity.durationKey)
    }
}

class FrequentActivityInfo: NSObject, NSCoding {

    static var activitiesKey = "activities"

    internal var activities: [FrequentActivity] = []

    init(activities: [FrequentActivity]) {
        self.activities = activities
    }

    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let activities = aDecoder.decodeObjectForKey(FrequentActivityInfo.activitiesKey) as? [FrequentActivity] else { return nil }
        self.init(activities: activities)
    }

    internal func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.activities, forKey: FrequentActivityInfo.activitiesKey)
    }
}
