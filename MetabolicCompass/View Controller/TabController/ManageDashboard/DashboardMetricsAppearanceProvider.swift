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
    
    func attributedText(text: String, forSampleType sampleType: String) -> NSAttributedString
    {
        return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: self.colorForSampleType(sampleType)])
    }
    
    func colorForSampleType(sampleType: String) -> UIColor
    {
        switch sampleType {
//        case HKQuantityTypeIdentifierBodyMass:
//            return
//        case HKQuantityTypeIdentifierHeartRate:
//            return ""
//        case HKCategoryTypeIdentifierSleepAnalysis:
//            return ""
//        case HKQuantityTypeIdentifierBodyMassIndex:
//            return ""
//            
//        case HKQuantityTypeIdentifierDietaryCaffeine:
//            return ""
//        case HKQuantityTypeIdentifierDietarySugar:
//            return ""
//        case HKQuantityTypeIdentifierDietaryCholesterol:
//            return ""
//        case HKQuantityTypeIdentifierDietaryProtein:
//            return ""
//        case HKQuantityTypeIdentifierDietaryFatTotal:
//            return ""
//        case HKQuantityTypeIdentifierDietaryCarbohydrates:
//            return ""
//        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
//            return ""
//        case HKQuantityTypeIdentifierDietaryFatSaturated:
//            return ""
//        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
//            return ""
//        case HKQuantityTypeIdentifierDietaryWater:
//            return ""
//        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
//            return ""
//            
//        case HKCorrelationTypeIdentifierBloodPressure:
//            return ""
//            
//        case HKQuantityTypeIdentifierStepCount:
//            return ""
            
        default:
            return UIColor.whiteColor()
        }
    }
    
    // TODO: move everything into plist
    
    func titleForSampleType(sampleType: String) -> NSAttributedString
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return self.attributedText(NSLocalizedString("Weight", comment: "user weight"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierHeartRate:
            return self.attributedText(NSLocalizedString("Heart rate", comment: "Heartrate"), forSampleType: sampleType)
        case HKCategoryTypeIdentifierSleepAnalysis:
            return self.attributedText(NSLocalizedString("Sleep", comment: "Sleep"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierBodyMassIndex:
            return self.attributedText(NSLocalizedString("BMI", comment: "Body Mass Index"), forSampleType: sampleType)
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return self.attributedText(NSLocalizedString("Caffeine", comment: "Caffeine"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietarySugar:
            return self.attributedText(NSLocalizedString("Sugar", comment: "Sugar"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return self.attributedText(NSLocalizedString("Cholesterol", comment: "Cholesterol"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryProtein:
            return self.attributedText(NSLocalizedString("Protein", comment: "Protein"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return self.attributedText(NSLocalizedString("Fat", comment: "Fat"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return self.attributedText(NSLocalizedString("Carbohydrates", comment: "Carbohydrates"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return self.attributedText(NSLocalizedString("Polyunsaturated fat", comment: "Polyunsaturated Fat"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return self.attributedText(NSLocalizedString("Saturated fat", comment: "Saturated Fat"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return self.attributedText(NSLocalizedString("Monosaturated fat", comment: "Monosaturated Fat"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryWater:
            return self.attributedText(NSLocalizedString("Water", comment: "Water"), forSampleType: sampleType)
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return self.attributedText(NSLocalizedString("Dietary energy", comment: "Dietary Energy"), forSampleType: sampleType)
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return self.attributedText(NSLocalizedString("Blood pressure", comment: "Blood pressure"), forSampleType: sampleType)
            
        case HKQuantityTypeIdentifierStepCount:
            return self.attributedText(NSLocalizedString("Step count", comment: "Step count"), forSampleType: sampleType)
            
        default:
            return NSAttributedString(string: "\(sampleType)")
        }
    }
    
    private func imageNameWithState(baseName: String, active: Bool) -> String
    {
        return baseName + (active ? "-normal": "-unactive");
    }

    func imageForSampleType(sampleType: String, active: Bool) -> UIImage?
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return UIImage(named: self.imageNameWithState("icon-weight", active: active))
        case HKQuantityTypeIdentifierHeartRate:
            return UIImage(named: self.imageNameWithState("icon-heart-rate", active: active))
        case HKCategoryTypeIdentifierSleepAnalysis:
            return UIImage(named: self.imageNameWithState("icon-sleep", active:  active))
        case HKQuantityTypeIdentifierBodyMassIndex:
            return UIImage(named: self.imageNameWithState("icon-bmi", active:  active))
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return UIImage(named: self.imageNameWithState("icon-caffeine", active: active))
        case HKQuantityTypeIdentifierDietarySugar:
            return UIImage(named: self.imageNameWithState("icon-sugar", active: active))
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return UIImage(named: self.imageNameWithState("icon-cholesterol", active: active))
        case HKQuantityTypeIdentifierDietaryProtein:
            return UIImage(named: self.imageNameWithState("icon-protein", active: active))
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return UIImage(named: self.imageNameWithState("icon-fat", active: active))
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return UIImage(named: self.imageNameWithState("icon-carbohydrates", active: active))
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return UIImage(named: self.imageNameWithState("icon-polyunsaturated-fat", active: active))
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return UIImage(named: self.imageNameWithState("icon-saturated-fat", active: active))
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return UIImage(named: self.imageNameWithState("icon-monosaturated-fat", active: active))
        case HKQuantityTypeIdentifierDietaryWater:
            return UIImage(named: self.imageNameWithState("icon-water", active: active))
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return UIImage(named: self.imageNameWithState("icon-calories", active: active))

        case HKCorrelationTypeIdentifierBloodPressure:
            return UIImage(named: self.imageNameWithState("icon-blood", active: active))
            
        case HKQuantityTypeIdentifierStepCount:
            return UIImage(named: self.imageNameWithState("icon-steps", active: active))
            
        default:
            return nil
        }
    }
    
}
