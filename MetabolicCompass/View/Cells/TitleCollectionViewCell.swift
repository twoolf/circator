//
//  TitleCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class TitleCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLbl.text = nil
    }
}
