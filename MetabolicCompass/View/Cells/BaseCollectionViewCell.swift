//
//  BaseCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    var changesHandler:((cell: UICollectionViewCell, newValue: AnyObject?)->Void)?
    
    @IBOutlet weak var cellImage: UIImageView?
    @IBOutlet weak var separatorView: UIView?
    @IBOutlet weak var separatorLineHeightConstraint: NSLayoutConstraint?
    
    func valueChanged(newValue: AnyObject?) {
        if let changesBlock = changesHandler {
            changesBlock(cell: self, newValue: newValue)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        separatorView?.backgroundColor = UIColor.lightGrayColor()
        separatorLineHeightConstraint?.constant = 0.5
    }
    
    
    func textFieldDidChange(textField: UITextField) {
        valueChanged(textField.text)
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
