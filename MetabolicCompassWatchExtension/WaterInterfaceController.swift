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
//              should there be a 'snack' category for the meals? (4th)
//  for sleep, should it be a prior, e.g. select start time and then interval
//     or first enter interval (duration) and then start or end time?
//  current thought is that all timed events (ie non-water) are entered via an
//    initial screen w/two buttons (one: takes to a duration screen when pushed)
//      other (2nd) is after scrolling to start time, for entering start and then
//      after that the 2nd screen is for end time
//         ((will want to note which screen they entered timed event from))
//  style notes: (a) make font on start/end time circle be larger;
//               (b) re-do colors on circles;
// should water have more than 4-cups at a time and/or should it be timed?
//  glances: right now goal is to have the same seven attributes as the
//      app selected w/their current values; user scrolls through them;
//  complications: will show (max fasting) in small and
//      max-fasting, last-meal-time, and time-spent-eating in longer window
//  should the App also have pages beyond data entry? (e.g. also the 7-metrics?)
// time-travel (1) in modular large support could be to list most recent entry into HealthKit; (2) while in smaller modular/others, could be 'maximum fasting time'; (3) may also want to have option in larger modular for three rows of information, similar to the 5-7 rows in the iPhone App


import WatchKit
import Foundation
import HealthKit

struct waterAmountVariable {
    var waterAmount: Double
}
var waterEnterButton = waterAmountVariable(waterAmount:250.0)

class WaterInterfaceController: WKInterfaceController {
    
    @IBOutlet var waterPicker: WKInterfacePicker!
    @IBOutlet var EnterButton: WKInterfaceButton!
    
    var water = 0.0
    let healthKitStore:HKHealthStore = HKHealthStore()
    let healthManager:HealthManager = HealthManager()
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...8 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "water\(i)")
            tempItems.append(item)
        }
        waterPicker.setItems(tempItems)
        waterPicker.setSelectedItemIndex(2)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onWaterEntry(value: Int) {
        water = Double(value)*250
    }
    @IBAction func waterSaveButton() {
        waterEnterButton.waterAmount = water
        pushControllerWithName("WaterTimesInterfaceController", context: self)
    }
    
    
}

