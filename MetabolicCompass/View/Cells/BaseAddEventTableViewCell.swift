//
//  BaseAddEventTableViewCell.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class BaseAddEventTableViewCell: UITableViewCell {

    @IBOutlet weak var dropdownImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clearColor()
        self.selectionStyle = .None
    }
    
    func toggleDropDownImage(close: Bool) {
        if close {
            self.dropdownImage.image = UIImage(named: "close-dropdown-button-white")!
        } else {
            self.dropdownImage.image = UIImage(named: "dropdown-button-white")!
        }
    }

}
