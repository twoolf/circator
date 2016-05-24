//
//  PopulationHealthManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 1/31/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import Async

/**
  This is the manager of information for the comparison population.
  By providing this comparison we provide our study participants with a greater ability to view themselves in context.

  Initially this is defined by the NHANES data.
  With sufficient enrolled subjects, this will be determined by aggregates over the ongoing study population.

 - remark: pulls from PostgreSQL store (AWS RDS) -- see MCRouter --
 */
public class PopulationHealthManager {

    public static let sharedManager = PopulationHealthManager()

    public var aggregateRefreshDate : NSDate = NSDate()

    public var mostRecentAggregates = [HKSampleType: [MCSample]]() {
        didSet {
            aggregateRefreshDate = NSDate()
        }
    }

    // MARK: - Population query execution.

    // Clear all aggregates.
    public func resetAggregates() { mostRecentAggregates = [:] }

    // Retrieve aggregates for all previewed rows.
    public func fetchAggregates() {
        var columnIndex = 0
        var columns : [String:AnyObject] = [:]

        for hksType in PreviewManager.supportedTypes {
            if let column = HMConstants.sharedInstance.hkToMCDB[hksType.identifier] {
                columns[String(columnIndex)] = column
                columnIndex += 1
            }
        }

        // TODO: set filtering constraints from query view controllers.
        let tstart  : NSDate             = NSDate(timeIntervalSince1970: 0)
        let tend    : NSDate             = NSDate()
        var filter  : [String:AnyObject] = [:]

        // Add population filter parameters.
        let popQueryIndex = QueryManager.sharedManager.getSelectedQuery()
        let popQueries = QueryManager.sharedManager.getQueries()
        if popQueryIndex >= 0 && popQueryIndex < popQueries.count  {
            switch popQueries[popQueryIndex].1 {
            case Query.ConjunctiveQuery(let aggpreds):
                let predArray = aggpreds.map(serializePredicateREST)
                for pred in predArray {
                    for (k,v) in pred {
                        filter.updateValue(v, forKey: k)
                    }
                }
            }
        }

        let params : [String:AnyObject] = [
            "tstart"  : tstart.timeIntervalSince1970,
            "tend"    : tend.timeIntervalSince1970,
            "columns" : columns,
            "filter"  : filter
        ]

        Service.json(MCRouter.AggMeasures(params), statusCode: 200..<300, tag: "AGGPOST") {
            _, response, result in
            guard !result.isSuccess else {
                self.refreshAggregatesFromMsg(result.value)
                return
            }
        }
    }

    func refreshAggregatesFromMsg(payload: AnyObject?) {
        var populationAggregates : [HKSampleType: [MCSample]] = [:]
        if let aggregates = payload as? [[String: AnyObject]] {
            var failed = false
            for sample in aggregates {
                for (column, val) in sample {
                    log.info("Refreshing population aggregate for \(column)")
                    if let sampleValue = val as? Double,
                           typeIdentifier = HMConstants.sharedInstance.mcdbToHK[column]
                    {
                        switch typeIdentifier {
                        case HKCategoryTypeIdentifierSleepAnalysis:
                            let sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
                            populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]

                        case HKCategoryTypeIdentifierAppleStandHour:
                            let sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!
                            populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]

                        default:
                            let sampleType = HKObjectType.quantityTypeForIdentifier(typeIdentifier)!
                            populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]
                        }
                    } else {
                        failed = true
                    }
                }
            }
            if ( !failed ) {
                Async.main {
                    self.mostRecentAggregates = populationAggregates
                    NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
                }
            }
        }
    }
}