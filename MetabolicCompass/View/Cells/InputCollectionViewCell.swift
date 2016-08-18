//
//  InputCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class InputCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet weak var inputTxtField: UITextField!
    @IBOutlet weak var nameLbl: UILabel!

    @IBOutlet weak var imageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTxtSpacing: NSLayoutConstraint!
    @IBOutlet weak var labelCellSpacing: NSLayoutConstraint!

    var inputFilter:TextInputFilter?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        inputTxtField.addTarget(self, action: #selector(InputCollectionViewCell.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        inputTxtField.delegate = self
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImage?.image = nil
        inputTxtField.text = nil
        nameLbl.text = nil

        inputTxtField.secureTextEntry = false
        inputTxtField.keyboardType = UIKeyboardType.Default
    }
    
 }
