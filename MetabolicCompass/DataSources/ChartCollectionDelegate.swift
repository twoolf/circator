//
//  ChartCollectionDelegate.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/1/16.  
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit

class ChartCollectionDelegate: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(collectionView.frame.widthCGRectGetWidth(collectionView.frame) - 20.0, 196)
//        return CGRect(collectionView(collectionView: collectionView, layout: collectionView.frame, sizeForItemAtIndexPath: (-200, 196))
 //       return CGSize(dictionaryRepresentation: collectionView.frame.width as! CFDictionary)!
        return CGSize(collectionView.frame.width - 20.0, 196)
    }
    
    @nonobjc internal func collectionView(_ collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    @nonobjc internal func collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
}
