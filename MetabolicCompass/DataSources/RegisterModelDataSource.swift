//
//  RegisterModelDataSource.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/27/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

let RegisterFont = UIFont(name: "GothamBook", size: 15.0)!
let RegisterUnitsFont = UIFont(name: "GothamBook", size: 13.0)!

class RegisterModelDataSource: BaseDataSource {

    let model = RegistrationModel()

    private let loadImageCellIdentifier = "loadImageCell"
    private let inputTextCellIdentifier = "inputTextCell"
    private let doubleCheckBoxCellIdentifier = "doubleCheckBoxCell"

    override func registerCells() {
        let loadImageCellNib = UINib(nibName: "LoadImageCollectionViewCell", bundle: nil)
        collectionView?.registerNib(loadImageCellNib, forCellWithReuseIdentifier: loadImageCellIdentifier)

        let inputTextCellNib = UINib(nibName: "InputCollectionViewCell", bundle: nil)
        collectionView?.registerNib(inputTextCellNib, forCellWithReuseIdentifier: inputTextCellIdentifier)

        let doubleCheckBoxCellNib = UINib(nibName: "DoubleCheckListCollectionViewCell", bundle: nil)
        collectionView?.registerNib(doubleCheckBoxCellNib, forCellWithReuseIdentifier: doubleCheckBoxCellIdentifier)
    }


    // MARK: - CollectionView Delegate & DataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.items.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let field = model.itemAtIndexPath(indexPath)
        var cell: BaseCollectionViewCell?

        let cellType = field.type

        switch (cellType) {
        case .Email, .Password, .FirstName, .LastName, .Weight, .Height, .HeightInches, .Age, .Other:
            cell = inputCellForIndex(indexPath, forField: field)
        case  .Gender, .Units:
            cell = checkSelectionCellForIndex(indexPath, forField: field)
        case .Photo:
            cell = loadPhotoCellForIndex(indexPath, forField: field)
        }

