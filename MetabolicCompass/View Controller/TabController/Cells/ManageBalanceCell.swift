//
//  ManageBalanceCell.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class ManageBalanceCell: UITableViewCell {
    
        
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var leftImage: UIImageView!
    var sampleTypesIndex: Int = 0
    weak var data: DashboardMetricsConfigItem!
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
