//
//  QueryManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import SwiftyUserDefaults
import HealthKit

public enum Comparator : Int {
    case LT
    case LTE
    case EQ
    case NEQ
    case GT
    case GTE
}

public enum MCActivityValue : Int {
    case Duration
    case Distance
    case EnergyBurned
}

public enum MCQueryMealActivity {
    case MCQueryMeal(String)
    case MCQueryActivity(HKWorkoutActivityType, MCActivityValue)
}

public enum Aggregate : Int {
    case AggAvg
    case AggMin
    case AggMax
}

public typealias MCQueryAttribute = (HKObjectType, MCQueryMealActivity?)

public typealias MCQueryPredicate = (Aggregate, MCQueryAttribute, String?, String?)

public enum Query {
    case ConjunctiveQuery(NSDate?, NSDate?, [MCQueryAttribute]?, [MCQueryPredicate])
        // Start time, end time, columns to retrieve, conjunct array
}

public typealias Queries = [(String, Query)]

private let QMQueriesKey  = DefaultsKey<[AnyObject]?>("QMQueriesKey")
private let QMSelectedKey = DefaultsKey<Int>("QMSelectedKey")

// TODO: Male/Female, age ranges (as profile queries).
private let defaultQueries : Queries = [
    ("Weight <50",     Query.ConjunctiveQuery(nil, nil, nil,
        [MCQueryPredicate(.AggAvg, (HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!, nil), nil, "50")])),

    ("Weight 50-100",  Query.ConjunctiveQuery(nil, nil, nil,
        [MCQueryPredicate(.AggAvg, (HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!, nil), "50", "100")])),

    ("Weight 100-150", Query.ConjunctiveQuery(nil, nil, nil,
        [MCQueryPredicate(.AggAvg, (HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!, nil), "100", "150")])),

    ("Weight 150-200", Query.ConjunctiveQuery(nil, nil, nil,
        [MCQueryPredicate(.AggAvg, (HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!, nil), "150", "200")])),

    ("Weight >200",    Query.ConjunctiveQuery(nil, nil, nil,
        [MCQueryPredicate(.AggAvg, (HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!, nil), "200", nil)]))
]

/**
 This class manages queries to enable more meaningful comparisons against population data.  For example, to limit the population column on the first page or the densities shown on the radar plot to individuals within a particular weight range or to a particular gender, this query filter would be used.

 - note: works with PopulationHealthManager, QueryBuilderViewController, QueryViewController
 */
public class QueryManager {
    public static let sharedManager = QueryManager()

    var queries: Queries = defaultQueries
    var querySelected : Int = -1

    init() { load() }

    func load() {
        let qs = Defaults[QMQueriesKey] as? [[String:AnyObject]] ?? []
        let dsQueries = deserializeQueries(qs)
        queries = dsQueries.isEmpty ? defaultQueries : dsQueries
        querySelected = dsQueries.isEmpty ? -1 : Defaults[QMSelectedKey]
    }

    func save() {
        saveQueries()
        saveIndex()
    }

    func saveQueries() {
        let q = serializeQueries(queries)
        Defaults[QMQueriesKey] = q
    }

    func saveIndex() {
        Defaults[QMSelectedKey] = querySelected
    }

    public func getQueries() -> Queries {
        return queries
    }

    public func addQuery(name: String, query: Query) {
        queries.append((name, query))
        saveQueries()
    }

    public func removeQuery(index: Int) {
        queries.removeAtIndex(index)
        if querySelected >= index {
            querySelected = querySelected == index ? 0 : querySelected - 1
        }
        save()
    }

    public func updateQuery(index: Int, name: String, query: Query) {
        queries[index] = (name, query)
        saveQueries()
    }

    public func getSelectedQuery() -> Int {
        return querySelected
    }

    public func selectQuery(index: Int) {
        querySelected = index
        saveIndex()
    }

    public func deselectQuery() {
        querySelected = -1
        saveIndex()
    }
}

private let AttrTypeKey      = "atyp"
private let MealTypeKey      = "mtyp"
private let WorkoutTypeKey   = "wtyp"
private let ActivityValueKey = "aval"
private let MealActivityDiscriminatorKey = "mora"

private let GKey = "aggr"
private let AKey = "attr"
private let LKey = "min"
private let UKey = "max"

private let NKey = "qname"
private let SKey = "qstart"
private let EKey = "qend"
private let CKey = "qcols"
private let QKey = "query"

func serializeMCQueryMealActivity(v: MCQueryMealActivity) -> [String: AnyObject] {
    switch v {
    case .MCQueryMeal(let mealType):
        return [MealActivityDiscriminatorKey: "meal", MealTypeKey: mealType]
    case .MCQueryActivity(let workoutType, let valueType):
        return [MealActivityDiscriminatorKey: "activity", WorkoutTypeKey: workoutType.rawValue, ActivityValueKey: valueType.rawValue]
    }
}

