//
//  CollectionViewCell.swift
//  SimpleApp
//
//  Created by Yanif Ahmad on 9/18/15.
//  Copyright © 2015 Yanif Ahmad. All rights reserved.
//

import UIKit

/**
 Probably can be removed : no longer hooked into anything 

 */
class CollectionViewCell: UICollectionViewCell {
    
    var button : PlotButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        asButton(0)
    }

    func asButton(plotType : Int) {
        let buttonFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        button = PlotButton(plot: plotType, frame: buttonFrame)
        button.setTitle("Plot \(plotType)", forState: .Normal)
        button.setTitleColor(plotType < 5 ? UIColor.blackColor() : UIColor.blueColor(), forState: .Normal)
        button.titleLabel!.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
        button.titleLabel!.textAlignment = .Center
        contentView.addSubview(button)
    }
    
    func setText(msg : String) {
        button.setTitle(msg, forState: .Normal)
    }
    
    func setPlotType(plotType : Int) {
        button.plotType = plotType
        button.setTitleColor(plotType < 5 ? UIColor.blackColor() : UIColor.blueColor(), forState: .Normal)
    }
    
    func isButton() -> Bool {
        return button != nil
    }
}