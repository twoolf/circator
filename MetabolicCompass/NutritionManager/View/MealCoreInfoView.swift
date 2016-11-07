//
//  MealCoreInfoView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class MealCoreInfoView: UIStackView {

    var meal : Meal! {
        didSet {
            self.updateUI()
        }
    }
    var itemCountLabel : UILabel!
    
    convenience init(meal : Meal) {
        self.init(frame: CGRect.zero)
        self.meal = meal
        self.configureView()
    }
    
    func configureView() {
        
        self.axis = .Vertical
        self.alignment = .Fill
        self.distribution = .FillProportionally
        
        self.itemCountLabel = UILabel()
        self.itemCountLabel.font = UIFont.systemFontOfSize(26, weight: UIFontWeightThin)
        self.itemCountLabel.lineBreakMode = .ByTruncatingTail
        
        self.addArrangedSubview(self.itemCountLabel)

        self.updateUI()
    }
    
    func updateUI() {
        
        let itemCountString = NSMutableAttributedString(string: "\(self.meal.items.count)", attributes: [NSForegroundColorAttributeName : UIColor.blueColor(), NSFontAttributeName: UIFont.systemFontOfSize(28, weight: UIFontWeightMedium)])
        
        if self.meal.items.count == 1 {
            itemCountString.appendAttributedString(NSAttributedString(string: " food in meal", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()]))
        } else {
            itemCountString.appendAttributedString(NSAttributedString(string: " foods in meal", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()]))
        }
        
        self.itemCountLabel.attributedText = itemCountString
    }
}
