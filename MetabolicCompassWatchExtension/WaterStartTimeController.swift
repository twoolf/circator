//
//  WaterStartTimeController.swift
//  MetabolicCompass
//
//  Created by twoolf on 6/24/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import WatchKit
import HealthKit
import SwiftDate

class WaterStartTimeController: WKInterfaceController {
    
    @IBOutlet var waterTimeStart: WKInterfacePicker!
    @IBOutlet var waterTimesEnterStart: WKInterfaceButton!
    
    var waterStart = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...47 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Sleep\(i)")
            tempItems.append(item)
        }
        waterTimeStart.setItems(tempItems)
        waterTimeStart.setSelectedItemIndex(waterEndTimeSelected.waterEnd-2)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton() {
        let buttonColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)
        waterTimesEnterStart.setBackgroundColor(buttonColor)
        waterTimesEnterStart.setTitle("Saved")
        print("HKStore should be updated for Water")
        
        // setting up conversion of saved value from 'finished drinking' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var endDate = NSDate.today(inRegion: thisRegion)
        print("end date should be midnight of today: \(endDate)")
        let endComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: endDate)
        var timeConvertEnd:Int = 0
        var timeAddHalfHourEnd:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if waterEndTimeSelected.waterEnd % 2 == 0 {
            print("\(waterEndTimeSelected.waterEnd) from water times 1st screen is even")
            _=0
            timeConvertEnd = ( (waterEndTimeSelected.waterEnd)/2 )
        } else {
            print("\(waterEndTimeSelected.waterEnd) from water times 1st screen is odd")
            timeConvertEnd = ( (waterEndTimeSelected.waterEnd-1)/2 )
            timeAddHalfHourEnd=30
        }
        endComponents.hour = timeConvertEnd
        endComponents.minute = timeAddHalfHourEnd
        print("should have adjusted, hour and minute for endTime: \(timeConvertEnd)")
        print("    and \(timeAddHalfHourEnd)")
        endDate = calendar.dateFromComponents(endComponents)!
        print("new endDate based on first screen: \(endDate)")
        
        // setting up values from current picker and getting 'beginning of water' ready
        var startDate = NSDate.today(inRegion: thisRegion)
        var timeConvertStart:Int = 0
        var timeAddHalfHourStart:Int = 0
        
        if waterStart % 2 == 0 {
            print("\(waterStart) from water 2nd screen is even")
            _=0
            timeConvertStart = ( (waterStart)/2)
        } else {
            print("\(waterStart) from water 2nd screen is odd")
            _=30
            timeConvertStart = ( (waterStart-1)/2  )
            timeAddHalfHourStart=30
        }
        
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
        
        let waterDurationHours = endComponents.hour - startComponents.hour
        let waterDurationMinutes = endComponents.minute - startComponents.minute
        let waterDurationTime = waterDurationHours*60+waterDurationMinutes
        
        if (startDate>endDate){
            print("logic error on startDate not earlier than endDate")
            startDate=endDate - 1.hours
        }
        
        let sample = HKQuantitySample(type: HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                                      quantity: HKQuantity.init(unit: HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli), doubleValue: waterEnterButton.waterAmount),
                                      startDate: startDate,
                                      endDate: endDate,
                                      metadata:["Apple Watch" : "water entry"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(sample) { success, error in
        }
    }
    
    @IBAction func onWaterStartTimePicker(value: Int) {
        waterStart = value
        print("in 2nd water picker")
        print(waterStart)
    }
    
    @IBAction func onWaterStartTimeButton() {
        showButton()
    }

}
