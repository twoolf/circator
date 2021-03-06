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
        
        // setting up conversion of saved value from 'finished drinking' in 1st screen
        let thisRegion = DateRegion()
        let calendar = NSCalendar.currentCalendar()
        var beginDate = NSDate.today(inRegion: thisRegion)
        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        var timeConvertBegin:Int = 0
        var timeAddHalfHourBegin:Int = 0
        
        // note: imageset (0-47) is keyed into 24-hour schedule
        //  so 0=midnight, 2=1AM, 4=2AM, etc
        if waterBeginTimeSelected.waterBegin % 2 == 0 {
            _=0
            timeConvertBegin = ( (waterBeginTimeSelected.waterBegin)/2 )
        } else {
            timeConvertBegin = ( (waterBeginTimeSelected.waterBegin-1)/2 )
            timeAddHalfHourBegin=30
        }
        beginComponents.hour = timeConvertBegin
        beginComponents.minute = timeAddHalfHourBegin
        beginDate = calendar.dateFromComponents(beginComponents)!
        
        // setting up values from current picker and getting 'beginning of water' ready
        var closeDate = NSDate.today(inRegion: thisRegion)
        var timeConvertClose:Int = 0
        var timeAddHalfHourClose:Int = 0
        
        if waterClose % 2 == 0 {
            _=0
            timeConvertClose = ( (waterClose)/2)
        } else {
            _=30
            timeConvertClose = ( (waterClose-1)/2  )
            timeAddHalfHourClose=30
        }
        
        let closeComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: closeDate)
        closeComponents.hour = timeConvertClose
        closeComponents.minute = timeAddHalfHourClose
        closeDate = calendar.dateFromComponents(closeComponents)!
    
        if closeDate < beginDate {
            closeComponents.day = closeComponents.day-1
            closeDate = calendar.dateFromComponents(closeComponents)!
        }
        
        let waterDurationHours = beginComponents.hour - closeComponents.hour
        let waterDurationMinutes = beginComponents.minute - closeComponents.minute
        let waterDurationTime = waterDurationHours*60+waterDurationMinutes
        
        if (closeDate<beginDate){
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
    }
    
    @IBAction func onWaterStartTimeButton() {
        showButton()
        dispatch_after(3,
                       dispatch_get_main_queue()){
                        self.popToRootController()
        }
    }

}
