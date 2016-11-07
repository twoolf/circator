//
//  MealBuilderViewController.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 8/2/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class MealBuilderViewController : UIViewController, ConfigurableStatusBar {
    
    let addFoodItemViewController = AddFoodItemViewController()
    let mealBuilderView = MealBuilderView()
    var meal : Meal = Meal()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        
    }
    
    private func configureView() {
        
        self.view.backgroundColor = UIColor.blackColor()
        
        self.mealBuilderView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.mealBuilderView)
        
        let mealBuilderViewConstraints : [NSLayoutConstraint] = [
            self.mealBuilderView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
            self.mealBuilderView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor),
            self.mealBuilderView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor),
            self.mealBuilderView.heightAnchor.constraintEqualToConstant(UIScreen.mainScreen().bounds.height * (1/7))
        ]
        
        self.view.addConstraints(mealBuilderViewConstraints)
        
        //lays out builder view such that its exact height can be referenced in next layout
        self.view.layoutIfNeeded()
        
        self.addChildViewController(self.addFoodItemViewController)
        
        let addFoodItemView = self.addFoodItemViewController.view
        addFoodItemView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(addFoodItemView)
        
        let addFoodItemViewConstraints : [NSLayoutConstraint] = [
            addFoodItemView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            addFoodItemView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
            addFoodItemView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor),
            addFoodItemView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor, constant: -self.mealBuilderView.bounds.height)
        ]
        
        self.view.addConstraints(addFoodItemViewConstraints)
        
        
        let statusBarBacking = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        statusBarBacking.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(statusBarBacking)
        
        self.view.bringSubviewToFront(self.mealBuilderView)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MealBuilderViewController.untoggleBuilderView(_:))))
    }
    
    func untoggleBuilderView(sender: AnyObject) {
        if self.mealBuilderView.isToggled {
            self.mealBuilderView.didToggleView()
        }
    }
    
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
