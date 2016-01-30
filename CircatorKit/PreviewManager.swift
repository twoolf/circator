//
//  PreviewManager.swift
//  Circator
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import HealthKit

public class PreviewManager: NSObject {
    public static let previewChoices: [[HKSampleType]] = [
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierBloodPressure)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
        ],
        [
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!
            
        ],
        [   HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!
        ],
        [   HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!
            
        ],
        [   HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!
        ],
        [
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!
        ]
    ]



    public static let rowIcons: [UIImage] = {
        return ["icon_scale", "icon_heart_rate", "icon_sleep", "icon_meal", "icon_food", "icon_run", "icon_blood_pressure"].map { UIImage(named: $0)! }
    }()

    public static var previewSampleTypes: [HKSampleType] {
        if let rawTypes = NSUserDefaults.standardUserDefaults().objectForKey("previewSampleTypes") as? [NSData] {
            return rawTypes.map { (data) -> HKSampleType in
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! HKSampleType
            }
        } else {
            let defaultTypes = [
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!
            ]
            let rawTypes = defaultTypes.map { (sampleType) -> NSData in
                return NSKeyedArchiver.archivedDataWithRootObject(sampleType)
            }
            NSUserDefaults.standardUserDefaults().setObject(rawTypes, forKey: "previewSampleTypes")
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
        NSUserDefaults.standardUserDefaults().setObject(rawTypes, forKey: "previewSampleTypes")
    }
}


