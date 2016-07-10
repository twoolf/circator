//
//  BalanceBarView.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 7/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

private let fastingViewLabelSize: CGFloat = 12.0
private let fastingViewTextSize: CGFloat = 24.0

public class BalanceBarView : UIView {
    public var ratio: CGFloat = 0.5

    public var color1: UIColor = .redColor()
    public var color2: UIColor = .blueColor()

    private var barTitle: UILabel = UILabel()
    private var barText: UILabel = UILabel()
    private var label1: UILabel = UILabel()
    private var label2: UILabel = UILabel()

    private var barConstraints: [NSLayoutConstraint] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience init(ratio: CGFloat = 0.5, title: NSAttributedString, color1: UIColor, color2: UIColor) {
        self.init(frame: CGRectZero)

        self.ratio = ratio
        self.color1 = color1
        self.color2 = color2

        backgroundColor = .clearColor()
        barTitle.backgroundColor = .clearColor()
        barTitle.font = UIFont.systemFontOfSize(fastingViewLabelSize, weight: UIFontWeightRegular)
        barTitle.textColor = .lightGrayColor()
        barTitle.textAlignment = .Center
        barTitle.attributedText = title

        barText.backgroundColor = .clearColor()
        barText.font = UIFont.systemFontOfSize(fastingViewTextSize, weight: UIFontWeightBold)
        barText.textColor = .whiteColor()
        barText.textAlignment = .Center

        barTitle.translatesAutoresizingMaskIntoConstraints = false
        barText.translatesAutoresizingMaskIntoConstraints = false
        label1.translatesAutoresizingMaskIntoConstraints = false
        label2.translatesAutoresizingMaskIntoConstraints = false

        addSubview(barTitle)
        addSubview(label1)
        addSubview(label2)
        addSubview(barText)

        refreshConstraints(false)
        refreshData()
    }

    public func refreshData() {
        if 0.0 <= ratio && ratio <= 1.0 {
            label1.backgroundColor = color1
            label2.backgroundColor = color2
            barText.text = "\(Int(ratio*100.0))%"
        } else {
            label1.backgroundColor = UIColor.lightGrayColor()
            label2.backgroundColor = UIColor.darkGrayColor()
            barText.text = "N/A"
        }
        setNeedsDisplay()
    }

    public func refreshConstraints(withRemove: Bool) {
        if withRemove {
            removeConstraints(constraints)
        }

        // Clean ratio value
        if ratio < 0.0 || ratio > 1.0 {
            log.warning("Invalid ratio of \(ratio), resetting to 0.5")
            ratio = 0.5
        }

        barConstraints = [
            barTitle.topAnchor.constraintEqualToAnchor(topAnchor),
            barTitle.heightAnchor.constraintEqualToConstant(15.0),
            label1.topAnchor.constraintEqualToAnchor(barTitle.bottomAnchor, constant: 8.0),
            label2.topAnchor.constraintEqualToAnchor(label1.topAnchor),
            label1.bottomAnchor.constraintEqualToAnchor(bottomAnchor),
            label2.bottomAnchor.constraintEqualToAnchor(label1.bottomAnchor),
            barTitle.leadingAnchor.constraintEqualToAnchor(leadingAnchor),
            barTitle.trailingAnchor.constraintEqualToAnchor(trailingAnchor),
            label1.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: 10.0),
            label2.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -10.0),
            label1.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: ratio, constant: 0.0),
            label2.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 1-ratio, constant: 0.0),
            barText.topAnchor.constraintEqualToAnchor(label1.topAnchor),
            barText.bottomAnchor.constraintEqualToAnchor(label1.bottomAnchor),
            barText.leadingAnchor.constraintEqualToAnchor(label1.leadingAnchor),
            barText.trailingAnchor.constraintEqualToAnchor(label2.trailingAnchor)
        ]
        
        addConstraints(barConstraints)
    }
}