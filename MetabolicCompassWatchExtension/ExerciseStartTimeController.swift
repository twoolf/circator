//
//  ExerciseStartTimeController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import SwiftDate

class ExerciseStartTimeController: WKInterfaceController {
    
    @IBOutlet var exerciseStartTimePicker: WKInterfacePicker!
    @IBOutlet var exerciseStartTimeButton: WKInterfaceButton!
    
    var exerciseClose = 0

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        exerciseStartTimeButton.setTitle("End \(exerciseTypebyButton.exerciseType) ")
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        exerciseStartTimePicker.setItems(tempItems)
        exerciseStartTimePicker.setSelectedItemIndex((exerciseTimeStruc.exerciseBegin)+2)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton()    {
        let buttonColor = UIColor(red: 0.50, green: 0.0, blue: 0.13, alpha: 0.5)
        exerciseStartTimeButton.setBackgroundColor(buttonColor)
        exerciseStartTimeButton.setTitle("Saved")
        print("HKStore should be updated for Exercise")
        
        // setting up conversion of saved value from 'end of exercise' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate.today(inRegion: thisRegion)
        print("begin date should be midnight of today: \(beginDate)")
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if exerciseTimeStruc.exerciseBegin % 2 == 0 {
            print("\(exerciseTimeStruc.exerciseBegin) from exercise times 1st screen is even")
            _=0
            timeConvertBegin = ( (exerciseTimeStruc.exerciseBegin)/2 )
            //            print("timeConvertStart: \(timeConvertStart)")
            //            startDate = startDate + timeConvertStart.hours
            //            print("new start date: \(startDate)")
        } else {
            print("\(exerciseTimeStruc.exerciseBegin) from exercise time 1st screen is odd")
            timeConvertBegin = ( (exerciseTimeStruc.exerciseBegin-1)/2 )
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
        
        // setting up values from current picker and getting 'beginning of exercise' ready
        var closeDate = NSDate.today(inRegion: thisRegion)
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if exerciseClose % 2 == 0 {
            print("\(exerciseClose) from exercise 2nd screen is even")
            _=0
            timeConvertClose = ( (exerciseClose)/2)
            //            endDate = endDate + timeConvertEnd.hours
        } else {
            print("\(exerciseClose) from exercise 2nd screen is odd")
            _=30
            timeConvertClose = ( (exerciseClose-1)/2  )
            timeAddHalfHourClose=30
            //            endDate = endDate + timeConvertEnd.hours + 30.minutes
        }
        
        //        var endDate = NSDate().startOf(.Day, inRegion: Region())
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        print("should have end adjusted, hour and minute for close point: \(timeConvertClose)")
        print("    and \(timeAddHalfHourClose)")
        if closeDate < beginDate {
            closeComponents.day = closeComponents.day-1
            print("adjusted close day by one")
            closeDate = calendar.dateFromComponents(closeComponents)!
        }
        
        print("computing a closeDate (2nd screen): \(closeDate)")
        print("and an beginning date of (1st screen): \(beginDate)")
        
        let exerciseDurationHours = beginComponents.hour - closeComponents.hour
        let exerciseDurationMinutes = beginComponents.minute - closeComponents.minute
        let exerciseDurationTime = exerciseDurationHours*60+exerciseDurationMinutes
        
/*        var workout = HKWorkoutActivityType.Running
        if ( (exerciseTypebyButton.exerciseType) == "Running") {
             workout = HKWorkoutActivityType.Running
        } else if ( (exerciseTypebyButton.exerciseType) == "Walking") {
             workout = HKWorkoutActivityType.Walking
        } */
        
        let workout = HKWorkout(activityType:
            .Running,
                                startDate: beginDate,
                                endDate: closeDate,
                                duration: Double(exerciseDurationTime)*60,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:0.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:0.0),
                                device: HKDevice.localDevice(),
                                metadata: [mealTypebyButton.mealType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
/*
        let workout = HKWorkoutActivityType(activityType: .Running,
                                startDate: beginDate,
                                endDate: closeDate,
                                duration: Double(exerciseDurationTime)*60,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:100.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:1.0),
                                device: HKDevice.localDevice(),
                                metadata: [exerciseTypebyButton.exerciseType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
 */
        
    }
    
    @IBAction func onExerciseStartPicker(value: Int) {
        exerciseClose = value
    }
    
    @IBAction func onExerciseStartSaveButton() {
        showButton()
    }
    
}
