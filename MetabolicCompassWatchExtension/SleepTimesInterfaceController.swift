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
    func awakeWithContext(context: AnyObject?) {
        super.awake(withContext: context)
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
        
// setting up conversion of saved value from 'waking from sleep' in 1st screen
        let thisRegion = DateInRegion()
        let calendar = Calendar.current
        var beginDate = Date()
        var beginComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0

        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if sleepTimesStruc.sleepBegin % 2 == 0 {
            timeConvertBegin = ( (sleepTimesStruc.sleepBegin)/2 )

        } else {
            timeConvertBegin = ( (sleepTimesStruc.sleepBegin-1)/2 )
            timeAddHalfHourBegin=30
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        beginDate = calendar.date(from: beginComponents)!
//        beginDate = calendar.dateFromComponents(beginComponents)!
  
//        var closeDate = NSDate.today(inRegion: thisRegion)
        var closeDate = Date().endOfDay
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if sleepClose % 2 == 0 {
            timeConvertClose = ( (sleepClose)/2)
        } else {
            timeConvertClose = ( (sleepClose-1)/2  )
            timeAddHalfHourClose=30
        }
        
        var closeComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.date(from: closeComponents)!
//        closeDate = calendar.dateFromComponents(closeComponents)!
        
        if closeDate < beginDate {
            beginComponents.day = beginComponents.day!-1
            beginDate = calendar.date(from: beginComponents)!
//            beginDate = calendar.dateFromComponents(beginComponents)!
        }
        
        let type = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let sample = HKCategorySample(type: type,
                                      value: HKCategoryValueSleepAnalysis.asleep.rawValue,
                                      start: beginDate,
                                      end: closeDate,
                                      metadata:["Apple Watch Sleep Entry":"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.save(sample) { success, error in
        }
    }
    
    @IBAction func onButtonSave() {
        showButton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                self.popToRootController()
        }
    }
    
    @IBAction func onSleepTimePick(value: Int) {
        sleepClose = value
    }
}
