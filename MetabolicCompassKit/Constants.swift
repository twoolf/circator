//
//  Constants.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit

// Controls the features compiled into the app.
public struct Deployment {
    public static let sharedInstance = Deployment()

    public let withDebugView : Bool = true
}

/**
 This maintains the constants and strings needed for Metabolic Compass. We tie this into the options and recommendations settings in the control panel.

 */

public enum FieldDataType: Int {
    case String = 0, Int, Decimal
}

public struct ProfileFieldData {
    public let fieldName: String!
    public let profileFieldName: String!
    public let type: FieldDataType!
    public let unitsTitle: String?
}

private let unitsTitleHours = "hours"
private let unitsTitleCalories = "calories"
private let unitsTitleSteps = "steps"
private let unitsTitleHeartrate = "bpm"
private let unitsTitleIntake = "m"

public struct UserProfile {

    public static let sharedInstance = UserProfile()

    public let emailIdx : Int = 0
    public let passwIdx : Int = 1
    public let fnameIdx : Int = 2
    public let lnameIdx : Int = 3
    public let updateableIdx : Int = 4

    public let requiredRange      : Range = 0..<8
    public let updateableReqRange : Range = 4..<8
    public let recommendedRange   : Range = 8..<14
    public let optionalRange      : Range = 14..<31
    public let updateableRange    : Range = 4..<31

    public let profileFields : [String]! = [
        "Email",
        "Password",
        "First name",
        "Last name",
        "Sex",
        "Age",
        "Weight",
        "Height",
        "Usual sleep",
        "Estimated bmi",
        "Resting heartrate",
        "Systolic blood pressure",
        "Diastolic blood pressure",
        "Step count",
        "Active energy",
        "Awake time w/light",
        "Fasting",
        "Eating",
        "Calorie intake",
        "Protein intake",
        "Carbohydrate intake",
        "Sugar intake",
        "Fiber intake",
        "Fat intake",
        "Saturated fat",
        "Monounsaturated fat",
        "Polyunsaturated fat",
        "Cholesterol",
        "Salt",
        "Caffeine",
        "Water"]

    public let profilePlaceholders : [String]! = [
        "example@gmail.com",
        "Required",
        "Jane or John",
        "Doe",
        "Female or male",
        "24",
        "160 lbs",
        "180 cm",
        "7 hours",
        "25",
        "60 bpm",
        "120",
        "80",
        "6000 steps",
        "2750 calories",
        "12 hours",
        "12 hours",
        "12 hours",
        "2757(m) or 1957(f)",
        "88.3(m) or 71.3(f)",
        "327(m) or 246.3(f)",
        "143.3(m) or 112(f)",
        "20.6(m) or 16.2(f)",
        "103.2(m) or 73.1(f)",
        "33.4(m) or 23.9(f)",
        "36.9(m) or 25.7(f)",
        "24.3(m) or 17.4(f)",
        "352(m) or 235.7(f)",
        "4560.7(m) or 3187.3(f)",
        "166.4(m) or 142.7(f)",
        "5(m) or 4.7(f)"
    ]

    public let profileMapping : [String: String]! = [
        "Email"                    : "email",
        "Password"                 : "password",
        "First name"               : "first_name",
        "Last name"                : "last_name",
        "Sex"                      : "sex",
        "Age"                      : "age",
        "Weight"                   : "body_weight",
        "Height"                   : "body_height",
        "Usual sleep"              : "sleep_duration",
        "Estimated bmi"            : "body_mass_index",
        "Resting heartrate"        : "heart_rate",
        "Systolic blood pressure"  : "systolic_blood_pressure",
        "Diastolic blood pressure" : "diastolic_blood_pressure",
        "Step count"               : "steps",
        "Active energy"            : "active_energy_burned",
        "Awake time w/light"       : "uv_exposure",
        "Fasting"                  : "fasting_duration",
        "Eating"                   : "meal_duration",
        "Calorie intake"           : "dietary_energy_consumed",
        "Caffeine"                 : "dietary_caffeine",
        "Carbohydrate intake"      : "dietary_carbohydrates",
        "Cholesterol"              : "dietary_cholesterol",
        "Monounsaturated fat"      : "dietary_fat_monounsaturated",
        "Polyunsaturated fat"      : "dietary_fat_polyunsaturated",
        "Saturated fat"            : "dietary_fat_saturated",
        "Fat intake"               : "dietary_fat_total",
        "Fiber intake"             : "dietary_fiber",
        "Protein intake"           : "dietary_protein",
        "Salt"                     : "dietary_salt",
        "Sugar intake"             : "dietary_sugar",
        "Water"                    : "dietary_water"
    ]

    public var updateableMapping : [String: String]! {
        return Dictionary(pairs: profileFields[updateableRange].map { k in return (k, profileMapping[k]!) })
    }

