//
//  InfoCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class InfoCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var inputTxtField: AppTextField!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var textValueCommentLbl: UILabel!
    
    @IBOutlet weak var commentLabelXConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftOffsetConstraint: NSLayoutConstraint!
    
    private var textOffsetIsSamll = false
    
    private var cellIconImage: UIImage? {
        didSet {
            cellImage?.image = cellIconImage
            
            let titleLeftOffset : CGFloat = cellIconImage == nil ? 0 : (textOffsetIsSamll ? 46 : 60)
            
            titleLeftOffsetConstraint.constant = titleLeftOffset
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        inputTxtField.addTarget(self, action: #selector(InputCollectionViewCell.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        inputTxtField.delegate = self
        
        inputTxtField.textColor = UIColor.whiteColor()
        
        addDoneToolbar(toTextField: inputTxtField)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImage?.image = nil
        inputTxtField.text = nil
        titleLbl.text = nil
        textValueCommentLbl.text = nil
        
        inputTxtField.secureTextEntry = false
        inputTxtField.keyboardType = UIKeyboardType.Default
        
        
    }
    
    func setImageWithName(imageName: String?, smallTextOffset: Bool = false) {
        
        textOffsetIsSamll = smallTextOffset
        
        var image: UIImage?
        if let imgName = imageName {
            image = UIImage(named: imgName)
        }
        
        cellIconImage = image
    }
    
    override func valueChanged(newValue: AnyObject?) {
        super.valueChanged(newValue)
    }
    
}
