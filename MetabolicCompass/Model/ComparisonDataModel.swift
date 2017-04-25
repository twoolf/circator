//
//  ComparisonDataModel.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/8/16. 
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries
import AwesomeCache


public class ComparisonDataModel : NSObject {
    static let sharedManager = ComparisonDataModel()

    public var recentSamples: [HKSampleType: [MCSample]] = [:]
    public var recentAggregates: [HKSampleType: [MCSample]] = [:]

    public func updateIndividualData(types: [HKSampleType], completion: @escaping NSError? -> Void) {
        AccountManager.shared.withHKCalAuth {
            log.debug("Fetching recent samples", feature: "comparison")
            MCHealthManager.sharedManager.fetchMostRecentSamples(ofTypes: types) { (samplesByType, error) -> Void in
                guard error == nil else { completion(error); return }
                log.debug("Done fetching recent samples", feature: "comparison")
                self.recentSamples = samplesByType
                NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
                completion(error)
            }
        }
    }

    public func updatePopulationData(types: [HKSampleType]) {
        types.forEach { type in
            if let samples = PopulationHealthManager.sharedManager.mostRecentAggregates[type] {
                self.recentAggregates.updateValue(samples, forKey: type)
            }
        }
    }
}
