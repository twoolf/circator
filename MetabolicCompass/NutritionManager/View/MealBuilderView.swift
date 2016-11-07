//
//  MealBuilderView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 8/2/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class MealBuilderView : UIView {
        
    var meal : Meal = Meal()
    var isToggled : Bool = false
    var isToggledView = UIImageView(image: UIImage(named: "arrow-chevron-white"))
    var summaryView : UIView!
    var detailView : UIView!
    var summaryViewToggledConstraint : NSLayoutConstraint!
    var summaryViewUntoggledConstraint : NSLayoutConstraint!
    var superHeightConstraint : NSLayoutConstraint?

    convenience init() {
        self.init(frame: CGRect.zero)
        self.configureView()
    }
    
    func configureView() {
        
        self.backgroundColor = UIColor.lightGrayColor()
        
        let edgeBar = UIView()
        edgeBar.backgroundColor = UIColor.darkGrayColor()
        edgeBar.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(edgeBar)
        
        let edgeBarConstraints : [NSLayoutConstraint] = [
            edgeBar.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            edgeBar.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            edgeBar.topAnchor.constraintEqualToAnchor(self.topAnchor),
            edgeBar.heightAnchor.constraintEqualToConstant(7.5)
        ]
        
        self.addConstraints(edgeBarConstraints)
        
        self.summaryView = MealCoreInfoView(meal: self.meal)
        
        self.summaryView.translatesAutoresizingMaskIntoConstraints = false
        self.summaryView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MealBuilderView.didToggleView(_:))))
        
        self.addSubview(self.summaryView)
        
        let summaryViewConstraints : [NSLayoutConstraint] = [
            self.summaryView.leftAnchor.constraintEqualToAnchor(self.leftAnchor, constant: 15),
            self.summaryView.topAnchor.constraintEqualToAnchor(self.topAnchor, constant: 15),
            self.summaryView.rightAnchor.constraintEqualToAnchor(self.rightAnchor, constant: -15)
        ]
        
        self.addConstraints(summaryViewConstraints)
        
        self.summaryViewUntoggledConstraint = self.summaryView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -15)
        
        self.addConstraint(self.summaryViewUntoggledConstraint)
        
        self.summaryViewToggledConstraint = self.summaryView.heightAnchor.constraintEqualToAnchor(self.heightAnchor, multiplier: 0.2)
        
        self.addConstraint(self.summaryViewToggledConstraint)
        
        self.summaryViewToggledConstraint.active = false

        self.detailView = MealSummaryView(meal: self.meal)
        
        self.detailView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.detailView)
        
        let detailViewConstraints : [NSLayoutConstraint] = [
            self.detailView.leftAnchor.constraintEqualToAnchor(self.leftAnchor, constant: 15),
            self.detailView.topAnchor.constraintEqualToAnchor(self.summaryView.bottomAnchor, constant: 15),
            self.detailView.rightAnchor.constraintEqualToAnchor(self.rightAnchor, constant: -15),
            self.detailView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor, constant: -15)
        ]
        
        self.addConstraints(detailViewConstraints)
        
        self.detailView.hidden = true
        
        self.configureSummaryView()
        self.configureDetailView()
        
    }
    
    func configureSummaryView() {
        
        self.isToggledView.translatesAutoresizingMaskIntoConstraints = false
        
        self.summaryView.addSubview(self.isToggledView)
        
        let isToggledViewConstraints : [NSLayoutConstraint] = [
            self.isToggledView.rightAnchor.constraintEqualToAnchor(self.summaryView.rightAnchor),
            self.isToggledView.centerYAnchor.constraintEqualToAnchor(self.summaryView.centerYAnchor),
            self.isToggledView.heightAnchor.constraintEqualToConstant(45),
            self.isToggledView.widthAnchor.constraintEqualToConstant(45)
        ]
        
        self.summaryView.addConstraints(isToggledViewConstraints)
        
        self.isToggledView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        
        
    }
    
    func configureDetailView() {
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.superHeightConstraint == nil {
            if let backingView = self.superview {
                for constraint in backingView.constraints {
                    if constraint.firstItem is MealBuilderView && constraint.firstAttribute == .Height {
                        self.superHeightConstraint = constraint
                    }
                }
            }
        }
    }
    
    func didToggleView(sender : AnyObject? = nil) {
        
        self.isToggled = !self.isToggled
        
        if let backingView = self.superview, height = self.superHeightConstraint {
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: self.isToggled ? 0.5 : 1, initialSpringVelocity: self.isToggled ? 10 : 0, options: [.CurveEaseInOut], animations: {
                
                self.isToggledView.transform = self.isToggled ? CGAffineTransformMakeRotation(CGFloat(0)) : CGAffineTransformMakeRotation(CGFloat(M_PI))
                
                self.summaryViewToggledConstraint.active = self.isToggled ? true : false
                self.summaryViewUntoggledConstraint.active = self.isToggled ? false : true
                
                for subview in backingView.subviews {
                    if !(subview is MealBuilderView) {
                        subview.alpha = self.isToggled ? 0.5 : 1
                        subview.userInteractionEnabled = self.isToggled ? false : true
                    }
                }
                
                height.constant = self.isToggled ? UIScreen.mainScreen().bounds.height * (5/7) : UIScreen.mainScreen().bounds.height * (1/7)
                backingView.layoutIfNeeded()
                
                self.detailView.hidden = self.isToggled ? false : true
                
                }, completion: nil)
        }
    }
}