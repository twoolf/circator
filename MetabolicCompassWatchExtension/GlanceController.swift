//
//  GlanceController.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class GlanceController: WKInterfaceController {
 
    @IBOutlet var firstRow: WKInterfaceLabel!
    @IBOutlet var secondRow: WKInterfaceLabel!
    @IBOutlet var thirdRow: WKInterfaceLabel!
    @IBOutlet var fourthRow: WKInterfaceLabel!

    var weightString:String = "150"
    var BMIString:String = "23.4"
    var maxDailyFastingString:String = "12.0"
    var proteinString:String = "ProteinAsString"
    var carbohydrateString:String = "carbs"
    var fatString:String = "fat"
    var stepsString:String = "stepsAsString"
    var heartRateString:String = "heartRateAsString"
    var firstRowString:String = "entry"
    var secondRowString:String = "2nd row"
    var thirdRowString:String = "3rd row long"
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    override func willActivate() {
        super.willActivate()
//        print("new glance conditions")
        firstRow.setText("M-Compass Stats:")
        firstRow.setTextColor(UIColor.greenColor())
        maxDailyFastingString = "Fast: \(MetricsStore.sharedInstance.fastingTime)"
        secondRow.setText(maxDailyFastingString)
        weightString         = "     Lbs:    " + MetricsStore.sharedInstance.weight
        BMIString            = "     BMI:    " + MetricsStore.sharedInstance.BMI
        proteinString        = "     Prot:   " + MetricsStore.sharedInstance.Protein
        carbohydrateString   = "     Carb:   " + MetricsStore.sharedInstance.Carbohydrate
        fatString            = "     Fat:    " + MetricsStore.sharedInstance.Fat
        stepsString          = "     Steps:  " + MetricsStore.sharedInstance.StepCount
        thirdRowString = weightString + "\n" +
            BMIString + "\n" +
            proteinString + "\n" +
            fatString + "\n" +
            carbohydrateString + "\n" +
            stepsString
        thirdRow.setText(thirdRowString)
        thirdRow.setTextColor(UIColor.blueColor())
        fourthRow.setText("")
        fourthRow.setTextColor(UIColor.yellowColor())
    }
}
