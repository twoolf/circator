//
//  FoodItem.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import Foundation
import HealthKit

class FoodItem : NSObject {
    
    var name : String = ""
    var brandName : String?
    var servingSizeUnit : String?
    var servingQuantity : Int = 1
    var servingWeight : Int?
    var nutritionixID : NSData?
    let nutrition = NutritionalContent()
    var statement : String?
    var ingredients : String?
    
    override init() {
        super.init()
    }
    
    init(nutritionixData : [String : AnyObject]) {
        super.init()
        
        for (key, value) in nutritionixData {
            switch key {
            case "item_name":
                if let name = value as? String {
                    self.name = name
                }
                
            case "brand_name":
                self.brandName = String(value) != "<null>" ? String(value) : nil
                
            case "item_description":
                self.statement = String(value) != "<null>" ? String(value) : nil
                
            case "nf_serving_size_unit":
                self.servingSizeUnit = String(value) != "<null>" ? String(value) : nil
                
            case "nf_serving_size_qty":
                if let quantity = value as? Int {
                    self.servingQuantity = quantity
                }
                
            case "nf_serving_weight_grams":
                self.servingWeight = value as? Int
                
            case "nf_calcium_dv":
                break
                
            case "nf_calories":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .EnergyConsumed, amount: amount))
                }
                
            case "nf_calories_from_fat":
                break
                
            case "nf_cholesterol":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Cholesterol, amount: amount))
                }
                
            case "nf_dietary_fiber":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Fiber, amount: amount))
                }
                
            case "nf_ingredient_statement":
                self.ingredients = String(value) != "<null>" ? String(value) : nil
                
            case "nf_iron_dv":
                break
                
            case "nf_monounsaturated_fat":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatMonounsaturated, amount: amount))
                }
                
            case "nf_polyunsaturated_fat":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatPolyunsaturated, amount: amount))
                }
                
            case "nf_protein":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Protein, amount: amount))
                }
                
            case "nf_saturated_fat":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatSaturated, amount: amount))
                }
                
            case "nf_sodium":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Sodium, amount: amount))
                }
                
            case "nf_sugars":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Sugar, amount: amount))
                }
                
            case "nf_total_carbohydrate":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Carbohydrates, amount: amount))
                }
                
            case "nf_total_fat":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatTotal, amount: amount))
                }
                
            case "nf_vitamin_a_dv":
                break
                
            case "nf_vitamin_c_dv":
                break
                
            case "nf_water_grams":
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Water, amount: amount))
                }
                
            default:
                break
            }
        }
    }
    
    static var combiner : ((FoodItem, FoodItem) -> FoodItem) = { (thisFood, thatFood) in
        return thisFood
    }
}
