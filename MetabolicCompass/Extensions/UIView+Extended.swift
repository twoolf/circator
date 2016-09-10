//
//  UIView+Extended.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

extension UIView {
    
    func makeCircled() {
        self.layer.cornerRadius = self.bounds.size.height / 2.0
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0
    }
    
    func roundCornersWithRadius(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
}
