//
//  BaseCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

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
        
        separatorView?.backgroundColor = ScreenManager.sharedInstance.appSeparatorColor()
        separatorLineHeightConstraint?.constant = 0.5
    }
    
    var separatorVisible : Bool = false {
        didSet {
            separatorView?.hidden = !separatorVisible
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImage?.image = nil
        separatorVisible = true
    }
        
    func textFieldDidChange(textField: UITextField) {
        valueChanged(textField.text)
    }
    
    func addDoneToolbar(toTextField textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(title: "Done".localized, style: UIBarButtonItemStyle.Plain, target: self, action:  #selector(TitledInputCollectionViewCell.doneAction(_:)))
        
        toolbar.setItems([doneBtn], animated: false)
        textField.inputAccessoryView = toolbar
    }
    
    func doneAction(Sender: UIBarButtonItem) {
        self.endEditing(true)
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
