//
//  SleepInterfaceController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

// note: logic is to have first entry be the 'end' time (sleep wake) and
//          then second screen is the 'start' of sleep (sleep began)

import WatchKit
import Foundation
import HealthKit
import SwiftDate

struct sleepTimesVariables {
    var sleepEnd: Int
}
var sleepTimesStruc = sleepTimesVariables(sleepEnd:2)

class SleepInterfaceController: WKInterfaceController {
    
    @IBOutlet var enterButton: WKInterfaceButton!
    @IBOutlet var sleepPicker: WKInterfacePicker!

    var sleep = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...47 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Sleep\(i)")
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
        sleepPicker.setItems(tempItems)
        sleepPicker.setSelectedItemIndex(endTimePointer)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onSleepEntry(value: Int) {
        sleep = value
    }
    @IBAction func sleepSaveButton() {
        sleepTimesStruc.sleepEnd = sleep
        print("Wake from Sleep: and variable --")
        print(sleepTimesStruc.sleepEnd)
        pushControllerWithName("SleepTimesInterfaceController", context: self)
    }
    }



