//
//  CircadianBehaviorViewController.swift
//  MetabolicCompass
//
//  Created by Edwin L. Whitman on 5/24/16.
//  Copyright © 2016 Edwin L. Whitman, Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

/*
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}*/

public func resizeImage(image image : UIImage?, scaledToSize size : CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    image!.drawInRect(CGRectMake(0, 0, size.width, size.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}

class CircadianBehaviorViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
    }
    
    private func configure() {
        
        self.setupViewControllers()
        
        let addEventButton : MCButton = {
            let button = MCButton(frame: CGRectMake(0, 0, 75, 75), buttonStyle: .Circular)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("+", forState: .Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(30)
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0)
            button.addTarget(self, action: "logEvent", forControlEvents: .TouchUpInside)
            return button
        }()
        
        view.addSubview(addEventButton)
        
        let addEventButtonConstraints : [NSLayoutConstraint] = [
            addEventButton.centerYAnchor.constraintEqualToAnchor(tabBar.centerYAnchor),
            addEventButton.centerXAnchor.constraintEqualToAnchor(tabBar.centerXAnchor)
        ]
        
        view.addConstraints(addEventButtonConstraints)
        
    }
    
    private func setupViewControllers() {
        
        let eventInboxViewController = EventInboxViewController()
        eventInboxViewController.tabBarItem = UITabBarItem(title: "Event Inbox", image: resizeImage(image: UIImage(named: "download-box-4"), scaledToSize: CGSizeMake(30, 30)), selectedImage: resizeImage(image: UIImage(named: "download-box-5"), scaledToSize: CGSizeMake(30, 30)))
        
        let repeatedEventManagerViewController = RepeatedEventManagerViewController.sharedManager
        repeatedEventManagerViewController.tabBarItem = UITabBarItem(title: "Repeated Events", image: resizeImage(image: UIImage(named: "image-logo"), scaledToSize: CGSizeMake(30, 30)), selectedImage: resizeImage(image: UIImage(named: "image-logo"), scaledToSize: CGSizeMake(30, 30)))
        
        let spacerForAddEventButton = UIViewController()
        self.viewControllers = [eventInboxViewController, spacerForAddEventButton, repeatedEventManagerViewController]
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        switch (item.title!) {
        case "Event Inbox":
            self.navigationItem.title = "Event Inbox"
            self.navigationItem.rightBarButtonItem = nil
            break
        case "Repeated Events":
            self.navigationItem.title = "Repeated Events"
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: "addRepeatedEvent:")
            break
        default:
            break
        }
        
        
    }
    
    func logEvent() {
        
        let vc = LogEventViewController()
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func addRepeatedEvent(sender: UIBarItem) {
        
        let vc = self.selectedViewController as! RepeatedEventManagerViewController
        vc.addRepeatedEvent(sender)
    }
    
    
    
}
