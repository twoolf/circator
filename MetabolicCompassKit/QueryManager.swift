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

public let noQuerySelected = -1

/**
 This class manages queries to enable more meaningful comparisons against population data.  For example, to limit the population column on the first page or the densities shown on the radar plot to individuals within a particular weight range or to a particular gender, this query filter would be used.

 - note: works with PopulationHealthManager, QueryBuilderViewController, QueryViewController
 */
public class QueryManager {
    public static let sharedManager = QueryManager()

    var querySelected : Int = noQuerySelected
    var queries: Queries = []
    var queriedTypes: [HKObjectType]? = nil

    init() { load() }

    func load() {
        let qs = Defaults[QMQueriesKey] as? [[String:AnyObject]] ?? []
        let dsQueries = deserializeQueries(qs)
        queries = dsQueries.isEmpty ? [] : dsQueries
        querySelected = dsQueries.isEmpty ? noQuerySelected : Defaults[QMSelectedKey]
        refreshQueriedTypes()
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
        if 0 <= index && index < queries.count {
            queries.removeAtIndex(index)
            if querySelected >= index {
                querySelected = querySelected == index ? 0 : querySelected - 1
            }
            save()
            refreshQueriedTypes()
        }
    }

    public func updateQuery(index: Int, name: String, query: Query) {
        if 0 <= index && index < queries.count {
            queries[index] = (name, query)
            saveQueries()
            refreshQueriedTypes()
        }
    }

    public func clearQueries() {
        queries.removeAll()
        querySelected = noQuerySelected
        save()
        refreshQueriedTypes()
    }

    public func getSelectedQuery() -> Int {
        return querySelected
    }

    public func selectQuery(index: Int) {
        if 0 <= index && index < queries.count {
            querySelected = index
            saveIndex()
            refreshQueriedTypes()
        }
    }

    public func deselectQuery() {
        querySelected = noQuerySelected
        saveIndex()
        refreshQueriedTypes()
    }

    public func getQueriedTypes() -> [HKObjectType]? {
        return queriedTypes
    }

    public func isQueriedType(sample: HKObjectType) -> Bool {
        return queriedTypes?.contains(sample) ?? false
    }

    private func refreshQueriedTypes() {
        log.info("Refreshing queried types")
        if 0 <= querySelected && querySelected < queries.count {
            switch queries[querySelected].1 {
            case .ConjunctiveQuery(_, _, _, let predicates):

                let initial : ([HKObjectType], Set<HKObjectType>) = ([], Set())

                let types = predicates.map({ $0.1.0 }).reduce(initial, combine: { (acc, elem) in
                    if acc.1.contains(elem) { return acc }
                    return (acc.0 + [elem], acc.1.union([elem]))
                }).0

                queriedTypes = types.isEmpty ? nil : types
                log.info("New queried types \(queriedTypes)")
            }
        } else {
            queriedTypes = nil
            log.info("Empty queried types \(queriedTypes)")
        }
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
            var result : [String:AnyObject] = [NKey: n, QKey: conjuncts.map(serializeMCQueryPredicate)]
            if start != nil {
                result[SKey] = start!
            }
            if end != nil {
                result[EKey] = end!
            }
            if columns != nil {
                result[CKey] = columns!.map(serializeMCQueryAttribute)
            }
            return result
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
        let preds   = (dict[QKey] as! [[String: AnyObject]]).map(deserializeMCQueryPredicate)
        let start   = dict[SKey] as? NSDate
        let end     = dict[EKey] as? NSDate
        let columns = dict[CKey] as? [MCQueryAttribute]
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
    else if let (activity_type, quantity) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[p.1.0.identifier] {
        spec["quantity"] = quantity
        return ["activity_value": [activity_type: spec]]
    }

    let mcAttrType = HMConstants.sharedInstance.hkToMCDB[p.1.0.identifier]!
    return [mcAttrType: spec]
}
