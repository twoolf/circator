//
//  PhysioParameterCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//
import UIKit

class PhysioParameterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var inputTxtField: UITextField!
    @IBOutlet weak var smallDescriptionLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        inputTxtField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
//        
//        inputTxtField.addTarget(self, action: #selector(InputCollectionViewCell.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
//        inputTxtField.delegate = self
//        
//        addDoneToolbar(toTextField: inputTxtField)
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        
//        titleLbl.text = nil
//        inputTxtField.text = nil
//        smallDescriptionLbl.text = nil
//    }
    
}