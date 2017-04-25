//
//  UIComponents.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 8/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import HTPressableButton

class MCButton: HTPressableButton {}

public class UIComponents {

    static public func createLabelledComponent<T>(title: String, attrs: [String: AnyObject]? = nil,
                                                  labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                                  stackAlignment: UIStackViewAlignment = .fill, value: T, constructor: (T) -> UIView) -> UIStackView
    {
        let desc : UILabel = {
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: labelFontSize)!
            label.textColor = .lightGray

            let aString = NSMutableAttributedString(string: title, attributes: attrs)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5.0
            paragraphStyle.alignment = .center
            aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))

            label.attributedText = aString

            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.sizeToFit()
            label.textAlignment = .center

            return label
        }()

        let component : UIView = constructor(value)

        let stack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: labelOnTop ? [desc, component] : [component, desc])
            stack.axis = .vertical
            stack.distribution = UIStackViewDistribution.fill
            stack.alignment = stackAlignment
            stack.spacing = labelSpacing
            return stack
        }()

        /*
        desc.translatesAutoresizingMaskIntoConstraints = false
        let constraints : [NSLayoutConstraint] = [
            desc.heightAnchor.constraintEqualToConstant(labelFontSize+4)
        ]

        stack.addConstraints(constraints)
        */
        return stack
    }

    static public func createNumberLabel(title: String, titleAttrs: [String: AnyObject]? = nil,
                                         bodyFontSize: CGFloat = 44.0, unitsFontSize: CGFloat = 20.0,
                                         labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                         value: Double, unit: String) -> UIStackView
    {
        return UIComponents.createLabelledComponent(title: title, attrs: titleAttrs, labelOnTop: labelOnTop, labelFontSize: labelFontSize,
                                                    labelSpacing: labelSpacing, value: value, constructor: { value in
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: bodyFontSize)!
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0

            let vString = String(format: "%.1f", value)
            let aString = NSMutableAttributedString(string: vString + " " + unit)
            let unitFont = UIFont(name: "GothamBook", size: unitsFontSize)!

            aString.addAttribute(NSFontAttributeName, value: unitFont, range: NSRange(location:vString.characters.count+1, length: unit.characters.count))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2.0
            paragraphStyle.alignment = .center
            aString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aString.length))

            label.attributedText = aString
            return label
        })
    }

    static public func createNumberWithImageAndLabel(title: String, imageName: String,
                                                     titleAttrs: [String: AnyObject]? = nil, bodyFontSize: CGFloat = 66.0, unitsFontSize: CGFloat = 20.0,
                                                     labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                                     value: Double, unit: String, prefix: String? = nil, suffix: String? = nil) -> UIStackView
    {
        return UIComponents.createLabelledComponent(title: title, attrs: titleAttrs,
                                                    labelOnTop: labelOnTop, labelFontSize: labelFontSize, labelSpacing: labelSpacing,
                                                    value: value, constructor:
        { value in
            let label = UILabel()
            label.font = UIFont(name: "GothamBook", size: bodyFontSize)!
            label.textColor = .white
            label.numberOfLines = 0

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

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2.0
            paragraphStyle.alignment = .center
            aStr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aStr.length))

            label.attributedText = aStr

            let imageView = UIImageView(frame: CGRect(0, 0, 110, 110))
            imageView.image = UIImage(named: imageName)
            imageView.contentMode = .scaleAspectFit

            let stack = UIStackView(arrangedSubviews: [imageView, label])
            stack.axis = .horizontal
            stack.distribution = UIStackViewDistribution.fill
            stack.alignment = UIStackViewAlignment.fill
            stack.spacing = 10.0
            return stack
        })
    }
}
