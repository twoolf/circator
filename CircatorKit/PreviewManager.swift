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

    public static let rowIcons: [UIImage] = {
        return ["icon_scale", "icon_egg_shell", "icon_water_droplet", "icon_run", "icon_sleep", "icon_meal", "icon_heart_rate"].map { UIImage(named: $0)! }
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
                HKObjectType.categoryTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
                HKObjectType.quantityTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
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
        let index = previewChoices.indexOf { (row) -> Bool in
            return row.indexOf(sampleType) != nil
        }
        return index != nil ? rowIcons[index!] : UIImage()
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


