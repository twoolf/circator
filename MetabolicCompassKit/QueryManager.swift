//
//  QueryManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import SwiftyUserDefaults

public typealias Predicate = (Aggregate, String, Comparator, String)
public typealias Queries = [(String, Query)]

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

public enum Query {
    case ConjunctiveQuery([Predicate])
    case UserDefinedQuery(String)
}

private let QMQueriesKey  = DefaultsKey<[AnyObject]?>("QMQueriesKey")
private let QMSelectedKey = DefaultsKey<Int>("QMSelectedKey")

// TODO: Male/Female, age ranges (as profile queries).
private let defaultQueries : Queries = [
        ("Weight <50",     Query.ConjunctiveQuery([Predicate(Aggregate.AggAvg, "body_weight", Comparator.LT, "50")])),

        ("Weight 50-100",  Query.ConjunctiveQuery([Predicate(Aggregate.AggAvg, "body_weight", Comparator.GTE, "50"),
                                                   Predicate(Aggregate.AggAvg, "body_weight", Comparator.LT, "100")])),

        ("Weight 100-150", Query.ConjunctiveQuery([Predicate(Aggregate.AggAvg, "body_weight", Comparator.GTE, "100"),
                                                   Predicate(Aggregate.AggAvg, "body_weight", Comparator.LT, "150")])),

        ("Weight 150-200", Query.ConjunctiveQuery([Predicate(Aggregate.AggAvg, "body_weight", Comparator.GTE, "150"),
                                                   Predicate(Aggregate.AggAvg, "body_weight", Comparator.LT, "200")])),

        ("Weight >200",    Query.ConjunctiveQuery([Predicate(Aggregate.AggAvg, "body_weight", Comparator.GTE, "200")]))
    ]

/**
 Manages queries to enable more meaningful comparisons against population data.
 
 - note: works with PopulationHealthManager, QueryBuilderViewController, QueryViewController, QueryWriterViewController
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
private let CKey = "comp"
private let VKey = "pval"

private let NKey = "qname"
private let UKey = "qudef"
private let QKey = "query"

func serializePredicate(p: Predicate) -> [String: AnyObject] {
    return [
        GKey : p.0.rawValue,
        AKey : p.1,
        CKey : p.2.rawValue,
        VKey : p.3
    ]
}

func serializeQueries(qs: Queries) -> [[String: AnyObject]] {
    return qs.map { (n,q) in
        switch q {
        case .ConjunctiveQuery(let ps):
            return [NKey: n,
                    UKey: false,
                    QKey: ps.map(serializePredicate)]

        case .UserDefinedQuery(let s):
            return [NKey: n,
                    UKey: true,
                    QKey: s]
        }
    }
}

func deserializePredicate(p: [String: AnyObject]) -> Predicate {
    return Predicate(
        Aggregate(rawValue: p[GKey] as! Int)!,
        p[AKey] as! String,
        Comparator(rawValue: p[CKey] as! Int)!,
        p[VKey] as! String)
}

func deserializeQueries(qs: [[String: AnyObject]]) -> Queries {
    return qs.map { dict in
        let name = dict[NKey] as! String
        let udef = dict[UKey] as! Bool
        if udef {
            let query = dict[QKey] as! String
            return (name, .UserDefinedQuery(query))
        } else {
            let preds = (dict[QKey] as! [[String: AnyObject]]).map(deserializePredicate)
            return (name, .ConjunctiveQuery(preds))
        }
    }
}

// Conversions for REST API.
func serializeREST(p: Predicate) -> [String: AnyObject] {
    let aggregateOperators = ["avg", "min", "max"]
    let comparisonOperators = ["<", "<=", "==", "!=", "=>", ">"]
    return [
        GKey : aggregateOperators[p.0.rawValue],
        AKey : p.1,
        CKey : comparisonOperators[p.2.rawValue],
        VKey : p.3
    ]
}

// Conversions for SQL.
func sqlizePredicate(p: Predicate) -> String {
    let aggregateOperators = ["avg", "min", "max"]
    let comparisonOperators = ["<", "<=", "==", "!=", "=>", ">"]
    return "\(aggregateOperators[p.0.rawValue])(\(p.1)) \(comparisonOperators[p.2.rawValue]) \(p.3)"
}

func sqlizeQuery(q: Query) -> String {
    switch q {
    case .ConjunctiveQuery(let p):
        return p.map(sqlizePredicate).joinWithSeparator(" and ")
    case .UserDefinedQuery(let s):
        return s
    }
}

func sqlize(q: (String, Query)) -> String {
    return sqlizeQuery(q.1)
}
