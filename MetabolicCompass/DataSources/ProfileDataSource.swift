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
        collectionView?.register(loadImageCellNib, forCellWithReuseIdentifier: loadProfileImageCellIdentifier)

        let imageCellNib = UINib(nibName: "CircleImageCollectionViewCell", bundle: nil)
        collectionView?.register(imageCellNib, forCellWithReuseIdentifier: profileImageCellIdentifier)

        let inputTextCellNib = UINib(nibName: "InfoCollectionViewCell", bundle: nil)
        collectionView?.register(inputTextCellNib, forCellWithReuseIdentifier: infoCellIdentifier)

        let doubleCheckBoxCellNib = UINib(nibName: "DoubleCheckListTitledCollectionViewCell", bundle: nil)
        collectionView?.register(doubleCheckBoxCellNib, forCellWithReuseIdentifier: doubleCheckBoxCellIdentifier)
    }


    // MARK: - CollectionView Delegate & DataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = model.items.count
        return count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let field = model.itemAtIndexPath(indexPath: (indexPath as IndexPath))
        var cell: BaseCollectionViewCell?

        let cellType = field.type
        if cellType == .Photo {
             cell = loadPhotoCellForIndex(indexPath: indexPath as IndexPath, forField: field)
        } else {
            let cellEditMode = editMode && model.isItemEditable(item: field)
            if cellEditMode {
                cell = infoEditableCellForIndex(indexPath: indexPath as IndexPath, forField: field)
            } else {
                cell = infoCellForIndex(indexPath: indexPath as IndexPath, forField: field)
            }

            // Adjust label spacing of weight and height cells.
            if cellType == .Weight || cellType == .Height || cellType == .HeightInches {
                if let infoCell = cell as? InfoCollectionViewCell{
                    var attrs: [NSAttributedStringKey: Any] = [:]
                    infoCell.inputTxtField.typingAttributes?.forEach({ (key, value) in
                        attrs[NSAttributedStringKey(rawValue: key)] = value
                    })
                    let w = infoCell.inputTxtField.text?.size(withAttributes: attrs).width
                    let tw = (cellType == .Weight ? 16.0 : 10.0) + (w ?? 0.0)
                    infoCell.commentLabelXConstraint.constant = tw
                }
            }
        }

        cell!.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in

            if let indexPath = self.collectionView!.indexPath(for: cell) {
                self.model.setAtItem(itemIndex: indexPath.row, newValue: newValue)

                let field = self.model.itemAtIndexPath(indexPath: (indexPath as IndexPath))
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
                    var attrs: [NSAttributedStringKey: Any] = [:]
                    infoCell.inputTxtField.typingAttributes?.forEach({ (key, value) in
                        attrs[NSAttributedStringKey(rawValue: key)] = value
                    })
                    let w = infoCell.inputTxtField.text?.size(withAttributes: attrs).width
                    let tw = (cellType == .Weight ? 16.0 : 10.0) + (w ?? 0.0)
                    infoCell.commentLabelXConstraint.constant = tw
                }
            }
        }
        return cell!
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let field = model.itemAtIndexPath(indexPath: (indexPath as IndexPath))

        if model.units == .Imperial && (field.type == .Weight || field.type == .Height || field.type == .HeightInches) {
            return field.type == .HeightInches ? smallHeightInchesCellSize() : smallWHCellSize()
        }

        if field.type == .Weight || field.type == .Height {
            return smallCellSize()
        }

        if field.type == .FirstName || field.type == .LastName {
            return smallCellSize(type: field.type)
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

    private func infoCellForIndex(indexPath: IndexPath,
                             forField field: ModelItem,
                                 isEdiatble: Bool = false,
                               keyboardType: UIKeyboardType = UIKeyboardType.default) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCell(withReuseIdentifier: infoCellIdentifier, for: indexPath as IndexPath) as! InfoCollectionViewCell
        
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

        cell.setImageWithName(imageName: field.iconImageName, smallTextOffset: field.type == .Height || field.type == .HeightInches)

        if model.units == .Imperial {
            if field.type == .HeightInches {
                cell.imageLeadingConstraint?.constant = 0
                cell.imageWidthConstraint?.constant = 0
            }
            else if field.type == .Height {
                cell.imageLeadingConstraint?.constant = 0
            }
        }

        cell.inputTxtField.isEnabled = isEdiatble
        cell.inputTxtField.keyboardType = keyboardType

        return cell
    }

    private func infoEditableCellForIndex(indexPath: IndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let field = model.itemAtIndexPath(indexPath: indexPath as IndexPath)
        let cellType = field.type

        if cellType == .Age || cellType == .Weight || cellType == .Height || cellType == .HeightInches {
            return infoCellForIndex(indexPath: indexPath, forField: field, isEdiatble: true, keyboardType: .numberPad)
        }

        if cellType == .Gender || cellType == .Units {
            return checkSelectionCellForIndex(indexPath: indexPath, forField: field)
        }

        // It is shouldn't be called
        return BaseCollectionViewCell()
    }

    private func checkSelectionCellForIndex(indexPath: IndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCell(withReuseIdentifier: doubleCheckBoxCellIdentifier, for: indexPath as IndexPath) as! DoubleCheckListTitledCollectionViewCell

        if field.type == .Gender {
            cell.setFirstTitle(firstTitle: Gender.Male.title)
            cell.setSecondTitle(firstTitle: Gender.Female.title)
            cell.setSelectedItem(selectedItemIndex: field.intValue()!)
        }
        else if field.type == .Units {
            cell.setFirstTitle(firstTitle: UnitsSystem.Imperial.title)
            cell.setSecondTitle(firstTitle: UnitsSystem.Metric.title)
            cell.setSelectedItem(selectedItemIndex: field.intValue()!)
        }

        cell.setTitle(title: field.title)

        cell.selectedTextColor = selectedTextColor
        cell.unselectedTextColor = unselectedTextColor

        cell.cellImage?.image = UIImage(named: field.iconImageName!)

        return cell
    }

    private func loadPhotoCellForIndex(indexPath: IndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        var cell : CircleImageCollectionViewCell?

        if editMode {
            cell = collectionView!.dequeueReusableCell(withReuseIdentifier: loadProfileImageCellIdentifier, for: indexPath as IndexPath) as! LoadImageCollectionViewCell
            (cell as! LoadImageCollectionViewCell).presentingViewController = viewController?.navigationController
            cell!.photoImg.image = field.value as? UIImage
        }
        else {
            cell = collectionView!.dequeueReusableCell(withReuseIdentifier: profileImageCellIdentifier, for: indexPath as IndexPath) as? CircleImageCollectionViewCell
            cell!.photoImg.image = UIImage.init(named: field.iconImageName!)
        }
        return cell!
    }

    // MARK: - Cells sizes
    private let spaceBetweenCellsInOneRow: CGFloat = 0
    private let cellHighHeight: CGFloat = 140
    private let smallCellWidthShift: CGFloat = 16
    private  var _cellHeight: CGFloat = 0.0

    var cellHeight: CGFloat {
        if (_cellHeight ?? 0.0) == 0.0{
            _cellHeight = ((self.collectionView?.frame.size.height ?? cellHighHeight) - cellHighHeight) * 0.16
        }
        return _cellHeight
    }

    private func highCellSize() -> CGSize {
        let size = CGSize(self.collectionView!.bounds.width, cellHighHeight)
        return size
    }

    private func defaultCellSize() -> CGSize {
        let size = CGSize(self.collectionView!.bounds.width, cellHeight)
        return size
    }

    private func smallCellSize(type: UserInfoFieldType) -> CGSize {
        var size = CGSize((self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 2.0, cellHeight)

        if type == .FirstName {
            size.width = size.width + smallCellWidthShift
        }

        if type == .LastName {
            size.width = size.width - smallCellWidthShift
        }

        return size
    }

    private func smallCellSize() -> CGSize {
        let size = CGSize((self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 2.0, cellHeight)
        return size
    }

    private func smallWHCellSize() -> CGSize {
        let size = CGSize(4 * (self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
        return size
    }

    private func smallHeightInchesCellSize() -> CGSize {
        let size = CGSize(2 * (self.collectionView!.bounds.width - spaceBetweenCellsInOneRow) / 10.0, cellHeight)
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
