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
    @IBOutlet weak var scrollContainerHeight: NSLayoutConstraint!
    
    private var pickerView: AKPickerView?
    
    var minValue: Int = 1
    var maxValue: Int = 10
    
    private var _pickerShown : Bool = true
    var pickerShown : Bool {
        set {
            _pickerShown = newValue;
            scrollContainerView?.hidden = !_pickerShown
            scrollContainerHeight.constant = _pickerShown ? 50.0 : 0.0
        }
        get { return _pickerShown }
    }
    
    
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
        scrollContainerView?.hidden = !_pickerShown
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
        pickerView?.selectItem(max(valueIndex, minValue))
        valueLbl.text = String(value)
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        let value = item + minValue
        valueLbl.text = String(value)
        valueChanged(value)
    }
}
