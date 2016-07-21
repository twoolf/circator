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
    var maxDailyFastingString:String = "need data"
    var currentFastingTimeString:String = "need data"
    var lastAteAsString:String = "no data"
    var proteinString:String = "ProteinAsString"
    var carbohydrateString:String = "carbs"
    var fatString:String = "fat"
    var stepsString:String = "stepsAsString"
    var heartRateString:String = "heartRateAsString"
    var firstRowString:String = "entry"
    var secondRowString:String = "2nd row"
    var thirdRowString:String = "3rd row long"
    var wokeFromSleep:String = "data needed"
    var finishedExerciseLast:String = "no data"
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    override func willActivate() {
        super.willActivate()
        print("new glance conditions")
        firstRow.setText("M-Compass Stats:")
        firstRow.setTextColor(UIColor.greenColor())
        maxDailyFastingString = "Fast: \(MetricsStore.sharedInstance.fastingTime)"
        secondRow.setText(maxDailyFastingString)
        currentFastingTimeString = "Current Fast: \(MetricsStore.sharedInstance.currentFastingTime)"
        lastAteAsString = "Last Ate: \(MetricsStore.sharedInstance.lastAte)"
        secondRow.setText(maxDailyFastingString)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        wokeFromSleep = "sleep:  " + dateFormatter.stringFromDate(MetricsStore.sharedInstance.Sleep)
        finishedExerciseLast = "exercise:   " + dateFormatter.stringFromDate(MetricsStore.sharedInstance.Exercise)
        weightString         = "     Lbs:    " + MetricsStore.sharedInstance.weight
        BMIString            = "     BMI:    " + MetricsStore.sharedInstance.BMI
        proteinString        = "     Prot:   " + MetricsStore.sharedInstance.Protein
        carbohydrateString   = "     Carb:   " + MetricsStore.sharedInstance.Carbohydrate
        fatString            = "     Fat:    " + MetricsStore.sharedInstance.Fat
        stepsString          = "     Steps:  " + MetricsStore.sharedInstance.StepCount
        thirdRowString =
            currentFastingTimeString + "\n" +
            wokeFromSleep + "\n" +
            finishedExerciseLast
        thirdRow.setText(thirdRowString)
        thirdRow.setTextColor(UIColor.blueColor())
        fourthRow.setText("")
        fourthRow.setTextColor(UIColor.yellowColor())
    }
}
