//
//  PreviewManager.swift
//  Circator
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit
import SwiftyUserDefaults

private let PMSampleTypesKey = DefaultsKey<[NSData]?>("previewSampleTypes")

public class PreviewManager: NSObject {
    public static let previewChoices: [[HKSampleType]] = [
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        ],
        [
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!,
        ]
    ]

    public static let rowIcons: [HKSampleType: UIImage] = { _ in
        let previewIcons : [HKSampleType: String] = [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!                  : "icon_scale",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!             : "icon_scale",         //"scale_white_for_BMI",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!            : "icon_egg_shell",     //"icon_steak_for_protein",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!           : "icon_egg_shell",     //"icon_for_fat_using_mayannoise",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!      : "icon_egg_shell",     //"icon_jelly_donut_for_carbs",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!     : "icon_egg_shell",     //"icon_eating_at_table",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!              : "icon_water_droplet", //"icon_hydrate_person_for_water",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!           : "icon_water_droplet", //"icon_coffee_for_caffeine",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!        : "icon_run",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!                 : "icon_run",           // "icon_steps_white",
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!             : "icon_sleep",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!                : "icon_sun",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!              : "icon_sugar_cubes_three",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!        : "icon_meal",          // "icon_cholesterol",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!             : "icon_meal",          // "icon_salt_for_sodium_entry",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)! : "icon_meal",          // "icon_corn_for_polyunsaturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!       : "icon_meal",          // "icon_coconut_for_saturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)! : "icon_meal",          // "icon_olive_oil_jug_for_monounsaturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!                 : "icon_heart_rate",
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!       : "icon_blood_pressure"
        ]
        return Dictionary(pairs: previewIcons.map { (k,v) in return (k, UIImage(named: v)!) })
    }()

    public static var previewSampleTypes: [HKSampleType] {
        if let rawTypes = Defaults[PMSampleTypesKey] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! HKSampleType
            }
        } else {
            let defaultTypes = [
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
            ]
            let rawTypes = defaultTypes.map { (sampleType) -> NSData in
                return NSKeyedArchiver.archivedDataWithRootObject(sampleType)
            }
            Defaults[PMSampleTypesKey] = rawTypes
            return defaultTypes
        }
    }

    public static func iconForSampleType(sampleType: HKSampleType) -> UIImage {
        return rowIcons[sampleType] ?? UIImage()
    }

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


