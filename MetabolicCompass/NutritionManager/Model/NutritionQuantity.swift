//
//  NutritionQuantity.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import Foundation
import HealthKit

class NutritionalContent : NSObject {
    
    var contents : [NutritionQuantity] = []
    
    var FatTotal : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .FatTotal) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var FatPolyunsaturated : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .FatPolyunsaturated) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var FatMonounsaturated : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .FatMonounsaturated) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var FatSaturated : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .FatSaturated) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Cholesterol : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Cholesterol) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Sodium : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Sodium) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Carbohydrates : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Carbohydrates) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Fiber : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Fiber) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Sugar : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Sugar) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var EnergyConsumed : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .EnergyConsumed) {
                print(index)
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Protein : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Protein) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminA : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminA) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminB6 : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminB6) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminB12 : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminB12) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminC : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminC) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminD : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminD) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminE : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminE) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var VitaminK : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .VitaminK) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Calcium : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Calcium) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Iron : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Iron) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Thiamin : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Thiamin) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Riboflavin : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Riboflavin) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Niacin : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Niacin) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Folate : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Folate) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Biotin : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Biotin) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var PantothenicAcid : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .PantothenicAcid) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Phosphorus : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Phosphorus) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Iodine : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Iodine) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Magnesium : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Magnesium) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Zinc : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Zinc) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Selenium : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Selenium) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Copper : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Copper) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Manganese : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Manganese) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Chromium : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Chromium) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Molybdenum : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Molybdenum) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Chloride : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Chloride) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Potassium : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Potassium) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Caffeine : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Caffeine) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    var Water : HKQuantity? {
        get {
            if let index = self.indexOfNutritionOfType(typeOfNutrition: .Water) {
                return self.contents[index].quantity
            }
            return nil
        }
    }
    
    func containsNutritionOfType(typeOfNutrition type : NutritionQuantityType) -> Bool {
        
        for i in 0..<self.contents.count {
            if self.contents[i].quantityType == type.identifier {
                return true
            }
        }
        
        return false
    }
    
    func indexOfNutritionOfType(typeOfNutrition type : NutritionQuantityType) -> Int? {
        
        for i in 0..<self.contents.count {
            if self.contents[i].quantityType == HKObjectType.quantityTypeForIdentifier(type.identifier) {
                return i
            }
        }
        
        return nil
    }
    
    func addNutritionQuantity(nutritionQuantity : NutritionQuantity) {
        
        for i in 0..<self.contents.count {
            if self.contents[i].quantityType.identifier == nutritionQuantity.quantityType.identifier && self.contents[i].quantity.isCompatibleWithUnit(nutritionQuantity.unit) {
                let sum = self.contents[i].quantity.doubleValueForUnit(self.contents[i].unit) + nutritionQuantity.quantity.doubleValueForUnit(nutritionQuantity.unit)
                self.contents[i].quantity = HKQuantity(unit: self.contents[i].unit, doubleValue: sum)
                return
            }
        }
        
        self.contents.append(nutritionQuantity)
    }
}

class NutritionQuantity : NSObject {
    
    var quantityType: HKQuantityType
    var quantity: HKQuantity
    var unit : HKUnit
    
    init(type quantityType: NutritionQuantityType, amount: Double) {
        self.quantityType = HKObjectType.quantityTypeForIdentifier(quantityType.identifier)!
        self.quantity = HKQuantity(unit: quantityType.unit, doubleValue: amount)
        self.unit = quantityType.unit
    }
}

enum NutritionQuantityType : String {
    
    case FatTotal
    case FatPolyunsaturated
    case FatMonounsaturated
    case FatSaturated
    case Cholesterol
    case Sodium
    case Carbohydrates
    case Fiber
    case Sugar
    case EnergyConsumed
    case Protein
    case VitaminA
    case VitaminB6
    case VitaminB12
    case VitaminC
    case VitaminD
    case VitaminE
    case VitaminK
    case Calcium
    case Iron
    case Thiamin
    case Riboflavin
    case Niacin
    case Folate
    case Biotin
    case PantothenicAcid
    case Phosphorus
    case Iodine
    case Magnesium
    case Zinc
    case Selenium
    case Copper
    case Manganese
    case Chromium
    case Molybdenum
    case Chloride
    case Potassium
    case Caffeine
    case Water
    
