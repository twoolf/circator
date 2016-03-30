//
//  WaterInterfaceController.swift
//  Circator
//
//  Created by Mariano on 3/30/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation


class WaterInterfaceController: WKInterfaceController {

    @IBOutlet var minusButton: WKInterfaceButton!
    @IBOutlet var plusButton: WKInterfaceButton!
    @IBOutlet var waterLabel: WKInterfaceLabel!
    @IBOutlet var enterButton: WKInterfaceButton!
    var cups = 0.00
        
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
        cups++
        updateConfiguration()
            
    }
        
    @IBAction func onMinusButton() {
        if(cups == 0) {
            updateConfiguration()
        } else{
            cups--
            updateConfiguration()
        }
    }
        
    func updateConfiguration() {
        waterLabel.setText("\(cups)")
    }
        
    @IBAction func onEnterButton() {
        //send time to healthKit and reset time to 0.00
    }
        
        
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
        


}
