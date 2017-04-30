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
            self.checkBoxButton.isSelected = data!.selected
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.checkBoxButton.isUserInteractionEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func didPressButton(sender: AnyObject) {
        self.checkBoxButton.isSelected = !self.checkBoxButton.isSelected;
        self.data?.selected = self.checkBoxButton.isSelected

        if let delegate = self.delegate {
            delegate.didChangeSelectionStatus(selected: self.checkBoxButton.isSelected)
        }
    }

}
