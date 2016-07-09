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
    
    var mealStart = 0
    //    var mealTypebyButton
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        mealStartTimePicker.setItems(tempItems)
        mealStartTimePicker.setSelectedItemIndex((mealTimesStruc.mealEnd)-2)
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
        let buttonColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)
        mealStartTimeButton.setBackgroundColor(buttonColor)
        mealStartTimeButton.setTitle("Saved")
        print("HKStore should be updated for Meal")
        
        // setting up conversion of saved value from 'waking from sleep' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var endDate = NSDate.today(inRegion: thisRegion)
        print("end date should be midnight of today: \(endDate)")
        let endComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: endDate)
        var timeConvertEnd:Int = 0
        var timeAddHalfHourEnd:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if mealTimesStruc.mealEnd % 2 == 0 {
            print("\(mealTimesStruc.mealEnd) from meal times 1st screen is even")
            _=0
            timeConvertEnd = ( (mealTimesStruc.mealEnd)/2 )
            //            print("timeConvertStart: \(timeConvertStart)")
            //            startDate = startDate + timeConvertStart.hours
            //            print("new start date: \(startDate)")
        } else {
            print("\(mealTimesStruc.mealEnd) from meal times 1st screen is odd")
            timeConvertEnd = ( (mealTimesStruc.mealEnd-1)/2 )
            timeAddHalfHourEnd=30
            //            print("timeConvertStart: \(timeConvertStart)")
            //            startDate = startDate + timeConvertStart.hours + 30.minutes
            //            print("new start date: \(startDate)")
        }
        endComponents.hour = timeConvertEnd
        endComponents.minute = timeAddHalfHourEnd
        print("should have adjusted, hour and minute for endTime: \(timeConvertEnd)")
        print("    and \(timeAddHalfHourEnd)")
        endDate = calendar.dateFromComponents(endComponents)!
        print("new endDate based on first screen: \(endDate)")
        
        // setting up values from current picker and getting 'beginning of sleep' ready
        var startDate = NSDate.today(inRegion: thisRegion)
        var timeConvertStart:Int = 0
        var timeAddHalfHourStart:Int = 0
        
        if mealStart % 2 == 0 {
            print("\(mealStart) from meal 2nd screen is even")
            _=0
            timeConvertStart = ( (mealStart)/2)
            //            endDate = endDate + timeConvertEnd.hours
        } else {
            print("\(mealStart) from meal 2nd screen is odd")
            _=30
            timeConvertStart = ( (mealStart-1)/2  )
            timeAddHalfHourStart=30
            //            endDate = endDate + timeConvertEnd.hours + 30.minutes
        }
        
        //        var endDate = NSDate().startOf(.Day, inRegion: Region())
        
        let startComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: startDate)
        startComponents.hour = timeConvertStart
        startComponents.minute = timeAddHalfHourStart
        startDate = calendar.dateFromComponents(startComponents)!
        
        print("should have end adjusted, hour and minute for start point: \(timeConvertStart)")
        print("    and \(timeAddHalfHourStart)")
        if startDate > endDate {
            startComponents.day = startComponents.day-1
            print("adjusted start day by one")
            startDate = calendar.dateFromComponents(startComponents)!
        }
        
        print("computing a startDate (2nd screen): \(startDate)")
        print("and an ending date of (1st screen): \(endDate)")
        
        let mealDurationHours = endComponents.hour - startComponents.hour
        let mealDurationMinutes = endComponents.minute - startComponents.minute
        let mealDurationTime = mealDurationHours*60+mealDurationMinutes
        
        let workout = HKWorkout(activityType:
            .PreparationAndRecovery,
                                startDate: startDate,
                                endDate: endDate,
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
        mealStart = value
    }
    
    @IBAction func mealSaveButton() {
        showButton()
    }

}
