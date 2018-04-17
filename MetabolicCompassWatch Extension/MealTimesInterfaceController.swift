//
//  MealTimesInterfaceController.swift
//  Circator
//
//  Created by Mariano on 4/19/16. 
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//
import WatchKit
import Foundation

struct mealTypeVariable {
    var mealType: String
}
var mealTypebyButton = mealTypeVariable(mealType:"to be named")

class MealTimesInterfaceController: WKInterfaceController {
    
    @IBOutlet var dinnerButton: WKInterfaceButton!
    @IBOutlet var breakfastButton: WKInterfaceButton!
    @IBOutlet var lunchButton: WKInterfaceButton!
    @IBOutlet var snackButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }

    @IBAction func onDinner() {
        mealTypebyButton.mealType = "Dinner"
        pushController(withName: "MealInterfaceController", context: self)
    }
    
    @IBAction func onLunch() {
        mealTypebyButton.mealType = "Lunch"
        pushController(withName: "MealInterfaceController", context: self)
    }
    
    @IBAction func onBreakfast() {
        mealTypebyButton.mealType = "Breakfast"
        pushController(withName: "MealInterfaceController", context: self)
    }
    
    @IBAction func onSnack() {
        mealTypebyButton.mealType = "Snack"
        pushController(withName: "MealInterfaceController", context: self)
    }
    
}
