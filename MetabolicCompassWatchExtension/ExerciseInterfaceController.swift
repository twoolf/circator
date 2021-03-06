//
//  ExerciseInterfaceController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//
import WatchKit
import Foundation

struct exerciseTypeVariable {
    var exerciseType: String
}
var exerciseTypebyButton = exerciseTypeVariable(exerciseType:"to be named")

class ExerciseInterfaceController: WKInterfaceController {
 
    
    @IBOutlet var runButton: WKInterfaceButton!
    @IBOutlet var cycleButton: WKInterfaceButton!
    @IBOutlet var swimButton: WKInterfaceButton!
    @IBOutlet var walkButton: WKInterfaceButton!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onRun() {
        exerciseTypebyButton.exerciseType = "Running"
        pushControllerWithName("ExerciseEndTimeController", context: self)
    }
    
    @IBAction func onCycle() {
        exerciseTypebyButton.exerciseType = "Cycling"
        pushControllerWithName("ExerciseEndTimeController", context: self)
    }
    
    @IBAction func onSwim() {
        exerciseTypebyButton.exerciseType = "Swimming"
        pushControllerWithName("ExerciseEndTimeController", context: self)
    }

    @IBAction func onWalk() {
        exerciseTypebyButton.exerciseType = "Walking"
        pushControllerWithName("ExerciseEndTimeController", context: self)
    }
    
}

