//
//  Sunpath.swift
//  Circator
//
//  Created by Edwin L. Whitman on 4/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class sunpath {
    
    
    
    internal var colors : [CGColor]
    internal var locations : [Double]
    
    var location1 : Double
    var location2: Double
    var location3: Double
    var location4: Double
    var location5: Double
    var location6: Double
    var location7: Double
    var location8: Double
    
    var cgfloats : [CGFloat]
    
    init() {
        let color1 = UIColor(red: 192.0/255.0, green: 38.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
        let color2 = UIColor.orangeColor().CGColor
        let color3 = UIColor.magentaColor().CGColor
        let color4 = UIColor.yellowColor().CGColor
        let color5 = UIColor.lightGrayColor().CGColor
        let color6 = UIColor(red: 12/255.0, green:40/255.0, blue: 64/255.0, alpha: 1.0).CGColor
        let color7 = UIColor(red: 4/255.0, green: 9/255.0, blue: 19/255.0, alpha: 1.0).CGColor
        let color8 = UIColor.blueColor().CGColor
        self.colors = [ color1, color2, color3, color4, color5, color6, color7, color8]
        
        
        self.location1 = Double(0)
        self.location2 = Double(1/7)
        self.location3 = Double((1/7)*2)
        self.location4 = Double((1/7)*3)
        self.location5 = Double((1/7)*4)
        self.location6 = Double((1/7)*5)
        self.location7 = Double((1/7)*6)
        self.location8 = Double((1/7)*7)
        
        self.locations = [location1, location2, location3, location4, location5, location6, location7, location8]
        
        self.cgfloats = locations.map {
            CGFloat(($0 as Double))
        }
        
    }
}



func drawRect(rect: CGRect) -> UIImage {
    
    let sp = sunpath()
    
    //2 - get the current context
    let context = UIGraphicsGetCurrentContext()
    let colors = sp.colors
    
    //3 - set up the color space
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    //4 - set up the color stops
    //5 - create the gradient
    let gradient = CGGradientCreateWithColors(colorSpace,
                                              colors,
                                              sp.cgfloats)
    
    //6 - draw the gradient
    let startPoint = CGPoint.zero
    let endPoint = CGPoint(x:0, y:rect.height)
    CGContextDrawLinearGradient(context,
                                gradient,
                                startPoint,
                                endPoint,
                                CGGradientDrawingOptions.DrawsBeforeStartLocation)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    
}