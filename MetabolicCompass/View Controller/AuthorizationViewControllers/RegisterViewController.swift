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
    internal var registerCompletion : ((Void) -> Void)?
    private var stashedUserId : String?
    
    //MARK: View life circle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScrollViewForKeyboardsActions(view: collectionView)

        dataSource.viewController = self
        dataSource.collectionView = self.collectionView

        self.setNeedsStatusBarAppearanceUpdate()
        self.doConsent()
    }

//    func preferredStatusBarStyle() -> UIStatusBarStyle {
//       return .lightContent
//   }
   
    //MARK: Actions
    @IBAction func registerAction(_ sender: UIButton) {
        startAction()

        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(vc: self.navigationController!, pop: true, asNav: true)
            return
        }

        let userRegistrationModel = dataSource.model
        if !userRegistrationModel.isModelValid() {
            self.showAlert(withMessage: userRegistrationModel.validationMessage!, title: "Registration Error".localized)
            return
        }

        sender.isEnabled = false
        UINotifications.genericMsg(vc: self.navigationController!, msg: "Registering account...")
        UserManager.sharedManager.overrideUserPass(user: userRegistrationModel.email, pass: userRegistrationModel.password)
        
        let initialProfile = self.dataSource.model.profileItems()
        UserManager.sharedManager.register(firstName: userRegistrationModel.firstName!, lastName: userRegistrationModel.lastName!, consentPath: consentPath, initialData: initialProfile) { (_, error, errormsg) in
            guard !error else {
                // Return from this function to allow the user to try registering again with the 'Done' button.
                // We reset the user/pass so that any view exit leaves the app without a registered user.
                // Re-entering this function will use overrideUserPass above to re-establish the account being registered.
                UserManager.sharedManager.resetFull()
                if let user = self.stashedUserId {
                    UserManager.sharedManager.setUserId(userId: user)
                }
                UINotifications.registrationError(vc: self.navigationController!, msg: errormsg)
                Answers.logSignUp(withMethod: "SPR", success: false, customAttributes: nil)
                sender.isEnabled = true
                return
            }
            //will be used for the first login with method
            UserManager.sharedManager.setAsFirstLogin()
            // save user profile image
            UserManager.sharedManager.setUserProfilePhoto(photo: userRegistrationModel.photo)
            self.performSegue(withIdentifier: self.segueRegistrationCompletionIdentifier, sender: nil)
        }
    }

    func doConsent() {
        stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(viewController: self.navigationController!) { [weak self] consentAndNames -> Void in
            guard consentAndNames.0 else {
                UserManager.sharedManager.resetFull()
                if let user = self!.stashedUserId {
                    UserManager.sharedManager.setUserId(userId: user)
                }
                self!.navigationController?.popViewController(animated: true)
                return
            }

            // Note: add 1 to index, due to photo field.
            if let s = self {
                let updatedData = consentAndNames.1 != nil || consentAndNames.2 != nil
                if consentAndNames.1 != nil { s.dataSource.model.setAtItem(itemIndex: s.dataSource.model.firstNameIndex+1, newValue: consentAndNames.1! as AnyObject?) }
                if consentAndNames.2 != nil { s.dataSource.model.setAtItem(itemIndex: s.dataSource.model.lastNameIndex+1, newValue: consentAndNames.2! as AnyObject?) }
                if updatedData { s.collectionView.reloadData() }
            }
        }
    }

    func registrationComplete() {
        self.navigationController?.popViewController(animated: true)
        self.registerCompletion?()
    }

    // MARK: - Navigation

    let segueRegistrationCompletionIdentifier = "completionRegistrationSeque"

    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueRegistrationCompletionIdentifier {
            segue.destination.modalPresentationStyle = .overCurrentContext
            if let vc = segue.destination as? RegistrationCompletionViewController {
                vc.registerViewController = self
            }
            else if let navVC = segue.destination as? UINavigationController {
                if let vc = navVC.viewControllers.first as? RegistrationCompletionViewController {
                    vc.registerViewController = self
                }
            }
        }
    }

}
