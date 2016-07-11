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
    
    var waterClose = 0
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }
        waterTimeStart.setItems(tempItems)
        waterTimeStart.setSelectedItemIndex(waterBeginTimeSelected.waterBegin+1)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func showButton() {
        let buttonColor = UIColor(red: 0.0, green: 0.18, blue: 0.45, alpha: 0.5)
        waterTimesEnterStart.setBackgroundColor(buttonColor)
        waterTimesEnterStart.setTitle("Saved")
        print("HKStore should be updated for Water")
        
        // setting up conversion of saved value from 'finished drinking' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate.today(inRegion: thisRegion)
        print("begin date should be midnight of today: \(beginDate)")
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if waterBeginTimeSelected.waterBegin % 2 == 0 {
            print("\(waterBeginTimeSelected.waterBegin) from water times 1st screen is even")
            _=0
            timeConvertBegin = ( (waterBeginTimeSelected.waterBegin)/2 )
        } else {
            print("\(waterBeginTimeSelected.waterBegin) from water times 1st screen is odd")
            timeConvertBegin = ( (waterBeginTimeSelected.waterBegin-1)/2 )
            timeAddHalfHourBegin=30
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        print("should have adjusted, hour and minute for beginTime: \(timeConvertBegin)")
        print("    and \(timeAddHalfHourBegin)")
        beginDate = calendar.dateFromComponents(beginComponents)!
        print("new beginDate based on first screen: \(beginDate)")
        
        // setting up values from current picker and getting 'beginning of water' ready
        var closeDate = NSDate.today(inRegion: thisRegion)
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if waterClose % 2 == 0 {
            print("\(waterClose) from water 2nd screen is even")
            _=0
            timeConvertClose = ( (waterClose)/2)
        } else {
            print("\(waterClose) from water 2nd screen is odd")
            _=30
            timeConvertClose = ( (waterClose-1)/2  )
            timeAddHalfHourClose=30
        }
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
        
        print("should have end adjusted, hour and minute for close point: \(timeConvertClose)")
        print("    and \(timeAddHalfHourClose)")
        if closeDate > beginDate {
            closeComponents.day = closeComponents.day-1
            print("adjusted close day by one")
            closeDate = calendar.dateFromComponents(closeComponents)!
        }
        
        print("computing a closeDate (2nd screen): \(closeDate)")
        print("and an beginning date of (1st screen): \(beginDate)")
        
        let waterDurationHours = beginComponents.hour - closeComponents.hour
        let waterDurationMinutes = beginComponents.minute - closeComponents.minute
        let waterDurationTime = waterDurationHours*60+waterDurationMinutes
        
        if (closeDate<beginDate){
            print("logic error on beginDate not earlier than closeDate")
            closeDate=closeDate + 1.hours
        }
        
        let sample = HKQuantitySample(type: HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!,
                                      quantity: HKQuantity.init(unit: HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli), doubleValue: waterEnterButton.waterAmount),
                                      startDate: beginDate,
                                      endDate: closeDate,
                                      metadata:["Apple Watch" : "water entry"])
        let healthKitStore:HKHealthStore = HKHealthStore()
        healthKitStore.saveObject(sample) { success, error in
        }
    }
    
    @IBAction func onWaterStartTimePicker(value: Int) {
        waterClose = value
        print("in 2nd water picker")
        print(waterClose)
    }
    
    @IBAction func onWaterStartTimeButton() {
        showButton()
    }

}
