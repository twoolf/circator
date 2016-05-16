//
//  AppLogoLabel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit


class AppLogoLabel: UIView {
    
    var logoFont = ScreenManager.sharedInstance.appFontOfSize(16.0) {
        didSet {
            label.font = logoFont
        }
    }
    
    var logoColor = UIColor.whiteColor() {
        didSet {
            label.textColor = logoColor
            topLine.backgroundColor = logoColor
            bottomLine.backgroundColor = logoColor
        }
    }
    
    var logoText = "METABOLIC COMPASS".localized {
        didSet {
            label.text = logoText
        }
    }
    
    private var label: UILabel!
    private var topLine: UIView!
    private var bottomLine: UIView!
    private let lineHeight: CGFloat = 1.5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    
    private func setup() {
        let bounds = self.bounds
        print("bounds \(bounds))")
        
        // init label
        label = UILabel(frame: bounds)
        label.autoresizingMask =
            [ .FlexibleBottomMargin,
              .FlexibleHeight,
              .FlexibleLeftMargin,
              .FlexibleRightMargin,
              .FlexibleTopMargin,
              .FlexibleWidth ]
        label.text = logoText
        label.font = logoFont
        label.textColor = logoColor
        label.textAlignment = .Center
        
        self.addSubview(label)
        
        // init top line
        topLine = UIView(frame: CGRectMake(0, 0, bounds.size.width, lineHeight))
        topLine.autoresizingMask =  [ .FlexibleLeftMargin,
                                      .FlexibleRightMargin,
                                      .FlexibleTopMargin,
                                      .FlexibleWidth ]
        topLine.backgroundColor = logoColor
        
        self.addSubview(topLine)
        
        // init bottom line
        bottomLine = UIView(frame: CGRectMake(0, bounds.size.height - lineHeight, bounds.size.width, lineHeight))
        bottomLine.autoresizingMask =  [
                                      .FlexibleBottomMargin,
                                      .FlexibleLeftMargin,
                                      .FlexibleRightMargin,
                                      .FlexibleWidth ]
        bottomLine.backgroundColor = logoColor
        
        self.addSubview(bottomLine)
    }


    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
