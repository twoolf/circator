//
//  WaterTimesInterfaceController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import WatchKit
import HealthKit
import SwiftDate

struct waterBeginTimeVariable {
    var waterBegin: Int
}

var waterBeginTimeSelected = waterBeginTimeVariable(waterBegin:2)

class WaterTimesInterfaceController: WKInterfaceController {
    
    @IBOutlet var waterTimes: WKInterfacePicker!
    @IBOutlet var waterTimesEnter: WKInterfaceButton!
    
    var waterBegin = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
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
        
        waterTimes.setItems(tempItems)
        waterTimes.setSelectedItemIndex(beginTimePointer-1)

    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onWaterTimePick(value: Int) {
        waterBegin = value
    }

    @IBAction func onWaterTimesEnter() {
        waterBeginTimeSelected.waterBegin = waterBegin
        pushControllerWithName("WaterStartTimeController", context: self)
    }
    
}
