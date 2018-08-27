//
//  PreviewManager.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit
import SwiftyUserDefaults

private let PMSampleTypesKey = DefaultsKey<[Any]?>("previewSampleTypes")
private let PMManageSampleTypesKey = DefaultsKey<[Any]?>("manageSampleTypesKey")
private let PMChartsSampleTypesKey = DefaultsKey<[Any]?>("chartsSampleTypes")
private let PMManageChartsSampleTypesKey = DefaultsKey<[Any]?>("manageChartsSampleTypes")
private let PMBalanceSampleTypesKey = DefaultsKey<[Any]?>("balanceSampleTypes")
public  let PMDidUpdateBalanceSampleTypesNotification = "PMDidUpdateBalanceSampleTypesNotification"
/**
Controls the HealthKit metrics that will be displayed on picker wheels, tableviews, and radar charts

 - Parameters:
 - previewChoices:        array of seven sub-arrays for metrics that can be displayed
 - rowIcons:              images for each of the metrics
 - previewSampleTypes:    current set of seven active metrics for display 

 */

public let PMDidUpdatePreviewSampleTypes = "pm.didUpdatePreviewSampleTypes"

public class PreviewManager: NSObject {
    public static let previewSampleMeals = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack"
    ]


    public static let previewSampleTimes = [
        Date()
    ]

    static func setupTypes() -> [HKSampleType] {
        return [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.uvExposure)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFiber)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySodium)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCholesterol)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatMonounsaturated)!,//
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!,//
            HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!,
        ]
    }

    public static let supportedTypes:[HKSampleType] = PreviewManager.setupTypes()

    public static let initialPreviewTypes: [HKSampleType] = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,//
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,//
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,//
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,//
        HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,//
        HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!,
    ]

    public static let previewChoices: [[HKSampleType]] = [
        [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        ],
        [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        ],
        [
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.uvExposure)!
        ],
        [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!
        ],
        [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySodium)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCholesterol)!
        ],
        [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatMonounsaturated)!
        ],
        [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!,
            HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!
        ],
    ]

    public static let rowIcons: [HKSampleType: UIImage] = {
        let previewIcons : [HKSampleType: String] = [
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!             : "icon_sleep",
            HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure)!       : "icon_blood_pressure",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!        : "icon_run",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!                  : "icon_scale",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!             : "scale_white_for_BMI",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine)!           : "icon_coffee_for_caffeine",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!      : "icon_jelly_donut_for_carbs",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCholesterol)!        : "icon_egg_shell",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!     : "icon_eating_at_table",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatMonounsaturated)! : "icon_olive_oil_jug_for_monounsaturated_fat",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)! : "icon_corn_for_polyunsaturated_fat",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatSaturated)!       : "icon_cocunut_for_saturated_fat",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!           : "icon_for_fat_using_mayannoise",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!            : "icon_steak_for_protein",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySodium)!             : "icon_salt_for_sodium_entry",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!              : "icon_sugar_cubes_three",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!              : "icon_water_droplet",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!                 : "icon_heart_rate",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!                 : "icon_steps_white",
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.uvExposure)!                : "icon_sun",
        ]
        return Dictionary(pairs: previewIcons.map { (k,v) in return (k, UIImage(named: v)!) })
    }()

    public static func resetPreviewTypes() {
        Defaults.remove(PMSampleTypesKey)
        Defaults.remove(PMManageSampleTypesKey)
        Defaults.remove(PMChartsSampleTypesKey)
        Defaults.remove(PMManageChartsSampleTypesKey)
        Defaults.remove(PMBalanceSampleTypesKey)
    }
    
    //MARK: Preview Sample Types
    
    private static var savedPreviewSampleTypes: [HKSampleType]? {
        if let rawTypes = Defaults[PMSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! HKSampleType
            }
        }
        return nil
    }
    
    public static var previewSampleTypes: [HKSampleType] {
        if let savedPreviewSampleTypes = self.savedPreviewSampleTypes {
            return savedPreviewSampleTypes
        } else {
            let defaultTypes = self.initialPreviewTypes
            self.updatePreviewSampleTypes(types: defaultTypes)
            return defaultTypes
        }
    }
    
    public static func updatePreviewSampleTypes (types: [HKSampleType]) {

        let rawTypes = types.map { (sampleType) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: sampleType)
        }

        let shouldNotify = (self.savedPreviewSampleTypes != nil) && (self.savedPreviewSampleTypes?.count ?? 0) < rawTypes.count
        Defaults[PMSampleTypesKey] = rawTypes
        if shouldNotify {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PMDidUpdatePreviewSampleTypes), object: self)
        }
    }
    
    public static var managePreviewSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMManageSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! HKSampleType
            }
        } else {
            let defaultTypes = self.supportedTypes
            self.updateManagePreviewSampleTypes(types: defaultTypes)
            return defaultTypes
        }
    }
    
    public static func updateManagePreviewSampleTypes (types: [HKSampleType]) {
        
        let rawTypes = types.map { (sampleType) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: sampleType)
        }
        
        Defaults[PMManageSampleTypesKey] = rawTypes
    }

    //MARK: Balance Sample Types
    public static var balanceSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMBalanceSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! HKSampleType
            }
        } else {
            let defaultTypes = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
                                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
                                HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!,
                                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
                                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietarySugar)!,
                                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatPolyunsaturated)!,
                                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)!]
            self.updateBalanceSampleTypes(types: defaultTypes)
            return defaultTypes
        }
    }

    public static func updateBalanceSampleTypes (types: [HKSampleType]) {
        let rawTypes = types.map { (sampleType) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: sampleType)
        }

        Defaults[PMBalanceSampleTypesKey] = rawTypes
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PMDidUpdateBalanceSampleTypesNotification), object: nil)
    }
    
    //MARK: Charts Sample Types
    public static var chartsSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMChartsSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! HKSampleType
            }
        } else {
            let defaultTypes = self.initialPreviewTypes
            self.updateChartsSampleTypes(types: defaultTypes)
            return defaultTypes
        }
    }
    
    public static func updateChartsSampleTypes (types: [HKSampleType]) {
        
        let rawTypes = types.map { (sampleType) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: sampleType)
        }
        
        Defaults[PMChartsSampleTypesKey] = rawTypes
    }
    
    public static var manageChartsSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMManageChartsSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! HKSampleType
            }
        } else {
            let defaultTypes = self.supportedTypes
            self.updateManageChartsSampleTypes(types: defaultTypes)
            return defaultTypes
        }
    }
    
    public static func updateManageChartsSampleTypes (types: [HKSampleType]) {
        
        let rawTypes = types.map { (sampleType) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: sampleType)
        }
        
        Defaults[PMManageChartsSampleTypesKey] = rawTypes
    }
    
    /// associates icon with sample type
    public static func iconForSampleType(sampleType: HKSampleType) -> UIImage {
        return rowIcons[sampleType] ?? UIImage()
    }

    /// with RowSettingViewController enables new association for selected row
    public static func reselectSampleType(sampleType: HKSampleType, forPreviewRow row: Int) {
        guard row >= 0 && row < previewChoices.count else {
            return
        }
        var types = previewSampleTypes
        types.remove(at: row)
        types.insert(sampleType, at: row)
        let rawTypes = types.map { (sampleType) -> Data in
            return NSKeyedArchiver.archivedData(withRootObject: sampleType)
        }
        Defaults[PMSampleTypesKey] = rawTypes
    }
    

}


