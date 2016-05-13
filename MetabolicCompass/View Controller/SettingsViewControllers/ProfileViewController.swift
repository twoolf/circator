//
//  ProfileViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class ProfileViewController: BaseViewController {

    var dataSource = ProfileDataSource()
    var rightBarBtn: UIBarButtonItem?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.viewController = self
        
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
        
        if !dataSource.editMode {
            changeMode()
            return
        }
        // Validate
        
        // Saving
        
        sender.enabled = false
        let newProfileInfo = dataSource.model.profileItems()
        
        UserManager.sharedManager.pushProfile(newProfileInfo, completion: { error, reason in
            
            if !error {
                // save new photo
                UserManager.sharedManager.setUserProfilePhoto(self.dataSource.model.loadPhotoField.value as? UIImage)

                self.changeMode()
            }
            else {
                let message = reason != nil ? reason! : "Your profile is not saving. Please, try later".localized
                self.showAlert(withMessage: message)
            }
            
            sender.enabled = true
        })
       
    }

    private func changeMode() {
        self.dataSource.swithMode()
        
        self.configureNavBar()
    }
    
    private func configureNavBar() {
        let barBtnTitle = dataSource.editMode ? "Save".localized : "Edit".localized
        rightBarBtn?.title = barBtnTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
}
