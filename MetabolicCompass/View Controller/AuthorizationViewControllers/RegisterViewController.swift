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
import Auth0

private let lblFontSize = ScreenManager.sharedInstance.profileLabelFontSize()
private let inputFontSize = ScreenManager.sharedInstance.profileInputFontSize()

 class RegisterViewController : BaseViewController {

    override class var storyboardName : String {
        return "RegisterLoginProcess"
    }

    var dataSource = RegisterModelDataSource()

    @IBOutlet weak var collectionView: UICollectionView!
    
    var updatingExistingUser = false
    
    internal var consentOnLoad : Bool = false
    internal var registerCompletion : (() -> Void)?
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
        dataSource.updateExistingUser = updatingExistingUser
        setupScrollViewForKeyboardsActions(view: collectionView)

        dataSource.viewController = self
        dataSource.collectionView = self.collectionView

        self.setNeedsStatusBarAppearanceUpdate()
        self.doConsent()   
    }
    
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
        
        UINotifications.genericMsg(vc: self.navigationController!, msg: "Registering account...")
        let initialProfile = self.dataSource.model.profileItems()
        
        
        
        let callback : (Error?) -> () = { error in
            guard error == nil else {
                // Return from this function to allow the user to try registering again with the 'Done' button.
                // We reset the user/pass so that any view exit leaves the app without a registered user.
                // Re-entering this function will use overrideUserPass above to re-establish the account being registered.
                UserManager.sharedManager.resetFull()
                if let user = self.stashedUserId {
                    UserManager.sharedManager.setUserId(userId: user)
                }
                UINotifications.registrationError(vc: self.navigationController!, msg: NSLocalizedString("Registration error", comment: "Registration error"))
                Answers.logSignUp(withMethod: "SPR", success: false, customAttributes: nil)
                return
            }
            
            UserManager.sharedManager.setAsFirstLogin()
            _ = UserManager.sharedManager.setUserProfilePhoto(photo: userRegistrationModel.photo)
            self.performSegue(withIdentifier: self.segueRegistrationCompletionIdentifier, sender: nil)
        }
        
        if updatingExistingUser {
            UserManager.sharedManager.updateAuth0ExistingUser(firstName: userRegistrationModel.firstName!,
                                                              lastName: userRegistrationModel.lastName!,
                                                              consentPath: consentPath,
                                                              initialData: initialProfile,
                                                              completion: callback)
        } else {
            UserManager.sharedManager.registerAuth0(firstName: userRegistrationModel.firstName!,
                                                    lastName: userRegistrationModel.lastName!,
                                                    consentPath: consentPath,
                                                    initialData: initialProfile,
                                                    completion: callback)
        }
    }

    func doConsent() {
        stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(self.navigationController!) { [weak self] (consent, firstName, lastName) in
            guard consent else {
                UserManager.sharedManager.resetFull()
                if let user = self?.stashedUserId {
                    UserManager.sharedManager.setUserId(userId: user)
                }
                self?.navigationController?.popViewController(animated: true)
                return ()
            }

            // Note: add 1 to index, due to photo field.
            if let strongSelf = self {
                let updatedData = firstName != nil || lastName != nil
                    if firstName != nil { strongSelf.dataSource.model.setAtItem(itemIndex: strongSelf.dataSource.model.firstNameIndex + 1, newValue: firstName! as AnyObject?) }
                    if lastName != nil { strongSelf.dataSource.model.setAtItem(itemIndex: strongSelf.dataSource.model.lastNameIndex + 1, newValue: lastName! as AnyObject?) }
                if updatedData { strongSelf.collectionView.reloadData() }
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
