//
//  ProfileDataSource.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

let ProfileFont = UIFont(name: "GothamBook", size: 16.0)!

class ProfileDataSource: BaseDataSource {

    private(set) var editMode = false

    private(set) lazy var model: ProfileModel = {
        let profileModel = ProfileModel()
        profileModel.setupValues()
        return profileModel
    }()

    private let profileImageCellIdentifier = "profileImageCell"
    private let loadProfileImageCellIdentifier = "loadProfileImageCell"
    private let infoCellIdentifier = "infoTextCell"
    private let doubleCheckBoxCellIdentifier = "doubleCheckBoxCell"

    override func registerCells() {
        let loadImageCellNib = UINib(nibName: "LoadImageCollectionViewCell", bundle: nil)
        collectionView?.registerNib(loadImageCellNib, forCellWithReuseIdentifier: loadProfileImageCellIdentifier)

        let imageCellNib = UINib(nibName: "CircleImageCollectionViewCell", bundle: nil)
        collectionView?.registerNib(imageCellNib, forCellWithReuseIdentifier: profileImageCellIdentifier)

        let inputTextCellNib = UINib(nibName: "InfoCollectionViewCell", bundle: nil)
        collectionView?.registerNib(inputTextCellNib, forCellWithReuseIdentifier: infoCellIdentifier)

        let doubleCheckBoxCellNib = UINib(nibName: "DoubleCheckListTitledCollectionViewCell", bundle: nil)
        collectionView?.registerNib(doubleCheckBoxCellNib, forCellWithReuseIdentifier: doubleCheckBoxCellIdentifier)
    }


    // MARK: - CollectionView Delegate & DataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = model.items.count
        return count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let field = model.itemAtIndexPath(indexPath)
        var cell: BaseCollectionViewCell?

