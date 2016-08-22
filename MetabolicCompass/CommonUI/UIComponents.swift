//
//  UIComponents.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 8/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

public class UIComponents {

    static public func createLabelledComponent<T>(title: String, labelOnTop: Bool = true,
                                                  labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                                  value: T, constructor: T -> UIView) -> UIStackView {
        let desc : UILabel = {
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: labelFontSize)!
            label.textColor = .lightGrayColor()
            label.textAlignment = .Center
            label.text = title
            return label
        }()

        let component : UIView = constructor(value)

        let stack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: labelOnTop ? [desc, component] : [component, desc])
            stack.axis = .Vertical
            stack.distribution = UIStackViewDistribution.Fill
            stack.alignment = UIStackViewAlignment.Fill
            stack.spacing = labelSpacing
            return stack
        }()

        desc.translatesAutoresizingMaskIntoConstraints = false
        let constraints : [NSLayoutConstraint] = [
            desc.heightAnchor.constraintEqualToConstant(labelFontSize+4)
        ]

        stack.addConstraints(constraints)
        return stack
    }

    static public func createNumberLabel(title: String, bodyFontSize: CGFloat = 44.0, unitsFontSize: CGFloat = 20.0,
                                         labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                         value: Double, unit: String) -> UIStackView
    {
        return UIComponents.createLabelledComponent(title, labelOnTop: labelOnTop, labelFontSize: labelFontSize,
                                                    labelSpacing: labelSpacing, value: value, constructor: { value in
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: bodyFontSize)!
            label.textColor = .whiteColor()
            label.textAlignment = .Center

            let vString = String(format: "%.1f", value)
            let aString = NSMutableAttributedString(string: vString + " " + unit)
            let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!
            aString.addAttribute(NSFontAttributeName, value: unitFont, range: NSRange(location:vString.characters.count+1, length: unit.characters.count))
            label.attributedText = aString
            return label
        })
    }

    static public func createNumberWithImageAndLabel(title: String, imageName: String, bodyFontSize: CGFloat = 66.0, unitsFontSize: CGFloat = 20.0,
                                                     labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                                     value: Double, unit: String, prefix: String? = nil, suffix: String? = nil) -> UIStackView
    {
        return UIComponents.createLabelledComponent(title,
                                                    labelOnTop: labelOnTop, labelFontSize: labelFontSize, labelSpacing: labelSpacing,
                                                    value: value, constructor:
        { value in
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: bodyFontSize)!
            label.textColor = .whiteColor()
            label.textAlignment = .Center

            let prefixStr = prefix ?? ""
            let suffixStr = suffix ?? ""
            let vStr = String(format: "%.1f", value)
            let aStr = NSMutableAttributedString(string: prefixStr + " " + vStr + " " + unit + " " + suffixStr)
            let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!

            if prefixStr.characters.count > 0 {
                let headRange = NSRange(location:0, length: prefixStr.characters.count + 1)
                aStr.addAttribute(NSFontAttributeName, value: unitFont, range: headRange)
            }

            let tailRange = NSRange(location:prefixStr.characters.count + vStr.characters.count + 1, length: unit.characters.count + suffixStr.characters.count + 2)
            aStr.addAttribute(NSFontAttributeName, value: unitFont, range: tailRange)

            label.attributedText = aStr

            let imageView = UIImageView(frame: CGRectMake(0, 0, 110, 110))
            imageView.image = UIImage(named: imageName)
            imageView.contentMode = .ScaleAspectFit

            let stack = UIStackView(arrangedSubviews: [imageView, label])
            stack.axis = .Horizontal
            stack.distribution = UIStackViewDistribution.FillProportionally
            stack.alignment = UIStackViewAlignment.Fill
            stack.spacing = 2.0
            return stack
        })
    }
}
