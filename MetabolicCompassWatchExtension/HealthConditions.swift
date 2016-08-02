//
//  HealthConditions.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import WatchConnectivity
import WatchKit

final class HealthConditions: NSObject {
    private static let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter
    }()
    
    var metrics: MetricDescriptions
    var weightMetrics: [WeightMetric] = []
    var averageWeightMetric: Double = 0
    var currentWeightMetric: WeightMetric? {
        return weightMetrics.count > 0 ? weightMetrics[weightMetrics.count/2] : nil
    }
    
    init(metrics: MetricDescriptions) {
        self.metrics = metrics
        super.init()
    }
    
    func readMostRecentSample(sampleType:
        HKSampleType , completion: ((HKSample!, NSError!) -> Void)!)
    {
        var weight:HKQuantitySample?
        let height:HKQuantitySample?
        var bmi:Double = 22.0
        let kUnknownString   = "Unknown"
        var HKBMIString:String = "24.0"
        let healthKitStore:HKHealthStore = HKHealthStore()
        let past = NSDate.distantPast()
        let now   = NSDate()
        let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        let limit = 1
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
        { (sampleQuery, results, error ) -> Void in
            if error != nil {
                completion(nil,error)
                return;
            }
            let mostRecentSample = results!.first as? HKQuantitySample
            if completion != nil {
                completion(mostRecentSample,nil)
            }
        }
        healthKitStore.executeQuery(sampleQuery)
    }
    
    func updateWeight()
    {
        let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        var weight:HKQuantitySample?
//        let height:HKQuantitySample?
//        _:Double = 22.0
        let kUnknownString   = "Unknown"
//        var HKBMIString:String = "24.0"
//        let healthKitStore:HKHealthStore = HKHealthStore()
        readMostRecentSample(sampleType!, completion: { (mostRecentWeight, error) -> Void in
            
            if( error != nil )
            {
                print("Error reading weight from HealthKit Store: \(error.localizedDescription)")
                return;
            }
            
            var weightLocalizedString = kUnknownString;
            weight = mostRecentWeight as? HKQuantitySample;
            if let kilograms = weight?.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)) {
                let weightFormatter = NSMassFormatter()
                weightFormatter.forPersonMassUse = true;
                weightLocalizedString = weightFormatter.stringFromKilograms(kilograms)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateBMI()
                print("in weight update: \(weightLocalizedString)")
            });
        });
    }
    
    func updateHeight()
    {
        var height, weight:HKQuantitySample?
//        _:Double = 22.0
        let kUnknownString   = "Unknown"
        var HKBMIString:String = "24.0"
//        _:HKHealthStore = HKHealthStore()
        let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        readMostRecentSample(sampleType!, completion: { (mostRecentHeight, error) -> Void in
            
            if( error != nil )
            {
                print("Error reading height from HealthKit Store: \(error.localizedDescription)")
                return;
            }
            
            var heightLocalizedString = kUnknownString;
            height = mostRecentHeight as? HKQuantitySample;
            if let meters = height?.quantity.doubleValueForUnit(HKUnit.meterUnit()) {
                let heightFormatter = NSLengthFormatter()
                heightFormatter.forPersonHeightUse = true;
                heightLocalizedString = heightFormatter.stringFromMeters(meters);
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("in height update: \(heightLocalizedString)")
                self.updateBMI()
            });
        })
    }
    
    func calculateBMIWithWeightInKilograms(weightInKilograms:Double, heightInMeters:Double) -> Double?
    {
//        var height, weight:HKQuantitySample?
//        var bmi:Double = 22.0
//        let kUnknownString   = "Unknown"
//        var HKBMIString:String = "24.0"
        if heightInMeters == 0 {
            return nil;
        }
        return (weightInKilograms/(heightInMeters*heightInMeters));
    }
    
    func updateBMI()
    {
        var height:HKQuantitySample?
        var weight:HKQuantitySample?
        var bmi:Double = 22.0
//        let kUnknownString   = "Unknown"
        var HKBMIString:String = "24.0"
        if weight != nil && height != nil {
            let weightInKilograms = weight!.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
            let heightInMeters = height!.quantity.doubleValueForUnit(HKUnit.meterUnit())
            bmi = calculateBMIWithWeightInKilograms(weightInKilograms, heightInMeters: heightInMeters)!
        }
//        print("new bmi in HealthConditions: \(bmi)")
        HKBMIString = String(format: "%.1f", bmi)
    }
    
    func updateHealthInfo() {
        //        updateWeight();
        //        print("updated weight info")
        //        updateHeight();
        //        print("updated height info")
        //        updateBMI();
        //        print("updated bmi info")
    }
    
}

