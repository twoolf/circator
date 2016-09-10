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
import MCCircadianQueries

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
    // TODO: enable input of start time, end time and columns retrieved in the query view controllers.
    public func fetchAggregates() {
        var columnIndex = 0
        var columns : [String:AnyObject] = [:]

        var tstart  : NSDate = NSDate(timeIntervalSince1970: 0)
        var tend    : NSDate = NSDate()

        var userfilter  : [String:AnyObject] = [:]

        // Add population filter parameters.
        let popQueryIndex = QueryManager.sharedManager.getSelectedQuery()
        let popQueries = QueryManager.sharedManager.getQueries()

        if popQueryIndex >= 0 && popQueryIndex < popQueries.count  {
            let popQuery = popQueries[popQueryIndex]
            switch popQuery.1 {
            case Query.ConjunctiveQuery(let qstartOpt, let qendOpt, let qcolsOpt, let aggpreds):
                if let qstart = qstartOpt { tstart = qstart }
                if let qend = qendOpt { tend = qend }

                if let qcols = qcolsOpt {
                    for (hksType, mealActivityInfoOpt) in qcols {
                        if hksType.identifier == HKObjectType.workoutType().identifier && mealActivityInfoOpt != nil {
                            if let mealActivityInfo = mealActivityInfoOpt {
                                switch mealActivityInfo {
                                case .MCQueryMeal(let meal_type):
                                    columns[String(columnIndex)] = ["meal_duration": meal_type]
                                    columnIndex += 1

                                case .MCQueryActivity(let hkWorkoutType, let mcActivityValueType):
                                    if let mcActivityType = HMConstants.sharedInstance.hkActivityToMCDB[hkWorkoutType] {
                                        if mcActivityValueType == .Duration {
                                            columns[String(columnIndex)] = ["activity_duration": mcActivityType]
                                            columnIndex += 1
                                        } else {
                                            let quantity = mcActivityValueType == .Distance ? "distance" : "kcal_burned"
                                            columns[String(columnIndex)] = ["activity_value": [mcActivityType: quantity]]
                                            columnIndex += 1
                                        }
                                    }
                                }
                            }
                        } else {
                            if let column = HMConstants.sharedInstance.hkToMCDB[hksType.identifier] {
                                columns[String(columnIndex)] = column
                                columnIndex += 1
                            } else if hksType.identifier == HKCorrelationTypeIdentifierBloodPressure {
                                // Issue queries for both systolic and diastolic.
                                columns[String(columnIndex)] = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureDiastolic]!
                                columnIndex += 1

                                columns[String(columnIndex)] = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureSystolic]!
                                columnIndex += 1
                            } else {
                                log.info("Cannot perform population query for \(hksType.identifier)")
                            }
                        }
                    }
                }

                let units : UnitsSystem = UserManager.sharedManager.useMetricUnits() ? .Metric : .Imperial
                let convert : (String, Int) -> Int = { (type, value) in
                    return Int((type == HKQuantityTypeIdentifierHeight) ?
                        UnitsUtils.heightValueInDefaultSystem(fromValue: Float(value), inUnitsSystem: units)
                        : UnitsUtils.weightValueInDefaultSystem(fromValue: Float(value), inUnitsSystem: units))
                }

                let predArray = aggpreds.map {
                    let predicateType = $0.1.0.identifier
                    if HMConstants.sharedInstance.healthKitTypesWithCustomMetrics.contains(predicateType) {
                        if let lower = $0.2, upper = $0.3, lowerInt = Int(lower), upperInt = Int(upper) {
                            return ($0.0, $0.1, String(convert(predicateType, lowerInt)), String(convert(predicateType, upperInt)))
                        }
                        return $0
                    } else {
                        return $0
                    }
                }.map(serializeMCQueryPredicateREST)

                for pred in predArray {
                    for (k,v) in pred {
                        userfilter.updateValue(v, forKey: k)
                    }
                }
            }
        }

        if columns.isEmpty {
            for hksType in PreviewManager.supportedTypes {
                if let column = HMConstants.sharedInstance.hkToMCDB[hksType.identifier] {
                    columns[String(columnIndex)] = column
                    columnIndex += 1
                }
                else if let (activity_category, quantity) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[hksType.identifier] {
                    columns[String(columnIndex)] = ["activity_value": [activity_category:quantity]]
                    columnIndex += 1
                }
                else if hksType.identifier == HKCorrelationTypeIdentifierBloodPressure {
                    // Issue queries for both systolic and diastolic.
                    columns[String(columnIndex)] = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureDiastolic]!
                    columnIndex += 1

                    columns[String(columnIndex)] = HMConstants.sharedInstance.hkToMCDB[HKQuantityTypeIdentifierBloodPressureSystolic]!
                    columnIndex += 1
                }
                else {
                    log.warning("No population query column available for \(hksType.identifier)")
                }
            }
        }

        let params : [String:AnyObject] = [
            "tstart"       : Int(floor(tstart.timeIntervalSince1970)),
            "tend"         : Int(ceil(tend.timeIntervalSince1970)),
            "columns"      : columns,
            "userfilter"   : userfilter
        ]

        // log.info("Running popquery \(params)")

        Service.json(MCRouter.AggregateMeasures(params), statusCode: 200..<300, tag: "AGGPOST") {
            _, response, result in
            guard !result.isSuccess else {
                self.refreshAggregatesFromMsg(result.value)
                return
            }
        }
    }

    // TODO: the current implementation of population aggregates is not sufficiently precise to distinguish between meals/activities.
    // These values are all treated as workout types, and thus produce a single population aggregate given mostRecentAggregtes is indexed
    // by a HKSampleType.
    //
    // We need to reimplement mostRecentAggregates as a mapping between a triple of (HKSampleType, MCDBType, Quantity) => value
    // where MCDBType is a union type, MCDBType = HKWorkoutActivityType | String (e.g., for meals)
    // and   Quantity is a String (e.g., distance, kcal_burned, step_count, flights)
    //
    func refreshAggregatesFromMsg(payload: AnyObject?) {
        var populationAggregates : [HKSampleType: [MCSample]] = [:]
        if let response = payload as? [String:AnyObject],
               aggregates = response["items"] as? [[String:AnyObject]]
        {
            var failed = false
            for sample in aggregates {
                for (column, val) in sample {
                    if !failed {
                        log.verbose("Refreshing population aggregate for \(column)")

                        // Handle meal_duration/activity_duration/activity_value columns.
                        // TODO: this only supports activity values that are HealthKit quantities for now (step count, flights climbed, distance/walking/running)
                        // We should support all MCDB meals/activity categories.
                        if HMConstants.sharedInstance.mcdbCategorized.contains(column) {
                            let categoryQuantities: [String: (String, String)] = column == "activity_value" ? HMConstants.sharedInstance.mcdbActivityToHKQuantity : [:]
                            if let categorizedVals = val as? [String:AnyObject] {
                                for (category, catval) in categorizedVals {
                                    if let (mcdbQuantity, hkQuantity) = categoryQuantities[category],
                                        sampleType = HKObjectType.quantityTypeForIdentifier(hkQuantity),
                                        categoryValues = catval as? [String: AnyObject]
                                    {
                                        if let sampleValue = categoryValues[mcdbQuantity] as? Double {
                                            populationAggregates[sampleType] = [doubleAsAggregate(sampleType, sampleValue: sampleValue)]
                                        } else {
                                            populationAggregates[sampleType] = []
                                        }
                                    }
                                    else {
                                        failed = true
                                        log.error("Invalid MCDB categorized quantity in popquery response: \(category) \(catval)")
                                    }
                                }
                            }
                            else {
                                failed = true
                                log.error("Invalid MCDB categorized values in popquery response: \(val)")
                            }
                        }
                        else if let typeIdentifier = HMConstants.sharedInstance.mcdbToHK[column]
                        {
                            var sampleType: HKSampleType! = nil
                            switch typeIdentifier {
                            case HKCategoryTypeIdentifierSleepAnalysis:
                                sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!

                            case HKCategoryTypeIdentifierAppleStandHour:
                                sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!

                            default:
                                sampleType = HKObjectType.quantityTypeForIdentifier(typeIdentifier)!
                            }

                            if let sampleValue = val as? Double {
                                let agg = doubleAsAggregate(sampleType, sampleValue: sampleValue)
                                populationAggregates[sampleType] = [agg]

                                // Population correlation type entry for systolic/diastolic blood pressure sample.
                                if typeIdentifier == HKQuantityTypeIdentifierBloodPressureSystolic
                                    || typeIdentifier == HKQuantityTypeIdentifierBloodPressureDiastolic
                                {
                                    let bpType = HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!
                                    let sType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!
                                    let dType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!

                                    let bpIndex = typeIdentifier == HKQuantityTypeIdentifierBloodPressureSystolic ? 0 : 1
                                    if populationAggregates[bpType] == nil {
                                        populationAggregates[bpType] = [
                                            MCAggregateSample(value: Double.quietNaN, sampleType: sType, op: sType.aggregationOptions),
                                            MCAggregateSample(value: Double.quietNaN, sampleType: dType, op: dType.aggregationOptions),
                                        ]
                                    }
                                    populationAggregates[bpType]![bpIndex] = agg
                                }
                            } else {
                                populationAggregates[sampleType] = []
                            }
                        }
                        else {
                            failed = true
                            // let err = NSError(domain: "App error", code: 0, userInfo: [NSLocalizedDescriptionKey:kvdict.description])
                            // let dict = ["title":"population data error", "error":err]
                            // NSNotificationCenter.defaultCenter().postNotificationName("ncAppLogNotification", object: nil, userInfo: dict)
                        }
                    }
                }
            }
            if ( !failed ) {
                Async.main {
                    // let dict = ["title":"population data", "obj":populationAggregates.description ?? ""]
                    // NSNotificationCenter.defaultCenter().postNotificationName("ncAppLogNotification", object: nil, userInfo: dict)
                    self.mostRecentAggregates = populationAggregates
                    NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
                }
            }
            else {
                log.error("Failed to retrieve population aggregates from response: \(response)")
            }
        }
        else {
            log.error("Failed to deserialize population query response")
        }
    }

    func doubleAsAggregate(sampleType: HKSampleType, sampleValue: Double) -> MCAggregateSample {
        let convertedSampleValue = HKQuantity(unit: sampleType.serviceUnit!, doubleValue: sampleValue).doubleValueForUnit(sampleType.defaultUnit!)
        log.info("Popquery \(sampleType.displayText ?? sampleType.identifier) \(sampleValue) \(convertedSampleValue)")
        return MCAggregateSample(value: convertedSampleValue, sampleType: sampleType, op: sampleType.aggregationOptions)
    }


    // MARK : - Study stats queries
    public func fetchStudyStats(completion: (Bool, AnyObject?) -> Void) {
        Service.json(MCRouter.StudyStats, statusCode: 200..<300, tag: "GETSTUDYSTATS") {
            _, response, result in
            completion(result.isSuccess, result.value)
        }
    }
}