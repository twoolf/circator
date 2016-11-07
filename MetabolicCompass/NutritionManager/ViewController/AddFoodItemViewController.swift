//
//  AddFoodItemViewController.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 8/2/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import UIKit

protocol FoodItemSelectionDelegate {
    var didSelectFoodItem : (FoodItem->Void)? { get set }
}

class AddFoodItemViewController : UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, ConfigurableStatusBar {
    
    var pages : [(String, UIViewController)] = [("Recent", RecentFoodItemsViewController()), ("Search", NutritionixSearchViewController()), ("Scan", BarcodeScannerViewController())]
    var pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    lazy var indicatorView : ViewControllerIndicator = { ViewControllerIndicator(indicators: self.pages.map({(title, _) in return title})) }()
    var selectedSegment = 0
    var didSelectFoodItem : (FoodItem->Void)? {
        didSet {
            for i in 0..<self.pages.count {
                var vc = self.pages[i].1 as? FoodItemSelectionDelegate
                vc?.didSelectFoodItem = self.didSelectFoodItem
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configurePageViewController()
        self.configureView()
        
        self.didSelectFoodItem = { item in
            let actionView = FoodItemActionView(foodItem: item)
            UIPresentSubview.presentSubview(actionView, backgroundTint: .Dark)
        }
    }
    
    
    private func configurePageViewController() {
        
        self.indicatorView.wasSelectedAtIndex = { (index, animated) in
            if index > self.selectedSegment {
                self.pageViewController.setViewControllers([self.pages[index].1], direction: .Forward, animated: animated, completion: nil)
            } else {
                self.pageViewController.setViewControllers([self.pages[index].1], direction: .Reverse, animated: animated, completion: nil)
            }
            
            self.selectedSegment = index
        }
        
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        
        self.indicatorView.selectIndicatorAtIndex(1, animated: false)
    }
    
    private func configureView() {
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.indicatorView)
        
        let indicatorViewConstraints : [NSLayoutConstraint] = [
            self.indicatorView.topAnchor.constraintEqualToAnchor(self.view.topAnchor),
            self.indicatorView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
            self.indicatorView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor),
            self.indicatorView.heightAnchor.constraintEqualToConstant(45)
        ]
        
        self.view.addConstraints(indicatorViewConstraints)

        self.addChildViewController(self.pageViewController)
        
        let pageView = self.pageViewController.view
        pageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(pageView)
        
        let pageViewConstraints : [NSLayoutConstraint] = [
            pageView.topAnchor.constraintEqualToAnchor(self.indicatorView.bottomAnchor),
            pageView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
            pageView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor),
            pageView.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor)
        ]
        
        self.view.addConstraints(pageViewConstraints)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        let vcs = self.pages.map({$0.1})
        
        for index in 1..<vcs.count {
            if vcs[index] == viewController {
                return vcs[index-1]
            }
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        let vcs = self.pages.map({$0.1})
        
        for index in 0..<vcs.count-1 {
            if vcs[index] == viewController {
                return vcs[index+1]
            }
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            
            if let vc = self.pageViewController.viewControllers?[0], index = self.pages.map({$0.1}).indexOf(vc) {
                self.indicatorView.setIndicatorAtIndex(index, animated: true)
            }
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

class ViewControllerIndicator : UIStackView {
    
    var wasSelectedAtIndex : ((Int,Bool)->Void)?
    var indicators : [String] = []
    let indicatorBar = UIView()
    
    convenience init(indicators : [String]) {
        self.init(frame: CGRect.zero)
        self.indicators = indicators
        self.configureView()
    }
    
    func configureView() {
        
        self.axis = .Horizontal
        self.alignment = .Fill
        self.distribution = .FillEqually

        
        for indicator in self.indicators {
            self.addIndicator(indicator)
        }
        
        self.indicatorBar.translatesAutoresizingMaskIntoConstraints = false
        self.indicatorBar.backgroundColor = UIColor.darkGrayColor()
        
        self.addSubview(self.indicatorBar)
        
        let indicatorBarConstraints : [NSLayoutConstraint] = [
            self.indicatorBar.heightAnchor.constraintEqualToConstant(7.5),
            self.indicatorBar.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor)
        ]
        
        self.addConstraints(indicatorBarConstraints)
        
        let bottomBar = UIView()
        
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.backgroundColor = UIColor.lightGrayColor()
        
        self.addSubview(bottomBar)
        
        let bottomBarConstraints : [NSLayoutConstraint] = [
            bottomBar.leftAnchor.constraintEqualToAnchor(self.leftAnchor),
            bottomBar.rightAnchor.constraintEqualToAnchor(self.rightAnchor),
            bottomBar.bottomAnchor.constraintEqualToAnchor(self.bottomAnchor),
            bottomBar.heightAnchor.constraintEqualToConstant(1)
        ]
        
        self.addConstraints(bottomBarConstraints)
                
    }
    
    private func addIndicator(title : String) {
        
        let button = UIButton()
        button.setTitle(title, forState: .Normal)
        button.titleLabel?.textAlignment = .Center
        button.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        button.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        button.addTarget(self, action: #selector(ViewControllerIndicator.didTapIndicator(_:)), forControlEvents: .AllEvents)
        
        self.addArrangedSubview(button)
    }

    func didTapIndicator(sender: UIButton) {
        
        print("tap")
        
        for index in 0..<self.indicators.count {
            if self.indicators[index] == sender.titleLabel?.text {
                self.selectIndicatorAtIndex(index, animated: true)
                return
            }
        }
    }
    
    func setIndicatorAtIndex(index : Int, animated: Bool) {
        
        if index < 0 || index >= self.arrangedSubviews.count {
            return
        }
        
        for view in self.arrangedSubviews {
            if let buton = view as? UIButton {
                buton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
            }
        }
        
        if let selectedButton = self.arrangedSubviews[index] as? UIButton {
            selectedButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        }
        
        for constraint in self.constraints {
            if let item = constraint.firstItem as? UIView {
                if item == self.indicatorBar && constraint.firstAttribute == .Left || constraint.firstAttribute == .Right {
                    constraint.active = false
                }
            }
        }
        
        let constraints : [NSLayoutConstraint] = [
            self.indicatorBar.leftAnchor.constraintEqualToAnchor(self.arrangedSubviews[index].leftAnchor),
            self.indicatorBar.rightAnchor.constraintEqualToAnchor(self.arrangedSubviews[index].rightAnchor)
        ]
        
        self.addConstraints(constraints)
        
        if animated {
            UIView.animateWithDuration(0.333, delay: 0, options: [.CurveEaseInOut], animations: {
                self.layoutIfNeeded()
            }, completion: nil)
        } else {
           self.layoutIfNeeded()
        }
        
    }
    
    func selectIndicatorAtIndex(index : Int, animated: Bool) {
        self.setIndicatorAtIndex(index, animated: animated)
        self.wasSelectedAtIndex?(index, animated)
    }
    
    
    
}