// MARK: Health Situations
extension HealthConditions {
    enum HealthSituation: String {
        case High, Low, Rising, Falling, Unknown
    }
    
    func computeHealthSituations() {
        let totalWeightMetric = self.weightMetrics.reduce(0.0) { (result, WeightMetric) -> Double in
            return result + WeightMetric.pounds
        }
        averageWeightMetric = totalWeightMetric / Double(weightMetrics.count)
        
        for (i, value) in weightMetrics.enumerate() {
            let pounds = value.pounds
            if (i == 0) { // First data point
                let nextPounds = weightMetrics[i+1].pounds
                value.situation = pounds > nextPounds ? .Falling : .Rising
                continue
            } else if (i == weightMetrics.count-1) { // Last data point
                let prevPounds = weightMetrics[i-1].pounds
                value.situation = prevPounds > pounds ? .Falling : .Rising
                continue
            }
            let prevPounds = weightMetrics[i-1].pounds
            let nextPounds = weightMetrics[i+1].pounds
            
            if (pounds > prevPounds && pounds > nextPounds) {
                value.situation = .High
            } else if (pounds < prevPounds && pounds < nextPounds) {
                value.situation = .Low
            } else if (pounds < nextPounds) {
                value.situation = .Rising
            } else {
                value.situation = .Falling
            }
        }
    }
}

extension HealthConditions {
    func loadWeightMetrics(from fromDate: NSDate, to toDate: NSDate, completion:(success: Bool)->()) {
        var params = [
            "units": "metric",
            "time_zone": "gmt",
            "application": "HealthWatch",
            "format": "json",
            "interval": "h",
            "metrics": metrics.metric_name
        ]
        params["begin_date"] = HealthConditions.dateFormatter.stringFromDate(fromDate)
        params["end_date"] = HealthConditions.dateFormatter.stringFromDate(toDate)
        print("in loadWeightMetrics")
        updateHealthInfo()
        completion(success: true)
    }
}

// MARK: Persistance
extension HealthConditions {
    private static var storePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docPath = paths.first!
        return (docPath as NSString).stringByAppendingPathComponent("HealthConditions")
    }
    
    /*    static func loadConditions() -> HealthConditions {
     if let data = NSData(contentsOfFile: storePath) {
     let savedConditions = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! HealthConditions
     return savedConditions
     } else {
     print("initial file not present")
     let metrics = MetricDescriptions.allMetrics();
     return HealthConditions(metrics: metrics)
     }
     }
     */
    static func saveConditions(healthConditions:HealthConditions) {
        NSKeyedArchiver.archiveRootObject(healthConditions, toFile: storePath)
    }
}

// MARK: NSCoding
extension HealthConditions: NSCoding {
    private struct CodingKeys {
        static let metrics = "metrics"
        static let weightMetrics = "weightMetrics"
        static let averageWeightMetric = "averageWeightMetric"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let metrics = aDecoder.decodeObjectForKey(CodingKeys.metrics) as! MetricDescriptions
        self.init(metrics: metrics)
        
        self.weightMetrics = aDecoder.decodeObjectForKey(CodingKeys.weightMetrics) as! [WeightMetric]
        self.averageWeightMetric = aDecoder.decodeDoubleForKey(CodingKeys.averageWeightMetric)
    }
    
    func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeObject(metrics, forKey: CodingKeys.metrics)
        encoder.encodeObject(weightMetrics, forKey: CodingKeys.weightMetrics)
        encoder.encodeDouble(averageWeightMetric, forKey: CodingKeys.averageWeightMetric)
    }
}
