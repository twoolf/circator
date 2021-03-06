//
//  MealStartTimeController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import SwiftDate

class MealStartTimeController: WKInterfaceController {
    
    @IBOutlet var mealStartTimePicker: WKInterfacePicker!
    @IBOutlet var mealStartTimeButton: WKInterfaceButton!
    
    var mealClose = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        mealStartTimeButton.setTitle("Ended \(mealTypebyButton.mealType)")
        var tempItems: [WKPickerItem] = []
        for i in 0...146 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "byTen\(i)")
            tempItems.append(item)
        }
        mealStartTimePicker.setItems(tempItems)
        mealStartTimePicker.setSelectedItemIndex((mealTimesStruc.mealBegin)+3)
    }
    
    func onMealTimeChanged() {
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton()    {
        let buttonColor = UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 0.5)
        mealStartTimeButton.setBackgroundColor(buttonColor)
        mealStartTimeButton.setTitle("Saved")
        
        // setting up conversion of saved value from 'waking from sleep' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate.today(inRegion: thisRegion)
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddToBegin:Int = 0
        
        // note: imageset (0-146) is keyed into 24-hour schedule
        //  so 0=midnight, 6=1AM, 12=2AM etc
        if mealTimesStruc.mealBegin % 6 == 0 {
            timeConvertBegin = ( (mealTimesStruc.mealBegin)/6 )
            timeAddToBegin=0
        } else if (mealTimesStruc.mealBegin-1) % 6 == 0 {
            timeConvertBegin = ( (mealTimesStruc.mealBegin-1)/6 )
            timeAddToBegin=10
        }
        else if (mealTimesStruc.mealBegin-2) % 6 == 0 {
            timeConvertBegin = ( (mealTimesStruc.mealBegin-2)/6 )
            timeAddToBegin=20
        }
        else if (mealTimesStruc.mealBegin-3) % 6 == 0 {
            timeConvertBegin = ( (mealTimesStruc.mealBegin-3)/6 )
            timeAddToBegin=30
        }
        else if (mealTimesStruc.mealBegin-4) % 6 == 0 {
            timeConvertBegin = ( (mealTimesStruc.mealBegin-4)/6 )
            timeAddToBegin=40
        }
        else if (mealTimesStruc.mealBegin-5) % 6 == 0 {
            timeConvertBegin = ( (mealTimesStruc.mealBegin-5)/6 )
            timeAddToBegin=50
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddToBegin
        beginDate = calendar.dateFromComponents(beginComponents)!
        
        // setting up values from current picker and getting 'beginning of sleep' ready
        var closeDate = NSDate.today(inRegion: thisRegion)
        var timeConvertClose:Int = 0
        var timeAddToClose:Int = 0
        
        if mealClose % 6 == 0 {
            timeConvertClose = ( (mealClose)/6)
            timeAddToClose = 0
        } else if (mealClose-1) % 6 == 0 {
            timeConvertClose = ( (mealClose-1)/6  )
            timeAddToClose=10
        }
        else if (mealClose-2) % 6 == 0 {
            timeConvertClose = ( (mealClose-2)/6  )
            timeAddToClose=20
        }
        else if (mealClose-3) % 6 == 0 {
            timeConvertClose = ( (mealClose-3)/6  )
            timeAddToClose=30
        }
        else if (mealClose-4) % 6 == 0 {
            timeConvertClose = ( (mealClose-4)/6  )
            timeAddToClose=40
        }
        else if (mealClose-5) % 6 == 0 {
            timeConvertClose = ( (mealClose-5)/6  )
            timeAddToClose=50
        }
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddToClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        if closeDate < beginDate {
            closeComponents.day = closeComponents.day-1
            closeDate = calendar.dateFromComponents(closeComponents)!
        }
        
        let mealDurationHours = beginComponents.hour - closeComponents.hour
        let mealDurationMinutes = beginComponents.minute - closeComponents.minute
        let mealDurationTime = mealDurationHours*60+mealDurationMinutes
        
        let workout = HKWorkout(activityType:
            .PreparationAndRecovery,
                                startDate: beginDate,
                                endDate: closeDate,
                                duration: Double(mealDurationTime)*60,
                                totalEnergyBurned: HKQuantity(unit:HKUnit.calorieUnit(), doubleValue:0.0),
                                totalDistance: HKQuantity(unit:HKUnit.meterUnit(), doubleValue:0.0),
                                device: HKDevice.localDevice(),
                                metadata: [mealTypebyButton.mealType:"source"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(workout) { success, error in
        }
    }
    
    @IBAction func onMealEntry(value: Int) {
        mealClose = value
    }
    
    @IBAction func mealSaveButton() {
        showButton()
        dispatch_after(3,
            dispatch_get_main_queue()){
              self.popToRootController()
        }
    }
    
}
