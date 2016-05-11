//
//  ProfileDataSource.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class ProfileDataSource: BaseDataSource {

    private var editMode = false
    
    let model = ProfileModel()
    
    private let profileImageCellIdentifier = "profileImageCell"
    private let infoCellIdentifier = "infoTextCell"
    
    override func registerCells() {
        let imageCellNib = UINib(nibName: "CircleImageCollectionViewCell", bundle: nil)
        collectionView?.registerNib(imageCellNib, forCellWithReuseIdentifier: profileImageCellIdentifier)
        
        let inputTextCellNib = UINib(nibName: "InfoCollectionViewCell", bundle: nil)
        collectionView?.registerNib(inputTextCellNib, forCellWithReuseIdentifier: infoCellIdentifier)
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
        }
        else {
            cell = infoCellForIndex(indexPath, forField: field)
        }
        
//        cell!.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in
//            
//            if let indexPath = self.collectionView!.indexPathForCell(cell) {
//                self.model.setAtItem(itemIndex: indexPath.row, newValue: newValue)
//                
//                let field = self.model.itemAtIndexPath(indexPath)
//                
//                if field.type == .Units {
//                    let needsUpdateIndexPathes = [NSIndexPath(forRow: RegistrationFiledType.Weight.rawValue, inSection: 0),
//                                                  NSIndexPath(forRow: RegistrationFiledType.Height.rawValue, inSection: 0)]
//                    
//                    collectionView.reloadItemsAtIndexPaths(needsUpdateIndexPathes)
//                }
//            }
//            
//        }
        
        return cell!
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let field = model.itemAtIndexPath(indexPath)
        
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
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footerView", forIndexPath: indexPath)
            return footerView
        }
        
        return UICollectionReusableView()
    }
    
    // MARK: - Cells configuration
   
    private func infoCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(infoCellIdentifier, forIndexPath: indexPath) as! InfoCollectionViewCell
        
        cell.inputTxtField.textColor = selectedTextColor
        
        cell.titleLbl.textColor = unselectedTextColor
        cell.titleLbl.text = field.title
        
        var valueStr: String?
        
        valueStr = field.value as? String
        
        if field.type == .Gender {
            valueStr = Gender.Female.title
        }
        else if field.type == .Units {
            valueStr = UnitsSystem.Metric.title
        }
        else {
            valueStr = "value" // user account field value must be here
        }
        
        cell.inputTxtField.text = valueStr
        
        if field.type == .Password {
            cell.inputTxtField.secureTextEntry = true
        }
        else if field.type == .Email {
            cell.inputTxtField.keyboardType = UIKeyboardType.EmailAddress
        }
        else if field.type == .Age {
            cell.inputTxtField.keyboardType = UIKeyboardType.NumberPad
        }
        
        
        if field.type == .Weight || field.type == .Height {
            cell.separatorVisible = false
        }
        
        cell.setImageWithName(field.iconImageName, smallTextOffset: field.type == .Height)
        
        cell.inputTxtField.enabled = editMode
        
        return cell
    }
    

    private func loadPhotoCellForIndex(indexPath: NSIndexPath, forField field: ModelItem) -> BaseCollectionViewCell {
        let cell = collectionView!.dequeueReusableCellWithReuseIdentifier(profileImageCellIdentifier, forIndexPath: indexPath) as! CircleImageCollectionViewCell
        
//        cell.photoImg.image = user image must be here
        
        return cell
    }
    
    // MARK: - Cells sizes
    private let spaceBetweenCellsInOneRow: CGFloat = 0
    private let cellHeight: CGFloat = 65
    private let cellHighHeight: CGFloat = 140
    private let smallCellWidthShift: CGFloat = 16
    
    private func highCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHighHeight)
        return size
    }
    
    private func defaultCellSize() -> CGSize {
        let size = CGSizeMake(self.collectionView!.bounds.width, cellHeight)
        return size
    }

    private func smallCellSize(type: RegistrationFiledType) -> CGSize {
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
}
