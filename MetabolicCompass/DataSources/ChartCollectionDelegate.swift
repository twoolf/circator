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
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        return CGSize(collectionView.frame.widthCGRectGetWidth(collectionView.frame) - 20.0, 196)
//        return CGRect(collectionView(collectionView: collectionView, layout: collectionView.frame, sizeForItemAtIndexPath: (-200, 196))
        return CGSize(collectionView.frame.width
    }
    
    func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
}
