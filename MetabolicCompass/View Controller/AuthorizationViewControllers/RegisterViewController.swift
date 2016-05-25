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
        
        setupScroolViewForKeyboardsActions(collectionView)
        
        dataSource.viewController = self
        dataSource.collectionView = self.collectionView
    
        self.setNeedsStatusBarAppearanceUpdate()
        if ( consentOnLoad ) { doConsent() }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
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
        UserManager.sharedManager.register(userRegistrationModel.firstName!, lastName: userRegistrationModel.lastName!) { (_, error, errormsg) in
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
            
        
            let initialProfile = self.dataSource.model.profileItems()
            //print("initialProfile \(initialProfile)")
            
            // Log in and update consent after successful registration.
            UserManager.sharedManager.loginWithPush(initialProfile) { res in
                guard !error else {
                    // Registration completed, but logging in failed.
                    // Pop this view to allow the user to try logging in again through the
                    // login/logout functionality on the main dashboard.
                    
                    UINotifications.loginFailed(self.navigationController!, pop: true, asNav: true, reason: res.info)
                    Answers.logSignUpWithMethod("SPR", success: false, customAttributes: nil)
                    return
                }
                
                // save user profile image
                UserManager.sharedManager.setUserProfilePhoto(userRegistrationModel.photo)
                
                UserManager.sharedManager.pushConsent(consentPath) { res in
                    
                    if (res.ok) {
                        ConsentManager.sharedManager.removeConsentFile(consentPath)
                    }
                    
                    
                    self.performSegueWithIdentifier(self.segueRegistrationCompletionIndentifier, sender: nil)
                    self.doWelcome()
                    
                    Answers.logSignUpWithMethod("SPR", success: true, customAttributes: nil)
                }
            }
        }
    }

    override func viewDidDisappear(animated: Bool) {
        // Remove the consent file for any scenario where we leave this view.
        if let consentPath = ConsentManager.sharedManager.getConsentFilePath() {
            let cPath = Path(consentPath)
            if cPath.exists {
                ConsentManager.sharedManager.removeConsentFile(consentPath)
            }
        }
    }

    func doConsent() {
        stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(self.navigationController!) {
            [weak self] (consented) -> Void in
            guard consented else {
                UserManager.sharedManager.resetFull()
                if let user = self!.stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                self!.navigationController?.popViewControllerAnimated(true)
                return
            }
        }
    }

    func doWelcome() {
        Async.main {
            self.parentView?.view.dodo.style.bar.hideAfterDelaySeconds = 3
            self.parentView?.view.dodo.style.bar.hideOnTap = true
            self.parentView?.view.dodo.success("Welcome " + (UserManager.sharedManager.getUserId() ?? ""))
            self.parentView?.initializeBackgroundWork()
        }
    }
    
    func registartionComplete() {
        navigationController?.popToRootViewControllerAnimated(true)
        doWelcome()
        if let comp = self.registerCompletion { comp() }
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
