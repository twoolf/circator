//
//  ExerciseEndTimeController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//


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
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        exerciseEndTimeButton.setTitle("Begin \(exerciseTypebyButton.exerciseType) ")
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        exerciseEndTimePicker.setItems(tempItems)
        
        _ = DateInRegion()
        var beginTimePointer = 24
        let calendar = Calendar.current
        let beginDate = Date()
//        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        let beginComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beginDate)
        if beginComponents.minute! < 15 {
            beginTimePointer = 2*beginComponents.hour!
        } else {
            beginTimePointer = 2*beginComponents.hour! + 1
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
        pushController(withName: "ExerciseStartTimeController", context: self)
    }
}