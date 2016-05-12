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
    var rightBarBtn: UIBarButtonItem?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        
        setupScroolViewForKeyboardsActions(collectionView)
        
        dataSource.collectionView = self.collectionView
    }
    
    private func setupNavBar() {
        rightBarBtn = UIBarButtonItem(title: NSLocalizedString("", comment: "edit profile button"),
                                         style: .Done,
                                         target: self,
                                         action: #selector(rightAction))
        
        self.navigationItem.rightBarButtonItem = rightBarBtn
        
        configureNavBar()
    }

    func rightAction(sender: UIBarButtonItem) {
        print("edit action")
        
        dataSource.swithMode()
        
        configureNavBar()
    }
    
    private func configureNavBar() {
        let barBtnTitle = dataSource.editMode ? "Save".localized : "Edit".localized
        rightBarBtn?.title = barBtnTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}
