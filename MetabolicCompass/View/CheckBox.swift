//
//  CheckButton.swift
//  MetabolicCompass 
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

@objc protocol CheckBoxProtocol {
    func checkBoxValueChanged(_ sender: CheckBox, newValue: Bool)
}

class CheckBox : AppButton {
    
    let checkedImage = UIImage(named: "checkbox-checked-register")
    let uncheckedImage = UIImage(named: "checkbox-unchecked-register")
    
    weak var delegate: CheckBoxProtocol?
    
    var isChecked: Bool = false {
        didSet{
            if isChecked == true {
                self.setImage(checkedImage, for: .normal)
            } else {
                self.setImage(uncheckedImage, for: .normal)
            }
        }
    }
    
    @objc public func buttonClicked(_ sender: UIButton) {
        isChecked = !isChecked
        
        if let _ = delegate {
            delegate!.checkBoxValueChanged(sender as! CheckBox, newValue: isChecked)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.addTarget(self, action: #selector(CheckBox.buttonClicked(_:)), for: UIControlEvents.TouchUpInside)
        self.addTarget(self, action: #selector(CheckBox.buttonClicked(_:)), for: UIControlEvents.touchUpInside)
        self.isChecked = false
    }
    
}
