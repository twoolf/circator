//
//  ManageEventMenu.swift
//  Derived from PathMenu/PathMenu.swift
//
//  PathMenu Copyright:
//  Created by pixyzehn on 12/27/14.
//  Copyright (c) 2014 pixyzehn. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import MCCircadianQueries


public class ManageEventMenu: UIView, PathMenuItemDelegate {

    //MARK: Internal typedefs
    struct Duration {
        static var DefaultAnimation: CGFloat      = 0.5
        static var MenuDefaultAnimation: CGFloat  = 0.2
    }

    public enum State {
        case Close
        case Expand
    }

    //MARK: tags for menu components.
    public let favoritesTag = 1000
    public let itemsTag = 2000

    public var menuItems: [PathMenuItem] = []

    public var startButton: PathMenuItem?
    public weak var delegate: ManageEventMenuDelegate?

    public var flag: Int?
    public var timer: NSTimer?

    public var timeOffset: CGFloat!

    public var animationDuration: CGFloat!
    public var startMenuAnimationDuration: CGFloat!

    public var motionState: State?

    public var startPoint: CGPoint = CGPointZero {
        didSet {
            startButton?.center = startPoint
        }
    }

    //MARK: Image

    public var image: UIImage? {
        didSet {
            startButton?.image = image
        }
    }

    public var highlightedImage: UIImage? {
        didSet {
            startButton?.highlightedImage = highlightedImage
        }
    }

    public var contentImage: UIImage? {
        didSet {
            startButton?.contentImageView?.image = contentImage
        }
    }

    public var highlightedContentImage: UIImage? {
        didSet {
            startButton?.contentImageView?.highlightedImage = highlightedContentImage
        }
    }
    

    //MARK: Quick add event.
    public var addView: AddActivityManager! = nil

    //MARK: Quick delete event.
    public var delView: DeleteActivityManager! = nil

    //MARK: Segmented control for add/delete interation
    var segmenter: UISegmentedControl! = nil

