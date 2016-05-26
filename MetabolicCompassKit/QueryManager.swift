//
//  QueryManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import SwiftyUserDefaults

public enum Comparator : Int {
    case LT
    case LTE
    case EQ
    case NEQ
    case GT
    case GTE
}

public enum Aggregate : Int {
    case AggAvg
    case AggMin
    case AggMax
}

public typealias Predicate = (Aggregate, String, String?, String?)

public enum Query {
    case ConjunctiveQuery(NSDate?, NSDate?, [HKObjectType]?, [Predicate])
        // Start time, end time, columns to retrieve, conjunct array
}

public typealias Queries = [(String, Query)]

private let QMQueriesKey  = DefaultsKey<[AnyObject]?>("QMQueriesKey")
private let QMSelectedKey = DefaultsKey<Int>("QMSelectedKey")

// TODO: Male/Female, age ranges (as profile queries).
private let defaultQueries : Queries = [
        ("Weight <50",     Query.ConjunctiveQuery(nil, nil, nil, [Predicate(.AggAvg, "body_weight", nil, "50")])),
        ("Weight 50-100",  Query.ConjunctiveQuery(nil, nil, nil, [Predicate(.AggAvg, "body_weight", "50", "100")])),
        ("Weight 100-150", Query.ConjunctiveQuery(nil, nil, nil, [Predicate(.AggAvg, "body_weight", "100", "150")])),
        ("Weight 150-200", Query.ConjunctiveQuery(nil, nil, nil, [Predicate(.AggAvg, "body_weight", "150", "200")])),
        ("Weight >200",    Query.ConjunctiveQuery(nil, nil, nil, [Predicate(.AggAvg, "body_weight", "200", nil)]))
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

private let GKey = "aggr"
private let AKey = "attr"
private let LKey = "min"
private let UKey = "max"

private let NKey = "qname"
private let SKey = "qstart"
private let EKey = "qend"
private let CKey = "qcols"
private let QKey = "query"

func serializePredicate(p: Predicate) -> [String: AnyObject] {
    var result :[String:AnyObject] = [GKey: p.0.rawValue, AKey: p.1]
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
                SKey: start,
                EKey: end,
                CKey: columns,
                QKey: conjuncts.map(serializePredicate)
            ]
        }
    }
}

func deserializePredicate(p: [String: AnyObject]) -> Predicate {
    return Predicate(Aggregate(rawValue: p[GKey] as! Int)!,
                     p[AKey] as! String,
                     p[LKey] as? String,
                     p[UKey] as? String)
}

func deserializeQueries(qs: [[String: AnyObject]]) -> Queries {
    return qs.map { dict in
        let name    = dict[NKey] as! String
        let start   = dict[SKey] as! NSDate?
        let end     = dict[EKey] as! NSDate?
        let columns = dict[CKey] as! [HKObjectType]?
        let preds   = (dict[QKey] as! [[String: AnyObject]]).map(deserializePredicate)
        return (name, .ConjunctiveQuery(start, end, columns, preds))
    }
}

func serializePredicateREST(p: Predicate) -> [String: AnyObject] {
    var spec : [String:AnyObject] = ["agg": p.0.rawValue]
    if let lb = p.2 { spec["min"] = lb }
    if let ub = p.3 { spec["max"] = ub }
    return [p.1: spec]
}