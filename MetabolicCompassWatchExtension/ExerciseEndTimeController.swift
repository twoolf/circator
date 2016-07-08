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
    var exerciseEnd: Int
}
var exerciseTimeStruc = exerciseTimeVariable(exerciseEnd:36)

class ExerciseEndTimeController: WKInterfaceController {
    
    @IBOutlet var exerciseEndTimePicker: WKInterfacePicker!
    @IBOutlet var exerciseEndTimeButton: WKInterfaceButton!
    
    var exerciseEndTime = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...47 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Sleep\(i)")
            tempItems.append(item)
        }
        exerciseEndTimePicker.setItems(tempItems)
        
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
        exerciseEndTimePicker.setSelectedItemIndex(endTimePointer)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    
    @IBAction func onExerciseStartTime(value: Int) {
        exerciseEndTime = value
    }
    
    @IBAction func onExerciseStartTimeSave() {
        exerciseTimeStruc.exerciseEnd = exerciseEndTime
        print("End of exercise time: and variable --")
        print(exerciseTimeStruc.exerciseEnd)
        pushControllerWithName("ExerciseStartTimeController", context: self)
    }
}
