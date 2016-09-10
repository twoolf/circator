//
//  MetricsStore.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class MetricsStore {
    static let sharedInstance = MetricsStore()
    var weight: String = "139"
    var BMI: String = "23.1"
    var DietaryEnergy: String = "1970"
    var HeartRate: String = "60"
    var StepCount: String = "10001"
    var ActiveEnergy: String = "1200"
    var RestingEnergy: String = "900"
    var Sleep: NSDate = NSDate()
    var Exercise: NSDate = NSDate()
    var UVExposure: String = "8"
    var Protein: String = "1215"
    var Carbohydrate: String = "1776"
    var Fat: String = "1770"
    var Fiber: String = "50"
    var Sugar: String = "75"
    var Salt: String = "20"
    var Caffeine: String = "22"
    var Cholesterol: String = "12"
    var PolyunsaturatedFat: String = "17"
    var SaturatedFat: String = "12"
    var MonosaturatedFat: String = "8"
    var Water: String = "800 ml"
    var BloodPressure: String = "120/80"
    var fastingTime = "no data"
    var currentFastingTime = "none"
    var lastEatingTime = "no data"
    var lastAte = "no data"
    var lastAteAsNSDate: NSDate = NSDate()
    var cumulativeWeeklyFasting = "7"
    var cumulativeWeeklyNonFast = "14"
    var weeklyFastingVariability = "2"
    var samplesCollected = "100"
    var fastSleep = "5"
    var fastAwake = "6"
    var fastEat = "7"
    var fastExercise = "8"
}

