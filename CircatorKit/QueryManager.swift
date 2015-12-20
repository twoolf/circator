//
//  QueryManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

public typealias Predicate = (String, Comparator, String)
public typealias ConjunctiveQuery = (String, [Predicate])
public typealias Queries = [ConjunctiveQuery]

public enum Comparator : Int {
    case LT
    case LTE
    case EQ
    case NEQ
    case GT
    case GTE
}

private let QueryManagerQueriesKey = "QMQueriesKey"
private let QueryManagerSelectedKey = "QMSelectedKey"

public class QueryManager {
    public static let sharedManager = QueryManager()

    var queries: Queries = []
    var querySelected : Int = 0

    init() { load() }
    
    func load() {
        let qs = NSUserDefaults.standardUserDefaults().objectForKey(QueryManagerQueriesKey) as? [[String:AnyObject]] ?? []
        queries = deserializeQueries(qs)
        querySelected = NSUserDefaults.standardUserDefaults().integerForKey(QueryManagerSelectedKey)
    }

    func save() {
        saveQueries()
        saveIndex()
    }

    func saveQueries() {
        let q = serializeQueries(queries)
        NSUserDefaults.standardUserDefaults().setObject(q, forKey: QueryManagerQueriesKey)
    }

    func saveIndex() {
        NSUserDefaults.standardUserDefaults().setInteger(querySelected, forKey: QueryManagerSelectedKey)
    }

    public func getQueries() -> Queries {
        return queries
    }
    
    public func addQuery(name: String, query: [Predicate]) {
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
    
    public func updateQuery(index: Int, name: String, query: [Predicate]) {
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
        querySelected = 0
        saveIndex()
    }
}

private let AKey = "hasAttr"
private let CKey = "hasComparator"
private let VKey = "hasValue"

func serializePredicate(p: Predicate) -> [String: AnyObject] {
    return [
        AKey : p.0,
        CKey : p.1.rawValue,
        VKey : p.2
    ]
}

func serializeQueries(q: Queries) -> [[String: AnyObject]] {
    return q.map { (n,p) in return ["key": n, "value": p.map(serializePredicate)] }
}

func deserializePredicate(p: [String: AnyObject]) -> Predicate {
    return Predicate(
        p[AKey] as! String,
        Comparator(rawValue: p[CKey] as! Int)!,
        p[VKey] as! String)
}

func deserializeQueries(q: [[String: AnyObject]]) -> Queries {
    return q.map { dict in
        let name = dict["key"] as! String
        let preds = (dict["value"] as! [[String: AnyObject]]).map(deserializePredicate)
        return (name, preds)
    }
}

func sqlize(p: Predicate) -> String {
    let comparisonOperators = ["<", "<=", "==", "!=", "=>", ">"]
    return "\(p.0) \(comparisonOperators[p.1.rawValue]) \(p.2)"
}

func sqlize(q: ConjunctiveQuery) -> String {
    return q.1.map(sqlize).joinWithSeparator(" and ")
}