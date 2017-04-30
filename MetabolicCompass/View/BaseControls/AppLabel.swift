//
//  AppLabel.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit


class AppLabel: FontScaleLabel {
    
    var fontSize: CGFloat = 14.0 {
        didSet {
            setupFontSize(size: fontSize)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFont()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupFont()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupFont()
    }
    
    private func setupFont() {
        fontSize = self.font.pointSize
        setupFontSize(size: fontSize)
    }

    func setupFontSize(size: CGFloat) {
        self.font = ScreenManager.appFontOfSize(size: fontSize)
    }
}
