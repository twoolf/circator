//
//  FoodItemCoreInfoView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/21/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class FoodItemCoreInfoView: UIStackView {
    
    var item : FoodItem!
    
    convenience init(foodItem item : FoodItem) {
        self.init(frame: CGRect.zero)
        self.item = item
        self.configureView()
    }
    
    func configureView() {
        
        self.axis = .Vertical
        self.alignment = .Fill
        self.distribution = .FillProportionally
        
        let itemNameLabel = UILabel()
        itemNameLabel.text = self.item.name
        itemNameLabel.font = UIFont.systemFontOfSize(26, weight: UIFontWeightThin)
        itemNameLabel.lineBreakMode = .ByTruncatingTail
        
        self.addArrangedSubview(itemNameLabel)
        
        if let unit = self.item.servingSizeUnit {
            let itemServingLabel = UILabel()
            
            print(self.item.servingQuantity)
            
            itemServingLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
            itemServingLabel.lineBreakMode = .ByTruncatingTail
            
            itemServingLabel.text = "\(self.item.servingQuantity) \(unit)"
            
            self.addArrangedSubview(itemServingLabel)
        }
        
    }
}
