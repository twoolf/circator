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

class Sample: Object {

    dynamic var id: String = ""
    
    dynamic var userID: Int = 0 {
        didSet {
            id = "\(userID)\(sampleID)"
        }
    }
    dynamic var sampleID: Int = 0 {
        didSet {
            id = "\(userID)\(sampleID)"
        }
    }
    
    convenience init(userID: Int, sampleID: Int) {
        self.init(value: ["userID": userID, "sampleID": sampleID])
    }

    dynamic var sleep = 0.0  // Sleep in minutes
    dynamic var weight = 0.0  // Weight in lbs
    dynamic var heartRate = 0.0
    dynamic var totalCalories = 0.0
    dynamic var bloodPressure = 0.0

    override static func primaryKey() -> String? {
        return "id"
    }
    
    func asDict() -> [String:AnyObject] {
        return ["userID":userID, "sampleID":sampleID,
                "sleep":sleep, "weight":weight, "heartRate":heartRate,
                "totalCalories":totalCalories, "bloodPressure":bloodPressure]
    }

    func asJSON () -> JSON {
        return JSON(self.asDict())
    }

    static func attributes() -> [String] {
        return ["Sleep", "Weight", "Heart Rate", "Calories", "BP"]
    }

    static func attrnames() -> [String] {
        return ["sleep", "weight", "heartRate", "totalCalories", "bloodPressure"]
    }
}

class WorkloadGenerator {
    func generate(num_users: Int, samples_per_user: Float, param_dict: [String: (Float,Float)]?) {
        let realm = try! Realm()
        let random = GKRandomSource()
        
        // Create distributions for each attribute
        let (slm,sls) = (param_dict?["sleep"]!)!
        let (wtm,wts) = (param_dict?["weight"]!)!
        let (hrm,hrs) = (param_dict?["heartRate"]!)!
        let (tcm,tcs) = (param_dict?["totalCalories"]!)!
        let (bpm,bps) = (param_dict?["bloodPressure"]!)!
        
        let sidDist = GKGaussianDistribution(randomSource: random, mean: samples_per_user, deviation: 10)
        let slDist  = GKGaussianDistribution(randomSource: random, mean: slm, deviation: sls)
        let wtDist  = GKGaussianDistribution(randomSource: random, mean: wtm, deviation: wts)
        let hrDist  = GKGaussianDistribution(randomSource: random, mean: hrm, deviation: hrs)
        let tcDist  = GKGaussianDistribution(randomSource: random, mean: tcm, deviation: tcs)
        let bpDist  = GKGaussianDistribution(randomSource: random, mean: bpm, deviation: bps)

        let dists = [(0,slDist), (1,wtDist), (2,hrDist), (3,tcDist), (4,bpDist)]
        
        for i in 0..<num_users {
            var argdict = [String : AnyObject]()
            argdict["userID"] = i
            for j in 0..<sidDist.nextInt() {
                argdict["sampleID"] = j
                for (idx,k) in dists {
                    argdict[Sample.attrnames()[idx]] = k.nextInt()
                }
                let x = Sample(value: argdict)
                try! realm.write { realm.add(x) }
            }
        }
    }
}