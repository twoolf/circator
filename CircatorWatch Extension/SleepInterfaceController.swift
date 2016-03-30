//
//  SleepInterfaceController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation


class SleepInterfaceController: WKInterfaceController {

    
    @IBOutlet var minusSleepTime: WKInterfaceButton!
    @IBOutlet var plusSleepTime: WKInterfaceButton!
    @IBOutlet var EnterSleepTimeButton: WKInterfaceButton!
    @IBOutlet var timeLabel: WKInterfaceLabel!
    var sleepTime = 0.00
    let SLEEP_HOUR_INCREMENT = 00.25
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        updateConfiguration()
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    
    @IBAction func onPlusButton() {
        sleepTime = sleepTime + SLEEP_HOUR_INCREMENT
        updateConfiguration()
        
    }
    
    @IBAction func onMinusButton() {
        if(sleepTime == 0) {
            updateConfiguration()
        } else{
            sleepTime = sleepTime - SLEEP_HOUR_INCREMENT
            updateConfiguration()
        }
    }
    
    func updateConfiguration() {
        let timeString = NSString(format: "%.2f", sleepTime)
       
        timeLabel.setText(timeString as String)
    }
    @IBAction func onEnterButton() {
        //send time to healthKit and reset time to 0.00
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
