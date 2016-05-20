//
//  BrightButton.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class BrightButton: AppButton {

    var cornerRadius: CGFloat = 3 {
        didSet {
            self.roundCornersWithRadius(cornerRadius)
        }
    }

    var textColor = ScreenManager.sharedInstance.appBrightTextColor()
    var bgColor = ScreenManager.sharedInstance.appBrightBlueColor()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = bgColor
        
        self.setTitleColor(textColor, forState: .Normal)
        
        roundCornersWithRadius(cornerRadius)
    }
}
