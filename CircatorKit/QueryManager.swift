//
//  QueryManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

public typealias Predicate = (String, Comparator, String)
public typealias Queries = [(String, Query)]

public enum Comparator : Int {
    case LT
    case LTE
    case EQ
    case NEQ
    case GT
    case GTE
}

public enum Query {
    case ConjunctiveQuery([Predicate])
    case UserDefinedQuery(String)
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
        querySelected = 0
        saveIndex()
    }
}

private let AKey = "attr"
private let CKey = "comp"
private let VKey = "pval"

private let NKey = "qname"
private let UKey = "qudef"
private let QKey = "query"

func serializePredicate(p: Predicate) -> [String: AnyObject] {
    return [
        AKey : p.0,
        CKey : p.1.rawValue,
        VKey : p.2
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
        p[AKey] as! String,
        Comparator(rawValue: p[CKey] as! Int)!,
        p[VKey] as! String)
}

func deserializeQueries(qs: [[String: AnyObject]]) -> Queries {
    print(qs)
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

func sqlizePredicate(p: Predicate) -> String {
    let comparisonOperators = ["<", "<=", "==", "!=", "=>", ">"]
    return "\(p.0) \(comparisonOperators[p.1.rawValue]) \(p.2)"
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
