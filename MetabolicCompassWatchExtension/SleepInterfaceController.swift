//
//  SleepInterfaceController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class SleepInterfaceController: WKInterfaceController {

    @IBOutlet var sleepPicker: WKInterfacePicker!
    @IBOutlet var enterButton: WKInterfaceButton!

    var sleep = 0.0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...14 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "sleep_radial\(i)")
            tempItems.append(item)
        }
        sleepPicker.setItems(tempItems)
    }

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
 
// note: right now picker menu is a duration, rather than a start/end date range
    func showButton()    {
        enterButton.setTitle("Saved")
        print("HKStore should be updated for Sleep")
        let type = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let sample = HKCategorySample(type: type,
                                      value: HKCategoryValueSleepAnalysis.Asleep.rawValue,
                                      startDate: NSDate(),
                                      endDate: NSDate(),
                                      metadata:["Apple Watch Sleep Entry":"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(sample) { success, error in
        }
    }
    
    @IBAction func onSleepEntry(value: Int) {
        sleep = Double(value) + 1
    }
    @IBAction func sleepSaveButton() {
        showButton()
    }

}

