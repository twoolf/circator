//
//  MetricDescriptions.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

final class MetricDescriptions: NSObject {
    let metric_name: String
    let HKSampleName: String
    let metric_units: String
    
    required init(metric_name: String, HKSampleName: String, metric_units: String) {
        self.metric_name = metric_name
        self.HKSampleName = HKSampleName
        self.metric_units = metric_units
    }
}

// MARK: NSCoding
extension MetricDescriptions: NSCoding {
    private struct CodingKeys {
        static let metric_name = "metric_name"
        static let HKSampleName = "HKSampleName"
        static let metric_units = "metric_units"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        let metric_name = aDecoder.decodeObject(forKey: CodingKeys.metric_name) as! String
        let HKSampleName = aDecoder.decodeObject(forKey: CodingKeys.HKSampleName) as! String
        let metric_units = aDecoder.decodeObject(forKey: CodingKeys.metric_units) as! String
        self.init(metric_name: metric_name, HKSampleName: HKSampleName, metric_units: metric_units)
    }
    
    func encode(with encoder: NSCoder) {
        encoder.encode(metric_name, forKey: CodingKeys.metric_name)
        encoder.encode(HKSampleName, forKey: CodingKeys.HKSampleName)
        encoder.encode(metric_units, forKey: CodingKeys.metric_units)
    }
}

// MARK: Loading
extension MetricDescriptions {
    class func allMetrics() -> [MetricDescriptions] {
        guard let file = Bundle.main.path(forResource: "Metrics", ofType: "plist") else { return [] }
        guard (NSArray(contentsOfFile: file) as? [String]) != nil else { return [] }
        let metrics = [MetricDescriptions(metric_name: "weight", HKSampleName: "HKSampleType", metric_units: "lbs")]
        /*        let metrics = metricStrings.map { s -> MetricDescriptions in
         let components = (s as NSString).componentsSeparatedByString(",")
         print("in metrics-1: \(components[0])")
         print("in metrics-2: \(components[1])")
         print("in metrics-3: \(components[2])")
         return MetricDescriptions(metric_name: components[0], HKSampleName: components[1], metric_units: components[2])
         */
        //        }
        return metrics
    }
}
