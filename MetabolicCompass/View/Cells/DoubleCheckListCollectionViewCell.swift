//
//  DoubleCheckListCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DoubleCheckListCollectionViewCell: BaseCollectionViewCell, CheckBoxProtocol {

    var selectedTextColor = UIColor.whiteColor()
    var unselectedTextColor = UIColor.lightGrayColor()
    
    @IBOutlet private weak var firstCheckBox: CheckBox!
    @IBOutlet private weak var secondCheckBox: CheckBox!
    
    @IBOutlet private weak var firstLbl: UILabel!
    @IBOutlet private weak var secondLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        firstCheckBox.delegate = self
        secondCheckBox.delegate = self
    }
    
    
    func setFirstTitle(firstTitle: String) {
        self.firstLbl.text = firstTitle
    }
    
    func setSecondTitle(firstTitle: String) {
        self.secondLbl.text = firstTitle
    }
    
    
    func setSelectedItem(selectedItemIndex index: Int) {
        if index < 0 || index > 1 {
           selectItemAtIndex(0)
        }
        else {
            selectItemAtIndex(index)
        }
    }
    
    private func selectItemAtIndex(index: Int) {
        let selectedCheckBox = index == 0 ? firstCheckBox : secondCheckBox
        let unselectedCheckBox = index == 0 ? secondCheckBox : firstCheckBox
        
        selectedCheckBox.isChecked = true
        unselectedCheckBox.isChecked = false

        layoutTitles()
    }
    
    private func layoutTitles() {
        firstLbl.textColor = firstCheckBox.isChecked ? selectedTextColor : unselectedTextColor
        secondLbl.textColor = secondCheckBox.isChecked ? selectedTextColor : unselectedTextColor
    }
    
    // MARK: - CheckBox Protocol
    
    func checkBoxValueChanged(sender: CheckBox, newValue: Bool) {
        let anotherCheckBox = sender == firstCheckBox ? secondCheckBox : firstCheckBox
        anotherCheckBox.isChecked = !newValue
        
        layoutTitles()
        
        // send new selected index
        let selectedIndex = firstCheckBox.isChecked ? 0 : 1
        valueChanged(selectedIndex)
        
    }
    
}