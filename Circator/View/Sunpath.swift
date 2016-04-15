//
//  Sunpath.swift
//  Circator
//
//  Created by Edwin L. Whitman on 4/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class SunpathView : UIView {
    
    lazy var colors : [CGColor] = {
        
        var color1 = UIColor(red: 32/255.0, green: 54/255.0, blue: 78/255.0, alpha: 1.0).CGColor
        var color2 = UIColor(red: 113/255.0, green: 129/255.0, blue: 165/255.0, alpha: 1.0).CGColor
        var color3 = UIColor(red: 222/255.0, green: 169/255.0, blue: 167/255.0, alpha: 1.0).CGColor
        var color4 = UIColor(red: 255/255.0, green: 238/255.0, blue: 177/255.0, alpha: 1.0).CGColor
        var color5 = UIColor(red: 249/255.0, green: 201/255.0, blue: 148/255.0, alpha: 1.0).CGColor
        var color6 = UIColor(red: 62/255.0, green: 110/255.0, blue: 137/255.0, alpha: 1.0).CGColor
        var color7 = UIColor(red: 32/255.0, green: 54/255.0, blue: 78/255.0, alpha: 1.0).CGColor
        
        return [color1, color2, color3, color4, color5, color6, color7]
    }()
    
    var locations : [CGFloat] = [CGFloat(0.0), CGFloat(1.0/6), CGFloat((1.0/6)*2), CGFloat((1.0/6)*3), CGFloat((1.0/6)*4), CGFloat((1.0/6)*5), CGFloat(1.0)]
    
    func getColors() -> [CGColor] {
        return self.colors
    }
    
    func getLocations() -> [CGFloat] {
        return self.locations
    }
    
    override func drawRect(rect: CGRect) {
        
        print(self.getColors())
        
        print(self.getLocations())
        
        self.setNeedsDisplay()
        
        let context = UIGraphicsGetCurrentContext()
        let colors = self.getColors()
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = self.getLocations()
        
        //5 - create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
        
        
        //6 - draw the gradient
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x:0, y:self.bounds.height)
        

        CGContextDrawLinearGradient(context,
                                    gradient,
                                    startPoint,
                                    endPoint,
                                    CGGradientDrawingOptions.DrawsBeforeStartLocation)
        
    
        
    }
}



class SunpathDuoView : UIView {
    
    lazy var colors : [CGColor] = {
        
        var color1 = UIColor(red: 32/255.0, green: 54/255.0, blue: 78/255.0, alpha: 1.0).CGColor
        var color2 = UIColor(red: 113/255.0, green: 129/255.0, blue: 165/255.0, alpha: 1.0).CGColor
        var color3 = UIColor(red: 222/255.0, green: 169/255.0, blue: 167/255.0, alpha: 1.0).CGColor
        var color4 = UIColor(red: 255/255.0, green: 238/255.0, blue: 177/255.0, alpha: 1.0).CGColor
        var color5 = UIColor(red: 249/255.0, green: 201/255.0, blue: 148/255.0, alpha: 1.0).CGColor
        var color6 = UIColor(red: 62/255.0, green: 110/255.0, blue: 137/255.0, alpha: 1.0).CGColor
        var color7 = UIColor(red: 32/255.0, green: 54/255.0, blue: 78/255.0, alpha: 1.0).CGColor
        
        return [color1, color2, color3, color4, color5, color6, color7]
    }()
    
    var locations : [CGFloat] = [CGFloat(0.0), CGFloat(1.0/6), CGFloat((1.0/6)*2), CGFloat((1.0/6)*3), CGFloat((1.0/6)*4), CGFloat((1.0/6)*5), CGFloat(1.0)]
    
    func getStart() -> Int {
        return Int(floor(6 * Double((NSDate().hour * 3600) + (NSDate().minute * 60)) / (24*3600)))
    }
    
    func getColors() -> [CGColor] {
        let index : Int = getStart()
        return [self.colors[index], self.colors[index + 1]]
    }
    
    func getLocations() -> [CGFloat] {
        return [0.0, 1.0]
    }
    
    override func drawRect(rect: CGRect) {
        
        self.getStart()
        

        self.setNeedsDisplay()
        
        let context = UIGraphicsGetCurrentContext()
        let colors = self.getColors()
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = self.getLocations()
        
        //5 - create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
        
        //6 - draw the gradient
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x:0, y:self.bounds.height)
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions.DrawsBeforeStartLocation)
    }
}

/*
func drawSunpathRectangleGradient(rect: CGRect) -> UIImage {
    
    let colors : [CGColor] = {
        
        let color1 = UIColor(red: 192.0/255.0, green: 38.0/255.0, blue: 42.0/255.0, alpha: 1.0).CGColor
        let color2 = UIColor.orangeColor().CGColor
        let color3 = UIColor.magentaColor().CGColor
        let color4 = UIColor.yellowColor().CGColor
        let color5 = UIColor.lightGrayColor().CGColor
        let color6 = UIColor(red: 12/255.0, green:40/255.0, blue: 64/255.0, alpha: 1.0).CGColor
        let color7 = UIColor(red: 4/255.0, green: 9/255.0, blue: 19/255.0, alpha: 1.0).CGColor
        let color8 = UIColor.blueColor().CGColor
        
        return [color1, color2, color3, color4, color5, color6, color7, color8]
    }()
    
    let locations : [CGFloat] = [CGFloat(0), CGFloat(1/7), CGFloat((1/7)*2), CGFloat((1/7)*3), CGFloat((1/7)*4), CGFloat((1/7)*5), CGFloat((1/7)*6), CGFloat((1/7)*7)]
    
    //creates vector path of circle bounded in canvas square
    let path = UIBezierPath(rect: rect)
    
    //creates core graphics contexts and assigns reference
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    let context = UIGraphicsGetCurrentContext()
    
    //set up the color space
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    
    /*
     //3 - set up the color space
     let colorSpace = CGColorSpaceCreateDeviceRGB()
     
     //4 - set up the color stops
     //5 - create the gradient
     
    let gradient = CGGradientCreateWithColors(colorSpace, colors, locations)
    
    //6 - draw the gradient
    let startPoint = CGPoint.zero
    let endPoint = CGPoint(x:0, y:rect.height)
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions.DrawsBeforeStartLocation)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
    */
}


//renders image of circle using bezier path
public func drawCircle(FillColor color : UIColor) -> UIImage {
    
    let circleImage : UIImage = {
        
        //creates square in pixels as bounds of canvas
        let canvas = CGRectMake(0, 0, 100, 100)
        
        //creates vector path of circle bounded in canvas square
        let path = UIBezierPath(ovalInRect: canvas)
        
        //creates core graphics contexts and assigns reference
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        //sets context's fill register with color
        CGContextSetFillColorWithColor(context, color.CGColor)
        
        //draws path in context
        CGContextBeginPath(context)
        CGContextAddPath(context, path.CGPath)
        
        //draws path defined in canvas within graphics context
        CGContextDrawPath(context, .Fill)
        
        //creates UIImage from current graphics contexts and returns
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()
    
    return circleImage
}
*/
