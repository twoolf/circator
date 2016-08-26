//
//  RegisterViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/21/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import MetabolicCompassKit
import UIKit
import Async
import Former
import FileKit
import Crashlytics
import SwiftDate
import SwiftyUserDefaults

private let lblFontSize = ScreenManager.sharedInstance.profileLabelFontSize()
private let inputFontSize = ScreenManager.sharedInstance.profileInputFontSize()

 class RegisterViewController : BaseViewController {

    override class var storyboardName : String {
        return "RegisterLoginProcess"
    }

    var dataSource = RegisterModelDataSource()

    @IBOutlet weak var collectionView: UICollectionView!

    internal var consentOnLoad : Bool = false
    internal var registerCompletion : (Void -> Void)?
    internal var parentView: IntroViewController?
    private var stashedUserId : String?
    
    //MARK: View life circle
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScrollViewForKeyboardsActions(collectionView)

        dataSource.viewController = self
        dataSource.collectionView = self.collectionView

        self.setNeedsStatusBarAppearanceUpdate()
        self.doConsent()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
   
    //MARK: Actions
    @IBAction func registerAction(sender: UIButton) {
        startAction()

        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(self.navigationController!, pop: true, asNav: true)
            return
        }

        let userRegistrationModel = dataSource.model
        if !userRegistrationModel.isModelValid() {
            self.showAlert(withMessage: userRegistrationModel.validationMessage!, title: "Registration Error".localized)
            return
        }

        sender.enabled = false

        UINotifications.genericMsg(self.navigationController!, msg: "Registering account...")
        UserManager.sharedManager.overrideUserPass(userRegistrationModel.email, pass: userRegistrationModel.password)
        
        let initialProfile = self.dataSource.model.profileItems()
        UserManager.sharedManager.register(userRegistrationModel.firstName!, lastName: userRegistrationModel.lastName!, consentPath: consentPath, initialData: initialProfile) { (_, error, errormsg) in
            guard !error else {
                // Return from this function to allow the user to try registering again with the 'Done' button.
                // We reset the user/pass so that any view exit leaves the app without a registered user.
                // Re-entering this function will use overrideUserPass above to re-establish the account being registered.
                UserManager.sharedManager.resetFull()
                if let user = self.stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                UINotifications.registrationError(self.navigationController!, msg: errormsg)
                Answers.logSignUpWithMethod("SPR", success: false, customAttributes: nil)
                sender.enabled = true
                return
            }
            //will be used for the first login with method
            UserManager.sharedManager.setAsFirstLogin()
            // save user profile image
            UserManager.sharedManager.setUserProfilePhoto(userRegistrationModel.photo)
            self.performSegueWithIdentifier(self.segueRegistrationCompletionIndentifier, sender: nil)
        }
    }

    func doConsent() {
        stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(self.navigationController!) { [weak self] consentAndNames -> Void in
            guard consentAndNames.0 else {
                UserManager.sharedManager.resetFull()
                if let user = self!.stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                self!.navigationController?.popViewControllerAnimated(true)
                return
            }

            // Note: add 1 to index, due to photo field.
            if let s = self {
                let updatedData = consentAndNames.1 != nil || consentAndNames.2 != nil
                if consentAndNames.1 != nil { s.dataSource.model.setAtItem(itemIndex: s.dataSource.model.firstNameIndex+1, newValue: consentAndNames.1!) }
                if consentAndNames.2 != nil { s.dataSource.model.setAtItem(itemIndex: s.dataSource.model.lastNameIndex+1, newValue: consentAndNames.2!) }
                if updatedData { s.collectionView.reloadData() }
            }
        }
    }

    func registartionComplete() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    // MARK: - Navigation

    private let segueRegistrationCompletionIndentifier = "completionRegistrationSeque"

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueRegistrationCompletionIndentifier {
            segue.destinationViewController.modalPresentationStyle = .OverCurrentContext
            if let vc = segue.destinationViewController as? RegistrationComplitionViewController {
                vc.registerViewController = self
            }
            else if let navVC = segue.destinationViewController as? UINavigationController {
                if let vc = navVC.viewControllers.first as? RegistrationComplitionViewController {
                    vc.registerViewController = self
                }
            }
        }
    }

}
