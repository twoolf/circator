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
import Crashlytics

class AdditionalInfoViewController: BaseViewController {

    weak var registerViewController: RegisterViewController?
    var dataSource = AdditionalInfoDataSource()

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollViewForKeyboardsActions(view: collectionView)
        dataSource.collectionView = self.collectionView
        configureNavBar()
    }

    private func configureNavBar() {
        
        let cancelButton = ScreenManager.sharedInstance.appNavButtonWithTitle(title: "Cancel".localized)
        cancelButton.addTarget(self, action: #selector(self.cancelAction), for: .touchUpInside)
        let cancelBarButton = UIBarButtonItem(customView: cancelButton)

        let nextButton = ScreenManager.sharedInstance.appNavButtonWithTitle(title: "Next".localized)
        nextButton.addTarget(self, action: #selector(self.nextAction), for: .touchUpInside)
        let nextBarButton = UIBarButtonItem(customView: nextButton)
        
        self.navigationItem.rightBarButtonItems = [nextBarButton]
        self.navigationItem.leftBarButtonItems = [cancelBarButton]
        self.navigationItem.title = NSLocalizedString("PHYSIOLOGICAL DATA", comment: "additional info data")
    }
    
    func cancelAction () {
        self.dismiss(animated: true, completion: { [weak controller = self.registerViewController] in
            Answers.logCustomEvent(withName: "Register Additional", customAttributes: ["WithAdditional": false])
            controller?.registrationComplete()
        });
    }
    
    func nextAction() {
        startAction()
        dataSource.model.additionalInfoDict { (error, additionalInfo) in
            guard error == nil else {
                UINotifications.genericError(vc: self, msg: error!)
                return
            }

            UserManager.sharedManager.saveAdditionalProfileData(data: additionalInfo)
            self.dismiss(animated: true, completion: { [weak controller = self.registerViewController] in
                Answers.logCustomEvent(withName: "Register Additional", customAttributes: ["WithAdditional": true])
                controller?.registrationComplete()
            })
        }
    }
}
