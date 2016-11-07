//
//  MealSummaryView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 8/3/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class MealSummaryView : UIView {
    
    var meal : Meal!
    
    convenience init(meal : Meal) {
        self.init(frame: CGRect.zero)
        self.meal = meal
        self.configureView()
    }
    
    func configureView() {
        
        let nutritionLabelView = NutritionLabelView(nutritionalContent: self.meal.nutrition)
        nutritionLabelView.scalesToFixedDimensions = false
        nutritionLabelView.translatesAutoresizingMaskIntoConstraints = false
        nutritionLabelView.clipsToBounds = true
        nutritionLabelView.layer.cornerRadius = 15
        nutritionLabelView.scrollView.scrollEnabled = true
        nutritionLabelView.userInteractionEnabled = true
        
        self.addSubview(nutritionLabelView)
        
        let nutritionLabelViewConstraints : [NSLayoutConstraint] = [
            nutritionLabelView.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            nutritionLabelView.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            nutritionLabelView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor),
            nutritionLabelView.topAnchor.constraintEqualToAnchor(self.topAnchor)
        ]
        
        self.addConstraints(nutritionLabelViewConstraints)
        
    }
    
}
