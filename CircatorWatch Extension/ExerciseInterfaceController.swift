//
//  ExerciseController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation


class ExerciseInterfaceController: WKInterfaceController {

    @IBOutlet var hourPicker: WKInterfacePicker!
    @IBOutlet var EnterExerciseTimeButton: WKInterfaceButton!
    var time = 0
    let EXERCISE_INCREMENT = 10
    var hourItems: [WKPickerItem] = []
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        for i in 1 ... 16 {
            let pickerItem = WKPickerItem()
            pickerItem.title = String(i)
            hourItems.append(pickerItem)
        }
        hourPicker.setItems(hourItems)
        
        if(time != 0){
            hourPicker.setSelectedItemIndex(time - 1)
        } else {
            hourPicker.setSelectedItemIndex(0);
        }
        //updateConfiguration()
        // Configure interface objects here.
    }
    
    @IBAction func onTimeChanged(value: Int) {
        time = value + 1
        
        print(value)
    }
    
    
    override func willActivate() {
        
        
        super.willActivate()
    }
    
    
    /*@IBAction func onPlusButton() {
        time = time + EXERCISE_INCREMENT
        updateConfiguration()
        
    }
    
    @IBAction func onMinusButton() {
        if(time == 0) {
            updateConfiguration()
        } else{
            time = time - EXERCISE_INCREMENT
            updateConfiguration()
        }
    }*/
    
    func updateConfiguration() {
        
    }
    
    @IBAction func onEnterButton() {
        //send time to healthKit and reset time to 0.00
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }


}
