//
//  UIFont+Common.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/18/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    class func printAllAppFonts(){
        for familyName in UIFont.familyNames() {
            print("family: \(familyName)")
            for fontName in UIFont.fontNamesForFamilyName(familyName){
                print("\tfont: \(fontName)")
            }
        }
    }
}