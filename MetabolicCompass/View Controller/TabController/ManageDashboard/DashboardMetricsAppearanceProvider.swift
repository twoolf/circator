//
//  DashboardMetricsAppearanceProvider.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

class DashboardMetricsAppearanceProvider: NSObject {
    
    func attributedText(text: String, forSampleType sampleType: String, active: Bool) -> NSAttributedString
    {
        return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: self.colorForSampleType(sampleType, active: active)])
    }
    
    func colorForSampleType(sampleType: String, active: Bool) -> UIColor
    {
        return self.getColorForSampleType(sampleType, active: active) ?? UIColor.whiteColor()
    }
    
    private func getColorForSampleType(sampleType: String, active: Bool) -> UIColor?
    {
        if (!active) {
            return UIColor.lightGrayColor()
        }
        
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return UIColor.colorWithHexString("#388CFB")
        case HKQuantityTypeIdentifierHeartRate:
            return UIColor.colorWithHexString("#E2472C")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return UIColor.colorWithHexString("#B68F14")
        case HKQuantityTypeIdentifierBodyMassIndex:
            return UIColor.colorWithHexString("#A57B55")
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return UIColor.colorWithHexString("#8627B5")
        case HKQuantityTypeIdentifierDietarySugar:
            return UIColor.colorWithHexString("#8627B5")
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return UIColor.colorWithHexString("#8627B5")
        case HKQuantityTypeIdentifierDietaryProtein:
            return UIColor.colorWithHexString("#E64C35")
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return UIColor.colorWithHexString("#E64C35")
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return UIColor.colorWithHexString("#E24739")
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return UIColor.colorWithHexString("#A57B55")
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return UIColor.colorWithHexString("#A57B55")
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return UIColor.colorWithHexString("#A57B55")
        case HKQuantityTypeIdentifierDietaryWater:
            return UIColor.colorWithHexString("#BA1075")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return UIColor.colorWithHexString("#388CFB")
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return UIColor.colorWithHexString("#AA0066")
            
        case HKQuantityTypeIdentifierStepCount:
            return UIColor.colorWithHexString("#138F16")
            
        default:
            return UIColor.whiteColor()
        }
    }
    
    private func stringForSampleType(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "user weight")
        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heart rate", comment: "Heartrate")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "Sleep")
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("BMI", comment: "Body Mass Index")
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSLocalizedString("Caffeine", comment: "Caffeine")
        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Sugar", comment: "Sugar")
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Cholesterol", comment: "Cholesterol")
        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Protein", comment: "Protein")
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Fat", comment: "Fat")
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Carbohydrates", comment: "Carbohydrates")
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Polyunsaturated fat", comment: "Polyunsaturated Fat")
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Saturated fat", comment: "Saturated Fat")
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Monosaturated fat", comment: "Monosaturated Fat")
        case HKQuantityTypeIdentifierDietaryWater:
            return NSLocalizedString("Water", comment: "Water")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Dietary energy", comment: "Dietary Energy")
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "Blood pressure")
            
        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Step count", comment: "Step count")
            
        default:
            return ""
        }
    }
    
    func titleForSampleType(sampleType: String, active: Bool) -> NSAttributedString
    {
        return self.attributedText(self.stringForSampleType(sampleType), forSampleType: sampleType, active: active)
    }
    
    private func imageNameWithState(baseName: String, active: Bool) -> String
    {
        return baseName + (active ? "-normal": "-unactive");
    }
    
    private func imageNameForSampleType(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return "icon-weight"
        case HKQuantityTypeIdentifierHeartRate:
            return "icon-heart-rate"
        case HKCategoryTypeIdentifierSleepAnalysis:
            return "icon-sleep"
        case HKQuantityTypeIdentifierBodyMassIndex:
            return "icon-bmi"
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return "icon-caffeine"
        case HKQuantityTypeIdentifierDietarySugar:
            return "icon-sugar"
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return "icon-cholesterol"
        case HKQuantityTypeIdentifierDietaryProtein:
            return "icon-protein"
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return "icon-fat"
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return "icon-carbohydrates"
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return "icon-polyunsaturated-fat"
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return "icon-saturated-fat"
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return "icon-monosaturated-fat"
        case HKQuantityTypeIdentifierDietaryWater:
            return "icon-water"
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return "icon-calories"
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return "icon-blood"
            
        case HKQuantityTypeIdentifierStepCount:
            return "icon-steps"
            
        default:
            return ""
        }
    }

    func imageForSampleType(sampleType: String, active: Bool) -> UIImage?
    {
        return UIImage(named: self.imageNameWithState(self.imageNameForSampleType(sampleType), active: active))
    }
    
}
