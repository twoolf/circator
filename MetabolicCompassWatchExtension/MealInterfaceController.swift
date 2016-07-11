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

struct mealTimesVariables {
    var mealBegin: Int
}
var mealTimesStruc = mealTimesVariables(mealBegin:24)

class MealInterfaceController: WKInterfaceController {
    
    @IBOutlet var mealPicker: WKInterfacePicker!
    @IBOutlet var enterButton: WKInterfaceButton!
    
    var mealTime = 0
    //    var mealTypebyButton
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        enterButton.setTitle("Started \(mealTypebyButton.mealType)")
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)            
        }
        mealPicker.setItems(tempItems)
        
        var beginTimePointer = 24
        let calendar = NSCalendar.currentCalendar()
        let beginDate = NSDate()
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        if beginComponents.minute < 15 {
            beginTimePointer = 2*beginComponents.hour
        } else {
            beginTimePointer = 2*beginComponents.hour + 1
        }
        mealPicker.setSelectedItemIndex(beginTimePointer-2)
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
        let buttonColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)
        enterButton.setBackgroundColor(buttonColor)
        enterButton.setTitle("Saved")

        // initially assumes duration w/current time being end point; start-time by picker
        let calendar = NSCalendar.currentCalendar()
        let beginDate = NSDate()

        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        let mealDuration = 0
        if mealDuration % 2 == 0 {
            timeConvertClose = ( (mealDuration)/2)
        } else {
            timeConvertClose = ( (mealDuration-1)/2  )
            timeAddHalfHourClose=30
        }
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        let closeDate = calendar.dateFromComponents(closeComponents)!
        
        let mealDurationDate = beginDate.timeIntervalSinceDate(closeDate)

        let workout = HKWorkout(activityType: .PreparationAndRecovery,
                                startDate: beginDate,
                                endDate: closeDate,
                                duration: mealDurationDate,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:0.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:0.0),
                                device: HKDevice.localDevice(),
                                metadata: [mealTypebyButton.mealType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
    }
    
    @IBAction func onMealEntry(value: Int) {
        mealTime = value
    }
    @IBAction func mealSaveButton() {
        mealTimesStruc.mealBegin = mealTime
        pushControllerWithName("MealStartTimeController", context: self)
    }
}

