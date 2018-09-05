//
//  HKUpdtesController.swift
//  HKUpdtesController.swift
//
//  Created by User on 9/5/18.
//  Copyright (c) 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//
//

import HealthKit
import MCCircadianQueries

public protocol HKUpdatesObserver: class {
    func updatesAvailable(for type: HKSampleType)
}

public final class HKUpdatesController {
    
    private class WeakObserver {
        weak var observer: HKUpdatesObserver?
        init(observer: HKUpdatesObserver) {
            self.observer = observer
        }
    }
    
    private var observers = [String: WeakObserver]()
    private var observingTypes = [HKSampleType: [String]]()
    private var queries = [HKSampleType: HKObserverQuery]()
    
    private static let instance = HKUpdatesController()
    private var healthKitStore: HKHealthStore {
        return MCHealthManager.sharedManager.healthKitStore
    }
    
    public class func add(observer: HKUpdatesObserver, forKey key: String, observingTypes: [HKSampleType]) {
        cancelObserving(for: key)
        instance.observers[key] = WeakObserver(observer: observer)
        instance.observe(types: observingTypes, forKey: key)
    }
    
    public class func cancelObserving(for key: String) {
        _ = instance.observers.removeValue(forKey: key)
        
        let observingTypes = instance.observingTypes.reduce([HKSampleType: [String]]()) { (result, obsType) in
            var mresult = result
            if let index = obsType.value.index(of: key) {
                var mkeys = obsType.value
                mkeys.remove(at: index)
                if mkeys.count > 0 {
                    mresult[obsType.key] = mkeys
                } else if let query = self.instance.queries[obsType.key] {
                    self.instance.healthKitStore.stop(query)
                    self.instance.queries.removeValue(forKey: obsType.key)
                }
            } else {
                mresult[obsType.key] = obsType.value
            }
            return mresult
        }
        instance.observingTypes = observingTypes
    }
    
    public class func cancelAll() {
        self.instance.observingTypes.removeAll()
        self.instance.observers.removeAll()
        self.instance.queries.forEach { query in
            self.instance.healthKitStore.stop(query.value)
        }
        self.instance.queries.removeAll()
    }
    
    public class func pauseObserving() {
        self.instance.queries.forEach { query in
            self.instance.healthKitStore.stop(query.value)
        }
    }
    
    public class func resumeObserving() {
        self.instance.queries.forEach { query in
            self.instance.healthKitStore.execute(query.value)
        }
    }
    
    private func observe(type: HKSampleType) {
        let obsQuery = HKObserverQuery(sampleType: type, predicate: nil) {
            query, completion, obsError in
            if let `obsError` = obsError {
                log.error(obsError.localizedDescription)
                return
            }
            if self.healthKitStore.authorizationStatus(for: type) == .sharingAuthorized {
                self.observingTypes[type]?.forEach({ key in
                    self.observers[key]?.observer?.updatesAvailable(for: type)
                })
            }
            log.debug("\n********** updtes for type \(type) avilable **********\n")
            completion()
        }
        self.queries[type] = obsQuery
        self.healthKitStore.execute(obsQuery)
    }
    
    private func observe(types: [HKSampleType], forKey key: String) {
        types.forEach { type in
            if self.observingTypes[type] == nil {
                self.observingTypes[type] = [key]
                self.observe(type: type)
            } else if self.observingTypes[type]?.contains(key) == false {
                self.observingTypes[type]?.append(key)
            }
        }
    }
}
