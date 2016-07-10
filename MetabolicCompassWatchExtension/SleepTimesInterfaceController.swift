//
//  SleepTimesInterfaceController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/15/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

// note:   the logic is to use 'sleep end' from 1st screen and w/picker in
//         this screen to find 'sleep start' and then write to HealthKit
// remember as well that 'sleep end' needs to be adjusted, since it may or
//         may not reflect the current time

import Foundation
import WatchKit
import HealthKit
import SwiftDate

class SleepTimesInterfaceController: WKInterfaceController {
    
    @IBOutlet var sleepTimesPicker: WKInterfacePicker!
    @IBOutlet var sleepTimesButton: WKInterfaceButton!

    var sleepClose = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        sleepTimesPicker.setItems(tempItems)
        sleepTimesPicker.setSelectedItemIndex((sleepTimesStruc.sleepBegin)+16)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton()    {
        let buttonColor = UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 0.5)
        sleepTimesButton.setBackgroundColor(buttonColor)
        sleepTimesButton.setTitle("Saved")
        print("HKStore should be updated for Sleep")
        
// setting up conversion of saved value from 'waking from sleep' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate.today(inRegion: thisRegion)
        print("begin date should be midnight of today: \(beginDate)")
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0

        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if sleepTimesStruc.sleepBegin % 2 == 0 {
            print("\(sleepTimesStruc.sleepBegin) from sleep times 1st screen is even")
            _=0
            timeConvertBegin = ( (sleepTimesStruc.sleepBegin)/2 )

        } else {
            print("\(sleepTimesStruc.sleepBegin) from sleep times 1st screen is odd")
            timeConvertBegin = ( (sleepTimesStruc.sleepBegin-1)/2 )
            timeAddHalfHourBegin=30

        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        print("should have adjusted, hour and minute for beginTime: \(timeConvertBegin)")
        print("    and \(timeAddHalfHourBegin)")
        beginDate = calendar.dateFromComponents(beginComponents)!
        print("new beginDate based on first screen: \(beginDate)")
  
        var closeDate = NSDate.today(inRegion: thisRegion)
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if sleepClose % 2 == 0 {
            print("\(sleepClose) from sleep 2nd screen is even")
            _=0
            timeConvertClose = ( (sleepClose)/2)
        } else {
            print("\(sleepClose) from sleep 2nd screen is odd")
            _=30
            timeConvertClose = ( (sleepClose-1)/2  )
            timeAddHalfHourClose=30
        }
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        print("should have end adjusted, hour and minute for close point: \(timeConvertClose)")
        print("    and \(timeAddHalfHourClose)")
        if closeDate < beginDate {
            beginComponents.day = beginComponents.day-1
            print("adjusted begin day by one")
            beginDate = calendar.dateFromComponents(beginComponents)!
        }

        print("computing a closeDate (2nd screen): \(closeDate)")
        print("and an beginning date of (1st screen): \(beginDate)")
        
        let type = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let sample = HKCategorySample(type: type,
                                      value: HKCategoryValueSleepAnalysis.Asleep.rawValue,
                                      startDate: beginDate,
                                      endDate: closeDate,
                                      metadata:["Apple Watch Sleep Entry":"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(sample) { success, error in
        }
    }
    
    @IBAction func onButtonSave() {
        showButton()
    }
    
    @IBAction func onSleepTimePick(value: Int) {
        sleepClose = value
        print("in sleep picker for end: \(sleepClose)")
    }
}
