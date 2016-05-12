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

    @IBOutlet var group: WKInterfaceGroup!
    let duration = 1.2

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        group.setBackgroundImageNamed("exercise")
        group.startAnimatingWithImagesInRange(NSMakeRange(0, 181), duration: duration, repeatCount: 1)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }



}
