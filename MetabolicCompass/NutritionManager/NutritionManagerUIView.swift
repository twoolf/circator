//
//  UIView.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/30/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

class UIPresentSubview : UIView {
    
    var wasCanceled : (Void->Void)?
    
    convenience init(backgroundTint tint : UIBlurEffectStyle) {
        self.init(frame: CGRect.zero)
        self.configureView(backgroundTint: tint)
    }
    
    func configureView(backgroundTint tint : UIBlurEffectStyle) {
        
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: tint))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(backgroundView)
        
        let backgroundViewConstraints : [NSLayoutConstraint] = [
            backgroundView.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            backgroundView.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            backgroundView.topAnchor.constraintEqualToAnchor(self.topAnchor),
            backgroundView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor)
        ]
        
        self.addConstraints(backgroundViewConstraints)
        
        
    }
    
    static func presentSubview(subviewToPresent : UIView, backgroundTint tint : UIBlurEffectStyle = .Light, canceled : (Void->Void)? = nil) {
        if let viewController = UIApplication.sharedApplication().keyWindow?.rootViewController {
            
            presentSubviewOnView(subviewToPresent, presentingView: viewController.view, backgroundTint: tint, canceled: {
                canceled?()
            })
        }
        
        
    }
        
    static func presentSubviewOnView(subviewToPresent : UIView, presentingView : UIView, backgroundTint tint : UIBlurEffectStyle = .Light, canceled : (Void->Void)? = nil) {
        
        for view in presentingView.subviews {
            if view is UIPresentSubview {
                return
            }
        }
        
        let view = UIPresentSubview(backgroundTint: tint)
        view.wasCanceled = canceled
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        
        presentingView.addSubview(view)
        
        let preanimationViewConstraints : [NSLayoutConstraint] = [
            view.topAnchor.constraintEqualToAnchor(presentingView.topAnchor),
            view.bottomAnchor.constraintEqualToAnchor(presentingView.bottomAnchor),
            view.leftAnchor.constraintEqualToAnchor(presentingView.leftAnchor),
            view.rightAnchor.constraintEqualToAnchor(presentingView.rightAnchor)
        ]
        
        presentingView.addConstraints(preanimationViewConstraints)
        
        let cancelButton : UIButton = {
            
            let button = UIButton()
            button.backgroundColor = UIColor.clearColor()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.clipsToBounds = true
            button.layer.borderColor = tint == .Light ? UIColor.whiteColor().CGColor : UIColor.blackColor().CGColor
            button.layer.borderWidth = 3.525
            button.addTarget(view.self, action: #selector(UIPresentSubview.cancel(_:)), forControlEvents: .TouchUpInside)
            button.setTitle("+", forState: .Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(72, weight: UIFontWeightThin)
            button.contentEdgeInsets = UIEdgeInsetsMake(-12, 0, 0, 0)
            button.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_4))
            button.setTitleColor(tint == .Light ? UIColor.whiteColor() : UIColor.blackColor(), forState: .Normal)
            return button
        }()
        cancelButton.titleLabel?.textColor = tint == .Light ? UIColor.whiteColor() : UIColor.blackColor()
        view.addSubview(cancelButton)
        
        let cancelButtonConstraints : [NSLayoutConstraint] = [
            cancelButton.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -15),
            cancelButton.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            cancelButton.heightAnchor.constraintEqualToConstant(60),
            cancelButton.widthAnchor.constraintEqualToConstant(60)
        ]
        
        view.addConstraints(cancelButtonConstraints)
        
        subviewToPresent.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(subviewToPresent)
        
        let subviewToPresentConstraints : [NSLayoutConstraint] = [
            subviewToPresent.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 15),
            subviewToPresent.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 15),
            subviewToPresent.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -15),
            subviewToPresent.bottomAnchor.constraintEqualToAnchor(cancelButton.topAnchor, constant: -15)
        ]
        
        view.addConstraints(subviewToPresentConstraints)
                
        //prepares view for presentation
        presentingView.layoutIfNeeded()
        
        cancelButton.layer.cornerRadius = cancelButton.bounds.height/2
        
        UIView.animateWithDuration(0.333, delay: 0, options: [.CurveEaseInOut], animations: {
            
            view.alpha = 1
            presentingView.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    func cancel(sender: UIButton) {
        
        self.wasCanceled?()
        
        UIView.animateWithDuration(0.333, delay: 0, options: [.CurveEaseInOut], animations: {
            sender.superview?.alpha = 0
            //sender.superview?.superview?.layoutIfNeeded()
            }, completion: { complete in sender.superview?.removeFromSuperview()
        })
        
    }
    
}

class UIViewWithBlurredBackground : UIView {
    
    convenience init(view : UIView, withBlurEffectStyle style : UIBlurEffectStyle) {
        self.init(frame: CGRect.zero)
        self.configureView(view, withBlurEffectStyle: style)
    }
    
    func configureView(view : UIView, withBlurEffectStyle style : UIBlurEffectStyle) {
        
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(backgroundView)
        
        let backgroundViewConstraints : [NSLayoutConstraint] = [
            backgroundView.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            backgroundView.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            backgroundView.topAnchor.constraintEqualToAnchor(self.topAnchor),
            backgroundView.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor)
        ]
        
        self.addConstraints(backgroundViewConstraints)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(view)
        
        let viewConstraints : [NSLayoutConstraint] = [
            view.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            view.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            view.topAnchor.constraintEqualToAnchor(self.topAnchor),
            view.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor)
        ]
        
        self.addConstraints(viewConstraints)
        
        
        
    }
}