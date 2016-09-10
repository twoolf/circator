//
//  FontScaleLabel.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit


public class FontScaleLabel: UILabel {
    private var notScaledFont:UIFont? = nil
    
    public static var scaleFactor: CGFloat = 1.0
    
//    required public init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)!
//        self.commonInit()
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.commonInit()
//    }
//    
//    func commonInit(){
//
//    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        if self.notScaledFont == nil {
            self.notScaledFont = self.font;
            self.font = self.notScaledFont;
        }
    }
    
    override public var font: UIFont!{
        get { return super.font }
        set {
            self.notScaledFont = newValue;
            if newValue != nil{
                let scaledFont = newValue!.fontWithSize(newValue!.pointSize * FontScaleLabel.scaleFactor)
                super.font = scaledFont
            }
        }

    }

}
