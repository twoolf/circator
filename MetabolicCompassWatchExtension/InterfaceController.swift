//
//  InterfaceController.swift
//  MetabolicCompassWatchExtension
//
//  Created by Sihao Lu on 10/29/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import HealthKit

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var table: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var theContext = context
        if context == nil {
            theContext = NSUserDefaults.standardUserDefaults().objectForKey("context")
        }
        guard let contextDict = theContext?["context"], info = contextDict as? [[String: String]] else {
            return
        }
        updateBioPreviewTableWithContext(info)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateBioPreviewTableWithContext(context: [[String: String]]) {
        table.setNumberOfRows(context.count, withRowType: "BioPreviewCell")
        /*
        for (i, info) in context.enumerate() {
            let row = table.rowControllerAtIndex(i) as! BioPreviewRow
            let imageName: String?
            switch info["sampleTypeIdentifier"]! {
            case HKQuantityTypeIdentifierBodyMass:
                imageName = "icon_weight"
            case HKQuantityTypeIdentifierHeartRate:
                imageName = "icon_heart_rate"
            case HKCategoryTypeIdentifierSleepAnalysis:
                imageName = "icon_sleep"
            case HKQuantityTypeIdentifierDietaryEnergyConsumed:
                imageName = "icon_food"
            case HKCorrelationTypeIdentifierBloodPressure:
                imageName = "icon_blood_pressure"
            default:
                imageName = nil
            }
//            row.icon.setImageNamed(imageName)
//            row.sampleTypeLabel.setText(info["displaySampleType"]!)
//            row.valueLabel.setText(info["value"]!)
        }
        */
    }

}
