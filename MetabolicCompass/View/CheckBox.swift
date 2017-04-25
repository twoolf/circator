//
//  CheckButton.swift
//  MetabolicCompass 
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit


@objc protocol CheckBoxProtocol {
    func checkBoxValueChanged(sender: CheckBox, newValue: Bool)
}

class CheckBox : AppButton {
    
    let checkedImage = UIImage(named: "checkbox-checked-register")
    let uncheckedImage = UIImage(named: "checkbox-unchecked-register")
    
    weak var delegate: CheckBoxProtocol?
    
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                self.setImage(checkedImage, for: .Normal)
            } else {
                self.setImage(uncheckedImage, forState: .Normal)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addTarget(self, action: #selector(CheckBox.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.isChecked = false
    }
    
    func buttonClicked(sender: UIButton) {
        isChecked = !isChecked
        
        if let _ = delegate {
            delegate!.checkBoxValueChanged(sender as! CheckBox, newValue: isChecked)
        }
    }
    
}
