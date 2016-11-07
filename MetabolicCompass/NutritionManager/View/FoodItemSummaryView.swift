//
//  FoodItemSummaryView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/30/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class FoodItemSummaryView : UIView {
    
    var item : FoodItem!
    
    convenience init(foodItem item : FoodItem) {
        self.init(frame: CGRect.zero)
        self.item = item
        self.configureView()
    }
    
    func configureView() {
        
        
        let nutritionLabelView = NutritionLabelView(nutritionalContent: self.item.nutrition)
        nutritionLabelView.scalesToFixedDimensions = false
        nutritionLabelView.translatesAutoresizingMaskIntoConstraints = false
        nutritionLabelView.clipsToBounds = true
        nutritionLabelView.layer.cornerRadius = 15
        nutritionLabelView.scrollView.scrollEnabled = true
        nutritionLabelView.userInteractionEnabled = true
        
        self.addSubview(nutritionLabelView)
        
        let nutritionLabelViewConstraints : [NSLayoutConstraint] = [
            nutritionLabelView.leftAnchor.constraintEqualToAnchor(self.leftAnchor, constant: 7.5),
            nutritionLabelView.rightAnchor.constraintEqualToAnchor(self.rightAnchor, constant: -7.5),
            nutritionLabelView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -7.5),
            nutritionLabelView.topAnchor.constraintEqualToAnchor(self.topAnchor, constant: 90)
        ]
        
        self.addConstraints(nutritionLabelViewConstraints)
        
        let foodItemCoreInfoView = FoodItemCoreInfoView(foodItem: self.item)
        foodItemCoreInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(foodItemCoreInfoView)
        
        let foodItemCoreInfoViewConstraints : [NSLayoutConstraint] = [
            foodItemCoreInfoView.topAnchor.constraintEqualToAnchor(self.topAnchor, constant: 15),
            foodItemCoreInfoView.leftAnchor.constraintEqualToAnchor(self.leftAnchor, constant: 15),
            foodItemCoreInfoView.rightAnchor.constraintEqualToAnchor(self.rightAnchor, constant: -15),
            foodItemCoreInfoView.bottomAnchor.constraintEqualToAnchor(nutritionLabelView.topAnchor, constant: -15)
        ]
        
        self.addConstraints(foodItemCoreInfoViewConstraints)
        
    }
}
