//
//  UIColor+Extended.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    public static func colorWithHex(hex6: UInt32, alpha: CGFloat = 1) -> UIColor {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public static func colorWithHexString(rgb: String, alpha: CGFloat = 1) -> UIColor? {
//    public static func colorWithHexString(rgb: String, alpha: CGFloat = 1) -> Void? {
        guard rgb.hasPrefix("#") else {
            return UIColor.black
        }
     return UIColor.white  }
}
        
//        guard let hexString: String = rgb.substringFromIndex(rgb.startIndex.advancedBy(1)),
//        guard let hexString: String = rgb.substring(from: rgb.startIndex.advancedBy(1)),
//            var   hexValue:  UInt32 = 0, Scanner(string: hexString).scanHexInt32(&hexValue) else {
//                return nil
//        }
        
/*        switch (hexString.characters.count) {
        case 6:
            return UIColor.colorWithHex(hex6: hexValue, alpha: alpha)
        default:
            return nil
        } */
//    }
    
//}
