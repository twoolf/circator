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
        titleLbl.font = ScreenManager.appFontOfSize(15)
    }
}

public class AdditionalInfoDataSource: BaseDataSource {

    let model = AdditionalInfoModel()

    var editMode = true

    private let titledInputCellIdentifier = "titledInputCell"
    private let scrollSelectionCellIdentifier = "scrollSelectionCell"

    override func registerCells() {
        let loadImageCellNib = UINib(nibName: "TitledInputCollectionViewCell", bundle: nil)
        collectionView?.registerNib(loadImageCellNib, forCellWithReuseIdentifier: titledInputCellIdentifier)

        let scrollSelectionCellNib = UINib(nibName: "ScrollSelectionViewCell", bundle: nil)
        collectionView?.registerNib(scrollSelectionCellNib, forCellWithReuseIdentifier: scrollSelectionCellIdentifier)
        
        let physiologicalHeaderViewNib = UINib(nibName: "PhysiologicalHeaderView", bundle: nil)
        collectionView?.registerNib(physiologicalHeaderViewNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "sectionHeaderView")
    }

    internal func isSleepCellAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0 && indexPath.row == 0
    }

    // MARK: - UICollectionView DataSource & Delegate

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return model.sections.count
    }

    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.numberOfItemsInSection(section)
    }

    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = model.itemAtIndexPath(indexPath)

        if isSleepCellAtIndexPath(indexPath) {
            // it is sleep cell
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(scrollSelectionCellIdentifier, forIndexPath: indexPath) as! ScrollSelectionViewCell

            cell.minValue = 3
            cell.maxValue = 12

            cell.titleLbl.text = item.name
            cell.smallDescriptionLbl.text = item.unitsTitle
            cell.pickerShown = editMode

            cell.titleLbl.font = AdditionalInfoFont
            cell.smallDescriptionLbl.font = AdditionalInfoUnitsFont
            cell.valueLbl.font = AdditionalInfoFont

            if let value = item.intValue() where value > 0 {
                cell.setSelectedValue(value)
            } else {
                let defaultValue = 8
                self.model.setNewValueForItem(atIndexPath: indexPath, newValue: defaultValue)
                cell.setSelectedValue(defaultValue)
            }
            cell.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in
                if let indexPath = self.collectionView!.indexPathForCell(cell) {
                    self.model.setNewValueForItem(atIndexPath: indexPath, newValue: newValue)
                }
            }
            return cell
        }

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(titledInputCellIdentifier, forIndexPath: indexPath) as! TitledInputCollectionViewCell

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

        var keypadType = UIKeyboardType.Default
        if item.dataType == .Int {
            keypadType = UIKeyboardType.NumberPad
        }
        else if item.dataType == .Decimal {
            keypadType = UIKeyboardType.DecimalPad
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
            if let indexPath = self.collectionView!.indexPathForCell(cell) {
                self.model.setNewValueForItem(atIndexPath: indexPath, newValue: newValue)
            }
        }

        cell.userInteractionEnabled = editMode
        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "sectionHeaderView", forIndexPath: indexPath) as! HeaderView
            headerView.titleLbl.text = model.sectionTitleAtIndexPath(indexPath)
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSizeMake(CGRectGetWidth(collectionView.frame), 50)
    }

    // MARK: - Cells sizes
    private let cellHeight: CGFloat = 60
    private let cellHeightHight: CGFloat = 110

    private func defaultCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHeight)
        return size
    }

    private func intPickerCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, editMode ? cellHeightHight : cellHeight)
        return size
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return isSleepCellAtIndexPath(indexPath) ? intPickerCellSize() : defaultCellSize()
    }

    func reset() {
        self.model.updateValues()
    }
}
