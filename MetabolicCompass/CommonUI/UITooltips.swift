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
        preferences.drawing.foregroundColor = .whiteColor()
        preferences.drawing.backgroundColor = .blueColor()
        preferences.drawing.arrowPosition = .Top
        EasyTipView.globalPreferences = preferences
    }

    public func showTip(forView view: UIView, withinSuperview superview: UIView? = nil, text: String, delegate: EasyTipViewDelegate? = nil) {
        EasyTipView.show(forView: view, withinSuperview: superview, text: text, delegate: delegate)
    }

    public func tipBelow() -> EasyTipView.Preferences {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .whiteColor()
        preferences.drawing.backgroundColor = .blueColor()
        preferences.drawing.arrowPosition = .Top
        return preferences
    }

    public func tipAbove() -> EasyTipView.Preferences {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .whiteColor()
        preferences.drawing.backgroundColor = .blueColor()
        preferences.drawing.arrowPosition = .Bottom
        return preferences
    }
}

public class TapTip : NSObject, EasyTipViewDelegate {
    public var visible: Bool = false
    public var tipView: EasyTipView! = nil
    public var targetView: UIView
    public var tapRecognizer: UITapGestureRecognizer! = nil

    public init(forView view: UIView, text: String, asTop: Bool = false) {
        self.targetView = view
        super.init()

        let preferences = asTop ? UITooltips.sharedInstance.tipAbove() : UITooltips.sharedInstance.tipBelow()
        tipView = EasyTipView(text: text, preferences: preferences, delegate: self)
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showTip))
        tapRecognizer.numberOfTapsRequired = 2
    }

    public func showTip() {
        if !visible {
            visible = true
            tipView.show(forView: targetView)
        }
    }

    public func easyTipViewDidDismiss(tipView: EasyTipView) {
        visible = false
    }
}