func serializeMCQueryAttribute(attr: MCQueryAttribute) -> [String:AnyObject] {
    if let mealActivityInfo = attr.1 {
        var qmaDict = serializeMCQueryMealActivity(mealActivityInfo)
        qmaDict[AttrTypeKey] = attr.0.identifier
        return qmaDict
    }
    return [AttrTypeKey: attr.0.identifier]
}

func deserializeMCQueryMealActivity(dict: [String:AnyObject]) -> MCQueryMealActivity? {
    if let mealOrActivity = dict[MealActivityDiscriminatorKey] as? String {
        if mealOrActivity == "meal" {
            return .MCQueryMeal(dict[MealTypeKey] as! String)
        } else {
            let workoutType = HKWorkoutActivityType(rawValue: dict[WorkoutTypeKey] as! UInt)!
            let activityValueType = MCActivityValue(rawValue: dict[ActivityValueKey] as! Int)!
            return .MCQueryActivity(workoutType, activityValueType)
        }
    }
    return nil
}

func deserializeMCQueryAttribute(dict: [String:AnyObject]) -> MCQueryAttribute {
    var attrType : HKObjectType? = nil
    let attrIdentifier = dict[AttrTypeKey] as! String

    switch attrIdentifier {
    case HKWorkoutTypeIdentifier:
        attrType = HKObjectType.workoutType()
    case HKCategoryTypeIdentifierSleepAnalysis:
        attrType = HKObjectType.categoryTypeForIdentifier(attrIdentifier)!
    case HKCategoryTypeIdentifierAppleStandHour:
        attrType = HKObjectType.categoryTypeForIdentifier(attrIdentifier)!
    default:
        attrType = HKObjectType.quantityTypeForIdentifier(attrIdentifier)!
    }

    return MCQueryAttribute(attrType!, deserializeMCQueryMealActivity(dict))
}

func serializeMCQueryPredicate(p: MCQueryPredicate) -> [String: AnyObject] {
    var result :[String:AnyObject] = [GKey: p.0.rawValue, AKey: serializeMCQueryAttribute(p.1)]
    if let lb = p.2 { result[LKey] = lb }
    if let ub = p.3 { result[UKey] = ub }
    return result
}

func serializeQueries(qs: Queries) -> [[String: AnyObject]] {
    return qs.map { (n,q) in
        switch q {
        case .ConjunctiveQuery(let start, let end, let columns, let conjuncts):
            return [
                NKey: n,
                SKey: start!,
                EKey: end!,
                CKey: columns!.map(serializeMCQueryAttribute),
                QKey: conjuncts.map(serializeMCQueryPredicate)
            ]
        }
    }
}

func deserializeMCQueryPredicate(p: [String: AnyObject]) -> MCQueryPredicate {
    return MCQueryPredicate(Aggregate(rawValue: p[GKey] as! Int)!,
                            deserializeMCQueryAttribute(p[AKey] as! [String:AnyObject]),
                            p[LKey] as? String,
                            p[UKey] as? String)
}

func deserializeQueries(qs: [[String: AnyObject]]) -> Queries {
    return qs.map { dict in
        let name    = dict[NKey] as! String
        let start   = dict[SKey] as! NSDate?
        let end     = dict[EKey] as! NSDate?
        let columns = dict[CKey] as! [MCQueryAttribute]?
        let preds   = (dict[QKey] as! [[String: AnyObject]]).map(deserializeMCQueryPredicate)
        return (name, .ConjunctiveQuery(start, end, columns, preds))
    }
}

func serializeMCQueryPredicateREST(p: MCQueryPredicate) -> [String: AnyObject] {
    var spec : [String:AnyObject] = [:]
    if let lb = p.2 { spec["min"] = lb }
    if let ub = p.3 { spec["max"] = ub }

    if p.1.0.identifier == HKObjectType.workoutType().identifier {
        if let mealActivityInfo = p.1.1 {
            switch mealActivityInfo {
            case .MCQueryMeal(let mealType):
                if mealType.isEmpty {
                    return ["meal_duration": spec]
                }
                return ["meal_duration": [mealType: spec]]

            case .MCQueryActivity(let workoutType, let activityValueType):
                if let mcActivityType = HMConstants.sharedInstance.hkActivityToMCDB[workoutType] {
                    if activityValueType == .Duration {
                        return ["activity_duration": [mcActivityType: spec]]
                    } else {
                        spec["quantity"] = activityValueType == .Distance ? "distance" : "kcal_burned"
                        return ["activity_value": [mcActivityType: spec]]
                    }
                }
            }
        }
    }

    let mcAttrType = HMConstants.sharedInstance.hkToMCDB[p.1.0.identifier]!
    return [mcAttrType: spec]
}