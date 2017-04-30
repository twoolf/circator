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
        return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: self.colorForSampleType(sampleType: sampleType, active: active)])
    }
    
    func colorForSampleType(sampleType: String, active: Bool) -> UIColor
    {
        return self.getColorForSampleType(sampleType: sampleType, active: active) ?? UIColor.white
    }
    
    enum SampleGroupColor: UInt32 {
        case sgBlue = 0x388CFB
        case sgRed = 0xE2472C
        case sgYelow = 0xB68F14
        case sgMagenta = 0x8627B5
    }
    
    
    private func getColorForSampleType(sampleType: String, active: Bool) -> UIColor?
    {
        if (!active) {
            return UIColor.lightGray
        }
        
        switch sampleType {
        case HKQuantityTypeIdentifier.bodyMass.rawValue,
             HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
             HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
            return UIColor.colorWithHexString(rgb: "#388CFB")
            
        case HKQuantityTypeIdentifier.heartRate.rawValue,
             HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
             HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return UIColor.colorWithHex(hex6: SampleGroupColor.sgRed.rawValue)
            
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
             HKQuantityTypeIdentifier.uvExposure.rawValue:
            return UIColor.colorWithHex(hex6: SampleGroupColor.sgYelow.rawValue)
        
        case HKQuantityTypeIdentifier.dietarySugar.rawValue,
             HKQuantityTypeIdentifier.dietarySodium.rawValue,
             HKQuantityTypeIdentifier.dietaryCholesterol.rawValue,
             HKQuantityTypeIdentifier.dietaryCaffeine.rawValue:
            return UIColor.colorWithHexString(rgb: "#8627B5")
        
        case HKQuantityTypeIdentifier.dietaryProtein.rawValue,
             HKQuantityTypeIdentifier.dietaryFatTotal.rawValue,
             HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue:
            return UIColor.colorWithHexString(rgb: "#138F16")
        
        case HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue,
             HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue,
             HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue,
             HKQuantityTypeIdentifier.dietaryFiber.rawValue:
            return UIColor.colorWithHexString(rgb: "#A57B55")
        
        case HKQuantityTypeIdentifier.dietaryWater.rawValue,
             HKCorrelationTypeIdentifier.bloodPressure.rawValue:
            return UIColor.colorWithHexString(rgb: "#BA1075")

        default:
            return UIColor.white
            
        }
    }
    
    func typeFromString(string:String) -> String {
        switch string {
        case NSLocalizedString("Weight", comment: "user weight"):
            return HKQuantityTypeIdentifier.bodyMass.rawValue
        case NSLocalizedString("Heart rate", comment: "Heartrate"):
            return HKQuantityTypeIdentifier.heartRate.rawValue
            
        case NSLocalizedString("Sleep", comment: "Sleep") :
            return HKCategoryTypeIdentifier.sleepAnalysis.rawValue
        case NSLocalizedString("BMI", comment: "Body Mass Index") :
            return HKQuantityTypeIdentifier.bodyMassIndex.rawValue
        case NSLocalizedString("Active Energy", comment: "energy burned") :
            return HKQuantityTypeIdentifier.activeEnergyBurned.rawValue
        case NSLocalizedString("Resting Energy", comment: "Basal Energy") :
            return HKQuantityTypeIdentifier.basalEnergyBurned.rawValue
        case NSLocalizedString("UV Exposure", comment: "UV Exposure") :
            return HKQuantityTypeIdentifier.uvExposure.rawValue
        case NSLocalizedString("Caffeine", comment: "Caffeine") :
            return HKQuantityTypeIdentifier.dietaryCaffeine.rawValue
        case NSLocalizedString("Sugar", comment: "Sugar") :
            return HKQuantityTypeIdentifier.dietarySugar.rawValue
        case NSLocalizedString("Cholesterol", comment: "Cholesterol") :
            return HKQuantityTypeIdentifier.dietaryCholesterol.rawValue
        case NSLocalizedString("Salt", comment: "Sodium") :
            return HKQuantityTypeIdentifier.dietarySodium.rawValue
        case NSLocalizedString("Protein", comment: "Protein") :
            return HKQuantityTypeIdentifier.dietaryProtein.rawValue
        case NSLocalizedString("Fiber", comment: "Fiber") :
            return HKQuantityTypeIdentifier.dietaryFiber.rawValue
        case NSLocalizedString("Fat", comment: "Fat") :
            return HKQuantityTypeIdentifier.dietaryFatTotal.rawValue
        case NSLocalizedString("Carbohydrates", comment: "Carbohydrates") :
            return HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue
        case NSLocalizedString("Polyunsaturated fat", comment: "Polyunsaturated Fat") :
            return HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue
        case NSLocalizedString("Saturated fat", comment: "Saturated Fat") :
            return HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue
        case NSLocalizedString("Monosaturated fat", comment: "Monosaturated Fat") :
            return HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue
        case NSLocalizedString("Water", comment: "Water") :
            return HKQuantityTypeIdentifier.dietaryWater.rawValue
        case NSLocalizedString("Dietary energy", comment: "Dietary Energy") :
            return HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue
        case NSLocalizedString("Blood pressure", comment: "Blood pressure") :
            return HKCorrelationTypeIdentifier.bloodPressure.rawValue
        case NSLocalizedString("Step count", comment: "Step count") :
            return HKQuantityTypeIdentifier.stepCount.rawValue
        case NSLocalizedString("UV Exposure", comment: "UV Exposure") :
            return HKQuantityTypeIdentifier.uvExposure.rawValue
        case NSLocalizedString("Salt", comment: "Salt") :
            return HKQuantityTypeIdentifier.dietarySodium.rawValue
        case NSLocalizedString("Active Energy Burned", comment: " Active Energy Burned") :
            return HKQuantityTypeIdentifier.activeEnergyBurned.rawValue
        default:
            return ""
        }
    }
    
    func stringForSampleType(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return NSLocalizedString("Weight", comment: "user weight")
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return NSLocalizedString("Heart rate", comment: "Heartrate")
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return NSLocalizedString("Sleep", comment: "Sleep")
        case HKQuantityTypeIdentifier.bodyMassIndex.rawValue:
            return NSLocalizedString("BMI", comment: "Body Mass Index")
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return NSLocalizedString("Active Energy", comment: "energy burned")
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            return NSLocalizedString("Resting Energy", comment: "Basal Energy")
        case HKQuantityTypeIdentifier.uvExposure.rawValue:
            return NSLocalizedString("UV Exposure", comment: "UV Exposure")
        case HKQuantityTypeIdentifier.dietaryCaffeine.rawValue:
            return NSLocalizedString("Caffeine", comment: "Caffeine")
        case HKQuantityTypeIdentifier.dietarySugar.rawValue:
            return NSLocalizedString("Sugar", comment: "Sugar")
        case HKQuantityTypeIdentifier.dietaryCholesterol.rawValue:
            return NSLocalizedString("Cholesterol", comment: "Cholesterol")
        case HKQuantityTypeIdentifier.dietarySodium.rawValue:
            return NSLocalizedString("Salt", comment: "Sodium")
        case HKQuantityTypeIdentifier.dietaryProtein.rawValue:
            return NSLocalizedString("Protein", comment: "Protein")
        case HKQuantityTypeIdentifier.dietaryFiber.rawValue:
            return NSLocalizedString("Fiber", comment: "Fiber")
        case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue:
            return NSLocalizedString("Fat", comment: "Fat")
        case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue:
            return NSLocalizedString("Carbohydrates", comment: "Carbohydrates")
        case HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue:
            return NSLocalizedString("Polyunsaturated fat", comment: "Polyunsaturated Fat")
        case HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue:
            return NSLocalizedString("Saturated fat", comment: "Saturated Fat")
        case HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue:
            return NSLocalizedString("Monosaturated fat", comment: "Monosaturated Fat")
        case HKQuantityTypeIdentifier.dietaryWater.rawValue:
            return NSLocalizedString("Water", comment: "Water")
        case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
            return NSLocalizedString("Dietary energy", comment: "Dietary Energy")
        case HKCorrelationTypeIdentifier.bloodPressure.rawValue:
            return NSLocalizedString("Blood pressure", comment: "Blood pressure")
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return NSLocalizedString("Step count", comment: "Step count")
        case HKQuantityTypeIdentifier.uvExposure.rawValue:
            return NSLocalizedString("UV Exposure", comment: "UV Exposure")
        case HKQuantityTypeIdentifier.dietarySodium.rawValue:
            return NSLocalizedString("Salt", comment: "Salt")
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return NSLocalizedString("Active Energy Burned", comment: " Active Energy Burned")
        default:
            return ""
        }
    }
    
    func stringForSampleTypeOfCorrelate(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return NSLocalizedString("Weight", comment: "user weight")
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return NSLocalizedString("Heart rate", comment: "Heartrate")
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return NSLocalizedString("Sleep", comment: "Sleep")
        case HKQuantityTypeIdentifier.bodyMassIndex.rawValue:
            return NSLocalizedString("BMI", comment: "Body Mass Index")
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return NSLocalizedString("Active En.", comment: "energy burned")
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            return NSLocalizedString("Resting En.", comment: "Basal Energy")
        case HKQuantityTypeIdentifier.dietaryCaffeine.rawValue:
            return NSLocalizedString("Caffeine", comment: "Caffeine")
        case HKQuantityTypeIdentifier.dietarySugar.rawValue:
            return NSLocalizedString("Sugar", comment: "Sugar")
        case HKQuantityTypeIdentifier.dietaryCholesterol.rawValue:
            return NSLocalizedString("Cholesterol", comment: "Cholesterol")
        case HKQuantityTypeIdentifier.dietarySodium.rawValue:
            return NSLocalizedString("Salt", comment: "Sodium")
        case HKQuantityTypeIdentifier.dietaryProtein.rawValue:
            return NSLocalizedString("Protein", comment: "Protein")
        case HKQuantityTypeIdentifier.dietaryFiber.rawValue:
            return NSLocalizedString("Fiber", comment: "Fiber")
        case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue:
            return NSLocalizedString("Fat", comment: "Fat")
        case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue:
            return NSLocalizedString("Carbohydrates", comment: "Carbohydrates")
        case HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue:
            return NSLocalizedString("Polyunsat. Fat", comment: "Polyunsaturated Fat")
        case HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue:
            return NSLocalizedString("Sat. Fat", comment: "Saturated Fat")
        case HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue:
            return NSLocalizedString("Monosat. Fat", comment: "Monosaturated Fat")
        case HKQuantityTypeIdentifier.dietaryWater.rawValue:
            return NSLocalizedString("Water", comment: "Water")
        case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
            return NSLocalizedString("Dietary En.", comment: "Dietary Energy")
        case HKCorrelationTypeIdentifier.bloodPressure.rawValue:
            return NSLocalizedString("Blood pressure", comment: "Blood pressure")
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return NSLocalizedString("Steps", comment: "Step count")
        case HKQuantityTypeIdentifier.uvExposure.rawValue:
            return NSLocalizedString("UV", comment: "UV Exposure")
        case HKQuantityTypeIdentifier.dietarySodium.rawValue:
            return NSLocalizedString("Salt", comment: "Salt")
        default:
            return ""
        }
    }
    
    func titleForSampleType(sampleType: String, active: Bool) -> NSAttributedString
    {
        return self.attributedText(text: self.stringForSampleType(sampleType: sampleType), forSampleType: sampleType, active: active)
    }
    
    func titleForAnalysisChartOfType(sampleType: String) -> NSAttributedString {
        return self.attributedText(text: self.stringForSampleTypeOfCorrelate(sampleType: sampleType), forSampleType: sampleType, active: false)
    }
    
    private func imageNameWithState(baseName: String, active: Bool) -> String
    {
        return baseName + (active ? "-normal": "-unactive");
    }
    
    private func imageNameForSampleType(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return "icon-weight"
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return "icon-heart-rate"
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return "icon-sleep"
        case HKQuantityTypeIdentifier.bodyMassIndex.rawValue:
            return "icon-bmi"
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return "icon-active-energy"
        case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            return "icon-resting-energy"
        case HKQuantityTypeIdentifier.uvExposure.rawValue:
            return "icon-uv"
        case HKQuantityTypeIdentifier.dietaryCaffeine.rawValue:
            return "icon-caffeine"
        case HKQuantityTypeIdentifier.dietarySugar.rawValue:
            return "icon-sugar"
        case HKQuantityTypeIdentifier.dietaryCholesterol.rawValue:
            return "icon-cholesterol"
        case HKQuantityTypeIdentifier.dietarySodium.rawValue:
            return "icon-salt"
        case HKQuantityTypeIdentifier.dietaryProtein.rawValue:
            return "icon-protein"
        case HKQuantityTypeIdentifier.dietaryFiber.rawValue:
            return "icon-fiber"
        case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue:
            return "icon-fat"
        case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue:
            return "icon-carbohydrates"
        case HKQuantityTypeIdentifier.dietaryFatPolyunsaturated.rawValue:
            return "icon-polyunsaturated-fat"
        case HKQuantityTypeIdentifier.dietaryFatSaturated.rawValue:
            return "icon-saturated-fat"
        case HKQuantityTypeIdentifier.dietaryFatMonounsaturated.rawValue:
            return "icon-monosaturated-fat"
        case HKQuantityTypeIdentifier.dietaryWater.rawValue:
            return "icon-water"
        case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
            return "icon-calories"
        case HKCorrelationTypeIdentifier.bloodPressure.rawValue:
            return "icon-blood"
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return "icon-steps"
        case HKQuantityTypeIdentifier.uvExposure.rawValue:
            return "icon-uv"
        case HKQuantityTypeIdentifier.dietarySodium.rawValue:
            return "icon-salt"
        default:
            return ""
        }
    }

    func imageForSampleType(sampleType: String, active: Bool) -> UIImage?
    {
        let imageName = self.imageNameWithState(baseName: self.imageNameForSampleType(sampleType: sampleType), active: active)
        let image = UIImage(named: imageName)
        return image
    }
    
}
