//
//  UnBrightButton.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class UnBrightButton: BrightButton {

    override var bgColor: UIColor {
        get {
            return ScreenManager.sharedInstance.appGrayColor()
        }
        set {
            
        }
    }
    
}
