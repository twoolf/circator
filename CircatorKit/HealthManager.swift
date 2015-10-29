//
//  HealthManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/27/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit
import WatchConnectivity

public typealias HealthManagerAuthorizationBlock = (success: Bool, error: NSError?) -> Void
public typealias HealthManagerFetchSampleBlock = (samples: [HKSample], error: NSError?) -> Void

public let HealthManagerErrorDomain = "HealthManagerErrorDomain"
public let HealthManagerSampleTypeIdentifierSleepDuration = "HealthManagerSampleTypeIdentifierSleepDuration"

public let HealthManagerDidUpdateRecentSamplesNotification = "HealthManagerDidUpdateRecentSamplesNotification"

public class HealthManager: NSObject, WCSessionDelegate {
    
    public static let sharedManager = HealthManager()
    
    lazy var healthKitStore: HKHealthStore = HKHealthStore()
    
    private override init() {
        super.init()
        connectWatch()
    }
    
    public static let previewSampleTypes = [
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
        HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!
    ]
    
    public var mostRecentSamples = [HKSampleType: [HKSample]]() {
        didSet {
            self.updateWatchContext()
        }
    }
    
    // Not guaranteed to be on main thread
    public func authorizeHealthKit(completion: HealthManagerAuthorizationBlock)
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
    
    public func fetchMostRecentSample(sampleType: HKSampleType, completion: HealthManagerFetchSampleBlock)
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
    
    public func fetchMostRecentSamples(ofTypes types: [HKSampleType] = previewSampleTypes, completion: (samples: [HKSampleType: [HKSample]], error: NSError?) -> Void) {
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
    
    public func fetchSamplesOfType(sampleType: HKSampleType, limit: Int = 20, completion: HealthManagerFetchSampleBlock) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: limit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) -> Void in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            completion(samples: samples!, error: nil)
        }
        healthKitStore.executeQuery(query)
    }
    
    // MARK: - Apple Watch
    
    func connectWatch() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    func updateWatchContext() {
        // This release currently removed watch support
        guard WCSession.isSupported() && WCSession.defaultSession().watchAppInstalled else {
            return
        }
        do {
            let sampleFormatter = SampleFormatter()
            let applicationContext = mostRecentSamples.map { (sampleType, samples) -> [String: String] in
                return [
                    "sampleTypeIdentifier": sampleType.identifier,
                    "displaySampleType": sampleType.displayText!,
                    "value": sampleFormatter.stringFromSamples(samples)
                ]
            }
            try WCSession.defaultSession().updateApplicationContext(["context": applicationContext])
        } catch {
            print(error)
        }
    }
}

public extension HKSampleType {
    public var displayText: String? {
        switch identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heart beat", comment: "HealthKit data type")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "HealthKit data type")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Food calories", comment: "HealthKit data type")
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "HealthKit data type")
        default:
            return nil
        }
    }
}

public extension HKSample {
    public var numeralValue: Double? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            fallthrough
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierHeartRate:
            return (self as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
        case HKCategoryTypeIdentifierSleepAnalysis:
            // TODO: implement sleep analysis
            return 0
        case HKCorrelationTypeIdentifierBloodPressure:
            return ((self as! HKCorrelation).objects.first as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
        default:
            return nil
        }
    }
    
    public var allNumeralValues: [Double]? {
        return numeralValue != nil ? [numeralValue!] : nil
    }
    
    public var defaultUnit: HKUnit? {
        let isMetric: Bool = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue
        switch sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()
        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
        case HKCategoryTypeIdentifierSleepAnalysis:
            return HKUnit.hourUnit()
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return HKUnit.kilocalorieUnit()
        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()
        default:
            return nil
        }
    }
}

public extension HKCorrelation {
    public override var allNumeralValues: [Double]? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKCorrelationTypeIdentifierBloodPressure:
            return objects.map { (sample) -> Double in
                (sample as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
            }
        default:
            return nil
        }
    }
}

public extension Array where Element: HKSample {
    public var sleepDuration: NSTimeInterval? {
        return filter { (sample) -> Bool in
            let categorySample = sample as! HKCategorySample
            return categorySample.sampleType.identifier == HKCategoryTypeIdentifierSleepAnalysis && categorySample.value == HKCategoryValueSleepAnalysis.Asleep.rawValue
            }.map { (sample) -> NSTimeInterval in
                return sample.endDate.timeIntervalSinceDate(sample.startDate)
            }.reduce(0) { $0 + $1 }
    }
}