    //MARK: Initializers
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience public init(frame: CGRect!, startItem: PathMenuItem?, items:[PathMenuItem]?) {
        self.init(frame: frame)

        self.menuItems = items ?? []
        self.menuItems.enumerate().forEach { (index, item) in
            item.tag = itemsTag + index
        }

        self.timeOffset = 0.036
        self.animationDuration = Duration.DefaultAnimation
        self.startMenuAnimationDuration = Duration.MenuDefaultAnimation
        self.startPoint = CGPointMake(UIScreen.mainScreen().bounds.width/2, UIScreen.mainScreen().bounds.height/2)
        self.motionState = .Close
        
        self.startButton = startItem
        self.startButton!.delegate = self
        self.startButton!.center = startPoint
        self.addSubview(startButton!)

        let attrs = [NSFontAttributeName: UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)]
        self.segmenter = UISegmentedControl(items: ["Add Activity", "Delete Activity"])
        self.segmenter.selectedSegmentIndex = 0
        self.segmenter.setTitleTextAttributes(attrs, forState: .Normal)
        self.segmenter.addTarget(self, action: #selector(segmentChanged(_:)), forControlEvents: .ValueChanged)

        self.segmenter.hidden = true
        self.segmenter.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(segmenter)

        let segConstraints : [NSLayoutConstraint] = [
            segmenter.topAnchor.constraintEqualToAnchor(topAnchor, constant: 60.0),
            segmenter.heightAnchor.constraintEqualToConstant(30.0),
            segmenter.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: 20.0),
            segmenter.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -20.0)
        ]

        self.addConstraints(segConstraints)

        // self.addTableView = AddEventTable(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)
        // self.delTableView = DeleteEventTable(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)

        self.addView = AddActivityManager(frame: CGRect.zero, style: .Grouped, menuItems: self.menuItems, notificationView: self.segmenter)
        self.delView = DeleteActivityManager(frame: CGRect.zero, style: .Grouped, notificationView: self.segmenter)
    }

    public func logContentView(asAppear: Bool = true) {
        Answers.logContentViewWithName("Quick Add Activity",
                                       contentType: asAppear ? "Appear" : "Disappear",
                                       contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
                                       customAttributes: ["action": (segmenter?.selectedSegmentIndex) ?? 0])
    }

    public func getCurrentManagerView() -> UIView? {
        if segmenter.selectedSegmentIndex == 0 {
            return addView
        } else {
            return delView
        }
    }

    public func getOtherManagerView() -> UIView? {
        if segmenter.selectedSegmentIndex == 0 {
            return delView
        } else {
            return addView
        }
    }

    public func hideView(hide: Bool = false) {
        self.segmenter.hidden = hide
        refreshHiddenFromSegmenter(hide)
    }

    public func refreshHiddenFromSegmenter(hide: Bool = false) {
        getCurrentManagerView()?.hidden = hide
        getOtherManagerView()?.hidden = true
    }

    func segmentChanged(sender: UISegmentedControl) {
        Async.main {
            self.refreshHiddenFromSegmenter()
            self.updateViewFromSegmenter()
        }
    }

    //MARK: UIView's methods

    override public func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if motionState == .Expand { return true }
        return CGRectContainsPoint(startButton!.frame, point)
    }

    override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let animId = anim.valueForKey("id") {
            if animId.isEqual("lastAnimation") {
                delegate?.manageEventMenuDidFinishAnimationClose(self)
            }
            if animId.isEqual("firstAnimation") {
                delegate?.manageEventMenuDidFinishAnimationOpen(self)
            }
        }
    }

    //MARK: UIGestureRecognizer
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        handleTap()
    }
    
    //MARK: PathMenuItemDelegate
    
    public func pathMenuItemTouchesBegin(item: PathMenuItem) {
        if item == startButton { handleTap() }
    }
    
    public func pathMenuItemTouchesEnd(item:PathMenuItem) {
        if item == startButton { return }

        motionState = .Close
        delegate?.manageEventMenuWillAnimateClose(self)
        
        let angle = motionState == .Expand ? CGFloat(M_PI_4) + CGFloat(M_PI) : 0.0
        UIView.animateWithDuration(Double(startMenuAnimationDuration!), animations: { [weak self] () -> Void in
            self?.startButton?.transform = CGAffineTransformMakeRotation(angle)
        })
        
        delegate?.manageEventMenu(self, didSelectIndex: item.tag - itemsTag)
    }
    
    //MARK: Animation, Position
    
    public func handleTap() {
        let state = motionState!

        let selector: Selector
        let angle: CGFloat
        
        switch state {
        case .Close:
            setMenu()
            delegate?.manageEventMenuWillAnimateOpen(self)
            selector = #selector(expand)
            flag = 0
            motionState = .Expand
            angle = CGFloat(M_PI_4) + CGFloat(M_PI)
        case .Expand:
            delegate?.manageEventMenuWillAnimateClose(self)
            selector = #selector(close)
            flag = 10
            motionState = .Close
            angle = 0
        }
        
        UIView.animateWithDuration(Double(startMenuAnimationDuration!), animations: { [weak self] () -> Void in
            self?.startButton?.transform = CGAffineTransformMakeRotation(angle)
        })
        
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(Double(timeOffset!), target: self, selector: selector, userInfo: nil, repeats: true)
            if let timer = timer {
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
            }
        }
    }
    
    public func expand() {
        if flag == 11 {
            timer?.invalidate()
            timer = nil
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(float: 0.0)
        opacityAnimation.toValue = NSNumber(float: 1.0)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))
        scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1, 1, 1))

        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations     = [opacityAnimation, scaleAnimation]
        animationgroup.duration       = CFTimeInterval(animationDuration!)
        animationgroup.fillMode       = kCAFillModeForwards
        animationgroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animationgroup.delegate = self

        if flag == 10 {
            animationgroup.setValue("firstAnimation", forKey: "id")
        }

        getCurrentManagerView()?.layer.addAnimation(animationgroup, forKey: "Expand")
        getCurrentManagerView()?.layer.opacity = 1.0

        flag! += 1
    }
    
    public func close() {
        if flag! == -1 {
            timer?.invalidate()
            timer = nil
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(float: 1.0)
        opacityAnimation.toValue = NSNumber(float: 0.0)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DMakeScale(1, 1, 1))
        scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(1.2, 1.2, 1))

        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations     = [opacityAnimation, scaleAnimation]
        animationgroup.duration       = CFTimeInterval(animationDuration!)
        animationgroup.fillMode       = kCAFillModeForwards
        animationgroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animationgroup.delegate = self

        if flag == 0 {
            animationgroup.setValue("lastAnimation", forKey: "id")
        }

        getCurrentManagerView()?.layer.addAnimation(animationgroup, forKey: "Close")
        getCurrentManagerView()?.layer.opacity = 0.0

        flag! -= 1
    }
    
    public func setMenu() {
        for (index, menuItem) in menuItems.enumerate() {
            let item = menuItem
            item.tag = itemsTag + index
            item.delegate = self
        }
        updateViewFromSegmenter()
    }

    func removeManagersFromSuperview() {
        for sv in subviews {
            if let _ = sv as? AddActivityManager {
                sv.removeFromSuperview()
            }
            else if let _ = sv as? DeleteActivityManager {
                sv.removeFromSuperview()
            }
        }
    }

    public func updateViewFromSegmenter() {
        removeManagersFromSuperview()

        if let manager = getCurrentManagerView() {
            if let adder = manager as? AddActivityManager { adder.reloadData() }

            manager.backgroundColor = .clearColor()
            manager.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(manager, belowSubview: startButton!)

            let screenSize = UIScreen.mainScreen().bounds.size
            let topAnchorOffset: CGFloat = screenSize.height < 569 ? 0.0: 20.0
            let bottomAnchorOffset: CGFloat = -44.0

            let managerConstraints: [NSLayoutConstraint] = [
                manager.topAnchor.constraintEqualToAnchor(segmenter.bottomAnchor, constant: topAnchorOffset),
                manager.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: bottomAnchorOffset),
                manager.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
                manager.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
            ]
            self.addConstraints(managerConstraints)
            logContentView()
        }
    }
}

