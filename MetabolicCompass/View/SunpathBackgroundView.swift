//
//  SunpathBackgroundView.swift
//  MetabolicCompass 
//
//  Created by Edwin L. Whitman on 5/25/16. 
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

/*
//create uicolor object from hexstring
//http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
extension UIColor {
    /// UIColor(hexString: "#cc0000")
    internal convenience init?(hexString:String) {
        guard hexString.characters[hexString.startIndex] == Character("#") else {
            return nil
        }
        guard hexString.count == "#000000".count else {
            return nil
        }
        let digits = hexString.substringFromIndex(hexString.startIndex.advancedBy(1))
        guard Int(digits,radix:16) != nil else{
            return nil
        }
        let red = digits.substringToIndex(digits.startIndex.advancedBy(2))
        let green = digits.substringWithRange(Range<String.Index>(start: digits.startIndex.advancedBy(2),
            end: digits.startIndex.advancedBy(4)))
        let blue = digits.substringWithRange(Range<String.Index>(start:digits.startIndex.advancedBy(4),
            end:digits.startIndex.advancedBy(6)))
        let redf = CGFloat(Double(Int(red, radix:16)!) / 255.0)
        let greenf = CGFloat(Double(Int(green, radix:16)!) / 255.0)
        let bluef = CGFloat(Double(Int(blue, radix:16)!) / 255.0)
        self.init(red: redf, green: greenf, blue: bluef, alpha: CGFloat(1.0))
    }
}

//sunpath color hexstrings
public enum SunpathColors : String {
    
    case Dawn = "506584"
    case Morning = "dca8a7"
    case Noon = "fbedb1"
    case Afternoon = "f9c995"
    case Dusk = "356984"
    case Night = "1e354c"
    
}*/



public class Sunpath : UIView {
    
    
    let colors : [CGColor] = {
        
        var dawn = UIColor(red: 113/255.0, green: 129/255.0, blue: 165/255.0, alpha: 1.0).cgColor
        var morning = UIColor(red: 222/255.0, green: 169/255.0, blue: 167/255.0, alpha: 1.0).cgColor
        var noon = UIColor(red: 255/255.0, green: 238/255.0, blue: 177/255.0, alpha: 1.0).cgColor
        var afternoon = UIColor(red: 249/255.0, green: 201/255.0, blue: 148/255.0, alpha: 1.0).cgColor
        var dusk = UIColor(red: 62/255.0, green: 110/255.0, blue: 137/255.0, alpha: 1.0).cgColor
        var night = UIColor(red: 32/255.0, green: 54/255.0, blue: 78/255.0, alpha: 1.0).cgColor
        
        return [night, dawn, morning, noon, afternoon, dusk, night]
    }()
    
    var locations : [CGFloat] = [CGFloat(0.0), CGFloat(1.0/6), CGFloat((1.0/6)*2), CGFloat((1.0/6)*3), CGFloat((1.0/6)*4), CGFloat((1.0/6)*5), CGFloat(1.0)]
    
    func getStart() -> Int {
        return Int(floor(6 * Double((Date().hour * 3600) + (Date().minute * 60)) / (24*3600)))
    }
    
    func getColors() -> [CGColor] {
        let index : Int = getStart()
        return [self.colors[index], self.colors[index + 1]]
    }
    
    func getLocations() -> [CGFloat] {
        return [0.0, 1.0]
    }
    
    override public func draw(_ rect: CGRect) {
        
        self.getStart()
        
        
        self.setNeedsDisplay()
        
        let context = UIGraphicsGetCurrentContext()
        let colors = self.getColors()
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = self.getLocations()
        
        //5 - create the gradient
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)
        
        //6 - draw the gradient
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x:0, y:self.bounds.height)
        
        context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions.drawsBeforeStartLocation)
    }
}

class SunpathBackgroundView : UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let gradient = Sunpath()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(gradient)
        
        let gradientConstraints : [NSLayoutConstraint] = [
        
            gradient.topAnchor.constraint(equalTo: self.topAnchor),
            gradient.leftAnchor.constraint(equalTo: self.leftAnchor),
            gradient.rightAnchor.constraint(equalTo: self.rightAnchor),
            gradient.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ]
        
        self.addConstraints(gradientConstraints)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(blurEffectView)
        
        let blurEffectViewConstraints : [NSLayoutConstraint] = [
            
            
            blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView.leftAnchor.constraint(equalTo: self.leftAnchor),
            blurEffectView.rightAnchor.constraint(equalTo: self.rightAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ]
        
        self.addConstraints(blurEffectViewConstraints)
    }
}
