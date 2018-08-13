//
//  FrequentActivity.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.    
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import MCCircadianQueries

class FrequentActivity: NSObject, NSCoding {
    var desc: String
    var start: Date
    var duration: Double

    static var descKey = "desc"
    static var startKey = "st"
    static var durationKey = "dur"

    init(desc: String, start: Date, duration: Double) {
        self.desc = desc
        self.start = start
        self.duration = duration
    }

    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let desc = aDecoder.decodeObject(forKey: FrequentActivity.descKey) as? String else { return nil }
        guard let start = aDecoder.decodeObject(forKey: FrequentActivity.startKey) as? Date else { return nil }
        let duration = aDecoder.decodeDouble(forKey: FrequentActivity.durationKey)
        self.init(desc: desc, start: start, duration: duration)
    }
    
/*    internal func init(coder aDecoder: NSCoder) {

    } */

    internal func encode(with aCoder: NSCoder) {
        aCoder.encode(self.desc, forKey: FrequentActivity.descKey)
        aCoder.encode(self.start, forKey: FrequentActivity.startKey)
        aCoder.encode(self.duration, forKey: FrequentActivity.durationKey)
    }
}

class FrequentActivityInfo: NSObject, CachableObject {
    public func encode(with aCoder: NSCoder) {
        return print ("here at 46")
    }


    static var activitiesKey = "activities"

    internal var activities: [FrequentActivity] = []

    init(activities: [FrequentActivity]) {
        self.activities = activities
    }

    required internal convenience init?(coder aDecoder: NSCoder) {
        guard let activities = aDecoder.decodeObject(forKey: FrequentActivityInfo.activitiesKey) as? [FrequentActivity] else { return nil }
        self.init(activities: activities)
    }
    
    internal func initWithCoder(coder aDecoder: NSCoder) {
        
    }

    internal func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encode(self.activities, forKey: FrequentActivityInfo.activitiesKey)
    }
    
    override init() {
        super.init()
    }
}
