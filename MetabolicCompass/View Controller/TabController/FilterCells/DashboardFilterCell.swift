//
//  DashboardFilterCell.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

protocol DashboardFilterCellDelegate: NSObjectProtocol {
    func didChangeSelectionStatus(selected: Bool)
}

class DashboardFilterCell: UITableViewCell {

    @IBOutlet weak var checkBoxButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    weak var delegate: DashboardFilterCellDelegate?
    var data: DashboardFilterCellData? {
      
        didSet {
            assert(data != nil)
            guard data != nil else { return }
            self.nameLabel.text = data!.title;
            self.checkBoxButton.selected = data!.selected
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func didPressButton(sender: AnyObject) {
        self.checkBoxButton.selected = !self.checkBoxButton.selected;
        self.data?.selected = self.checkBoxButton.selected
        
        if let delegate = self.delegate {
            delegate.didChangeSelectionStatus(self.checkBoxButton.selected)
        }
    }
    
}
