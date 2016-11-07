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
            
            if key == "item_name" {
                if let name = value as? String {
                    self.name = name
                }
            }
            
            if key == "brand_name" {
                self.brandName = String(value) != "<null>" ? String(value) : nil
            }
            
            if key == "item_description" {
                self.statement = String(value) != "<null>" ? String(value) : nil
            }
            
            if key == "nf_serving_size_unit" {
                self.servingSizeUnit = String(value) != "<null>" ? String(value) : nil
            }
            
            if key == "nf_serving_size_qty" {
                if let quantity = value as? Int {
                    self.servingQuantity = quantity
                }
            }
            
            if key == "nf_serving_weight_grams" {
                self.servingWeight = value as? Int
            }
            
            if key == "nf_calcium_dv" {
                //TODO: daily value percentage calculation
            }
            
            if key == "nf_calories" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .EnergyConsumed, amount: amount))
                    
                }
            }
            if key == "nf_calories_from_fat" {
                // TODO: calories from fat can be calculated from fat total?
            }
            
            if key == "nf_cholesterol" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Cholesterol, amount: amount))
                    
                }
            }
            
            if key == "nf_dietary_fiber" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Fiber, amount: amount))
                    
                }
            }
            
            if key == "nf_ingredient_statement" {
                self.ingredients = String(value) != "<null>" ? String(value) : nil
            }
            
            if key == "nf_iron_dv" {
                //TODO: daily value percentage calculation
            }
            
            if key == "nf_monounsaturated_fat" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatMonounsaturated, amount: amount))
                    
                }
            }
            if key == "nf_polyunsaturated_fat" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatPolyunsaturated, amount: amount))
                    
                }
            }
            if key == "nf_protein" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Protein, amount: amount))
                    
                }
            }

            if key == "nf_saturated_fat" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatSaturated, amount: amount))
                    
                }
            }
            
            if key == "nf_sodium" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Sodium, amount: amount))
                    
                }
            }
            if key == "nf_sugars" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Sugar, amount: amount))
                    
                }
            }
            if key == "nf_total_carbohydrate" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Carbohydrates, amount: amount))
                    
                }
            }
            if key == "nf_total_fat" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .FatTotal, amount: amount))
                    
                }
            }
            
            /*
 
            TODO: Does HealthKit have a transfat object type?
 
            if key == "nf_trans_fatty_acid" {
                /* do something with 0 */
            }
 
            */
            
            if key == "nf_vitamin_a_dv" {
                //TODO: daily value percentage calculation
            }
            if key == "nf_vitamin_c_dv" {
                //TODO: daily value percentage calculation
            }
            if key == "nf_water_grams" {
                if let amount = value as? Double {
                    self.nutrition.addNutritionQuantity(NutritionQuantity(type: .Water, amount: amount))
                }
            }

        }
    }
    
    static var combiner : ((FoodItem, FoodItem) -> FoodItem) = { (thisFood, thatFood) in
        return thisFood
    }
}