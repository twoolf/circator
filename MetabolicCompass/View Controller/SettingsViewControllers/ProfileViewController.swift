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

    private var dataSource = ProfileDataSource()
    private var rightBarBtn: UIBarButtonItem?
    private var cancelBarBtn: UIBarButtonItem?

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()

        dataSource.viewController = self

        setupNavBar()

        setupScrollViewForKeyboardsActions(view: collectionView)

        dataSource.collectionView = self.collectionView
    }

    private func setupNavBar() {
        rightBarBtn = createBarButtonItem("", action: #selector(self.rightAction))
        cancelBarBtn = createBarButtonItem("Cancel".localized, action: #selector(self.cancelAction))
        self.navigationItem.rightBarButtonItem = rightBarBtn
        configureNavBar()
    }

    func cancelAction(_ sender: UIBarButtonItem) {
        let confirmTitle = "Confirm cancel".localized
        let confirmMessage = "Your changes have not been saved yet. Exit without saving?".localized

        let confirmAlert = UIAlertController(title: confirmTitle, message: confirmMessage, preferredStyle: UIAlertControllerStyle.alert)

        confirmAlert.addAction(UIAlertAction(title: "Yes".localized, style: .default, handler: { (action: UIAlertAction!) in
            //reset data & change mode

            self.dataSource.reset()
            self.changeMode()
        }))

        confirmAlert.addAction(UIAlertAction(title: "No".localized, style: .cancel, handler: nil))

        present(confirmAlert, animated: true, completion: nil)
    }

    func rightAction(_ sender: UIBarButtonItem) {

        if !dataSource.editMode {
            changeMode()
            return
        }

        // Validate

        if !dataSource.model.isModelValid() {
            self.showAlert(withMessage: dataSource.model.validationMessage!, title: "Profile saving error".localized)
            return
        }

        // Saving

        sender.isEnabled = false
        let newProfileInfo = dataSource.model.profileItems()

        UserManager.sharedManager.pushProfile(componentData: newProfileInfo as [String : AnyObject], completion: { res in

            if res.ok {
                // save new photo
                UserManager.sharedManager.setUserProfilePhoto(photo: self.dataSource.model.loadPhotoField.value as? UIImage)

                self.changeMode()
            }
            else {
                let message = res.info.hasContent ? res.info : "Unable to sync your profile remotely. Please, try later".localized
                self.showAlert(withMessage: message)
            }

            sender.isEnabled = true
        })

    }

    private func changeMode() {
        self.dataSource.switchMode()
        self.configureNavBar()
    }

    private func configureNavBar() {

        let editMode = dataSource.editMode

        let barBtnTitle = editMode ? "Save".localized : "Edit".localized
        rightBarBtn?.title = barBtnTitle

        self.navigationItem.leftBarButtonItem = editMode ? cancelBarBtn : nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
