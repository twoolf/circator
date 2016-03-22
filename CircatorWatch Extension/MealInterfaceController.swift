//
//  MealController.swift
//  Circator
//
//  Created by Mariano on 3/2/16.
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
        time++
        updateConfiguration()
        
    }
    
    @IBAction func onMinusButton() {
        if(time == 0) {
            updateConfiguration()
        } else{
            time--
            updateConfiguration()
        }
    }
    
    func updateConfiguration() {
        timeLabel.setText("\(time)")
    }

    @IBAction func onEnterButton() {
        
    }
    
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
