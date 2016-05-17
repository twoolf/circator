//
//  PhysioParametersDataSource.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//


import UIKit


public class PhysioParametersDataSource: AdditionalInfoDataSource {

//    private let PhysioParameterCellIdentifier = "PhysioParameterCell"
//    private let cellHeight: CGFloat = 65

//    override func registerCells() {
//        let loadImageCellNib = UINib(nibName: "PhysioParameterCollectionViewCell", bundle: nil)
//        collectionView?.registerNib(loadImageCellNib, forCellWithReuseIdentifier: PhysioParameterCellIdentifier)
//    }
//
//    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        
//        let item = model.itemAtIndexPath(indexPath)
//        
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhysioParameterCellIdentifier, forIndexPath: indexPath) as! PhysioParameterCollectionViewCell
//        
////        cell.titleLbl.text = item.name
////        if let strValue = item.stringValue() {
////            cell.inputTxtField.text = strValue
////        }
////        else {
////            cell.inputTxtField.text = nil
////        }
////        
////        cell.smallDescriptionLbl.text = item.unitsTitle
////        
////        cell.inputTxtField.attributedPlaceholder = NSAttributedString(string: item.title,
////                                                                      attributes: [NSForegroundColorAttributeName : unselectedTextColor])
////        
////        var keypadType = UIKeyboardType.Default
////        if item.dataType == .Int {
////            keypadType = UIKeyboardType.NumberPad
////        }
////        else if item.dataType == .Decimal {
////            keypadType = UIKeyboardType.DecimalPad
////        }
////        
////        cell.inputTxtField.keyboardType = keypadType
////        
////        cell.titleLbl.textColor = selectedTextColor
////        cell.inputTxtField.textColor = selectedTextColor
////        
////        cell.smallDescriptionLbl.textColor = selectedTextColor
////        
////        cell.changesHandler = { (cell: UICollectionViewCell, newValue: AnyObject?) -> () in
////            
////            if let indexPath = self.collectionView!.indexPathForCell(cell) {
////                self.model.setNewValueForItem(atIndexPath: indexPath, newValue: newValue)
////            }
////            
////        }
//        
//        
//        return cell
//    }

//    override func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        
//        return CGSizeMake(self.collectionView!.bounds.width, cellHeight)
//    }

}
