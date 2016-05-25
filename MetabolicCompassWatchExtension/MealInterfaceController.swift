//
//  MealController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class MealInterfaceController: WKInterfaceController {

    @IBOutlet var mealPicker: WKInterfacePicker!
    @IBOutlet var enterButton: WKInterfaceButton!
    
//    var mealTypebyButton
    var mealDuration = 0.0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...90 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "meal\(i)")
            tempItems.append(item)
        }
        mealPicker.setItems(tempItems)
    }

    func onMealTimeChanged() {

    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    func showButton() {
        enterButton.setTitle("Saved")
        print("HKStore should update")
        let workout = HKWorkout(activityType:
            .PreparationAndRecovery,
                                startDate: NSDate(),
                                endDate: NSDate(),
                                duration: mealDuration,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:0.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:0.0),
                                device: HKDevice.localDevice(),
                                metadata: [mealTypebyButton.mealType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
    }
    
    @IBAction func onMealEntry(value: Int) {
        mealDuration = Double(value)*60
    }
    @IBAction func mealSaveButton() {
        showButton()
    }
}
