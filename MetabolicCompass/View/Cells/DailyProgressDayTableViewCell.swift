//
//  DailyProgressDayTableViewCell.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

class DailyProgressDayTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.dayLabel.text = ""
    }
}