//
//  Meal.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import Foundation
import HealthKit

enum MealType {
    
    case Snack
    case Breakfast
    case Lunch
    case Dinner
    
}

class Meal : NSObject {
    
    var type : MealType!
    var items : [FoodItem] = []
    var nutrition : NutritionalContent {
        get {
            return self.items.reduce(FoodItem(), combine: FoodItem.combiner).nutrition
        }
    }
    
    func addItem(item : FoodItem) {
        
    }
    
    func indexOfFoodItem(item : FoodItem) -> Int? {
        return nil
    }
    
    func removeItemAtIndex(index : Int) {
        
    }
    
}