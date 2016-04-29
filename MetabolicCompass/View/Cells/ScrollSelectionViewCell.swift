//
//  ScrollSelectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/29/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import AKPickerView_Swift


class ScrollSelectionViewCell: BaseCollectionViewCell, AKPickerViewDataSource, AKPickerViewDelegate {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var valueLbl: UITextField!
    @IBOutlet weak var smallDescriptionLbl: UILabel!
    @IBOutlet weak var scrollContainerView: UIView!
    
    private var pickerView: AKPickerView?
    
    var minValue: Int = 1
    var maxValue: Int = 10
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        pickerView = AKPickerView(frame: scrollContainerView.bounds)
        scrollContainerView.addSubview(pickerView!)
        
        pickerView!.delegate = self
        pickerView!.dataSource = self
        
        pickerView!.interitemSpacing = 50
        
        let pickerFont = UIFont.systemFontOfSize(16.0)
        pickerView!.font = pickerFont
        pickerView!.highlightedFont = pickerFont
        
        pickerView!.highlightedTextColor = UIColor.whiteColor()
        pickerView!.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
    }
    
    
    @objc func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return (maxValue - minValue) + 1
    }
    
    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        let value = item + minValue
        return String(value)
    }
    
    func setSelectedValue(value: Int) {
        let valueIndex = value - minValue
        pickerView?.selectItem(valueIndex)
        valueLbl.text = String(value)
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        let value = item + minValue
        valueLbl.text = String(value)
        valueChanged(value)
    }
}
