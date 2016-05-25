//
//  ExerciseController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit


class ExerciseInterfaceController: WKInterfaceController {
    @IBOutlet var exerPicker: WKInterfacePicker!
    @IBOutlet var enterButton: WKInterfaceButton!
    var exerciseDuration = 1.0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...180 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "exercise\(i)")
            tempItems.append(item)
        }
        exerPicker.setItems(tempItems)
        
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
    // may want to update to enable users to log type of exercise workout (picker)
        let workout = HKWorkout(activityType:
            .Running,
                    startDate: NSDate(),
                    endDate: NSDate(),
                    duration: exerciseDuration,
                    totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:5.0),
                    totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:1.0),
                    device: HKDevice.localDevice(),
                    metadata: ["Apple Watch":"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
    }

    @IBAction func onSave() {
        showButton()
    }
    @IBAction func onExercise(value: Int) {
        exerciseDuration = Double(value) + 1
    }
}
