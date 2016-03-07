//
//  TableInputCell.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/13/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

/**
 not currently used -
 
 */
public class TextInputTableViewCell : UITableViewCell {

    var cellInput : UITextField!

    public func configure(text: String, placeholder: String, asPassword: Bool) {
        cellInput.adjustsFontSizeToFitWidth = true
        cellInput.textColor = UIColor.blackColor()
        cellInput.text = text
        cellInput.placeholder = placeholder
        if ( asPassword ) {
            cellInput.keyboardType = UIKeyboardType.Default
            cellInput.returnKeyType = UIReturnKeyType.Done
            cellInput.secureTextEntry = true
        }
        else {
            cellInput.keyboardType = UIKeyboardType.EmailAddress
            cellInput.returnKeyType = UIReturnKeyType.Next
        }
        cellInput.backgroundColor = UIColor.whiteColor()
        cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
        cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support
        cellInput.textAlignment = NSTextAlignment.Left
        cellInput.tag = 0

        cellInput.clearButtonMode = UITextFieldViewMode.Never // no clear 'x' button to the right
        cellInput.enabled = true
    }
}