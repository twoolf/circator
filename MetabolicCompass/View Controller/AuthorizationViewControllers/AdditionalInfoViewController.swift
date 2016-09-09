//
//  AdditionalInfoViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import SwiftyUserDefaults

class AdditionalInfoViewController: BaseViewController {

    weak var registerViewController: RegisterViewController?
    var dataSource = AdditionalInfoDataSource()

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollViewForKeyboardsActions(collectionView)
        dataSource.collectionView = self.collectionView
        configureNavBar()
    }

    private func configureNavBar() {
        
        let cancelButton = ScreenManager.sharedInstance.appNavButtonWithTitle("Cancel".localized)
        cancelButton.addTarget(self, action: #selector(cancelAction), forControlEvents: .TouchUpInside)
        let cancelBarButton = UIBarButtonItem(customView: cancelButton)

        let nextButton = ScreenManager.sharedInstance.appNavButtonWithTitle("Next".localized)
        nextButton.addTarget(self, action: #selector(nextAction), forControlEvents: .TouchUpInside)
        let nextBarButton = UIBarButtonItem(customView: nextButton)
        
        self.navigationItem.rightBarButtonItems = [nextBarButton]
        self.navigationItem.leftBarButtonItems = [cancelBarButton]
        self.navigationItem.title = NSLocalizedString("PHYSIOLOGICAL DATA", comment: "additional info data")
    }
    
    func cancelAction () {
        self.dismissViewControllerAnimated(true, completion: { [weak controller = self.registerViewController] in
            controller?.registrationComplete()
        });
    }
    
    func nextAction() {
        startAction()
        dataSource.model.additionalInfoDict { (error, additionalInfo) in
            guard error == nil else {
                UINotifications.genericError(self, msg: error!)
                return
            }

            UserManager.sharedManager.saveAdditionalProfileData(additionalInfo)
            self.dismissViewControllerAnimated(true, completion: { [weak controller = self.registerViewController] in
                controller?.registrationComplete()
            })
        }
    }
}
