//
//  MealController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation


class MealInterfaceController: WKInterfaceController {
    
    @IBOutlet var MinusMealTimeButton: WKInterfaceButton!
    @IBOutlet var EnterMealTimeButton: WKInterfaceButton!
    @IBOutlet var PlusMealTimeButton: WKInterfaceButton!
    @IBOutlet var timeLabel: WKInterfaceLabel!
    var time = 0.00

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
        time = time + 5
        updateConfiguration()
        
    }
    
    @IBAction func onMinusButton() {
        if(time == 0) {
            updateConfiguration()
        } else{
            time = time - 5
            updateConfiguration()
        }
    }
    
    func updateConfiguration() {
        timeLabel.setText("\(time)")
    }

    @IBAction func onEnterButton() {
        //send time to healthKit and reset time to 0.00
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
