//
//  MealStartTimeController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import SwiftDate

class MealStartTimeController: WKInterfaceController {
    
    @IBOutlet var mealStartTimePicker: WKInterfacePicker!
    @IBOutlet var mealStartTimeButton: WKInterfaceButton!
    
    var mealClose = 0
    //    var mealTypebyButton
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        mealStartTimeButton.setTitle("Ended \(mealTypebyButton.mealType)")
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        mealStartTimePicker.setItems(tempItems)
        mealStartTimePicker.setSelectedItemIndex((mealTimesStruc.mealBegin)+2)
    }
    
    func onMealTimeChanged() {
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton()    {
        let buttonColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 0.5)
        mealStartTimeButton.setBackgroundColor(buttonColor)
        mealStartTimeButton.setTitle("Saved")
        print("HKStore should be updated for Meal")
        
        // setting up conversion of saved value from 'waking from sleep' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate.today(inRegion: thisRegion)
        print("begin date should be midnight of today: \(beginDate)")
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if mealTimesStruc.mealBegin % 2 == 0 {
            print("\(mealTimesStruc.mealBegin) from meal times 1st screen is even")
            _=0
            timeConvertBegin = ( (mealTimesStruc.mealBegin)/2 )
            //            print("timeConvertStart: \(timeConvertStart)")
            //            startDate = startDate + timeConvertStart.hours
            //            print("new start date: \(startDate)")
        } else {
            print("\(mealTimesStruc.mealBegin) from meal times 1st screen is odd")
            timeConvertBegin = ( (mealTimesStruc.mealBegin-1)/2 )
            timeAddHalfHourBegin=30
            //            print("timeConvertStart: \(timeConvertStart)")
            //            startDate = startDate + timeConvertStart.hours + 30.minutes
            //            print("new start date: \(startDate)")
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        print("should have adjusted, hour and minute for beginTime: \(timeConvertBegin)")
        print("    and \(timeAddHalfHourBegin)")
        beginDate = calendar.dateFromComponents(beginComponents)!
        print("new beginDate based on first screen: \(beginDate)")
        
        // setting up values from current picker and getting 'beginning of sleep' ready
        var closeDate = NSDate.today(inRegion: thisRegion)
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if mealClose % 2 == 0 {
            print("\(mealClose) from meal 2nd screen is even")
            _=0
            timeConvertClose = ( (mealClose)/2)
            //            endDate = endDate + timeConvertEnd.hours
        } else {
            print("\(mealClose) from meal 2nd screen is odd")
            _=30
            timeConvertClose = ( (mealClose-1)/2  )
            timeAddHalfHourClose=30
            //            endDate = endDate + timeConvertEnd.hours + 30.minutes
        }
        
        //        var endDate = NSDate().startOf(.Day, inRegion: Region())
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        print("should have end adjusted, hour and minute for start point: \(timeConvertClose)")
        print("    and \(timeAddHalfHourClose)")
        if closeDate < beginDate {
            closeComponents.day = closeComponents.day-1
            print("adjusted close day by one")
            closeDate = calendar.dateFromComponents(closeComponents)!
        }
        
        print("computing a beginning date (2nd screen): \(beginDate)")
        print("and an closing date of (1st screen): \(closeDate)")
        
        let mealDurationHours = beginComponents.hour - closeComponents.hour
        let mealDurationMinutes = beginComponents.minute - closeComponents.minute
        let mealDurationTime = mealDurationHours*60+mealDurationMinutes
        
        let workout = HKWorkout(activityType:
            .PreparationAndRecovery,
                                startDate: beginDate,
                                endDate: closeDate,
                                duration: Double(mealDurationTime)*60,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:0.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:0.0),
                                device: HKDevice.localDevice(),
                                metadata: [mealTypebyButton.mealType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }

    }
    
    @IBAction func onMealEntry(value: Int) {
        mealClose = value
    }
    
    @IBAction func mealSaveButton() {
        showButton()
    }

}
