//
//  UITooltips.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/17/16.   
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import EasyTipView

public class UITooltips : NSObject {
    public static let sharedInstance = UITooltips()

    public override init() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .blue
        preferences.drawing.arrowPosition = .top
        EasyTipView.globalPreferences = preferences
    }

    public func showTip(forView view: UIView, withinSuperview superview: UIView? = nil, text: String, delegate: EasyTipViewDelegate? = nil) {
        EasyTipView.show(forView: view, withinSuperview: superview, text: text, delegate: delegate)
    }

    public func tipBelow() -> EasyTipView.Preferences {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .blue
        preferences.drawing.arrowPosition = .top
        preferences.positioning.maxWidth = ScreenManager.sharedInstance.tooltipMaxWidth()
        return preferences
    }

    public func tipAbove() -> EasyTipView.Preferences {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .blue
        preferences.drawing.arrowPosition = .bottom
        preferences.positioning.maxWidth = ScreenManager.sharedInstance.tooltipMaxWidth()
        return preferences
    }
}

public class TapTip : NSObject, EasyTipViewDelegate {
    public var visible: Bool = false
    public var tipView: EasyTipView! = nil
    public var forView: UIView
    public var withinView: UIView? = nil
    public var tapRecognizer: UITapGestureRecognizer! = nil

    public init(forView view: UIView, withinView: UIView? = nil, text: String, width: CGFloat? = nil, numTaps: Int = 2, numTouches: Int = 1, asTop: Bool = false) {
        self.forView = view
        self.withinView = withinView
        super.init()

        var preferences = asTop ? UITooltips.sharedInstance.tipAbove() : UITooltips.sharedInstance.tipBelow()
        if let w = width {
            preferences.positioning.maxWidth = min(w, ScreenManager.sharedInstance.tooltipMaxWidth())
        }
        tipView = EasyTipView(text: text, preferences: preferences, delegate: self)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showTip))
        tapRecognizer.numberOfTapsRequired = numTaps
        tapRecognizer.numberOfTouchesRequired = numTouches
    }

    public func showTip() {
        if !visible {
            visible = true
            tipView.show(forView: forView, withinSuperview: withinView)
        }
    }

    public func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        visible = false
    }
}
