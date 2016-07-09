//
//  MealController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

// similar to Sleep pickers, the first screen is set by time of day and determines
//   the 'end point' while the 2nd screen is used to set the start of the eating event

import WatchKit
import Foundation
import HealthKit
import SwiftDate

struct mealTimesVariables {
    var mealEnd: Int
}
var mealTimesStruc = mealTimesVariables(mealEnd:24)

class MealInterfaceController: WKInterfaceController {
    
    @IBOutlet var mealPicker: WKInterfacePicker!
    @IBOutlet var enterButton: WKInterfaceButton!
    
    var mealTime = 0
    //    var mealTypebyButton
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)            
        }
        mealPicker.setItems(tempItems)
        
        let thisRegion = DateRegion()
        var endTimePointer = 24
        let calendar = NSCalendar.currentCalendar()
        var endDate = NSDate()
        let endComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: endDate)
        if endComponents.minute < 15 {
            endTimePointer = 2*endComponents.hour
        } else {
            endTimePointer = 2*endComponents.hour + 1
        }
        mealPicker.setSelectedItemIndex(endTimePointer)
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
        print("HKStore should update for meal: \(mealTypebyButton.mealType) ")
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var endDate = NSDate()
        let endComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: endDate)
    
        var startDate = endDate
        let startComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: startDate)
    
        var timeConvertStart:Int = 0
        var timeAddHalfHourStart:Int = 0
        var mealDuration = 0
        if mealDuration % 2 == 0 {
            print("\(mealDuration) from meal duration is even")
            _=0
            timeConvertStart = ( (mealDuration)/2)
        } else {
            print("\(mealDuration) from meal duration is odd")
            _=30
            timeConvertStart = ( (mealDuration-1)/2  )
            timeAddHalfHourStart=30
        }
        
        startComponents.hour = timeConvertStart
        startComponents.minute = timeAddHalfHourStart
        startDate = calendar.dateFromComponents(startComponents)!
        
        let mealDurationHours = endComponents.hour - startComponents.hour
        let mealDurationDate = endDate.timeIntervalSinceDate(startDate)
        if (endDate<startDate){
            print("end Date is before start Date")
            print("\(endDate) and \(startDate)")
        }
        
        let workout = HKWorkout(activityType:
            .PreparationAndRecovery,
                                startDate: startDate,
                                endDate: endDate,
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
        mealTimesStruc.mealEnd = mealTime
        print("End of meal time: and variable --")
        print(mealTimesStruc.mealEnd)
        pushControllerWithName("MealStartTimeController", context: self)
//        showButton()
    }
}

