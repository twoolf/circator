//
//  AdditionalInfoViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class AdditionalInfoViewController: BaseViewController {

    var dataSource = AdditionalInfoDataSource()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScroolViewForKeyboardsActions(collectionView)
    
        dataSource.collectionView = self.collectionView
        
        self.configureNavBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configureNavBar() {
        let nextBtn = UIBarButtonItem(title: "Next".localized, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(AdditionalInfoViewController.nextAction(_:)))
        
        self.navigationItem.rightBarButtonItems = [nextBtn]
    }
 
    func nextAction(sender: UIBarButtonItem) {
        print("Next !")
        
        let additionalInfo = dataSource.model.additionalInfoDict()
        
        print("add info: \(additionalInfo)")
        
        UserManager.sharedManager.pushProfile(additionalInfo, completion: { _ in
            
            // Do next step
            
        })
    }
}
