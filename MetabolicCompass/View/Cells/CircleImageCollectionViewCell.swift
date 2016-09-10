//
//  CircleImageCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class CircleImageCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var photoImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        photoImg.makeCircled()
    }

}