        let cellType = field.type
        if cellType == .Photo {
             cell = loadPhotoCellForIndex(indexPath, forField: field)
        } else {
            let cellEditMode = editMode && model.isItemEditable(field)
            if cellEditMode {
                cell = infoEditableCellForIndex(indexPath, forField: field)
            } else {
                cell = infoCellForIndex(indexPath, forField: field)
            }

            // Adjust label spacing of weight and height cells.
            if cellType == .Weight || cellType == .Height || cellType == .HeightInches {
                if let infoCell = cell as? InfoCollectionViewCell{
                    let w = infoCell.inputTxtField.text?.sizeWithAttributes(infoCell.inputTxtField.typingAttributes).width
                    let tw = (cellType == .Weight ? 16.0 : 10.0) + (w ?? 0.0)
                    infoCell.commentLabelXConstraint.constant = tw
                }
            }
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
                if let infoCell = cell as? InfoCollectionViewCell{
                    let w = infoCell.inputTxtField.text?.sizeWithAttributes(infoCell.inputTxtField.typingAttributes).width
                    let tw = (cellType == .Weight ? 16.0 : 10.0) + (w ?? 0.0)
                    infoCell.commentLabelXConstraint.constant = tw
                }
            }
        }
        return cell!
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let field = model.itemAtIndexPath(indexPath)

        if model.units == .Imperial && (field.type == .Weight || field.type == .Height || field.type == .HeightInches) {
            return field.type == .HeightInches ? smallHeightInchesCellSize() : smallWHCellSize()
        }

        if field.type == .Weight || field.type == .Height {
            return smallCellSize()
        }

        if field.type == .FirstName || field.type == .LastName {
            return smallCellSize(field.type)
        }

        if field.type == .Photo {
            return highCellSize()
        }

        return defaultCellSize()
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return spaceBetweenCellsInOneRow
    }

    // MARK: - Cells configuration

    private func infoCellForIndex(indexPath: NSIndexPath, forField field: ModelItem, isEdiatble: Bool = false, keyboardType: UIKeyboardType = UIKeyboardType.Default) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(infoCellIdentifier, forIndexPath: indexPath) as! InfoCollectionViewCell
        
        cell.inputTxtField.textColor = selectedTextColor
        cell.textValueCommentLbl.textColor = selectedTextColor

        cell.titleLbl.textColor = unselectedTextColor
        cell.titleLbl.text = field.title
        cell.titleLbl.font = ProfileFont

        cell.inputTxtField.text = field.stringValue()
        cell.inputTxtField.font = ProfileFont

        if field.type == .Weight || field.type == .Height || field.type == .HeightInches {
            cell.separatorVisible = false
        }

        if field.type == .Weight {
            cell.textValueCommentLbl.text = model.units.weightTitle
        }
        else if field.type == .Height {
            cell.textValueCommentLbl.text = model.units.heightTitle
        }
        else if field.type == .HeightInches {
            cell.textValueCommentLbl.text = model.units.heightInchesTitle ?? ""
        }

        cell.textValueCommentLbl.font = ProfileFont

        if let _ = field.iconImageName {
            cell.imageLeadingConstraint?.constant = 16
            cell.imageWidthConstraint?.constant = 21
        }

        cell.setImageWithName(field.iconImageName, smallTextOffset: field.type == .Height || field.type == .HeightInches)

        if model.units == .Imperial {
            if field.type == .HeightInches {
                cell.imageLeadingConstraint?.constant = 0
                cell.imageWidthConstraint?.constant = 0
            }
            else if field.type == .Height {
                cell.imageLeadingConstraint?.constant = 0
            }
        }

        cell.inputTxtField.enabled = isEdiatble
        cell.inputTxtField.keyboardType = keyboardType

        return cell
    }

    private func infoEditableCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let field = model.itemAtIndexPath(indexPath)
        let cellType = field.type

        if cellType == .Age || cellType == .Weight || cellType == .Height || cellType == .HeightInches {
            return infoCellForIndex(indexPath, forField: field, isEdiatble: true, keyboardType: .NumberPad)
        }

        if cellType == .Gender || cellType == .Units {
            return checkSelectionCellForIndex(indexPath, forField: field)
        }

        // It is shouldn't be called
        return BaseCollectionViewCell()
    }

    private func checkSelectionCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(doubleCheckBoxCellIdentifier, forIndexPath: indexPath) as! DoubleCheckListTitledCollectionViewCell

        if field.type == .Gender {
            cell.setFirstTitle(Gender.Male.title)
            cell.setSecondTitle(Gender.Female.title)
            cell.setSelectedItem(selectedItemIndex: field.intValue()!)
        }
        else if field.type == .Units {
            cell.setFirstTitle(UnitsSystem.Imperial.title)
            cell.setSecondTitle(UnitsSystem.Metric.title)
            cell.setSelectedItem(selectedItemIndex: field.intValue()!)
        }

        cell.setTitle(field.title)

        cell.selectedTextColor = selectedTextColor
        cell.unselectedTextColor = unselectedTextColor

        cell.cellImage?.image = UIImage(named: field.iconImageName!)

        return cell
    }

    private func loadPhotoCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        var cell : CircleImageCollectionViewCell?

        if editMode {
            cell = collectionView!.dequeueReusableCellWithReuseIdentifier(loadProfileImageCellIdentifier, forIndexPath: indexPath) as! LoadImageCollectionViewCell
            (cell as! LoadImageCollectionViewCell).presentingViewController = viewController?.navigationController
        }
        else {
            cell = collectionView!.dequeueReusableCellWithReuseIdentifier(profileImageCellIdentifier, forIndexPath: indexPath) as? CircleImageCollectionViewCell
        }

        cell!.photoImg.image = field.value as? UIImage

        return cell!
    }

    // MARK: - Cells sizes
    private let spaceBetweenCellsInOneRow: CGFloat = 0
    //private let cellHeight: CGFloat = 65
    private let cellHighHeight: CGFloat = 140
    private let smallCellWidthShift: CGFloat = 16

//    private  var cellHeight: CGFloat =  ((self.collectionView?.frame.size.height ?? cellHighHeight) - cellHighHeight) * 0.15 ///round((UIScreen.mainScreen().bounds.height - 200.0)

    private  var _cellHeight: CGFloat = 0.0
    var cellHeight: CGFloat{
        if (_cellHeight ?? 0.0) == 0.0{
            _cellHeight = ((self.collectionView?.frame.size.height ?? cellHighHeight) - cellHighHeight) * 0.16
        }
        return _cellHeight
    }

    private func highCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHighHeight)
        return size
    }

    private func defaultCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHeight)
        return size
    }

    private func smallCellSize(type: UserInfoFieldType) -> CGSize {
        var size = CGSizeMake((self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 2.0, cellHeight)

        if type == .FirstName {
            size.width = size.width + smallCellWidthShift
        }

        if type == .LastName {
            size.width = size.width - smallCellWidthShift
        }

        return size
    }

    private func smallCellSize() -> CGSize {
        let size = CGSizeMake((self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 2.0, cellHeight)
        return size
    }

    private func smallWHCellSize() -> CGSize {
        let size = CGSizeMake(4 * (self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
        return size
    }

    private func smallHeightInchesCellSize() -> CGSize {
        let size = CGSizeMake(2 * (self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
        return size
    }

    // MARK: - Mode chnages

    func switchMode() {
        editMode = !editMode
        collectionView?.reloadData()
    }

    func reset() {
        self.model.setupValues()
    }

}
