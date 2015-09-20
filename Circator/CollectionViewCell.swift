//
//  CollectionViewCell.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    var textLabel : UILabel!
    var button : PlotButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let textFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        button = nil
        textLabel = UILabel(frame: textFrame)
        textLabel.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        textLabel.textAlignment = .Center
        contentView.addSubview(textLabel)
    }
    
    func asButton(plotType : Int) {
        textLabel = nil
        let buttonFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        button = PlotButton(plot: plotType, frame: buttonFrame)
        button.setTitle("Button \(plotType)", forState: .Normal)
        button.setTitleColor(UIColor.blueColor(), forState: .Normal)
        contentView.addSubview(button)
    }
}