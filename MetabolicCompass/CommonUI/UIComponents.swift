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
            // label.font = UIFont.systemFontOfSize(labelFontSize, weight: UIFontWeightRegular)
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

    static public func createNumberLabel(title: String,
                                         labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                         value: Double, unit: String) -> UIStackView
    {
        return UIComponents.createLabelledComponent(title, labelOnTop: labelOnTop, labelFontSize: labelFontSize,
                                                    labelSpacing: labelSpacing, value: value, constructor: { value in
            let label = UILabel()
            //label.font = UIFont.systemFontOfSize(44, weight: UIFontWeightRegular)
            label.font = UIFont(name: "GothamBook", size: 44)!
            label.textColor = .whiteColor()
            label.textAlignment = .Center

            let vString = String(format: "%.1f", value)
            let aString = NSMutableAttributedString(string: vString + " " + unit)
            //let unitFont = UIFont.systemFontOfSize(20, weight: UIFontWeightRegular)
            let unitFont = UIFont(name: "GothamBook", size: 20)!
            aString.addAttribute(NSFontAttributeName, value: unitFont, range: NSRange(location:vString.characters.count+1, length: unit.characters.count))
            label.attributedText = aString
            return label
        })
    }

    static public func createNumberWithImageAndLabel(title: String, imageName: String,
                                                     labelOnTop: Bool = true, labelFontSize: CGFloat, labelSpacing: CGFloat = 8.0,
                                                     value: Double, unit: String) -> UIStackView
    {
        return UIComponents.createLabelledComponent(title, labelOnTop: labelOnTop, labelFontSize: labelFontSize,
                                                    labelSpacing: labelSpacing, value: value, constructor: { value in
            let label = UILabel()
            //label.font = UIFont.systemFontOfSize(66, weight: UIFontWeightRegular)
            label.font = UIFont(name: "GothamBook", size: 66)!
            label.textColor = .whiteColor()
            label.textAlignment = .Center

            let vString = String(format: "%.1f", value)
            let aString = NSMutableAttributedString(string: vString + " " + unit)
            //let unitFont = UIFont.systemFontOfSize(20, weight: UIFontWeightRegular)
            let unitFont = UIFont(name: "GothamBook", size: 20)!
            aString.addAttribute(NSFontAttributeName, value: unitFont, range: NSRange(location:vString.characters.count+1, length: unit.characters.count))
            label.attributedText = aString

            let imageView = UIImageView(frame: CGRectMake(0, 0, 110, 110))
            imageView.image = UIImage(named: imageName)
            imageView.contentMode = .ScaleAspectFill

            let stack = UIStackView(arrangedSubviews: [imageView, label])
            stack.axis = .Horizontal
            stack.distribution = UIStackViewDistribution.FillProportionally
            stack.alignment = UIStackViewAlignment.Fill
            stack.spacing = 2.0
            return stack
        })
    }
}
