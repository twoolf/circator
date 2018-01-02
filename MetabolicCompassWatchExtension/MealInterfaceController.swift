//
//  MealController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//


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
    override func awake(withContext context: Any?){
        super.awake(withContext: context)
        enterButton.setTitle("Started \(mealTypebyButton.mealType)")
        var tempItems: [WKPickerItem] = []
        for i in 0...146 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "byTen\(i)")
            tempItems.append(item)
        }
        mealPicker.setItems(tempItems)
        
        _ = DateInRegion()
        var beginTimePointer = 24
        let calendar = Calendar.current
        let beginDate = Date()
        let beginComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beginDate)
        if beginComponents.minute! < 15 {
            beginTimePointer = 6 * beginComponents.hour!
        } else {
            beginTimePointer = 6 * beginComponents.hour! + 3
        }
        mealPicker.setSelectedItemIndex(beginTimePointer)
    }
    
    func onMealTimeChanged() {
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onMealEntry(value: Int) {
        mealTime = value
    }
    @IBAction func mealSaveButton() {
        mealTimesStruc.mealBegin = mealTime
        pushController(withName: "MealStartTimeController", context: self)
    }
}

