//
//  WaterInterfaceController.swift
//  Circator
//
//  Created by Mariano on 3/30/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

struct waterAmountVariable {
    var waterAmount: Double
}
var waterEnterButton = waterAmountVariable(waterAmount:250.0)

class WaterInterfaceController: WKInterfaceController {
    
    @IBOutlet var waterPicker: WKInterfacePicker!
    @IBOutlet var EnterButton: WKInterfaceButton!
    
    var water = 0.0
    let healthKitStore:HKHealthStore = HKHealthStore()
    let healthManager:HealthManager = HealthManager()
    
    func awakeWithContext(context: AnyObject?) {
        super.awake(withContext: context)
        var tempItems: [WKPickerItem] = []
        for i in 0...8 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "WaterInCups\(i)")
            tempItems.append(item)
        }
        waterPicker.setItems(tempItems)
        waterPicker.setSelectedItemIndex(2)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onWaterEntry(value: Int) {
        water = Double(value)*250
    }
    @IBAction func waterSaveButton() {
        waterEnterButton.waterAmount = water
        pushController(withName: "WaterTimesInterfaceController", context: self)
    }
    
    
}

