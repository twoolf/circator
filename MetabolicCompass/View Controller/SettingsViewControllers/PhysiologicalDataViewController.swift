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
    var dataSource = PhysioParametersDataSource()
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
        setupScroolViewForKeyboardsActions(collectionView)
        
        dataSource.collectionView = self.collectionView
        
        self.setupNavBar()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func createBarButtonItem(title: String?, action: Selector) -> UIBarButtonItem{
        let bbItem = UIBarButtonItem(title: title, style: UIBarButtonItemStyle.Plain, target: self, action: action)
        bbItem.setTitleTextAttributes([NSForegroundColorAttributeName: ScreenManager.appTitleColor()], forState: UIControlState.Normal)
        return bbItem
    }
    
    private func setupNavBar() {
//        rightButton = UIBarButtonItem(title: lsEditTitle, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PhysiologicalDataViewController.rightAction(_:)))
//        rightButton!.setTitleTextAttributes([NSForegroundColorAttributeName: ScreenManager.appTitleColor()], forState: UIControlState.Normal);
        rightButton = createBarButtonItem(lsEditTitle, action: #selector(rightAction))
        self.navigationItem.rightBarButtonItem = rightButton
        
        leftButton = createBarButtonItem(lsCancelTitle, action: #selector(leftAction))
        
    }
    
    func rightAction(sender: UIBarButtonItem) {
        if dataSource.editMode {
            let additionalInfo = dataSource.model.additionalInfoDict()
            
            print("add info: \(additionalInfo)")
            
            UserManager.sharedManager.pushProfile(additionalInfo, completion: { _ in
//                self.dismissViewControllerAnimated(true, completion: {
//                    [weak controller = self.registerViewController] in
//                    controller?.registartionComplete()
//                });
                self.editMode = false
            })
        }
        else{
            editMode = true
        }

    }
    
    func leftAction(sender: UIBarButtonItem) {
        let lsConfirmTitle = "Confirm cancel".localized
        let lsConfirmMessage = "Your changes have not been saved yet. Exit without saving?".localized
        
        let confirmAlert = UIAlertController(title: lsConfirmTitle, message: lsConfirmMessage, preferredStyle: UIAlertControllerStyle.Alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Yes".localized, style: .Default, handler: { (action: UIAlertAction!) in
            //reset data & change mode
            //self.dataSource.reset()
            self.editMode = false
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "No".localized, style: .Cancel, handler: nil))
        
        presentViewController(confirmAlert, animated: true, completion: nil)
        
    }
}
