//
//  WaterTimesInterfaceController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//
// same logic as sleep: endTime is first, then startTime

import Foundation
import WatchKit
import HealthKit
import SwiftDate

struct waterEndTimeVariable {
    var waterEnd: Int
}

var waterEndTimeSelected = waterEndTimeVariable(waterEnd:2)

class WaterTimesInterfaceController: WKInterfaceController {
    
    @IBOutlet var waterTimes: WKInterfacePicker!
    @IBOutlet var waterTimesEnter: WKInterfaceButton!
    
    var waterEnd = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
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
        
        waterTimes.setItems(tempItems)
        waterTimes.setSelectedItemIndex(endTimePointer)

    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onWaterTimePick(value: Int) {
        waterEnd = value
        print("in water picker for end time")
        print(waterEnd)
    }

    @IBAction func onWaterTimesEnter() {
        waterEndTimeSelected.waterEnd = waterEnd
        pushControllerWithName("WaterStartTimeController", context: self)
    }
    
}
