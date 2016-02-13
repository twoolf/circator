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
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!
        ]
    ]

    public static let rowIcons: [HKSampleType: UIImage] = { _ in
        let previewIcons : [HKSampleType: String] = [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!                  : "icon_scale",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!             : "scale_white_for_BMI",
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!             : "icon_sleep",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!              : "icon_sugar_cubes_three",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!                : "icon_sun",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!            : "icon_steak_for_protein",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!           : "icon_for_fat_using_mayannoise",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!      : "icon_jelly_donut_for_carbs",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!        : "icon_egg_shell",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!     : "icon_eating_at_table",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!              : "icon_water_droplet",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!           : "icon_coffee_for_caffeine",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!                 : "icon_heart_rate",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!             : "icon_salt_for_sodium_entry",
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!       : "icon_blood_pressure",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!        : "icon_run",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!                 : "icon_steps_white",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)! : "icon_corn_for_polyunsaturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!       : "icon_cocunut_for_saturated_fat",
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)! : "icon_olive_oil_jug_for_monounsaturated_fat"
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
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
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


