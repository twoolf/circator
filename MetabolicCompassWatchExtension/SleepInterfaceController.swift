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

    @IBOutlet var sleepPicker: WKInterfacePicker!
    @IBOutlet var enterButton: WKInterfaceButton!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        var tempItems: [WKPickerItem] = []
        for i in 0...4 {
            // 2
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "sleep_radial\(i)")
            tempItems.append(item)
        }
        sleepPicker.setItems(tempItems)

        //group.setBackgroundImageNamed("meal")
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
