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

        // setting up conversion of saved value from 'end of exercise' in 1st screen
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate()
        let beginComponents = calendar.components([.Year, .Month, .Day], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0
        
        // note: imageset (0-48) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, 48=midnight etc
        if exerciseTimeStruc.exerciseBegin % 2 == 0 {
            timeConvertBegin = ( (exerciseTimeStruc.exerciseBegin)/2 )
        } else {
            timeConvertBegin = ( (exerciseTimeStruc.exerciseBegin-1)/2 )
            timeAddHalfHourBegin=30
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        beginDate = calendar.dateFromComponents(beginComponents)!
        print("new beginDate based on first screen: \(beginDate)")
        
        var closeDate = NSDate()
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if exerciseClose % 2 == 0 {
            timeConvertClose = ( (exerciseClose)/2)
        } else {
            timeConvertClose = ( (exerciseClose-1)/2  )
            timeAddHalfHourClose=30
        }
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        if closeDate.compare(beginDate) == .OrderedAscending {
            closeComponents.day = closeComponents.day-1
            closeDate = calendar.dateFromComponents(closeComponents)!
        }

        let exerciseDurationHours = beginComponents.hour - closeComponents.hour
        let exerciseDurationMinutes = beginComponents.minute - closeComponents.minute
        let exerciseDurationTime = exerciseDurationHours*60+exerciseDurationMinutes
        let workout = HKWorkout(activityType: .Running,
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
        
    }
    
    @IBAction func onExerciseStartPicker(value: Int) {
        exerciseClose = value
    }
    
    @IBAction func onExerciseStartSaveButton() {
        showButton()
    }
    
}
