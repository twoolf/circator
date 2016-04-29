//
//  BaseDataSource.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class BaseDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    let selectedTextColor = UIColor.whiteColor()
    let unselectedTextColor = UIColor.lightGrayColor()
    
    weak var collectionView: UICollectionView? {
        didSet {
            
            collectionView?.delegate = self
            collectionView?.dataSource = self
            
            registerCells()
        }
    }
    
    func registerCells() {
        // Override it
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        return UICollectionViewCell()
    }

    
}
