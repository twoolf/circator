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
 manager of information for comparison population
 
 - note: initially this is NHANES data and with time will be study population defined
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

    public static let attributeNamesBySampleType : [HKSampleType:(String,String,String?)] =
    PreviewManager.previewChoices.flatten().reduce([:]) { (var dict, sampleType) in
        switch sampleType.identifier {
        case HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!.identifier:
            dict[sampleType] = ("blood_pressure", "blood_pressure", "HKCorrelationTypeIdentifierBloodPressure")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!.identifier:
            dict[sampleType] = ("active_energy_burned", "active_energy_burned", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!.identifier:
            dict[sampleType] = ("unit_value", "basal_energy_burned", "HKQuantityTypeIdentifierBasalEnergyBurned")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!.identifier:
            dict[sampleType] = ("unit_value", "diastolic_blood_pressure", "HKQuantityTypeIdentifierBloodPressureDiastolic")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!.identifier:
            dict[sampleType] = ("unit_value", "systolic_blood_pressure", "HKQuantityTypeIdentifierBloodPressureSystolic")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!.identifier:
            dict[sampleType] = ("body_weight", "body_weight", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!.identifier:
            dict[sampleType] = ("body_mass_index", "body_mass_index", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!.identifier:
            dict[sampleType] = ("blood_glucose", "blood_glucose", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!.identifier:
            dict[sampleType] = ("heart_rate", "heart_rate", nil)

        case HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!.identifier:
            dict[sampleType] = ("sleep_duration", "sleep_duration", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!.identifier:
            dict[sampleType] = ("unit_value", "energy_consumed", "HKQuantityTypeIdentifierDietaryEnergyConsumed")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!.identifier:
            dict[sampleType] = ("unit_value", "carbs", "HKQuantityTypeIdentifierDietaryCarbohydrates")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!.identifier:
            dict[sampleType] = ("unit_value", "fat_total", "HKQuantityTypeIdentifierDietaryFatTotal")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!.identifier:
            dict[sampleType] = ("unit_value", "fat_polyunsaturated", "HKQuantityTypeIdentifierDietaryFatPolyunsaturated")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!.identifier:
            dict[sampleType] = ("unit_value", "fat_monounsaturated", "HKQuantityTypeIdentifierDietaryFatMonounsaturated")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!.identifier:
            dict[sampleType] = ("unit_value", "fat_saturated", "HKQuantityTypeIdentifierDietaryFatSaturated")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!.identifier:
            dict[sampleType] = ("unit_value", "protein", "HKQuantityTypeIdentifierDietaryProtein")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!.identifier:
            dict[sampleType] = ("unit_value", "sugar", "HKQuantityTypeIdentifierDietarySugar")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!.identifier:
            dict[sampleType] = ("unit_value", "cholesterol", "HKQuantityTypeIdentifierDietaryCholesterol")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!.identifier:
            dict[sampleType] = ("unit_value", "sodium", "HKQuantityTypeIdentifierDietarySodium")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!.identifier:
            dict[sampleType] = ("unit_value", "caffeine", "HKQuantityTypeIdentifierDietaryCaffeine")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!.identifier:
            dict[sampleType] = ("unit_value", "water", "HKQuantityTypeIdentifierDietaryWater")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!.identifier:
            dict[sampleType] = ("unit_value", "distance_walkingrunning", "HKQuantityTypeIdentifierDistanceWalkingRunning")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!.identifier:
            dict[sampleType] = ("unit_value", "flights_climbed", "HKQuantityTypeIdentifierFlightsClimbed")

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!.identifier:
            dict[sampleType] = ("body_height", "body_height", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!.identifier:
            dict[sampleType] = ("step_count", "step_count", nil)

        case HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!.identifier:
            dict[sampleType] = ("unit_value", "UV_exposure", "HKQuantityTypeIdentifierUVExposure")

        case HKObjectType.workoutType().identifier:HKWorkoutActivityType.PreparationAndRecovery
        dict[sampleType] = ("effective_time_frame", "workout", "HKWorkoutActivityType")

        default:
            log.warning("Mismatched sample types on: " + sampleType.identifier)
        }
        return dict
    }

    public static let attributesByName : [String: (HKSampleType, String, String?)] =
    attributeNamesBySampleType
        .map { $0 }
        .reduce([:]) { (var dict, kv) in dict[kv.1.1] = (kv.0, kv.1.0, kv.1.2); return dict }

    // Clear all aggregates.
    public func resetAggregates() { mostRecentAggregates = [:] }

    // Retrieve aggregates for all previewed rows.
    public func fetchAggregates() {
        do {
            var attributes    : [String] = []
            var names         : [String] = []
            var predicates    : [String] = []
            var samplesByName : [String:HKSampleType] = [:]

            for hksType in PreviewManager.previewSampleTypes {
                if let (attr, name, predicate) = PopulationHealthManager.attributeNamesBySampleType[hksType] {
                    attributes.append(attr)
                    names.append(name)
                    predicates.append(predicate ?? "")
                    samplesByName[name] = hksType
                }
            }

            var params : [String:AnyObject] = ["attributes":attributes, "names":names, "predicates":predicates]

            // Add population filter parameters.
            let popQueryIndex = QueryManager.sharedManager.getSelectedQuery()
            let popQueries = QueryManager.sharedManager.getQueries()
            if popQueryIndex >= 0 && popQueryIndex < popQueries.count  {
                switch popQueries[popQueryIndex].1 {
                case Query.UserDefinedQuery(_):
                    log.error("NYI: UserDefinedQueries")

                case Query.ConjunctiveQuery(let aggpreds):
                    let pfdict : [[String: AnyObject]] = aggpreds.map { (aggr, attr, cmp, val) in
                        var dict : [String: AnyObject] = [:]
                        if let attrspec = PopulationHealthManager.attributesByName[attr] {
                            dict = serializeREST((aggr, attrspec.1, cmp, val))
                            dict["name"] = attr
                            if let attrAsPred = attrspec.2 {
                                dict["predicate"] = attrAsPred
                            }
                        } else {
                            log.error(PopulationHealthManager.attributesByName)
                            log.error("Could not find attribute '\(attr)' for a conjunctive query")
                        }
                        return dict
                        }.filter { dict in !dict.isEmpty }

                    params["popfilter"] = pfdict
                }
            }

            let json = try NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted)
            let serializedAttrs = try NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions()) as! [String : AnyObject]

            Service.json(MCRouter.AggMeasures(serializedAttrs), statusCode: 200..<300, tag: "AGGPOST") {
                _, response, result in
                guard !result.isSuccess else {
                    self.refreshAggregatesFromMsg(samplesByName, payload: result.value)
                    return
                }
            }
        } catch {
            log.error(error)
        }
    }

    func refreshAggregatesFromMsg(samplesByName: [String:HKSampleType], payload: AnyObject?) {
        var populationAggregates : [HKSampleType: [MCSample]] = [:]
        if let aggregates = payload as? [[String: AnyObject]] {
            var failed = false
            for kvdict in aggregates {
                if let sampleName = kvdict["key"] as? String, sampleType = samplesByName[sampleName]
                {
                    if let sampleValue = kvdict["value"] as? Double {
                        populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]
                    } else {
                        populationAggregates[sampleType] = []
                    }
                } else {
                    failed = true
                    break
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

    public func fetchMealAggregates() {
        Service.string(MCRouter.MealMeasures([:]), statusCode: 200..<300, tag: "MEALS") {
            _, response, result in
            log.info(result.value)
        }
    }

}