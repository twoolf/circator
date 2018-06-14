//
//  WKInterfacePicker+Extensions.swift
//  MetabolicCompassWatch Extension
//
//  Created by Olearis on 6/14/18.
//  Copyright © 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import WatchKit

extension WKInterfacePicker {
    func setupForSleep() {
        var tempItems: [WKPickerItem] = []
        for i in 0...144 {
            let item : WKPickerItem = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i % 48)")
            tempItems.append(item)
        }
        self.setItems(tempItems)
    }
    
    func setUnwrappedSleepHalfHour(value: Int)  {
        self.setSelectedItemIndex(value + 48)
    }
    
    func wrappedSleepHalfHour(from unwrappedHalfHour: Int) -> Int {
        return unwrappedHalfHour % 48
    }
}
