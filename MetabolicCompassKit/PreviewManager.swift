//
//  PreviewManager.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit
import SwiftyUserDefaults

private let PMSampleTypesKey = DefaultsKey<[NSData]?>("previewSampleTypes")
private let PMBalanceSampleTypesKey = DefaultsKey<[NSData]?>("balanceSampleTypes")
public  let PMDidUpdateBalanceSampleTypesNotification = "PMDidUpdateBalanceSampleTypesNotification"
/**
Controls the HealthKit metrics that will be displayed on picker wheels, tableviews, and radar charts
 
 - Parameters:
 - previewChoices:        array of seven sub-arrays for metrics that can be displayed
 - rowIcons:              images for each of the metrics
 - previewSampleTypes:    current set of seven active metrics for display

 */

public class PreviewManager: NSObject {
    public static let previewSampleMeals = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack"
    ]


    public static let previewSampleTimes = [
        NSDate()
    ]
    
    static func setupTypes() -> [HKSampleType] {
        if #available(iOS 9.3, *) {
            return [
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierAppleExerciseTime)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!,
            ]
        }
        else{
            return [
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!,
            ]
        }
    }
    public static let supportedTypes:[HKSampleType] = PreviewManager.setupTypes()
    

    
//    @available(iOS 9.3, *)
//    public static let supportedTypes = [
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
//        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
//        HKObjectType.categoryTypeForIdentifier(HKQuantityTypeIdentifierAppleExerciseTime)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
//        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
//        HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!,
//    ]


    
    public static let previewChoices: [[HKSampleType]] = [
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
        ],
        [
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!
        ],
    ]

    public static let rowIcons: [HKSampleType: UIImage] = { _ in
        let previewIcons : [HKSampleType: String] = [
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!             : "icon_sleep",
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!       : "icon_blood_pressure",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!        : "icon_run",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!                  : "icon_scale",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!             : "scale_white_for_BMI",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!           : "icon_coffee_for_caffeine",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!      : "icon_jelly_donut_for_carbs",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!        : "icon_egg_shell",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!     : "icon_eating_at_table",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)! : "icon_olive_oil_jug_for_monounsaturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)! : "icon_corn_for_polyunsaturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!       : "icon_cocunut_for_saturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!           : "icon_for_fat_using_mayannoise",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!            : "icon_steak_for_protein",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!             : "icon_salt_for_sodium_entry",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!              : "icon_sugar_cubes_three",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!              : "icon_water_droplet",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!                 : "icon_heart_rate",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!                 : "icon_steps_white",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!                : "icon_sun",
        ]
        return Dictionary(pairs: previewIcons.map { (k,v) in return (k, UIImage(named: v)!) })
    }()

    /// note archiver for retaining memory of picked metrics
    public static var previewSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! HKSampleType
            }
        } else {
            let defaultTypes = self.supportedTypes
            self.updatePreviewSampleTypes(defaultTypes)
            return defaultTypes
        }
    }
    
    public static func updatePreviewSampleTypes (types: [HKSampleType]) {
    
        let rawTypes = types.map { (sampleType) -> NSData in
            return NSKeyedArchiver.archivedDataWithRootObject(sampleType)
        }
        
        Defaults[PMSampleTypesKey] = rawTypes
    }
    
    /// note archiver for retaining memory of picked metrics
    public static var balanceSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMBalanceSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! HKSampleType
            }
        } else {
            let defaultTypes = Array(self.supportedTypes[0..<7])
            self.updateBalanceSampleTypes(defaultTypes)
            return defaultTypes
        }
    }
    
    public static func updateBalanceSampleTypes (types: [HKSampleType]) {
        
        let rawTypes = types.map { (sampleType) -> NSData in
            return NSKeyedArchiver.archivedDataWithRootObject(sampleType)
        }
        
        Defaults[PMBalanceSampleTypesKey] = rawTypes
        NSNotificationCenter.defaultCenter().postNotificationName(PMDidUpdateBalanceSampleTypesNotification, object: nil)
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
        types.removeAtIndex(row)
        types.insert(sampleType, atIndex: row)
        let rawTypes = types.map { (sampleType) -> NSData in
            return NSKeyedArchiver.archivedDataWithRootObject(sampleType)
        }
        Defaults[PMSampleTypesKey] = rawTypes
    }
    

}


