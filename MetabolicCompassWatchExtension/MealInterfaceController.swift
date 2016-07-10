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
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)            
        }
        mealPicker.setItems(tempItems)
        
        let thisRegion = DateRegion()
        var beginTimePointer = 24
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate()
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
        print("HKStore should update for meal: \(mealTypebyButton.mealType) ")
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate()
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
    
        var closeDate = beginDate
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
    
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        var mealDuration = 0
        if mealDuration % 2 == 0 {
            print("\(mealDuration) from meal duration is even")
            _=0
            timeConvertClose = ( (mealDuration)/2)
        } else {
            print("\(mealDuration) from meal duration is odd")
            _=30
            timeConvertClose = ( (mealDuration-1)/2  )
            timeAddHalfHourClose=30
        }
        
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        let mealDurationHours = beginComponents.hour - closeComponents.hour
        let mealDurationDate = beginDate.timeIntervalSinceDate(closeDate)
        if (beginDate<closeDate){
            print("begin Date is before close Date")
            print("\(beginDate) and \(closeDate)")
        }
        
        let workout = HKWorkout(activityType:
            .PreparationAndRecovery,
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
        print("Begin of meal time: and variable --")
        print(mealTimesStruc.mealBegin)
        pushControllerWithName("MealStartTimeController", context: self)
//        showButton()
    }
}

