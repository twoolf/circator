//
//  ProfileViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController {

    var dataSource = ProfileDataSource()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        
        setupScroolViewForKeyboardsActions(collectionView)
        
        dataSource.collectionView = self.collectionView
    }
    
    private func setupNavBar() {
        let editBarBtn = UIBarButtonItem(title: NSLocalizedString("Edit".localized, comment: "edit profile button"),
                                         style: .Done,
                                         target: self,
                                         action: #selector(editAction))
        self.navigationItem.rightBarButtonItem = editBarBtn
    }

    func editAction(sender: UIBarButtonItem) {
        print("edit action")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}
