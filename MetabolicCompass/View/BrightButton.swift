//
//  BrightButton.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class BrightButton: UIButton {

    var textFont = ScreenManager.sharedInstance.appFontOfSize(17.0)
    var textColor = UIColor.whiteColor()
    var bgColor = ScreenManager.sharedInstance.appBrightBlueColor()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = bgColor
        
        self.setTitleColor(textColor, forState: .Normal)
        self.titleLabel?.font = textFont
    }
}