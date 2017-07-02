 //
//  ManageDashboardCell.swift
//  MetabolicCompass 
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class ManageDashboardCell: UITableViewCell {

    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var reorderImage: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.button.isUserInteractionEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSelectionStatus (_ selected: Bool, appearanceProvider: DashboardMetricsAppearanceProvider, itemType: String)
    {
        self.button.isSelected = selected
        
        if (selected) {
            self.reorderImage?.image  = UIImage(named: "icon-manage-filters-active")
        }
        else {
            self.reorderImage?.image  = UIImage(named: "icon-manage-filters-unactive")
        }
        
        self.leftImageView.image         = appearanceProvider.imageForSampleType(itemType, active: selected)
        self.captionLabel.attributedText = appearanceProvider.titleForSampleType(itemType, active: selected)
        
    }

}
