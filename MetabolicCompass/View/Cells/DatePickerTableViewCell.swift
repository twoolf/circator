//
//  DatePickerTableViewCell.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DatePickerTableViewCell: UITableViewCell {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    var delegate: DatePickerTableViewCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.contentView.isUserInteractionEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func pickerDateChanged(sender: UIDatePicker) {
        self.delegate?.picker(picker: sender, didSelectDate: sender.date)
    }
}

protocol DatePickerTableViewCellDelegate {
    func picker(picker:UIDatePicker, didSelectDate date:Date)
}
