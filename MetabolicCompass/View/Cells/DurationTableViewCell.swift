//
//  DurationTableViewCell.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DurationTableViewCell: BaseAddEventTableViewCell {
    
    @IBOutlet weak var durationLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
