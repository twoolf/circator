//
//  AdditionalInfoDataSource.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.   
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

let AdditionalInfoFont = UIFont(name: "GothamBook", size: 16.0)!
let AdditionalInfoUnitsFont = UIFont(name: "GothamBook", size: 12.0)!

class HeaderView: UICollectionReusableView {
    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLbl.font = ScreenManager.appFontOfSize(size: 15)
    }
}

public class AdditionalInfoDataSource: BaseDataSource {

    let model = AdditionalInfoModel()

    var editMode = true

    private let titledInputCellIdentifier = "titledInputCell"
    private let scrollSelectionCellIdentifier = "scrollSelectionCell"

    override func registerCells() {
        let loadImageCellNib = UINib(nibName: "TitledInputCollectionViewCell", bundle: nil)
        collectionView?.register(loadImageCellNib, forCellWithReuseIdentifier: titledInputCellIdentifier)

        let scrollSelectionCellNib = UINib(nibName: "ScrollSelectionViewCell", bundle: nil)
        collectionView?.register(scrollSelectionCellNib, forCellWithReuseIdentifier: scrollSelectionCellIdentifier)
        
        let physiologicalHeaderViewNib = UINib(nibName: "PhysiologicalHeaderView", bundle: nil)
        collectionView?.register(physiologicalHeaderViewNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "sectionHeaderView")
    }

    internal func isSleepCellAtIndexPath(indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && indexPath.row == 0
    }

    // MARK: - UICollectionView DataSource & Delegate

    func numberOfSectionsInCollectionView(_ collectionView: UICollectionView) -> Int {
        return model.sections.count
    }

    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.numberOfItemsInSection(section)
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = model.itemAtIndexPath(indexPath as IndexPath)

        if isSleepCellAtIndexPath(indexPath: indexPath as IndexPath) {
            // it is sleep cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: scrollSelectionCellIdentifier, for: indexPath as IndexPath) as! ScrollSelectionViewCell

            cell.minValue = 3
            cell.maxValue = 12

            cell.titleLbl.text = item.name
            cell.smallDescriptionLbl.text = item.unitsTitle
            cell.pickerShown = editMode

            cell.titleLbl.font = AdditionalInfoFont
            cell.smallDescriptionLbl.font = AdditionalInfoUnitsFont
            cell.valueLbl.font = AdditionalInfoFont

            if let value = item.intValue(), value > 0 {
                cell.setSelectedValue(value: value)
            } else {
                let defaultValue = 8
                self.model.setNewValueForItem(atIndexPath: indexPath as IndexPath, newValue: defaultValue as AnyObject?)
                cell.setSelectedValue(value: defaultValue)
            }
            cell.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in
                if let indexPath = self.collectionView!.indexPath(for: cell) {
                    self.model.setNewValueForItem(atIndexPath: indexPath as IndexPath, newValue: newValue)
                }
            }
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: titledInputCellIdentifier, for: indexPath as IndexPath) as! TitledInputCollectionViewCell

        cell.titleLbl.text = item.name
        if let strValue = item.stringValue() {
            cell.inputTxtField.text = strValue
            //cell.inputTxtField.font = ScreenManager.appFontOfSize(15.0)
        }
        else {
            cell.inputTxtField.text = nil
            //cell.inputTxtField.font = ScreenManager.appFontOfSize(13.0)
        }

        cell.smallDescriptionLbl.text = item.unitsTitle
        let attr = [NSForegroundColorAttributeName : unselectedTextColor, NSFontAttributeName: AdditionalInfoFont]
        cell.inputTxtField.attributedPlaceholder = NSAttributedString(string: item.title, attributes: attr)

        var keypadType = UIKeyboardType.default
        if item.dataType == .Int {
            keypadType = UIKeyboardType.numberPad
        }
        else if item.dataType == .Decimal {
            keypadType = UIKeyboardType.decimalPad
        }

        cell.inputTxtField.keyboardType = keypadType

        cell.titleLbl.textColor = selectedTextColor
        cell.inputTxtField.textColor = selectedTextColor
        cell.smallDescriptionLbl.textColor = unselectedTextColor

        cell.titleLbl.font = AdditionalInfoFont
        cell.inputTxtField.font = AdditionalInfoFont
        cell.smallDescriptionLbl.font = AdditionalInfoUnitsFont

        cell.titleLbl.adjustsFontSizeToFitWidth = true
        cell.titleLbl.numberOfLines = 0

        cell.inputTxtField.adjustsFontSizeToFitWidth = true
        cell.inputTxtField.minimumFontSize = 10.0

        cell.smallDescriptionLbl.adjustsFontSizeToFitWidth = true
        cell.smallDescriptionLbl.numberOfLines = 1

        cell.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in
            if let indexPath = self.collectionView!.indexPath(for: cell) {
                self.model.setNewValueForItem(atIndexPath: indexPath as IndexPath, newValue: newValue)
            }
        }

        cell.isUserInteractionEnabled = editMode
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeaderView", for: (indexPath as IndexPath) as IndexPath) as! HeaderView
            headerView.titleLbl.text = model.sectionTitleAtIndexPath(indexPath as IndexPath)
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(collectionView.frame.width, 50)
    }

    // MARK: - Cells sizes
    private let cellHeight: CGFloat = 60
    private let cellHeightHight: CGFloat = 110

    private func defaultCellSize() -> CGSize {
        let size = CGSize(self.collectionView!.bounds.width, cellHeight)
        return size
    }

    private func intPickerCellSize() -> CGSize {
        let size = CGSize(self.collectionView!.bounds.width, editMode ? cellHeightHight : cellHeight)
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return isSleepCellAtIndexPath(indexPath: indexPath) ? intPickerCellSize() : defaultCellSize()
    }

    func reset() {
        self.model.updateValues()
    }
}
