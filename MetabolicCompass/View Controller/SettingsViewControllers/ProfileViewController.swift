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

        dataSource.viewController = self

        setupNavBar()

        setupScrollViewForKeyboardsActions(collectionView)

        dataSource.collectionView = self.collectionView
    }

    private func setupNavBar() {
//        rightBarBtn = UIBarButtonItem(title: NSLocalizedString("", comment: "edit profile button"),
//                                         style: .Done,
//                                         target: self,
//                                         action: #selector(rightAction))
//
//        cancelBarBtn = UIBarButtonItem(title: "Cancel".localized,
//                                         style: .Done,
//                                         target: self,
//                                         action: #selector(cancelAction))

        rightBarBtn = createBarButtonItem("", action: #selector(rightAction))
        cancelBarBtn = createBarButtonItem("Cancel".localized, action: #selector(rightAction))
        
        self.navigationItem.rightBarButtonItem = rightBarBtn

        configureNavBar()
    }

    func cancelAction(sender: UIBarButtonItem) {

        let confirmTitle = "Confirm cancel".localized
        let confirmMessage = "Your changes have not been saved yet. Exit without saving?".localized

        let confirmAlert = UIAlertController(title: confirmTitle, message: confirmMessage, preferredStyle: UIAlertControllerStyle.Alert)

        confirmAlert.addAction(UIAlertAction(title: "Yes".localized, style: .Default, handler: { (action: UIAlertAction!) in
            //reset data & change mode

            self.dataSource.reset()
            self.changeMode()
        }))

        confirmAlert.addAction(UIAlertAction(title: "No".localized, style: .Cancel, handler: nil))

        presentViewController(confirmAlert, animated: true, completion: nil)
    }

    func rightAction(sender: UIBarButtonItem) {

        if !dataSource.editMode {
            changeMode()
            return
        }

        // Validate

        if !dataSource.model.isModelValid() {
            self.showAlert(withMessage: dataSource.model.validationMessage!, title: "Profile saving Error".localized)
            return
        }

        // Saving

        sender.enabled = false
        let newProfileInfo = dataSource.model.profileItems()

        UserManager.sharedManager.pushProfile(newProfileInfo, completion: { res in

            if res.ok {
                // save new photo
                UserManager.sharedManager.setUserProfilePhoto(self.dataSource.model.loadPhotoField.value as? UIImage)

                self.changeMode()
            }
            else {
                let message = res.info.hasContent ? res.info : "Your profile is not saving. Please, try later".localized
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

        let editMode = dataSource.editMode

        let barBtnTitle = editMode ? "Save".localized : "Edit".localized
        rightBarBtn?.title = barBtnTitle

        self.navigationItem.leftBarButtonItem = editMode ? cancelBarBtn : nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}
