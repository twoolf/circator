//
//  PhysiologicalDataViewController.swift
//  MetabolicCompass 
//
//  Created by Anna Tkach on 5/12/16.   
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class PhysiologicalDataViewController: BaseViewController {

    weak var registerViewController: RegisterViewController?
    var dataSource = AdditionalInfoDataSource()
    @IBOutlet weak var collectionView: UICollectionView!

    let lsSaveTitle = "Save".localized
    let lsCancelTitle = "Cancel".localized
    let lsEditTitle = "Edit".localized

    var rightButton:UIBarButtonItem?
    var leftButton:UIBarButtonItem?

    var editMode : Bool {
        set {
            dataSource.editMode = newValue;
            collectionView.reloadData()
            rightButton?.title = newValue ? lsSaveTitle : lsEditTitle
            self.navigationItem.leftBarButtonItem = newValue ? leftButton : nil
        }
        get { return dataSource.editMode }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.editMode = false
        setupScrollViewForKeyboardsActions(view: collectionView)
        dataSource.collectionView = self.collectionView
        self.setupNavBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.model.loadValues{ _ in
            self.collectionView.reloadData()
        }
    }

//    private func createBarButtonItem(title: String?, action: Selector) -> UIBarButtonItem{
//        let bbItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: self, action: action)
//        bbItem.setTitleTextAttributes([NSForegroundColorAttributeName: ScreenManager.appTitleTextColor()], forState: UIControlState.Normal)
//        return bbItem
//    }

    private func setupNavBar() {
        rightButton = createBarButtonItem(title: lsEditTitle, action: #selector(rightAction))
        self.navigationItem.rightBarButtonItem = rightButton
        leftButton = createBarButtonItem(title: lsCancelTitle, action: #selector(leftAction))
    }

    func rightAction(sender: UIBarButtonItem) {
        if dataSource.editMode {
            dataSource.model.additionalInfoDict { (error, additionalInfo) in
                guard error == nil else {
                    UINotifications.genericError(vc: self, msg: error!)
                    return
                }
                UserManager.sharedManager.pushProfile(componentData: additionalInfo, completion: { _ in
                    self.editMode = false
                })
            }
        } else{
            editMode = true
        }
    }

    func leftAction(sender: UIBarButtonItem) {
        let lsConfirmTitle = "Confirm cancel".localized
        let lsConfirmMessage = "Your changes have not been saved yet. Exit without saving?".localized
        let confirmAlert = UIAlertController(title: lsConfirmTitle, message: lsConfirmMessage, preferredStyle: UIAlertControllerStyle.alert)
        confirmAlert.addAction(UIAlertAction(title: "Yes".localized, style: .default, handler: { (action: UIAlertAction!) in
            //reset data & change mode
            self.dataSource.reset()
            self.editMode = false
        }))
        confirmAlert.addAction(UIAlertAction(title: "No".localized, style: .cancel, handler: nil))
        present(confirmAlert, animated: true, completion: nil)

    }
}
