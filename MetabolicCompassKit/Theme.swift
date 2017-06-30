
//
//  Theme.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/1/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

/**
 This class sets up the color/theme for the entire Metabolic Compass App.  The choice of colors reflects the Universities color choices as well as typical complementary colors to the primary University colors.
 
 - note: uses University colors
 */
public class Theme: NSObject {

    public static let universityDarkTheme = Theme(.White, .Blue, .White, .Custom(Color.White.color.withAlphaComponent(0.75)), complementForegroundColors: [.Emerald, .Gray, .MilkyGreen, .Crimson])!

    public enum Color {
        case Blue
        case Emerald
        case White
        case Gray
        case LightGray
        case Black
        case MilkyGreen
        case Crimson
        case Custom(UIColor)
        
        public var color: UIColor {
            switch self {
            case .Black:
                return UIColor.black
            case .Emerald:
                return UIColor(red: 71 / 255.0, green: 201 / 255.0, blue: 113 / 255.0, alpha: 1)
            case .White:
                return UIColor.white
            case .LightGray:
                return UIColor(red: 239 / 255.0, green: 241 / 255.0, blue: 243 / 255.0, alpha: 1)
            case .Gray:
                return UIColor(red: 203 / 255.0, green: 212 / 255.0, blue: 194 / 255.0, alpha: 1)
            case .Blue:
                return UIColor(red: 0, green: 45 / 255.0, blue: 114 / 255.0, alpha: 1)
            case .MilkyGreen:
                return UIColor(red: 219 / 255.0, green: 235 / 255.0, blue: 192 / 255.0, alpha: 1)
            case .Crimson:
                return UIColor(red: 215 / 255.0, green: 122 / 255.0, blue: 97 / 255.0, alpha: 1)
            case .Custom(let color):
                return color
            }
        }
    }
    
    /**
     sets up foreground colors for Metabolic Compass

     */
    public class ForegroundColorGroup: ExpressibleByArrayLiteral {
        let foregroundColors: [Color]
        
        public required convenience init(arrayLiteral elements: Color...) {
            self.init(foregroundColors: elements)
        }
        
        public init(foregroundColors: [Color]) {
            self.foregroundColors = foregroundColors.sorted { c1, c2 -> Bool in
                var saturation1: CGFloat = 0
                var saturation2: CGFloat = 0
                c1.color.getHue(nil, saturation: &saturation1, brightness: nil, alpha: nil)
                c2.color.getHue(nil, saturation: &saturation2, brightness: nil, alpha: nil)
                return saturation1 < saturation2
            }
        }
        
        /**
            Returns a foreground color with desired vibrancy (saturation)
        
            - parameter vibrancy: The desired vibrancy, ranged from 0.0 to 1.0.
            - returns: A color with desired vibrancy.
        */
        public func colorWithVibrancy(vibrancy: CGFloat) -> UIColor? {
            let index = Int(floor(vibrancy * CGFloat(foregroundColors.count)))
            if index < 0 {
                return foregroundColors.first?.color
            } else if index >= foregroundColors.count {
                return foregroundColors.last?.color
            } else {
                return foregroundColors[index].color
            }
        }
    }
    
    public var foregroundColor: UIColor
    
    public var backgroundColor: UIColor
    
    public var titleTextColor: UIColor
    
    public var bodyTextColor: UIColor
    
    public var complementForegroundColors: ForegroundColorGroup?

    init?(_ colors: Color..., complementForegroundColors: ForegroundColorGroup? = nil) {
        guard colors.count >= 4 else {
            foregroundColor = UIColor()
            backgroundColor = UIColor()
            titleTextColor = UIColor()
            bodyTextColor = UIColor()
            super.init()
            return nil
        }
        foregroundColor = colors[0].color
        backgroundColor = colors[1].color
        titleTextColor = colors[2].color
        bodyTextColor = colors[3].color
        self.complementForegroundColors = complementForegroundColors
        super.init()
    }
    
}
