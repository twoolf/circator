//
//  DataModel.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import RealmSwift
import GameplayKit
import SwiftyJSON

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
    
    func asDict() -> [String:AnyObject] {
        return ["user_id":user_id, "sample_id":sample_id,
                "sleep":sleep, "weight":weight, "heart_rate":heart_rate,
                "total_calories":total_calories, "blood_pressure":blood_pressure]
    }

    func asJSON () -> JSON {
        return JSON(self.asDict())
    }

    static func attributes() -> [String] {
        return ["Sleep", "Weight", "Heart Rate", "Calories", "BP"]
    }

    static func attrnames() -> [String] {
        return ["sleep", "weight", "heart_rate", "total_calories", "blood_pressure"]
    }
}

class WorkloadGenerator {
    func generate(num_users : Int, samples_per_user : Float, param_dict : [String : (Float,Float)]?) {
        let realm = try! Realm()
        let random = GKRandomSource()
        
        // Create distributions for each attribute
        let (slm,sls) = (param_dict?["sleep"]!)!
        let (wtm,wts) = (param_dict?["weight"]!)!
        let (hrm,hrs) = (param_dict?["heart_rate"]!)!
        let (tcm,tcs) = (param_dict?["total_calories"]!)!
        let (bpm,bps) = (param_dict?["blood_pressure"]!)!
        
        let sidDist = GKGaussianDistribution(randomSource: random, mean: samples_per_user, deviation: 10)
        let slDist  = GKGaussianDistribution(randomSource: random, mean: slm, deviation: sls)
        let wtDist  = GKGaussianDistribution(randomSource: random, mean: wtm, deviation: wts)
        let hrDist  = GKGaussianDistribution(randomSource: random, mean: hrm, deviation: hrs)
        let tcDist  = GKGaussianDistribution(randomSource: random, mean: tcm, deviation: tcs)
        let bpDist  = GKGaussianDistribution(randomSource: random, mean: bpm, deviation: bps)

        let dists = [(0,slDist), (1,wtDist), (2,hrDist), (3,tcDist), (4,bpDist)]
        
        for i in 0..<num_users {
            var argdict = [String : AnyObject]()
            argdict["user_id"] = i
            for j in 0..<sidDist.nextInt() {
                argdict["sample_id"] = j
                for (idx,k) in dists {
                    argdict[Sample.attrnames()[idx]] = k.nextInt()
                }
                let x = Sample(value: argdict)
                x.refreshKey()
                try! realm.write { realm.add(x) }
            }
        }
    }
}