//
//  WaterInterfaceController.swift
//  Circator
//
//  Created by Mariano on 3/30/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

// to do for all four:
//   (1): make sure that picker units are being brought over correctly to HK
//          initial tests suggest that picker units differ from hours/minutes
//   (2): add ability to adjust time (not only from time of entry)?
//          e.g. right now sleep is entered as a duration (but from when to when?)
//   (3): add ability to choose exercise type
//          would be a 2nd picker menu
//   (4): add glance screen with summary stats in each of the four categories
//         note: from API call to backend, rather than to phone
//           exercise, water, meals, sleep
//              meals with time-fasting? with time-eating? with time since last meal?
//   (5): add complication(s) -- time in fasting, water, exercise amount --
//         note: should be via API call to backend, rather than to phone
//   (6): add notifications -- based on lack of entry for the day -- (maybe aperiodic) --
//   questions: should users be encouraged to estimate calories burned on exercise?
//              should heart-rate be displayed?
//              should a count-up timer be enabled for meals/exercise?
//              should notifications be enabled to support missing data entry?
//                e.g. could send a notification if missing a day (for now) 
//                 -- what about duplicate entries or those that are non-sensical
//              should accelerometer be used for anything?  {probably not}
//              should core-location be used for anything?  {probably not}


import WatchKit
import Foundation
import HealthKit

class WaterInterfaceController: WKInterfaceController {

    @IBOutlet var waterPicker: WKInterfacePicker!
    @IBOutlet var EnterButton: WKInterfaceButton!
    
    var water = 0.0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...4 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "water\(i)")
            tempItems.append(item)
        }
        waterPicker.setItems(tempItems)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }

    func showButton() {
        EnterButton.setTitle("Saved")
        print("HKStore should update")
        let workout = HKWorkout(activityType:
            .Running,
                                startDate: NSDate(),
                                endDate: NSDate(),
                                duration: water,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:5.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:1.0),
                                device: HKDevice.localDevice(),
                                metadata: ["Apple Watch":"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
    }

    @IBAction func onWaterEntry(value: Int) {
        water = Double(value) + 1
    }
    @IBAction func waterSaveButton() {
        showButton()
    }


}