    public static func keyForItemName(itemName: String) -> String?{
        return sharedInstance.profileMapping[itemName]
    }

    public var fields: [ProfileFieldData] = {
        var fields = [ProfileFieldData]()

        fields.append(ProfileFieldData(fieldName: "Email",                    profileFieldName: "email",                       type: .String, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Password",                 profileFieldName: "password",                    type: .String, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "First name",               profileFieldName: "first_name",                  type: .String, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Last name",                profileFieldName: "last_name",                   type: .String, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Sex",                      profileFieldName: "sex",                         type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Age",                      profileFieldName: "age",                         type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Weight",                   profileFieldName: "body_weight",                 type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Height",                   profileFieldName: "body_height",                 type: .Int, unitsTitle: nil))

        fields.append(ProfileFieldData(fieldName: "Usual sleep",              profileFieldName: "sleep_duration",              type: .Int, unitsTitle: unitsTitleHours))
        fields.append(ProfileFieldData(fieldName: "Estimated bmi",            profileFieldName: "body_mass_index",             type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Resting heartrate",        profileFieldName: "heart_rate",                  type: .Int, unitsTitle: unitsTitleHeartrate))
        fields.append(ProfileFieldData(fieldName: "Systolic blood pressure",  profileFieldName: "systolic_blood_pressure",     type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Diastolic blood pressure", profileFieldName: "diastolic_blood_pressure",    type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Step count",               profileFieldName: "steps",                       type: .Int, unitsTitle: unitsTitleSteps))

        fields.append(ProfileFieldData(fieldName: "Active energy",            profileFieldName: "active_energy_burned",        type: .Int, unitsTitle: unitsTitleCalories))
        fields.append(ProfileFieldData(fieldName: "Awake time w/light",       profileFieldName: "uv_exposure",                 type: .Int, unitsTitle: unitsTitleHours))
        fields.append(ProfileFieldData(fieldName: "Fasting",                  profileFieldName: "fasting_duration",            type: .Int, unitsTitle: unitsTitleHours))
        fields.append(ProfileFieldData(fieldName: "Eating",                   profileFieldName: "meal_duration",               type: .Int, unitsTitle: unitsTitleHours))
        fields.append(ProfileFieldData(fieldName: "Calorie intake",           profileFieldName: "dietary_energy_consumed",     type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Protein intake",           profileFieldName: "dietary_protein",             type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Carbohydrate intake",      profileFieldName: "dietary_carbohydrates",       type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Sugar intake",             profileFieldName: "dietary_sugar",               type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Fiber intake",             profileFieldName: "dietary_fiber",               type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Fat intake",               profileFieldName: "dietary_fat_total",           type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Saturated fat",            profileFieldName: "dietary_fat_saturated",       type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Monounsaturated fat",      profileFieldName: "dietary_fat_monounsaturated", type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Polyunsaturated fat",      profileFieldName: "dietary_fat_polyunsaturated", type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Cholesterol",              profileFieldName: "dietary_cholesterol",         type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Salt",                     profileFieldName: "dietary_salt",                type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Caffeine",                 profileFieldName: "dietary_caffeine",            type: .Decimal, unitsTitle: unitsTitleIntake))
        fields.append(ProfileFieldData(fieldName: "Water",                    profileFieldName: "dietary_water",               type: .Decimal, unitsTitle: unitsTitleIntake))

        return fields
    }()

}

/*
 * HealthKit constants
 */

public struct HMConstants
{
    public static let sharedInstance = HMConstants()

    // Metadata key for generated samples.
    public let generatedSampleKey : String = "MCLGen"
    public let generatedUploadSampleKey : String = "MCUGen"

    // Note: these are in alphabetical order within each type.
    public let healthKitTypesToRead : Set<HKObjectType>? = [
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!,
        HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
        HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
        HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierFitzpatrickSkinType)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalBodyTemperature)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodAlcoholContent)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryBiotin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCalcium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChloride)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChromium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCopper)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFolate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIodine)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIron)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryMagnesium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryManganese)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryMolybdenum)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryNiacin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPantothenicAcid)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPhosphorus)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPotassium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryRiboflavin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySelenium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryThiamin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminA)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminB12)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminB6)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminC)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminD)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminE)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminK)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryZinc)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierElectrodermalActivity)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierForcedExpiratoryVolume1)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierForcedVitalCapacity)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierLeanBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierNikeFuel)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierNumberOfTimesFallen)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierOxygenSaturation)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeripheralPerfusionIndex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierRespiratoryRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
        HKObjectType.workoutType()
    ]

    public let healthKitTypesToWrite : Set<HKSampleType>? =
        Deployment.sharedInstance.withDebugView ?
            // Cannot write apple stand hour, nike fuel.
            [
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalBodyTemperature)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodAlcoholContent)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryBiotin)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCalcium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChloride)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChromium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCopper)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFolate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIodine)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIron)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryMagnesium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryManganese)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryMolybdenum)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryNiacin)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPantothenicAcid)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPhosphorus)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPotassium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryRiboflavin)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySelenium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryThiamin)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminA)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminB12)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminB6)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminC)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminD)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminE)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminK)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryZinc)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierElectrodermalActivity)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierForcedExpiratoryVolume1)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierForcedVitalCapacity)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierLeanBodyMass)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierNumberOfTimesFallen)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierOxygenSaturation)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeripheralPerfusionIndex)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierRespiratoryRate)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
                HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
                HKObjectType.workoutType()
            ]
            :
            [
                HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
                HKQuantityType.workoutType()
            ]

    // Note: these are in alphabetical order within each type.
    public let healthKitTypesToObserve : [HKSampleType] = [
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!,
        HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalBodyTemperature)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBasalEnergyBurned)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodAlcoholContent)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyFatPercentage)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryBiotin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCalcium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCaffeine)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCarbohydrates)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCholesterol)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChloride)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryChromium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryCopper)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatMonounsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatPolyunsaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatSaturated)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFatTotal)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFiber)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryFolate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIodine)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryIron)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryMagnesium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryManganese)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryMolybdenum)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryNiacin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPantothenicAcid)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPhosphorus)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryPotassium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryProtein)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryRiboflavin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySelenium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySodium)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietarySugar)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryThiamin)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminA)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminB12)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminB6)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminC)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminD)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminE)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryVitaminK)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryZinc)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierElectrodermalActivity)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierForcedExpiratoryVolume1)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierForcedVitalCapacity)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierInhalerUsage)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierLeanBodyMass)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierNikeFuel)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierNumberOfTimesFallen)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierOxygenSaturation)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeakExpiratoryFlowRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierPeripheralPerfusionIndex)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierRespiratoryRate)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
        HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierUVExposure)!,
        HKObjectType.workoutType()
    ]

    // Note: these are in alphabetical order within each type.
    public let healthKitShortNames : [String: String] = [
        HKCategoryTypeIdentifierAppleStandHour            : "Stood",
        HKCategoryTypeIdentifierSleepAnalysis             : "Sleep",
        HKCharacteristicTypeIdentifierBloodType           : "Blood type",
        HKCharacteristicTypeIdentifierBiologicalSex       : "Sex",
        HKCharacteristicTypeIdentifierFitzpatrickSkinType : "Skin type",
        HKCorrelationTypeIdentifierBloodPressure          : "BP",
        HKQuantityTypeIdentifierActiveEnergyBurned        : "Cal burned",
        HKQuantityTypeIdentifierBasalBodyTemperature      : "Temperature(B)",
        HKQuantityTypeIdentifierBasalEnergyBurned         : "Cal burned(B)",
        HKQuantityTypeIdentifierBloodAlcoholContent       : "BAC",
        HKQuantityTypeIdentifierBloodGlucose              : "Glucose",
        HKQuantityTypeIdentifierBloodPressureDiastolic    : "BP Diastolic",
        HKQuantityTypeIdentifierBloodPressureSystolic     : "BP Systolic",
        HKQuantityTypeIdentifierBodyFatPercentage         : "Body Fat",
        HKQuantityTypeIdentifierBodyMass                  : "Weight",
        HKQuantityTypeIdentifierBodyMassIndex             : "BMI",
        HKQuantityTypeIdentifierBodyTemperature           : "Temperature",
        HKQuantityTypeIdentifierDietaryBiotin             : "Biotin",
        HKQuantityTypeIdentifierDietaryCalcium            : "Calcium",
        HKQuantityTypeIdentifierDietaryCaffeine           : "Caffeine",
        HKQuantityTypeIdentifierDietaryCarbohydrates      : "Carbs",
        HKQuantityTypeIdentifierDietaryCholesterol        : "Cholesterol",
        HKQuantityTypeIdentifierDietaryChloride           : "Chloride",
        HKQuantityTypeIdentifierDietaryChromium           : "Chromium",
        HKQuantityTypeIdentifierDietaryCopper             : "Copper",
        HKQuantityTypeIdentifierDietaryEnergyConsumed     : "Net Calories",
        HKQuantityTypeIdentifierDietaryFatMonounsaturated : "Fat(MS)",
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated : "Fat(PS)",
        HKQuantityTypeIdentifierDietaryFatSaturated       : "Fat(S)",
        HKQuantityTypeIdentifierDietaryFatTotal           : "Fat",
        HKQuantityTypeIdentifierDietaryFiber              : "Fiber",
        HKQuantityTypeIdentifierDietaryFolate             : "Folate",
        HKQuantityTypeIdentifierDietaryIodine             : "Iodine",
        HKQuantityTypeIdentifierDietaryIron               : "Iron",
        HKQuantityTypeIdentifierDietaryMagnesium          : "Magnesium",
        HKQuantityTypeIdentifierDietaryManganese          : "Manganese",
        HKQuantityTypeIdentifierDietaryMolybdenum         : "Molybdenum",
        HKQuantityTypeIdentifierDietaryNiacin             : "Niacin",
        HKQuantityTypeIdentifierDietaryPantothenicAcid    : "Pant. Acid",
        HKQuantityTypeIdentifierDietaryPhosphorus         : "Phosphorus",
        HKQuantityTypeIdentifierDietaryPotassium          : "Potassium",
        HKQuantityTypeIdentifierDietaryProtein            : "Protein",
        HKQuantityTypeIdentifierDietaryRiboflavin         : "Riboflavin",
        HKQuantityTypeIdentifierDietarySelenium           : "Selenium",
        HKQuantityTypeIdentifierDietarySodium             : "Salt",
        HKQuantityTypeIdentifierDietarySugar              : "Sugar",
        HKQuantityTypeIdentifierDietaryThiamin            : "Thiamin",
        HKQuantityTypeIdentifierDietaryVitaminA           : "Vit. A",
        HKQuantityTypeIdentifierDietaryVitaminB12         : "Vit. B12",
        HKQuantityTypeIdentifierDietaryVitaminB6          : "Vit. B6",
        HKQuantityTypeIdentifierDietaryVitaminC           : "Vit. C",
        HKQuantityTypeIdentifierDietaryVitaminD           : "Vit. D",
        HKQuantityTypeIdentifierDietaryVitaminE           : "Vit. E",
        HKQuantityTypeIdentifierDietaryVitaminK           : "Vit. K",
        HKQuantityTypeIdentifierDietaryWater              : "Water",
        HKQuantityTypeIdentifierDietaryZinc               : "Zinc",
        HKQuantityTypeIdentifierDistanceWalkingRunning    : "Distance",
        HKQuantityTypeIdentifierElectrodermalActivity     : "Electrodermal",
        HKQuantityTypeIdentifierFlightsClimbed            : "Climbed",
        HKQuantityTypeIdentifierForcedExpiratoryVolume1   : "Exp. Volume",
        HKQuantityTypeIdentifierForcedVitalCapacity       : "Vital Capacity",
        HKQuantityTypeIdentifierHeartRate                 : "Heart rate",
        HKQuantityTypeIdentifierHeight                    : "Height",
        HKQuantityTypeIdentifierInhalerUsage              : "Inhaler",
        HKQuantityTypeIdentifierLeanBodyMass              : "Lean Weight",
        HKQuantityTypeIdentifierNikeFuel                  : "Nike Fuel",
        HKQuantityTypeIdentifierNumberOfTimesFallen       : "Fallen",
        HKQuantityTypeIdentifierOxygenSaturation          : "Oxygen",
        HKQuantityTypeIdentifierPeakExpiratoryFlowRate    : "Exp. Flow",
        HKQuantityTypeIdentifierPeripheralPerfusionIndex  : "Perfusion",
        HKQuantityTypeIdentifierRespiratoryRate           : "Respiratory",
        HKQuantityTypeIdentifierStepCount                 : "Steps",
        HKQuantityTypeIdentifierUVExposure                : "Light",
        HKObjectType.workoutType().identifier             : "Workouts/Meals"
    ]

    // Note: We use strings as short ids to be compatible with JSON dictionary keys.
    public let healthKitShortIds : [String: String] = [
        HKCategoryTypeIdentifierSleepAnalysis             : "0",
        HKCategoryTypeIdentifierAppleStandHour            : "1",
        HKQuantityTypeIdentifierActiveEnergyBurned        : "2",
        HKQuantityTypeIdentifierBasalBodyTemperature      : "3",
        HKQuantityTypeIdentifierBasalEnergyBurned         : "4",
        HKQuantityTypeIdentifierBloodAlcoholContent       : "5",
        HKQuantityTypeIdentifierBloodGlucose              : "6",
        HKQuantityTypeIdentifierBloodPressureDiastolic    : "7",
        HKQuantityTypeIdentifierBloodPressureSystolic     : "8",
        HKQuantityTypeIdentifierBodyFatPercentage         : "9",
        HKQuantityTypeIdentifierBodyMass                  : "10",
        HKQuantityTypeIdentifierBodyMassIndex             : "11",
        HKQuantityTypeIdentifierBodyTemperature           : "12",
        HKQuantityTypeIdentifierDietaryBiotin             : "13",
        HKQuantityTypeIdentifierDietaryCalcium            : "14",
        HKQuantityTypeIdentifierDietaryCaffeine           : "15",
        HKQuantityTypeIdentifierDietaryCarbohydrates      : "16",
        HKQuantityTypeIdentifierDietaryCholesterol        : "17",
        HKQuantityTypeIdentifierDietaryChloride           : "18",
        HKQuantityTypeIdentifierDietaryChromium           : "19",
        HKQuantityTypeIdentifierDietaryCopper             : "20",
        HKQuantityTypeIdentifierDietaryEnergyConsumed     : "21",
        HKQuantityTypeIdentifierDietaryFatMonounsaturated : "22",
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated : "23",
        HKQuantityTypeIdentifierDietaryFatSaturated       : "24",
        HKQuantityTypeIdentifierDietaryFatTotal           : "25",
        HKQuantityTypeIdentifierDietaryFiber              : "26",
        HKQuantityTypeIdentifierDietaryFolate             : "27",
        HKQuantityTypeIdentifierDietaryIodine             : "28",
        HKQuantityTypeIdentifierDietaryIron               : "29",
        HKQuantityTypeIdentifierDietaryMagnesium          : "30",
        HKQuantityTypeIdentifierDietaryManganese          : "31",
        HKQuantityTypeIdentifierDietaryMolybdenum         : "32",
        HKQuantityTypeIdentifierDietaryNiacin             : "33",
        HKQuantityTypeIdentifierDietaryPantothenicAcid    : "34",
        HKQuantityTypeIdentifierDietaryPhosphorus         : "35",
        HKQuantityTypeIdentifierDietaryPotassium          : "36",
        HKQuantityTypeIdentifierDietaryProtein            : "37",
        HKQuantityTypeIdentifierDietaryRiboflavin         : "38",
        HKQuantityTypeIdentifierDietarySelenium           : "39",
        HKQuantityTypeIdentifierDietarySodium             : "40",
        HKQuantityTypeIdentifierDietarySugar              : "41",
        HKQuantityTypeIdentifierDietaryThiamin            : "42",
        HKQuantityTypeIdentifierDietaryVitaminA           : "43",
        HKQuantityTypeIdentifierDietaryVitaminB12         : "44",
        HKQuantityTypeIdentifierDietaryVitaminB6          : "45",
        HKQuantityTypeIdentifierDietaryVitaminC           : "46",
        HKQuantityTypeIdentifierDietaryVitaminD           : "47",
        HKQuantityTypeIdentifierDietaryVitaminE           : "48",
        HKQuantityTypeIdentifierDietaryVitaminK           : "49",
        HKQuantityTypeIdentifierDietaryWater              : "50",
        HKQuantityTypeIdentifierDietaryZinc               : "51",
        HKQuantityTypeIdentifierDistanceWalkingRunning    : "52",
        HKQuantityTypeIdentifierElectrodermalActivity     : "53",
        HKQuantityTypeIdentifierFlightsClimbed            : "54",
        HKQuantityTypeIdentifierForcedExpiratoryVolume1   : "55",
        HKQuantityTypeIdentifierForcedVitalCapacity       : "56",
        HKQuantityTypeIdentifierHeartRate                 : "57",
        HKQuantityTypeIdentifierHeight                    : "58",
        HKQuantityTypeIdentifierInhalerUsage              : "59",
        HKQuantityTypeIdentifierLeanBodyMass              : "60",
        HKQuantityTypeIdentifierNikeFuel                  : "61",
        HKQuantityTypeIdentifierNumberOfTimesFallen       : "62",
        HKQuantityTypeIdentifierOxygenSaturation          : "63",
        HKQuantityTypeIdentifierPeakExpiratoryFlowRate    : "64",
        HKQuantityTypeIdentifierPeripheralPerfusionIndex  : "65",
        HKQuantityTypeIdentifierRespiratoryRate           : "66",
        HKQuantityTypeIdentifierStepCount                 : "67",
        HKQuantityTypeIdentifierUVExposure                : "68",
        HKObjectType.workoutType().identifier             : "69",
    ]

    // A mapping between HealthKit types and MC database schema attributes.
    //
    // TODO: the following types have a more complex mapping.
    // HKCorrelationTypeIdentifierBloodPressure          : "BP",            // Maps to individual components.
    // HKQuantityTypeIdentifierDistanceWalkingRunning    : "Distance",      // Activity
    // HKQuantityTypeIdentifierFlightsClimbed            : "Climbed",       // Activity
    // HKQuantityTypeIdentifierStepCount                 : "Steps",         // Activity
    // HKObjectType.workoutType().identifier             : "Workouts/Meals" // Activity/Meal
    //
    // TODO: the following types should be stored as profile attribute:
    // HKCharacteristicTypeIdentifierBloodType           : "Blood type",
    // HKCharacteristicTypeIdentifierBiologicalSex       : "Sex",
    // HKCharacteristicTypeIdentifierFitzpatrickSkinType : "Skin type",
    //
    public let hkToMCDB : [String: String] = [
        HKCategoryTypeIdentifierAppleStandHour            : "apple_stand_hour",
        HKCategoryTypeIdentifierSleepAnalysis             : "sleep_duration",
        HKQuantityTypeIdentifierActiveEnergyBurned        : "active_energy_burned",
        HKQuantityTypeIdentifierBasalBodyTemperature      : "basal_body_temperature",
        HKQuantityTypeIdentifierBasalEnergyBurned         : "basal_energy_burned",
        HKQuantityTypeIdentifierBloodAlcoholContent       : "blood_alcohol_content",
        HKQuantityTypeIdentifierBloodGlucose              : "blood_glucose",
        HKQuantityTypeIdentifierBloodPressureDiastolic    : "diastolic_blood_pressure",
        HKQuantityTypeIdentifierBloodPressureSystolic     : "systolic_blood_pressure",
        HKQuantityTypeIdentifierBodyFatPercentage         : "body_fat_percentage",
        HKQuantityTypeIdentifierBodyMass                  : "body_weight",
        HKQuantityTypeIdentifierBodyMassIndex             : "body_mass_index",
        HKQuantityTypeIdentifierBodyTemperature           : "body_temperature",
        HKQuantityTypeIdentifierDietaryBiotin             : "dietary_biotin",
        HKQuantityTypeIdentifierDietaryCalcium            : "dietary_calcium",
        HKQuantityTypeIdentifierDietaryCaffeine           : "dietary_caffeine",
        HKQuantityTypeIdentifierDietaryCarbohydrates      : "dietary_carbohydrates",
        HKQuantityTypeIdentifierDietaryCholesterol        : "dietary_cholesterol",
        HKQuantityTypeIdentifierDietaryChloride           : "dietary_chloride",
        HKQuantityTypeIdentifierDietaryChromium           : "dietary_chromium",
        HKQuantityTypeIdentifierDietaryCopper             : "dietary_copper",
        HKQuantityTypeIdentifierDietaryEnergyConsumed     : "dietary_energy_consumed",
        HKQuantityTypeIdentifierDietaryFatMonounsaturated : "dietary_fat_monounsaturated",
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated : "dietary_fat_polyunsaturated",
        HKQuantityTypeIdentifierDietaryFatSaturated       : "dietary_fat_saturated",
        HKQuantityTypeIdentifierDietaryFatTotal           : "dietary_fat_total",
        HKQuantityTypeIdentifierDietaryFiber              : "dietary_fiber",
        HKQuantityTypeIdentifierDietaryFolate             : "dietary_folate",
        HKQuantityTypeIdentifierDietaryIodine             : "dietary_iodine",
        HKQuantityTypeIdentifierDietaryIron               : "dietary_iron",
        HKQuantityTypeIdentifierDietaryMagnesium          : "dietary_magnesium",
        HKQuantityTypeIdentifierDietaryManganese          : "dietary_manganese",
        HKQuantityTypeIdentifierDietaryMolybdenum         : "dietary_molybdenum",
        HKQuantityTypeIdentifierDietaryNiacin             : "dietary_niacin",
        HKQuantityTypeIdentifierDietaryPantothenicAcid    : "dietary_pantothenic_acid",
        HKQuantityTypeIdentifierDietaryPhosphorus         : "dietary_phosphorus",
        HKQuantityTypeIdentifierDietaryPotassium          : "dietary_potassium",
        HKQuantityTypeIdentifierDietaryProtein            : "dietary_protein",
        HKQuantityTypeIdentifierDietaryRiboflavin         : "dietary_riboflavin",
        HKQuantityTypeIdentifierDietarySelenium           : "dietary_selenium",
        HKQuantityTypeIdentifierDietarySodium             : "dietary_sodium",
        HKQuantityTypeIdentifierDietarySugar              : "dietary_sugar",
        HKQuantityTypeIdentifierDietaryThiamin            : "dietary_thiamin",
        HKQuantityTypeIdentifierDietaryVitaminA           : "dietary_vitaminA",
        HKQuantityTypeIdentifierDietaryVitaminB12         : "dietary_vitaminB12",
        HKQuantityTypeIdentifierDietaryVitaminB6          : "dietary_vitaminB6",
        HKQuantityTypeIdentifierDietaryVitaminC           : "dietary_vitaminC",
        HKQuantityTypeIdentifierDietaryVitaminD           : "dietary_vitaminD",
        HKQuantityTypeIdentifierDietaryVitaminE           : "dietary_vitaminE",
        HKQuantityTypeIdentifierDietaryVitaminK           : "dietary_vitaminK",
        HKQuantityTypeIdentifierDietaryWater              : "dietary_water",
        HKQuantityTypeIdentifierDietaryZinc               : "dietary_zinc",
        HKQuantityTypeIdentifierElectrodermalActivity     : "electrodermal_activity",
        HKQuantityTypeIdentifierForcedExpiratoryVolume1   : "forced_expiratory_volume_one_second",
        HKQuantityTypeIdentifierForcedVitalCapacity       : "forced_vital_capacity",
        HKQuantityTypeIdentifierHeartRate                 : "heart_rate",
        HKQuantityTypeIdentifierHeight                    : "body_height",
        HKQuantityTypeIdentifierInhalerUsage              : "inhaler_usage",
        HKQuantityTypeIdentifierLeanBodyMass              : "lean_body_mass",
        HKQuantityTypeIdentifierNikeFuel                  : "nike_fuel",
        HKQuantityTypeIdentifierNumberOfTimesFallen       : "number_of_times_fallen",
        HKQuantityTypeIdentifierOxygenSaturation          : "blood_oxygen_saturation",
        HKQuantityTypeIdentifierPeakExpiratoryFlowRate    : "peak_expiratory_flow",
        HKQuantityTypeIdentifierPeripheralPerfusionIndex  : "peripheral_perfusion_index",
        HKQuantityTypeIdentifierRespiratoryRate           : "respiratory_rate",
        HKQuantityTypeIdentifierUVExposure                : "uv_exposure"
    ]

    public let mcdbToHK : [String: String] = [
        "apple_stand_hour"                    : HKCategoryTypeIdentifierAppleStandHour            ,
        "sleep_duration"                      : HKCategoryTypeIdentifierSleepAnalysis             ,
        "active_energy_burned"                : HKQuantityTypeIdentifierActiveEnergyBurned        ,
        "basal_body_temperature"              : HKQuantityTypeIdentifierBasalBodyTemperature      ,
        "basal_energy_burned"                 : HKQuantityTypeIdentifierBasalEnergyBurned         ,
        "blood_alcohol_content"               : HKQuantityTypeIdentifierBloodAlcoholContent       ,
        "blood_glucose"                       : HKQuantityTypeIdentifierBloodGlucose              ,
        "diastolic_blood_pressure"            : HKQuantityTypeIdentifierBloodPressureDiastolic    ,
        "systolic_blood_pressure"             : HKQuantityTypeIdentifierBloodPressureSystolic     ,
        "body_fat_percentage"                 : HKQuantityTypeIdentifierBodyFatPercentage         ,
        "body_weight"                         : HKQuantityTypeIdentifierBodyMass                  ,
        "body_mass_index"                     : HKQuantityTypeIdentifierBodyMassIndex             ,
        "body_temperature"                    : HKQuantityTypeIdentifierBodyTemperature           ,
        "dietary_biotin"                      : HKQuantityTypeIdentifierDietaryBiotin             ,
        "dietary_calcium"                     : HKQuantityTypeIdentifierDietaryCalcium            ,
        "dietary_caffeine"                    : HKQuantityTypeIdentifierDietaryCaffeine           ,
        "dietary_carbohydrates"               : HKQuantityTypeIdentifierDietaryCarbohydrates      ,
        "dietary_cholesterol"                 : HKQuantityTypeIdentifierDietaryCholesterol        ,
        "dietary_chloride"                    : HKQuantityTypeIdentifierDietaryChloride           ,
        "dietary_chromium"                    : HKQuantityTypeIdentifierDietaryChromium           ,
        "dietary_copper"                      : HKQuantityTypeIdentifierDietaryCopper             ,
        "dietary_energy_consumed"             : HKQuantityTypeIdentifierDietaryEnergyConsumed     ,
        "dietary_fat_monounsaturated"         : HKQuantityTypeIdentifierDietaryFatMonounsaturated ,
        "dietary_fat_polyunsaturated"         : HKQuantityTypeIdentifierDietaryFatPolyunsaturated ,
        "dietary_fat_saturated"               : HKQuantityTypeIdentifierDietaryFatSaturated       ,
        "dietary_fat_total"                   : HKQuantityTypeIdentifierDietaryFatTotal           ,
        "dietary_fiber"                       : HKQuantityTypeIdentifierDietaryFiber              ,
        "dietary_folate"                      : HKQuantityTypeIdentifierDietaryFolate             ,
        "dietary_iodine"                      : HKQuantityTypeIdentifierDietaryIodine             ,
        "dietary_iron"                        : HKQuantityTypeIdentifierDietaryIron               ,
        "dietary_magnesium"                   : HKQuantityTypeIdentifierDietaryMagnesium          ,
        "dietary_manganese"                   : HKQuantityTypeIdentifierDietaryManganese          ,
        "dietary_molybdenum"                  : HKQuantityTypeIdentifierDietaryMolybdenum         ,
        "dietary_niacin"                      : HKQuantityTypeIdentifierDietaryNiacin             ,
        "dietary_pantothenic_acid"            : HKQuantityTypeIdentifierDietaryPantothenicAcid    ,
        "dietary_phosphorus"                  : HKQuantityTypeIdentifierDietaryPhosphorus         ,
        "dietary_potassium"                   : HKQuantityTypeIdentifierDietaryPotassium          ,
        "dietary_protein"                     : HKQuantityTypeIdentifierDietaryProtein            ,
        "dietary_riboflavin"                  : HKQuantityTypeIdentifierDietaryRiboflavin         ,
        "dietary_selenium"                    : HKQuantityTypeIdentifierDietarySelenium           ,
        "dietary_sodium"                      : HKQuantityTypeIdentifierDietarySodium             ,
        "dietary_sugar"                       : HKQuantityTypeIdentifierDietarySugar              ,
        "dietary_thiamin"                     : HKQuantityTypeIdentifierDietaryThiamin            ,
        "dietary_vitaminA"                    : HKQuantityTypeIdentifierDietaryVitaminA           ,
        "dietary_vitaminB12"                  : HKQuantityTypeIdentifierDietaryVitaminB12         ,
        "dietary_vitaminB6"                   : HKQuantityTypeIdentifierDietaryVitaminB6          ,
        "dietary_vitaminC"                    : HKQuantityTypeIdentifierDietaryVitaminC           ,
        "dietary_vitaminD"                    : HKQuantityTypeIdentifierDietaryVitaminD           ,
        "dietary_vitaminE"                    : HKQuantityTypeIdentifierDietaryVitaminE           ,
        "dietary_vitaminK"                    : HKQuantityTypeIdentifierDietaryVitaminK           ,
        "dietary_water"                       : HKQuantityTypeIdentifierDietaryWater              ,
        "dietary_zinc"                        : HKQuantityTypeIdentifierDietaryZinc               ,
        "electrodermal_activity"              : HKQuantityTypeIdentifierElectrodermalActivity     ,
        "forced_expiratory_volume_one_second" : HKQuantityTypeIdentifierForcedExpiratoryVolume1   ,
        "forced_vital_capacity"               : HKQuantityTypeIdentifierForcedVitalCapacity       ,
        "heart_rate"                          : HKQuantityTypeIdentifierHeartRate                 ,
        "body_height"                         : HKQuantityTypeIdentifierHeight                    ,
        "inhaler_usage"                       : HKQuantityTypeIdentifierInhalerUsage              ,
        "lean_body_mass"                      : HKQuantityTypeIdentifierLeanBodyMass              ,
        "nike_fuel"                           : HKQuantityTypeIdentifierNikeFuel                  ,
        "number_of_times_fallen"              : HKQuantityTypeIdentifierNumberOfTimesFallen       ,
        "blood_oxygen_saturation"             : HKQuantityTypeIdentifierOxygenSaturation          ,
        "peak_expiratory_flow"                : HKQuantityTypeIdentifierPeakExpiratoryFlowRate    ,
        "peripheral_perfusion_index"          : HKQuantityTypeIdentifierPeripheralPerfusionIndex  ,
        "respiratory_rate"                    : HKQuantityTypeIdentifierRespiratoryRate           ,
        "uv_exposure"                         : HKQuantityTypeIdentifierUVExposure
    ]
}

