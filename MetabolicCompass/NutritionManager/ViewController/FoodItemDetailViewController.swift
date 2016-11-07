//
//  FoodItemDetailViewController.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit
import WebKit

class FoodItemDetailViewController: UIViewController, UIWebViewDelegate {
    
    var foodItem : FoodItem!
    var nutritionFactsView : NutritionLabelView!
    
    init(foodItem item : FoodItem) {
        self.foodItem = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    private func configureView() {
        
        self.nutritionFactsView = NutritionLabelView(nutritionalContent: self.foodItem.nutrition)
        self.nutritionFactsView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.nutritionFactsView)
        
        let nutritionFactsViewContraints : [NSLayoutConstraint] = [
            self.nutritionFactsView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor, constant: 15),
            self.nutritionFactsView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor, constant: 15),
            self.nutritionFactsView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor, constant: -15)
        ]
        
        self.view.addConstraints(nutritionFactsViewContraints)
        
    }
}
