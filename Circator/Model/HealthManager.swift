//
//  HealthManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/27/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit

typealias HealthManagerAuthorizationBlock = (success: Bool, error: NSError?) -> Void
typealias HealthManagerFetchSampleBlock = (samples: [HKSample], error: NSError?) -> Void

let HealthManagerErrorDomain = "HealthManagerErrorDomain"
let HealthManagerSampleTypeIdentifierSleepDuration = "HealthManagerSampleTypeIdentifierSleepDuration"

let HealthManagerDidUpdateRecentSamplesNotification = "HealthManagerDidUpdateRecentSamplesNotification"

class HealthManager {
    
    static let sharedManager = HealthManager()
    
    lazy var healthKitStore: HKHealthStore = HKHealthStore()
    
    static let previewSampleTypes = [
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
        HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!
    ]
    
    var mostRecentSamples = [HKSampleType: [HKSample]]()
    
    // Not guaranteed to be on main thread
    func authorizeHealthKit(completion: HealthManagerAuthorizationBlock)
    {
        let healthKitTypesToRead : Set<HKObjectType>? = [
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!
        ]
        
        let healthKitTypesToWrite : Set<HKSampleType>? = []
        
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: HealthManagerErrorDomain, code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this Device"])
            completion(success: false, error:error)
            return
        }
        
        healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead)
            { (success, error) -> Void in
                completion(success: success, error: error)
        }
        
    }
    
    func fetchMostRecentSample(sampleType: HKSampleType, completion: HealthManagerFetchSampleBlock)
    {
        let mostRecentPredicate: NSPredicate
        let limit: Int
        
        let aDay = NSDateComponents()
        aDay.day = -1
        let aDayAgo = NSCalendar.currentCalendar().dateByAddingComponents(aDay, toDate: NSDate(), options: NSCalendarOptions())!
        let now = NSDate()
        if sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis {
            mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(aDayAgo, endDate: now, options: .None)
            limit = Int(HKObjectQueryNoLimit)
        } else {
            mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(NSDate.distantPast(), endDate: now, options: .None)
            limit = 1
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                guard error == nil else {
                    completion(samples: [], error: error)
                    return
                }
                completion(samples: results!, error: nil)
        }
        self.healthKitStore.executeQuery(sampleQuery)
    }
    
    func fetchMostRecentSamples(forTypes types: [HKSampleType] = previewSampleTypes, completion: (samples: [HKSampleType: [HKSample]], error: NSError?) -> Void) {
        let group = dispatch_group_create()
        var samples = [HKSampleType: [HKSample]]()
        types.forEach { (type) -> () in
            dispatch_group_enter(group)
            fetchMostRecentSample(type) { (sampleCollection, error) -> Void in
                dispatch_group_leave(group)
                guard error == nil else {
                    return
                }
                guard sampleCollection.isEmpty == false else {
                    return
                }
                samples[sampleCollection[0].sampleType] = sampleCollection
            }
        }
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            // TODO: partial error handling
            self.mostRecentSamples = samples
            completion(samples: samples, error: nil)
        }
    }
}

extension Array where Element: HKSample {
    var sleepDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKCategorySample
            return categorySample.sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis && categorySample.value == HKCategoryValueSleepAnalysis.Asleep.rawValue
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
}