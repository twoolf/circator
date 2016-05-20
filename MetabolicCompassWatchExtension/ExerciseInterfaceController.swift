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
    @IBOutlet var exerPicker: WKInterfacePicker!
    @IBOutlet var group: WKInterfaceGroup!
    let duration = 1.2

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...180 {
            // 2
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "exercise\(i)")
            tempItems.append(item)
        }
        exerPicker.setItems(tempItems)
        
        //group.setBackgroundImageNamed("exercise0")
        //group.startAnimatingWithImagesInRange(NSMakeRange(0, 181), duration: duration, repeatCount: 1)
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