/*
 * HealthKit predicates
 */

// Helper predicates
public let mealsPredicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)

public let exerciseConjuncts = [
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.AmericanFootball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Archery),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.AustralianFootball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Badminton),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Baseball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Basketball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Bowling),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Boxing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Climbing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Cricket),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.CrossTraining),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Curling),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Cycling),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Dance),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.DanceInspiredTraining),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Elliptical),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.EquestrianSports),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Fencing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Fishing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.FunctionalStrengthTraining),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Golf),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Gymnastics),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Handball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Hiking),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Hockey),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Hunting),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Lacrosse),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.MartialArts),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.MindAndBody),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.MixedMetabolicCardioTraining),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.PaddleSports),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Play),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Racquetball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Rowing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Rugby),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Running),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Sailing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.SkatingSports),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.SnowSports),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Soccer),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Softball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Squash),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.StairClimbing),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.SurfingSports),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Swimming),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.TableTennis),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Tennis),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.TrackAndField),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.TraditionalStrengthTraining),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Volleyball),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Walking),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.WaterFitness),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.WaterPolo),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.WaterSports),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Wrestling),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Yoga),
    HKQuery.predicateForWorkoutsWithWorkoutActivityType(.Other),
]

public let exercisePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: exerciseConjuncts)


public let asleepPredicate = HKQuery.predicateForCategorySamplesWithOperatorType(.EqualToPredicateOperatorType, value: HKCategoryValueSleepAnalysis.Asleep.rawValue)
