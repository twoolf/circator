//
//  ExerciseEndTimeController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

// similar to Sleep pickers, the first screen is set by time of day and determines
//   the 'end point' while the 2nd screen is used to set the start of the eating event

import WatchKit
import Foundation
import HealthKit
import SwiftDate

struct exerciseTimeVariable {
    var exerciseBegin: Int
}
var exerciseTimeStruc = exerciseTimeVariable(exerciseBegin:36)

class ExerciseEndTimeController: WKInterfaceController {
    
    @IBOutlet var exerciseEndTimePicker: WKInterfacePicker!
    @IBOutlet var exerciseEndTimeButton: WKInterfaceButton!
    
    var exerciseBeginTime = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        exerciseEndTimeButton.setTitle("Begin \(exerciseTypebyButton.exerciseType) ")
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        exerciseEndTimePicker.setItems(tempItems)
        
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
        exerciseEndTimePicker.setSelectedItemIndex(beginTimePointer-2)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    
    @IBAction func onExerciseStartTime(value: Int) {
        exerciseBeginTime = value
    }
    
    @IBAction func onExerciseStartTimeSave() {
        exerciseTimeStruc.exerciseBegin = exerciseBeginTime
//        print("Begin of exercise time: and variable --")
//        print(exerciseTimeStruc.exerciseBegin)
        pushControllerWithName("ExerciseStartTimeController", context: self)
    }
}
