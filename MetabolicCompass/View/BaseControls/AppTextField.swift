//
//  AppTextField.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

public class AppTextField: FontScaleTextField {
    
    private let defaultFontSize: CGFloat = 14.0
    
    var fontSize: CGFloat = 14.0 {
        didSet {
            setupFontSize(size: fontSize)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFont()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupFont()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        setupFont()
    }
    
    private func setupFont() {
        fontSize = self.font?.pointSize ?? defaultFontSize
        setupFontSize(size: fontSize)
    }
    
    func setupFontSize(size: CGFloat) {
        self.font = ScreenManager.appFontOfSize(size: fontSize)
    }
    
    
}
