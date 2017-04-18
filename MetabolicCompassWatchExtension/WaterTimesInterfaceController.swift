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
    func awakeWithContext(context: AnyObject?) {
        super.awake(withContext: context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        let thisRegion = DateInRegion()
        var beginTimePointer = 24
        let calendar = Calendar.current
        var beginDate = Date()
        let beginComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beginDate)
        if beginComponents.minute! < 15 {
            beginTimePointer = 2*beginComponents.hour!
        } else {
            beginTimePointer = 2*beginComponents.hour! + 1
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
        pushController(withName: "WaterStartTimeController", context: self)
    }
    
}
