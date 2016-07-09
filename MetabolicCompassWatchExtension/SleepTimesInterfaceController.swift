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

    var sleepStart = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        sleepTimesPicker.setItems(tempItems)
        sleepTimesPicker.setSelectedItemIndex((sleepTimesStruc.sleepEnd)-16)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton()    {
        let buttonColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)
        sleepTimesButton.setBackgroundColor(buttonColor)
        sleepTimesButton.setTitle("Saved")
        print("HKStore should be updated for Sleep")
        
// setting up conversion of saved value from 'waking from sleep' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var endDate = NSDate.today(inRegion: thisRegion)
        print("end date should be midnight of today: \(endDate)")
        let endComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: endDate)
        var timeConvertEnd:Int = 0
        var timeAddHalfHourEnd:Int = 0

        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if sleepTimesStruc.sleepEnd % 2 == 0 {
            print("\(sleepTimesStruc.sleepEnd) from sleep times 1st screen is even")
            _=0
            timeConvertEnd = ( (sleepTimesStruc.sleepEnd)/2 )
//            print("timeConvertStart: \(timeConvertStart)")
//            startDate = startDate + timeConvertStart.hours
//            print("new start date: \(startDate)")
        } else {
            print("\(sleepTimesStruc.sleepEnd) from sleep times 1st screen is odd")
            timeConvertEnd = ( (sleepTimesStruc.sleepEnd-1)/2 )
            timeAddHalfHourEnd=30
//            print("timeConvertStart: \(timeConvertStart)")
//            startDate = startDate + timeConvertStart.hours + 30.minutes
//            print("new start date: \(startDate)")
        }
        endComponents.hour = timeConvertEnd
        endComponents.minute = timeAddHalfHourEnd
        print("should have adjusted, hour and minute for endTime: \(timeConvertEnd)")
        print("    and \(timeAddHalfHourEnd)")
        endDate = calendar.dateFromComponents(endComponents)!
        print("new endDate based on first screen: \(endDate)")
  
// setting up values from current picker and getting 'beginning of sleep' ready
        var startDate = NSDate.today(inRegion: thisRegion)
        var timeConvertStart:Int = 0
        var timeAddHalfHourStart:Int = 0
        
        if sleepStart % 2 == 0 {
            print("\(sleepStart) from sleep 2nd screen is even")
            _=0
            timeConvertStart = ( (sleepStart)/2)
//            endDate = endDate + timeConvertEnd.hours
        } else {
            print("\(sleepStart) from sleep 2nd screen is odd")
            _=30
            timeConvertStart = ( (sleepStart-1)/2  )
            timeAddHalfHourStart=30
//            endDate = endDate + timeConvertEnd.hours + 30.minutes
        }
        
//        var endDate = NSDate().startOf(.Day, inRegion: Region())

        let startComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: startDate)
        startComponents.hour = timeConvertStart
        startComponents.minute = timeAddHalfHourStart
        startDate = calendar.dateFromComponents(startComponents)!
        
        print("should have end adjusted, hour and minute for start point: \(timeConvertStart)")
        print("    and \(timeAddHalfHourStart)")
        if startDate > endDate {
            startComponents.day = startComponents.day-1
            print("adjusted start day by one")
            startDate = calendar.dateFromComponents(startComponents)!
        }

        print("computing a startDate (2nd screen): \(startDate)")
        print("and an ending date of (1st screen): \(endDate)")
        
        let type = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let sample = HKCategorySample(type: type,
                                      value: HKCategoryValueSleepAnalysis.Asleep.rawValue,
                                      startDate: startDate,
                                      endDate: endDate,
                                      metadata:["Apple Watch Sleep Entry":"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(sample) { success, error in
        }
    }
    
    @IBAction func onButtonSave() {
        showButton()
    }
    
    @IBAction func onSleepTimePick(value: Int) {
        sleepStart = value
        print("in sleep picker for end: \(sleepStart)")
    }
}
