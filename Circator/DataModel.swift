//
//  DataModel.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import RealmSwift

class Sample : Object {

    dynamic lazy var id : String = self.key() // Primary key as (user_id)(sample_id)

    func key () -> String { return "\(user_id)\(sample_id)" }
    func refreshKey () { id = key () }
    
    dynamic var user_id   = 0
    dynamic var sample_id = 0

    func setUserID(i: Int) {
        self.user_id = i
        id = key()
    }

    func setSampleID(i: Int) {
        self.sample_id = i
        id = key()
    }
    
    dynamic var sleep          = 0.0  // Sleep in minutes
    dynamic var weight         = 0.0  // Weight in lbs
    dynamic var heart_rate     = 0.0
    dynamic var total_calories = 0.0
    dynamic var blood_pressure = 0.0

    override static func primaryKey() -> String? {
        return "id"
    }

    static func attributes() -> [String] {
        return ["Sleep", "Weight", "Heart Rate", "Calories", "BP"]
    }

    static func attrnames() -> [String] {
        return ["sleep", "weight", "heart_rate", "total_calories", "blood_pressure"]
    }
}