        cell!.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in
            if let indexPath = self.collectionView!.indexPathForCell(cell) {
                self.model.setAtItem(itemIndex: indexPath.row, newValue: newValue)

                let field = self.model.itemAtIndexPath(indexPath)
                if field.type == .Units {
                    /*
                    let needsUpdateIndexPathes = self.model.unitsDependedItemsIndexes()
                    collectionView.reloadItemsAtIndexPaths(needsUpdateIndexPathes)
                    */
                    self.model.switchItemUnits()
                    self.model.reloadItems()
                    collectionView.reloadData()
                }
            }
        }

        return cell!
    }


    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let field = model.itemAtIndexPath(indexPath)

        if model.units == .Imperial && (field.type == .Weight || field.type == .Height || field.type == .HeightInches) {
            return field.type == .HeightInches ? smallHeightInchesCellSize() : (field.type == .Height ? smallHeightCellSize() : smallWeightCellSize())
        }

        if field.type == .Weight || field.type == .Height {
            return smallCellSize()
        }

        if field.type == .Photo {
            return highCellSize()
        }

        return defaultCellSize()
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return spaceBetweenCellsInOneRow
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footerView", forIndexPath: indexPath)
            return footerView
        }

        return UICollectionReusableView()
    }

    // MARK: - Cells configuration

    private func inputCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(inputTextCellIdentifier, forIndexPath: indexPath) as! InputCollectionViewCell

        cell.inputTxtField.textColor = selectedTextColor
        cell.inputTxtField.attributedPlaceholder = NSAttributedString(string: (field.type == .HeightInches ? "0-11 " : field.title), attributes: [NSForegroundColorAttributeName : unselectedTextColor, NSFontAttributeName: RegisterFont])

        cell.inputTxtField.text = field.stringValue()
        cell.inputTxtField.font = ProfileFont

        cell.nameLbl.font = RegisterFont

        if field.type == .Password {
            cell.inputTxtField.secureTextEntry = true
        }
        else if field.type == .Email {
            cell.inputTxtField.keyboardType = UIKeyboardType.EmailAddress
        }
        else if field.type == .Age {
            cell.inputTxtField.keyboardType = UIKeyboardType.NumberPad
        }

        if let iconImageName = field.iconImageName {
            cell.cellImage?.image = UIImage(named: iconImageName)
            cell.imageLeadingConstraint?.constant = 16
            cell.imageWidthConstraint?.constant = 21
            cell.imageTxtSpacing?.constant = 16
            cell.labelCellSpacing?.constant = 16
        }

        if model.units == .Imperial {
            if field.type == .HeightInches {
                cell.imageLeadingConstraint?.constant = 0
                cell.imageWidthConstraint?.constant = 0
                cell.imageTxtSpacing?.constant = 0
                cell.nameLbl.font = RegisterUnitsFont
            }
            else if field.type == .Height {
                cell.imageLeadingConstraint?.constant = 0
                cell.imageTxtSpacing?.constant = 8
                cell.labelCellSpacing?.constant = 8
                cell.nameLbl.font = RegisterUnitsFont
                cell.inputTxtField.attributedPlaceholder = NSAttributedString(string: field.title, attributes: [NSForegroundColorAttributeName : unselectedTextColor, NSFontAttributeName: RegisterUnitsFont])

            }
            else if field.type == .Weight {
                //cell.imageTxtSpacing?.constant = 8
                cell.labelCellSpacing?.constant = 8
                cell.nameLbl.font = RegisterUnitsFont
                cell.inputTxtField.attributedPlaceholder = NSAttributedString(string: field.title, attributes: [NSForegroundColorAttributeName : unselectedTextColor, NSFontAttributeName: RegisterUnitsFont])

            }
        }

        if field.type == .Weight {
            cell.nameLbl.text = model.units.weightTitle
            cell.inputTxtField.keyboardType = UIKeyboardType.NumberPad
        }
        else if field.type == .Height {
            cell.nameLbl.text = model.units.heightTitle
            cell.inputTxtField.keyboardType = UIKeyboardType.NumberPad
        }
        else if field.type == .HeightInches {
            cell.nameLbl.text = model.units.heightInchesTitle ?? ""
            cell.inputTxtField.keyboardType = UIKeyboardType.NumberPad
        }


        cell.nameLbl.textColor = selectedTextColor
        return cell
    }

    private func checkSelectionCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(doubleCheckBoxCellIdentifier, forIndexPath: indexPath) as! DoubleCheckListCollectionViewCell

        if field.type == .Gender {
            cell.setFirstTitle(Gender.Male.title)
            cell.setSecondTitle(Gender.Female.title)
            cell.setSelectedItem(selectedItemIndex: model.gender.rawValue)
        }
        else if field.type == .Units {
            cell.setFirstTitle(UnitsSystem.Imperial.title)
            cell.setSecondTitle(UnitsSystem.Metric.title)
            cell.setSelectedItem(selectedItemIndex: model.units.rawValue)
        }

        cell.selectedTextColor = selectedTextColor
        cell.unselectedTextColor = unselectedTextColor
        cell.cellImage?.image = UIImage(named: field.iconImageName!)
        return cell
    }

    private func loadPhotoCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(loadImageCellIdentifier, forIndexPath: indexPath) as! LoadImageCollectionViewCell
        cell.presentingViewController = viewController!.navigationController
        return cell
    }

    // MARK: - Cells sizes
    private let spaceBetweenCellsInOneRow: CGFloat = 0 // 26
    private let cellHeight: CGFloat = 45
    private let cellHighHeight: CGFloat = 160

    private func highCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHighHeight)
        return size
    }

    private func defaultCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHeight)
        return size
    }

    private func smallCellSize() -> CGSize {
        let size = CGSizeMake((self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 2.0, cellHeight)
        return size
    }

    private func smallWeightCellSize() -> CGSize {
        let size = CGSizeMake(4.5*(self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
        return size
    }

    private func smallHeightCellSize() -> CGSize {
        let size = CGSizeMake(3.5*(self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
        return size
    }

    private func smallHeightInchesCellSize() -> CGSize {
        let size = CGSizeMake(2*(self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
        return size
    }

}
