//
//  TitleCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/12/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class TitleCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet weak var accessoryView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        separatorView?.backgroundColor = UIColor.black
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLbl.text = nil
        
        hasAccessoryView = true
    }
    
    var hasAccessoryView: Bool = true {
        didSet {
            accessoryView.isHidden = !hasAccessoryView
        }
    }
    
}
