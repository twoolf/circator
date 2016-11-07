//
//  FoodItemBuilderViewController.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class FoodItemBuilderViewController: UIViewController, ConfigurableStatusBar {

    //status bar animation add-on
    var showStatusBar = true
    
    override func prefersStatusBarHidden() -> Bool {
        
        return !self.showStatusBar
        
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    func showStatusBar(enabled: Bool) {
        self.showStatusBar = enabled
        UIView.animateWithDuration(0.5, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
}
