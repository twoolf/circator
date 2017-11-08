//
//  Constants.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MCCircadianQueries

//let log = RemoteLogManager.sharedManager.log

/**
 This maintains the constants and strings needed for Metabolic Compass. We tie this into the options and recommendations settings in the control panel.

 */

// Shared notifications.
public let MCRemoteErrorNotification = "MCRemoteError"
public let MEMDidUpdateCircadianEvents = "MEMDidUpdateCircadianEvents"
public let SyncDidUpdateCircadianEvents = "SyncDidUpdateCircadianEvents"


public enum FieldDataType: Int {
    case String = 0, Int, Decimal
}

public struct ProfileFieldData {
    public let fieldName: String!
    public let profileFieldName: String!
    public let type: FieldDataType!
    public let unitsTitle: String?
}

private let unitsTitleBMI = "kg/m2"
private let unitsTitleBP = "mmHg"
private let unitsTitleHours = "hrs"
private let unitsTitleKiloCalories = "kcal"
private let unitsTitleSteps = "steps"
private let unitsTitleBPM = "bpm"
private let unitsTitleGrams = "g"
private let unitsTitleMG = "mg"
private let unitsTitleML = "ml"

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
    public let optionalRange      : Range = 14..<29
    public let updateableRange    : Range = 4..<29

    public let profileFields : [String]! = [
        "Email",
        "Password",
        "First name",
        "Last name",
        "Sex",
        "Age",
        "Weight",
        "Height",
        "Usual Sleep",
        "Estimated BMI",
        "Resting Heart Rate",
        "Systolic BP",
        "Diastolic BP",
        "Step Count",
        "Energy Expenditure",
        "Daily Sunlight",
        "Daily Calorie",
        "Daily Protein",
        "Daily Carbohydrates",
        "Daily Sugar",
        "Daily Fiber",
        "Daily Total Fat",
        "Saturated Fat",
        "Monounsaturated Fat",
        "Polyunsaturated Fat",
        "Daily Cholesterol",
        "Daily Salt",
        "Daily Caffeine",
        "Daily Water"]

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
        "First name"               : "first_name",
        "Last name"                : "last_name",
        "Sex"                      : "sex",
        "Age"                      : "age",
        "Weight"                   : "body_weight",
        "Height"                   : "body_height",
        "Usual Sleep"              : "sleep_duration",
        "Estimated BMI"            : "body_mass_index",
        "Resting Heart Rate"       : "heart_rate",
        "Systolic BP"              : "systolic_blood_pressure",
        "Diastolic BP"             : "diastolic_blood_pressure",
        "Step Count"               : "step_count",
        "Energy Expenditure"       : "active_energy_burned",
        "Daily Sunlight"           : "uv_exposure",
        "Daily Calories"           : "dietary_energy_consumed",
        "Daily Caffeine"           : "dietary_caffeine",
        "Daily Carbohydrates"      : "dietary_carbohydrates",
        "Daily Cholesterol"        : "dietary_cholesterol",
        "Daily Total Fat"          : "dietary_fat_total",
        "Saturated Fat"            : "dietary_fat_saturated",
        "Monounsaturated Fat"      : "dietary_fat_monounsaturated",
        "Polyunsaturated Fat"      : "dietary_fat_polyunsaturated",
        "Daily Fiber"              : "dietary_fiber",
        "Daily Protein"            : "dietary_protein",
        "Daily Salt"               : "dietary_sodium",
        "Daily Sugar"              : "dietary_sugar",
        "Daily Water"              : "dietary_water"
    ]

    public var updateableMapping : [String: String]! {
        return Dictionary(pairs: profileFields[updateableRange].map { k in return (k, profileMapping[k]!) })
    }

    public static func keyForItemName(itemName: String) -> String?{
        return sharedInstance.profileMapping[itemName]
    }

    public var fields: [ProfileFieldData] = {
        var fields = [ProfileFieldData]()

        fields.append(ProfileFieldData(fieldName: "First name",               profileFieldName: "first_name",                  type: .String, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Last name",                profileFieldName: "last_name",                   type: .String, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Sex",                      profileFieldName: "sex",                         type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Age",                      profileFieldName: "age",                         type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Weight",                   profileFieldName: "body_weight",                 type: .Int, unitsTitle: nil))
        fields.append(ProfileFieldData(fieldName: "Height",                   profileFieldName: "body_height",                 type: .Int, unitsTitle: nil))

        fields.append(ProfileFieldData(fieldName: "Usual Sleep",              profileFieldName: "sleep_duration",              type: .Int, unitsTitle: unitsTitleHours))
        fields.append(ProfileFieldData(fieldName: "Estimated BMI",            profileFieldName: "body_mass_index",             type: .Int, unitsTitle: unitsTitleBMI))
        fields.append(ProfileFieldData(fieldName: "Resting Heart Rate",       profileFieldName: "heart_rate",                  type: .Int, unitsTitle: unitsTitleBPM))
        fields.append(ProfileFieldData(fieldName: "Systolic BP",              profileFieldName: "systolic_blood_pressure",     type: .Int, unitsTitle: unitsTitleBP))
        fields.append(ProfileFieldData(fieldName: "Diastolic BP",             profileFieldName: "diastolic_blood_pressure",    type: .Int, unitsTitle: unitsTitleBP))
        fields.append(ProfileFieldData(fieldName: "Step Count",               profileFieldName: "step_count",                  type: .Int, unitsTitle: unitsTitleSteps))

        fields.append(ProfileFieldData(fieldName: "Energy Expenditure",       profileFieldName: "active_energy_burned",        type: .Int, unitsTitle: unitsTitleKiloCalories))
        fields.append(ProfileFieldData(fieldName: "Daily Sunlight",           profileFieldName: "uv_exposure",                 type: .Int, unitsTitle: unitsTitleHours))
        fields.append(ProfileFieldData(fieldName: "Daily Calories",           profileFieldName: "dietary_energy_consumed",     type: .Decimal, unitsTitle: unitsTitleKiloCalories))
        fields.append(ProfileFieldData(fieldName: "Daily Protein",            profileFieldName: "dietary_protein",             type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Daily Carbohydrates",      profileFieldName: "dietary_carbohydrates",       type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Daily Sugar",              profileFieldName: "dietary_sugar",               type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Daily Fiber",              profileFieldName: "dietary_fiber",               type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Daily Total Fat",          profileFieldName: "dietary_fat_total",           type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Saturated Fat",            profileFieldName: "dietary_fat_saturated",       type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Monounsaturated Fat",      profileFieldName: "dietary_fat_monounsaturated", type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Polyunsaturated Fat",      profileFieldName: "dietary_fat_polyunsaturated", type: .Decimal, unitsTitle: unitsTitleGrams))
        fields.append(ProfileFieldData(fieldName: "Daily Cholesterol",        profileFieldName: "dietary_cholesterol",         type: .Decimal, unitsTitle: unitsTitleMG))
        fields.append(ProfileFieldData(fieldName: "Daily Salt",               profileFieldName: "dietary_sodium",              type: .Decimal, unitsTitle: unitsTitleMG))
        fields.append(ProfileFieldData(fieldName: "Daily Caffeine",           profileFieldName: "dietary_caffeine",            type: .Decimal, unitsTitle: unitsTitleMG))
        fields.append(ProfileFieldData(fieldName: "Daily Water",              profileFieldName: "dietary_water",               type: .Decimal, unitsTitle: unitsTitleML))

        return fields
    }()

    public var customFieldUnits: [String: HKUnit] = [
        "uv_exposure": HKUnit.count()
    ]

    public var profileUnitsMapping: [String: HKUnit] = [
        unitsTitleBMI          : HKUnit.count(),
        unitsTitleBP           : HKUnit.millimeterOfMercury(),
        unitsTitleHours        : HKUnit.hour(),
        unitsTitleKiloCalories : HKUnit.kilocalorie(),
        unitsTitleSteps        : HKUnit.count(),
        unitsTitleBPM          : HKUnit.count().unitDivided(by: HKUnit.minute()),
        unitsTitleGrams        : HKUnit.gram(),
        unitsTitleMG           : HKUnit.gramUnit(with: .milli),
        unitsTitleML           : HKUnit.literUnit(with: .milli)
    ]
}


/*
 * HealthKit predicates
 */

// Helper predicates
public let mealsPredicate = HKQuery.predicateForWorkouts(with: HKWorkoutActivityType.preparationAndRecovery)

public let exerciseConjuncts = [
    HKQuery.predicateForWorkouts(with: .americanFootball),
    HKQuery.predicateForWorkouts(with: .archery),
    HKQuery.predicateForWorkouts(with: .australianFootball),
    HKQuery.predicateForWorkouts(with: .badminton),
    HKQuery.predicateForWorkouts(with: .baseball),
    HKQuery.predicateForWorkouts(with: .basketball),
    HKQuery.predicateForWorkouts(with: .bowling),
    HKQuery.predicateForWorkouts(with: .boxing),
    HKQuery.predicateForWorkouts(with: .climbing),
    HKQuery.predicateForWorkouts(with: .cricket),
    HKQuery.predicateForWorkouts(with: .crossTraining),
    HKQuery.predicateForWorkouts(with: .curling),
    HKQuery.predicateForWorkouts(with: .cycling),
    HKQuery.predicateForWorkouts(with: .dance),
    HKQuery.predicateForWorkouts(with: .danceInspiredTraining),
    HKQuery.predicateForWorkouts(with: .elliptical),
    HKQuery.predicateForWorkouts(with: .equestrianSports),
    HKQuery.predicateForWorkouts(with: .fencing),
    HKQuery.predicateForWorkouts(with: .fishing),
    HKQuery.predicateForWorkouts(with: .functionalStrengthTraining),
    HKQuery.predicateForWorkouts(with: .golf),
    HKQuery.predicateForWorkouts(with: .gymnastics),
    HKQuery.predicateForWorkouts(with: .handball),
    HKQuery.predicateForWorkouts(with: .hiking),
    HKQuery.predicateForWorkouts(with: .hockey),
    HKQuery.predicateForWorkouts(with: .hunting),
    HKQuery.predicateForWorkouts(with: .lacrosse),
    HKQuery.predicateForWorkouts(with: .martialArts),
    HKQuery.predicateForWorkouts(with: .mindAndBody),
    HKQuery.predicateForWorkouts(with: .mixedMetabolicCardioTraining),
    HKQuery.predicateForWorkouts(with: .paddleSports),
    HKQuery.predicateForWorkouts(with: .play),
    HKQuery.predicateForWorkouts(with: .racquetball),
    HKQuery.predicateForWorkouts(with: .rowing),
    HKQuery.predicateForWorkouts(with: .rugby),
    HKQuery.predicateForWorkouts(with: .running),
    HKQuery.predicateForWorkouts(with: .sailing),
    HKQuery.predicateForWorkouts(with: .skatingSports),
    HKQuery.predicateForWorkouts(with: .snowSports),
    HKQuery.predicateForWorkouts(with: .soccer),
    HKQuery.predicateForWorkouts(with: .softball),
    HKQuery.predicateForWorkouts(with: .squash),
    HKQuery.predicateForWorkouts(with: .stairClimbing),
    HKQuery.predicateForWorkouts(with: .surfingSports),
    HKQuery.predicateForWorkouts(with: .swimming),
    HKQuery.predicateForWorkouts(with: .tableTennis),
    HKQuery.predicateForWorkouts(with: .tennis),
    HKQuery.predicateForWorkouts(with: .trackAndField),
    HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining),
    HKQuery.predicateForWorkouts(with: .volleyball),
    HKQuery.predicateForWorkouts(with: .walking),
    HKQuery.predicateForWorkouts(with: .waterFitness),
    HKQuery.predicateForWorkouts(with: .waterPolo),
    HKQuery.predicateForWorkouts(with: .waterSports),
    HKQuery.predicateForWorkouts(with: .wrestling),
    HKQuery.predicateForWorkouts(with: .yoga),
    HKQuery.predicateForWorkouts(with: .other),
]

public let exercisePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: exerciseConjuncts)


public let asleepPredicate = HKQuery.predicateForCategorySamples(with: .equalTo, value: HKCategoryValueSleepAnalysis.asleep.rawValue)

