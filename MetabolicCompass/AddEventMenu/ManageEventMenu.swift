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


public class ManageEventMenu: UIView, CAAnimationDelegate, PathMenuItemDelegate {

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
    public var timer: Timer?

    public var timeOffset: CGFloat!

    public var animationDuration: CGFloat!
    public var startMenuAnimationDuration: CGFloat!

    public var motionState: State?

    public var startPoint: CGPoint = CGPoint.zero {
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
        self.menuItems.enumerated().forEach { (index, item) in
            item.tag = itemsTag + index
        }

        self.timeOffset = 0.036
        self.animationDuration = Duration.DefaultAnimation
        self.startMenuAnimationDuration = Duration.MenuDefaultAnimation
        self.startPoint = CGPoint(UIScreen.main.bounds.width/2, UIScreen.main.bounds.height/2)
        self.motionState = .Close
        
        self.startButton = startItem
        self.startButton!.delegate = self
        self.startButton!.center = startPoint
        self.addSubview(startButton!)

        let attrs = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)]
        self.segmenter = UISegmentedControl(items: ["Add Activity", "Delete Activity"])
        self.segmenter.selectedSegmentIndex = 0
        self.segmenter.setTitleTextAttributes(attrs, for: .normal)
        self.segmenter.addTarget(self, action: #selector(self.segmentChanged(_:)), for: .valueChanged)

        self.segmenter.isHidden = true
        self.segmenter.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(segmenter)

        let segConstraints : [NSLayoutConstraint] = [
            segmenter.topAnchor.constraint(equalTo: topAnchor, constant: 60.0),
            segmenter.heightAnchor.constraint(equalToConstant: 30.0),
            segmenter.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            segmenter.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0)
        ]

        self.addConstraints(segConstraints)

        self.addView = AddActivityManager(frame: CGRect.zero, style: .grouped, menuItems: self.menuItems, notificationView: self.segmenter)
        self.delView = DeleteActivityManager(frame: CGRect.zero, style: .grouped, notificationView: self.segmenter)
    }

    public func logContentView(_ asAppear: Bool = true) {
        Answers.logContentView(withName: "Quick Add Activity",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH")),
            contentId: Date().string(),
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

    public func hideView(_ hide: Bool = false) {
        self.segmenter.isHidden = hide
        refreshHiddenFromSegmenter(hide)
    }

    public func refreshHiddenFromSegmenter(_ hide: Bool = false) {
        getCurrentManagerView()?.isHidden = hide
        getOtherManagerView()?.isHidden = true
    }

    @objc public func segmentChanged(_ sender: UISegmentedControl) {
        Async.main {
            self.refreshHiddenFromSegmenter()
            self.updateViewFromSegmenter()
        }
    }

    //MARK: UIView's methods

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if motionState == .Expand { return true }
        return startButton!.frame.contains(point)
    }

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let animId = anim.value(forKey: "id") {
            if (animId as AnyObject).isEqual("lastAnimation") {
                delegate?.manageEventMenuDidFinishAnimationClose(menu: self)
            }
            if (animId as AnyObject).isEqual("firstAnimation") {
                delegate?.manageEventMenuDidFinishAnimationOpen(menu: self)
            }
        }
    }

    //MARK: UIGestureRecognizer

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTap()
    }
    
    //MARK: PathMenuItemDelegate
    
    public func TouchesBegin(on item: PathMenuItem) {
        if item == startButton { handleTap() }
    }
    
    public func TouchesEnd(on item: PathMenuItem) {
        if item == startButton { return }

        motionState = .Close
        delegate?.manageEventMenuWillAnimateClose(menu: self)
        
        let angle = motionState == .Expand ? CGFloat(Double.pi/4) + CGFloat(Double.pi) : 0.0
        UIView.animate(withDuration: Double(startMenuAnimationDuration!), animations: { [weak self] () -> Void in
            self?.startButton?.transform = CGAffineTransform(rotationAngle: angle)
        })
        
        delegate?.manageEventMenu(menu: self, didSelectIndex: item.tag - itemsTag)
    }
    
    //MARK: Animation, Position
    
    public func handleTap() {
        let state = motionState!

        let selector: Selector
        let angle: CGFloat
        
        switch state {
        case .Close:
            setMenu()
            delegate?.manageEventMenuWillAnimateOpen(menu: self)
            selector = #selector(expand)
            flag = 0
            motionState = .Expand
            angle = CGFloat(Double.pi/4) + CGFloat(Double.pi)
        case .Expand:
            delegate?.manageEventMenuWillAnimateClose(menu: self)
            selector = #selector(close)
            flag = 10
            motionState = .Close
            angle = 0
        }
        
        UIView.animate(withDuration: Double(startMenuAnimationDuration!), animations: { [weak self] () -> Void in
            self?.startButton?.transform = CGAffineTransform(rotationAngle: angle)
        })
        
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: Double(timeOffset!), target: self, selector: selector, userInfo: nil, repeats: true)
            if let timer = timer {
                RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
            }
        }
    }
    
    @objc public func expand() {
        if flag == 11 {
            timer?.invalidate()
            timer = nil
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(value: 0.0)
        opacityAnimation.toValue = NSNumber(value: 1.0)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(1.2, 1.2, 1))
        scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(1, 1, 1))

        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations     = [opacityAnimation, scaleAnimation]
        animationgroup.duration       = CFTimeInterval(animationDuration!)
        animationgroup.fillMode       = kCAFillModeForwards
        animationgroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animationgroup.delegate = self

        if flag == 10 {
            animationgroup.setValue("firstAnimation", forKey: "id")
        }

        getCurrentManagerView()?.layer.add(animationgroup, forKey: "Expand")
        getCurrentManagerView()?.layer.opacity = 1.0

        flag! += 1
    }
    
   @objc public func close() {
        if flag! == -1 {
            timer?.invalidate()
            timer = nil
            return
        }

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(value: 1.0)
        opacityAnimation.toValue = NSNumber(value: 0.0)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DMakeScale(1, 1, 1))
        scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(1.2, 1.2, 1))

        let animationgroup: CAAnimationGroup = CAAnimationGroup()
        animationgroup.animations     = [opacityAnimation, scaleAnimation]
        animationgroup.duration       = CFTimeInterval(animationDuration!)
        animationgroup.fillMode       = kCAFillModeForwards
        animationgroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animationgroup.delegate = self

        if flag == 0 {
            animationgroup.setValue("lastAnimation", forKey: "id")
        }
        getCurrentManagerView()?.layer.add(animationgroup, forKey: "Close")
        getCurrentManagerView()?.layer.opacity = 0.0

        flag! -= 1
    }
    
    public func setMenu() {
        for (index, menuItem) in menuItems.enumerated() {
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

            manager.backgroundColor = .clear
            manager.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(manager, belowSubview: startButton!)

            let screenSize = UIScreen.main.bounds.size
            let topAnchorOffset: CGFloat = screenSize.height < 569 ? 0.0: 20.0
            let bottomAnchorOffset: CGFloat = -44.0

            let managerConstraints: [NSLayoutConstraint] = [
                manager.topAnchor.constraint(equalTo: segmenter.bottomAnchor, constant: topAnchorOffset),
                manager.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomAnchorOffset),
                manager.leadingAnchor.constraint(equalTo: leadingAnchor),
                manager.trailingAnchor.constraint(equalTo: trailingAnchor)
            ]
            self.addConstraints(managerConstraints)
            logContentView()
        }
    }
}