    var identifier : String {
        switch self {
        case FatTotal:
            return HKQuantityTypeIdentifierDietaryFatTotal
        case FatPolyunsaturated:
            return HKQuantityTypeIdentifierDietaryFatPolyunsaturated
        case FatMonounsaturated:
            return HKQuantityTypeIdentifierDietaryFatMonounsaturated
        case FatSaturated:
            return HKQuantityTypeIdentifierDietaryFatSaturated
        case Cholesterol:
            return HKQuantityTypeIdentifierDietaryCholesterol
        case Sodium:
            return HKQuantityTypeIdentifierDietarySodium
        case Carbohydrates:
            return HKQuantityTypeIdentifierDietaryCarbohydrates
        case Fiber:
            return HKQuantityTypeIdentifierDietaryFiber
        case Sugar:
            return HKQuantityTypeIdentifierDietarySugar
        case EnergyConsumed:
            return HKQuantityTypeIdentifierDietaryEnergyConsumed
        case Protein:
            return HKQuantityTypeIdentifierDietaryProtein
        case VitaminA:
            return HKQuantityTypeIdentifierDietaryVitaminA
        case VitaminB6:
            return HKQuantityTypeIdentifierDietaryVitaminB6
        case VitaminB12:
            return HKQuantityTypeIdentifierDietaryVitaminB12
        case VitaminC:
            return HKQuantityTypeIdentifierDietaryVitaminC
        case VitaminD:
            return HKQuantityTypeIdentifierDietaryVitaminD
        case VitaminE:
            return HKQuantityTypeIdentifierDietaryVitaminE
        case VitaminK:
            return HKQuantityTypeIdentifierDietaryVitaminK
        case Calcium:
            return HKQuantityTypeIdentifierDietaryCalcium
        case Iron:
            return HKQuantityTypeIdentifierDietaryIron
        case Thiamin:
            return HKQuantityTypeIdentifierDietaryThiamin
        case Riboflavin:
            return HKQuantityTypeIdentifierDietaryRiboflavin
        case Niacin:
            return HKQuantityTypeIdentifierDietaryNiacin
        case Folate:
            return HKQuantityTypeIdentifierDietaryFolate
        case Biotin:
            return HKQuantityTypeIdentifierDietaryBiotin
        case PantothenicAcid:
            return HKQuantityTypeIdentifierDietaryPantothenicAcid
        case Phosphorus:
            return HKQuantityTypeIdentifierDietaryPhosphorus
        case Iodine:
            return HKQuantityTypeIdentifierDietaryIodine
        case Magnesium:
            return HKQuantityTypeIdentifierDietaryMagnesium
        case Zinc:
            return HKQuantityTypeIdentifierDietaryZinc
        case Selenium:
            return HKQuantityTypeIdentifierDietarySelenium
        case Copper:
            return HKQuantityTypeIdentifierDietaryCopper
        case Manganese:
            return HKQuantityTypeIdentifierDietaryManganese
        case Chromium:
            return HKQuantityTypeIdentifierDietaryChromium
        case Molybdenum:
            return HKQuantityTypeIdentifierDietaryMolybdenum
        case Chloride:
            return HKQuantityTypeIdentifierDietaryChloride
        case Potassium:
            return HKQuantityTypeIdentifierDietaryPotassium
        case Caffeine:
            return HKQuantityTypeIdentifierDietaryCaffeine
        case Water:
            return HKQuantityTypeIdentifierDietaryWater
            
        }
    }
    
    var unit : HKUnit {
        switch self {
        case FatTotal:
            return HKUnit.gramUnit()
        case FatPolyunsaturated:
            return HKUnit.gramUnit()
        case FatMonounsaturated:
            return HKUnit.gramUnit()
        case FatSaturated:
            return HKUnit.gramUnit()
        case Cholesterol:
            return HKUnit.gramUnitWithMetricPrefix(.Milli)
        case Sodium:
            return HKUnit.gramUnitWithMetricPrefix(.Milli)
        case Carbohydrates:
            return HKUnit.gramUnit()
        case Fiber:
            return HKUnit.gramUnit()
        case Sugar:
            return HKUnit.gramUnit()
        case EnergyConsumed:
            return HKUnit.kilocalorieUnit()
        case Protein:
            return HKUnit.gramUnit()
        case VitaminA:
            return HKUnit.gramUnit()
        case VitaminB6:
            return HKUnit.gramUnit()
        case VitaminB12:
            return HKUnit.gramUnit()
        case VitaminC:
            return HKUnit.gramUnit()
        case VitaminD:
            return HKUnit.gramUnit()
        case VitaminE:
            return HKUnit.gramUnit()
        case VitaminK:
            return HKUnit.gramUnit()
        case Calcium:
            return HKUnit.gramUnit()
        case Iron:
            return HKUnit.gramUnit()
        case Thiamin:
            return HKUnit.gramUnit()
        case Riboflavin:
            return HKUnit.gramUnit()
        case Niacin:
            return HKUnit.gramUnit()
        case Folate:
            return HKUnit.gramUnit()
        case Biotin:
            return HKUnit.gramUnit()
        case PantothenicAcid:
            return HKUnit.gramUnit()
        case Phosphorus:
            return HKUnit.gramUnit()
        case Iodine:
            return HKUnit.gramUnit()
        case Magnesium:
            return HKUnit.gramUnit()
        case Zinc:
            return HKUnit.gramUnit()
        case Selenium:
            return HKUnit.gramUnit()
        case Copper:
            return HKUnit.gramUnit()
        case Manganese:
            return HKUnit.gramUnit()
        case Chromium:
            return HKUnit.gramUnit()
        case Molybdenum:
            return HKUnit.gramUnit()
        case Chloride:
            return HKUnit.gramUnit()
        case Potassium:
            return HKUnit.gramUnitWithMetricPrefix(.Milli)
        case Caffeine:
            return HKUnit.gramUnit()
        case Water:
            return HKUnit.gramUnit()
            
        }
    }
}