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

    func awakeWithContext(context: AnyObject?) {
        super.awake(withContext: context)
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
        _ = DateInRegion.self
        let calendar = Calendar.current
//        var beginDate = Date.today(inRegion: thisRegion)
        var beginDate = Date()
//        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
//        let beginComponents = calendar.dateComponents([.Year, .Month, .Day, .Hour, .Minute], from: beginDate) 
        var beginComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if exerciseTimeStruc.exerciseBegin % 2 == 0 {
            _=0
            timeConvertBegin = ( (exerciseTimeStruc.exerciseBegin)/2 )
        } else {
            timeConvertBegin = ( (exerciseTimeStruc.exerciseBegin-1)/2 )
            timeAddHalfHourBegin=30
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        beginDate = calendar.date(from: beginComponents)!
//        beginDate = calendar.dateFromComponents(beginComponents)!
//        var closeDate = Date.today(inRegion: thisRegion)
        var closeDate = Date.init()
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if exerciseClose % 2 == 0 {
            _=0
            timeConvertClose = ( (exerciseClose)/2)
        } else {
            _=30
            timeConvertClose = ( (exerciseClose-1)/2  )
            timeAddHalfHourClose=30
        }

        
        var closeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.date(from: closeComponents)!
//        closeDate = calendar.dateFromComponents(closeComponents)!
        
        if closeDate < beginDate {
            closeComponents.day = closeComponents.day!-1
            closeDate = calendar.date(from: closeComponents)!
//            closeDate = calendar.dateFromComponents(closeComponents)!
        }
        
        let exerciseDurationHours = beginComponents.hour! - closeComponents.hour!
        let exerciseDurationMinutes = beginComponents.minute! - closeComponents.minute!
        let exerciseDurationTime = exerciseDurationHours*60+exerciseDurationMinutes
        
        let workout = HKWorkout(activityType:
            .running,
                                start: beginDate,
                                end: closeDate,
                                duration: Double(exerciseDurationTime)*60,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorie(), doubleValue:0.0),
                                totalDistance: HKQuantity(unit:HKUnit.meter(), doubleValue:0.0),
                                device: HKDevice.local(),
                                metadata: [mealTypebyButton.mealType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.save(workout) { success, error in
        }
        
    }
    
    @IBAction func onExerciseStartPicker(value: Int) {
        exerciseClose = value
    }
    
    @IBAction func onExerciseStartSaveButton() {
        showButton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                self.popToRootController()
        }
    }
    
}
