//
//  CollectionViewCell.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var textLabel: UILabel!
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let textFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        textLabel = UILabel(frame: textFrame)
        textLabel.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        textLabel.textAlignment = .Center
        contentView.addSubview(textLabel)
    }
}