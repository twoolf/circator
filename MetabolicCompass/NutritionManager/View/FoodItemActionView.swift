//
//  FoodItemActionView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/30/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class FoodItemActionView : UIPresentSubview {
    
    var foodItem : FoodItem!
    var proceedToAction : (Void->Void)?
    var proceedToActionButton : UIButton!
    
    convenience init(foodItem: FoodItem) {
        self.init(frame: CGRect.zero)
        self.foodItem = foodItem
        self.configureView()
    }
    
    func configureView() {
        
        self.proceedToActionButton = {
            let button = UIButton()
            button.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.clipsToBounds = true
            button.addTarget(self, action: #selector(FoodItemActionView.proceedToAction(_:)), forControlEvents: .TouchUpInside)
            button.setTitle("Add to...", forState: .Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(24, weight: UIFontWeightMedium)
            
            return button
        }()
        
        self.addSubview(self.proceedToActionButton)
        
        let proceedToActionButtonConstraints : [NSLayoutConstraint] = [
            self.proceedToActionButton.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            self.proceedToActionButton.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            self.proceedToActionButton.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor),
            self.proceedToActionButton.heightAnchor.constraintEqualToConstant(60)
        ]
        
        self.addConstraints(proceedToActionButtonConstraints)
        
        let foodItemView = UIViewWithBlurredBackground(view: FoodItemSummaryView(foodItem: self.foodItem), withBlurEffectStyle: .Light)
        
        foodItemView.translatesAutoresizingMaskIntoConstraints = false
        foodItemView.clipsToBounds = true
        foodItemView.layer.cornerRadius = 15
        foodItemView.layer.shadowColor = UIColor.blackColor().CGColor
        foodItemView.layer.shadowRadius = 15
        foodItemView.layer.shadowOffset = CGSize.zero
        foodItemView.layer.shadowOpacity = 0.5
        
        self.addSubview(foodItemView)
        
        let foodItemViewConstraints : [NSLayoutConstraint] = [
            foodItemView.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            foodItemView.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            foodItemView.topAnchor.constraintEqualToAnchor(self.topAnchor),
            foodItemView.bottomAnchor.constraintEqualToAnchor(self.proceedToActionButton.topAnchor, constant: -15)
        ]
        
        self.addConstraints(foodItemViewConstraints)
    }
    
    func proceedToAction(sender: AnyObject) {
        
        self.proceedToAction?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.proceedToActionButton.layer.cornerRadius = self.proceedToActionButton.bounds.height/2
    }
}