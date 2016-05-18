//
//  EventManagerViewController.swift
//  Circator
//
//  Created by Edwin L. Whitman on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class EventManagerViewController : UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
    
    func configureView() {
        
        let vc = UIViewController()
        vc.tabBarItem = UITabBarItem(title: "-", image: nil, tag: 0)
        
        self.viewControllers = [vc]
        
        let addEventButton : MCButton = {
            let button = MCButton(frame: CGRectMake(0, 0, 75, 75), buttonStyle: .Circular)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("+", forState: .Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(30)
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0)
            button.addTarget(self, action: "addEventNow", forControlEvents: .TouchUpInside)
            return button
        }()
        
        view.addSubview(addEventButton)
        
        let addEventButtonConstraints : [NSLayoutConstraint] = [
            addEventButton.centerYAnchor.constraintEqualToAnchor(tabBar.centerYAnchor),
            addEventButton.centerXAnchor.constraintEqualToAnchor(tabBar.centerXAnchor)
        ]
        
        view.addConstraints(addEventButtonConstraints)
    }
    
    func addEventNow() {
        
        let vc = AddEventViewController()
        self.presentViewController(vc, animated: true, completion: nil)
    }
}

/*
lazy var plotButton: UIButton = {
    let image = UIImage(named: "icon_plot") as UIImage?
    let button = MCButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular)
    button.setImage(image, forState: .Normal)
    button.imageEdgeInsets = UIEdgeInsetsMake(13,12,12,13)
    button.tintColor = Theme.universityDarkTheme.foregroundColor
    button.buttonColor = UIColor.ht_emeraldColor()
    button.shadowColor = UIColor.ht_nephritisColor()
    button.shadowHeight = 6
    button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
    return button
 */