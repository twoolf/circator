//
//  SlideButtonArray.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import AKPickerView_Swift

public protocol SlideButtonArrayDelegate {
    func layoutDefault() -> Void
}

public class SlideButtonArray: UIView, SlideButtonArrayDelegate {

    public var buttonsTagBase: Int
    public var arrayRowIndex: Int
    public var activeButtonIndex: Int

    public var exclusiveArrays: [SlideButtonArrayDelegate!] = []

    var buttons: [UIButton] = []
    var pickers: [AKPickerView] = []
    var managers: [PickerManager] = []

    var delegate: PickerManagerSelectionDelegate! = nil {
        didSet {
            self.managers.forEach { $0.delegate = delegate }
        }
    }

    var firstLayout = true
    var buttonLeadingConstraints: [NSLayoutConstraint] = []
    var pickerLeadingConstraints: [NSLayoutConstraint] = []

    public init(frame: CGRect, buttonsTag: Int, arrayRowIndex: Int) {
        self.buttonsTagBase = buttonsTag
        self.arrayRowIndex = arrayRowIndex
        self.activeButtonIndex = -1
        super.init(frame: frame)
        setupButtonArray()
    }

    required public init?(coder aDecoder: NSCoder) {
        buttonsTagBase = aDecoder.decodeIntegerForKey("buttonsTagBase")
        arrayRowIndex = aDecoder.decodeIntegerForKey("arrayRowIndex")
        activeButtonIndex = aDecoder.decodeIntegerForKey("activeButtonIndex")
        super.init(coder: aDecoder)
    }

    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(buttonsTagBase, forKey: "buttonsTagBase")
        aCoder.encodeInteger(arrayRowIndex, forKey: "arrayRowIndex")
        aCoder.encodeInteger(activeButtonIndex, forKey: "activeButtonIndex")
    }

    private func setupButtonArray() {
        var buttonSpecs: [(String, String, [(String, Double)])] = []

        if arrayRowIndex == 0 {
            let mealPickerData : [(String, Double)] =
                [5, 10, 15, 20, 30, 45, 60, 75, 90, 120].map { ("\(Int($0)) m", $0) }

            buttonSpecs = [
                ("Breakfast", "icon-breakfast-quick", mealPickerData),
                ("Lunch", "icon-lunch-quick", mealPickerData),
                ("Dinner", "icon-dinner-quick", mealPickerData),
                ("Snack", "icon-snack-quick", mealPickerData)
            ]
        } else {
            let exercisePickerData : [(String, Double)] =
                [5, 10, 15, 20, 30, 45, 60, 75, 90, 120].map { ("\(Int($0)) m", $0)}

            let sleepPickerData : [(String, Double)] = (1...30).map { i in
                let h = Double(i) / 2
                let s = String(format: i >= 20 ? "%.3g" : "%.2g", h)
                return ("\(s) h", h)
            }

            buttonSpecs = [
                ("Running", "icon-running-quick", exercisePickerData),
                ("Exercise", "icon-exercises-quick", exercisePickerData),
                ("Cycling", "icon-cycling-quick", exercisePickerData),
                ("Sleep", "icon-sleep-quick", sleepPickerData)
            ]
        }

        let screenSize = UIScreen.mainScreen().bounds.size

        buttonSpecs.enumerate().forEach { (index, spec) in
            let button = UIButton(frame: CGRectMake(0, 0, 60, 60))
            button.tag = self.buttonsTagBase + index
            button.backgroundColor = .clearColor()

            button.setImage(UIImage(named: spec.1), forState: .Normal)
            button.imageView?.contentMode = .ScaleAspectFit

            button.setTitle(spec.0, forState: .Normal)
            button.setTitleColor(UIColor.ht_midnightBlueColor(), forState: .Normal)
            button.titleLabel?.contentMode = .Center
            button.titleLabel?.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightBold)

            let imageSize: CGSize = button.imageView!.image!.size
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -((screenSize.height < 569 ? 0.62 : 0.7) * imageSize.height), 0.0)

            /*
             let labelString = NSString(string: button.titleLabel!.text!)
             let titleSize = labelString.sizeWithAttributes([NSFontAttributeName: button.titleLabel!.font])
             button.imageEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, -titleSize.width)
             */

            button.addTarget(self, action: #selector(self.handleTap(_:)), forControlEvents: .TouchUpInside)

            var pickerData: [String: AnyObject] = [:]
            spec.2.forEach { pickerData[$0.0] = $0.1 }
            let manager = PickerManager(itemType: spec.0, items: spec.2.map { $0.0 }, data: pickerData)
            manager.delegate = delegate

            let picker = AKPickerView()
            picker.delegate = manager
            picker.dataSource = manager
            picker.interitemSpacing = 50

            let pickerFont = UIFont(name: "GothamBook", size: 18.0)!
            picker.font = pickerFont
            picker.highlightedFont = pickerFont

            picker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
            picker.highlightedTextColor = UIColor.whiteColor()
            picker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
            picker.reloadData()

            buttons.append(button)
            managers.append(manager)
            pickers.append(picker)
        }

        initializeLayout()
    }

    func initializeLayout() {
        let numButtons = buttons.count
        activeButtonIndex = -1

        buttons.enumerate().forEach { (index, button) in
            let picker = self.pickers[index]
            picker.layer.opacity = 0.0

            button.translatesAutoresizingMaskIntoConstraints = false
            picker.translatesAutoresizingMaskIntoConstraints = false
            addSubview(button)
            addSubview(picker)

            var constraints: [NSLayoutConstraint] = [
                button.topAnchor.constraintEqualToAnchor(topAnchor),
                button.heightAnchor.constraintEqualToAnchor(heightAnchor),
                button.leadingAnchor.constraintEqualToAnchor(index == 0 ? leadingAnchor : buttons[index-1].trailingAnchor, constant: 5.0),
                button.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: 1.0 / CGFloat(numButtons), constant: -5),
                picker.topAnchor.constraintEqualToAnchor(button.topAnchor),
                picker.heightAnchor.constraintEqualToAnchor(heightAnchor),
                picker.leadingAnchor.constraintEqualToAnchor(button.trailingAnchor, constant: -3000),
                picker.widthAnchor.constraintEqualToAnchor(widthAnchor, multiplier: (CGFloat(numButtons) - 1.0) / CGFloat(numButtons), constant: 0.0)
            ]

            buttonLeadingConstraints.append(constraints[2])
            pickerLeadingConstraints.append(constraints[6])

            addConstraints(constraints)
        }

        self.layoutIfNeeded()
    }

    func fixLayout() {
        let numButtons = buttons.count
        removeConstraints(buttonLeadingConstraints)
        buttonLeadingConstraints.removeAll()

        buttons.enumerate().forEach { (index, button) in
            let o = 5 + (CGFloat(index) * self.frame.width) / CGFloat(numButtons)
            let c = button.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: o)
            self.addConstraint(c)
            buttonLeadingConstraints.append(c)
        }
        self.layoutIfNeeded()
    }

    public func layoutDefault() {
        let numButtons = buttons.count
        let prevActiveButtonIndex = activeButtonIndex
        activeButtonIndex = -1

        if firstLayout {
            firstLayout = false
            fixLayout()
        }

        buttonLeadingConstraints.enumerate().forEach { (index, constraint) in
            constraint.constant = 5 + ( (CGFloat(index) * self.frame.width) / CGFloat(numButtons) )
        }

        pickerLeadingConstraints.forEach { $0.constant = -3000.0 }

        UIView.animateWithDuration(0.4, animations: {
            self.buttons.forEach { $0.layer.opacity = 1.0 }
            if prevActiveButtonIndex >= 0 {
                self.pickers[prevActiveButtonIndex].layer.opacity = 0.0
            }
            self.layoutIfNeeded()
        })
    }

    func layoutFocused(buttonTag: Int) {
        let index = buttonTag - self.buttonsTagBase
        let numButtons = buttons.count

        if firstLayout {
            firstLayout = false
            fixLayout()
        }

        if 0 <= index && index < numButtons {
            activeButtonIndex = index

            buttonLeadingConstraints.enumerate().forEach { (index, constraint) in
                if index == activeButtonIndex {
                    // Set the constraint's offset relative to the button's original anchor.
                    constraint.constant = 5.0
                } else {
                    // Move all other buttons offscreen.
                    constraint.constant += self.frame.width * (CGFloat(numButtons+1) / CGFloat(numButtons))
                }
            }

            pickerLeadingConstraints[activeButtonIndex].constant = 0.0

            UIView.animateWithDuration(0.4, animations: {
                self.buttons.enumerate().forEach { if $0.0 != self.activeButtonIndex { $0.1.layer.opacity = 0.0 } }
                self.pickers[self.activeButtonIndex].layer.opacity = 1.0
                self.layoutIfNeeded()
            })
        }

        exclusiveArrays.forEach { array in
            if array != nil { array.layoutDefault() }
        }
    }

    func handleTap(sender: UIButton) {
        if activeButtonIndex >= 0 {
            layoutDefault()
        } else {
            layoutFocused(sender.tag)
        }
    }
    
    func getSelection() -> (PickerManager, String?, Int, String, AnyObject?)? {
        if activeButtonIndex >= 0 {
            let m = managers[activeButtonIndex]
            return (m, m.itemType, m.current, m.getSelectedItem(), m.getSelectedValue())
        }
        return nil
    }
    
}