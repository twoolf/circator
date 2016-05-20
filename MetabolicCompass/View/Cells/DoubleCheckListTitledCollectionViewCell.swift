//
//  DoubleCheckListTitledCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DoubleCheckListTitledCollectionViewCell: DoubleCheckListCollectionViewCell {

    @IBOutlet private weak var titleLbl: UILabel!
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLbl.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.titleLbl.textColor = unselectedTextColor
    }
    
    func setTitle(title: String?) {
        titleLbl.text = title
    }
    
    override func colorsChanged() {
        super.colorsChanged()
        
        self.titleLbl.textColor = unselectedTextColor
    }

}
