//
//  NavVC.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/23/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

protocol ConfigurableStatusBar {
    var showStatusBar : Bool { get set }
    func showStatusBar(enabled: Bool)
}

import UIKit

public func resizeImage(image image : UIImage?, scaledToSize size : CGSize, tintColor tint : UIColor? = nil) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    if let toDraw = image {
        
        toDraw.drawInRect(CGRectMake(0, 0, size.width, size.height))
    }
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
}

class NavVC: UITabBarController, ConfigurableStatusBar {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViewControllers()
        self.navigationItem.title = "Meal Builder"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: #selector(NavVC.addMeal(_:)))

    }
    
    private func setupViewControllers() {
        
        let mealBuilderViewController = MealBuilderViewController()
        mealBuilderViewController.tabBarItem = UITabBarItem(title: "Meal Builder", image: resizeImage(image: UIImage(named: "components-icon-black"), scaledToSize: CGSizeMake(30, 30)), selectedImage: resizeImage(image: UIImage(named: "components-icon-white"), scaledToSize: CGSizeMake(30, 30)))
        
        let mealCollectionViewController = MealCollectionViewController()
        mealCollectionViewController.tabBarItem = UITabBarItem(title: "My Meals", image: resizeImage(image: UIImage(named: "list-icon-black"), scaledToSize: CGSizeMake(30, 30)), selectedImage: resizeImage(image: UIImage(named: "list-icon-white"), scaledToSize: CGSizeMake(30, 30)))
        
        self.viewControllers = [mealBuilderViewController, mealCollectionViewController]
        
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        switch (item.title!) {
        case "My Meals":
            self.navigationItem.title = "My Meals"
            self.navigationItem.rightBarButtonItem = nil
            break
        case "Meal Builder":
            self.navigationItem.title = "Meal Builder"
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: #selector(NavVC.addMeal(_:)))
            break
        default:
            break
        }
        
        
    }
    
    func addMeal(sender: UIBarItem) {
        
        
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
        
        if let vcs = self.viewControllers {
            for vc in vcs {
                if let configuring = vc as? ConfigurableStatusBar {
                    configuring.showStatusBar(self.showStatusBar)
                }
            }
        }
    }
}