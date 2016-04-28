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

    
    var profileValues : [String: String] = [:]

    var recommendedSubview : ProfileSubviewController! = nil
    var optionalSubview : ProfileSubviewController! = nil

    internal var consentOnLoad : Bool = false
    internal var registerCompletion : (Void -> Void)?
    internal var parentView: IntroViewController?

    private var stashedUserId : String?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "REGISTER"
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
    
        if ( consentOnLoad ) { doConsent() }
    }
    
    @IBAction func registerAction(sender: UIButton) {
        
        let a = true
        
        if a {
            performSegueWithIdentifier(segueRegistrationCompletionIndentifier, sender: nil)
            return
        }
        
        self.profileValues = self.dataSource.model.profileItems()
        //print("profile items: \(self.profileValues)")

        UINotifications.genericMsg(self.navigationController!, msg: "Registering account...")
        
        
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(self.navigationController!, pop: true, asNav: true)
            return
        }
        
        let userRegistrationModel = dataSource.model
        if !userRegistrationModel.isModelValid() {
            self.showAlert(withMessage: userRegistrationModel.validationMessage!, title: "Registration Error")
            return
        }
        
        
        sender.enabled = false
        
        
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
            
        
            let initialProfile = Dictionary(pairs:
                self.profileValues.filter { (k,v) in UserProfile.sharedInstance.updateableMapping[k] != nil }.map { (k,v) in
                    (UserProfile.sharedInstance.updateableMapping[k]!, v)
                })
            
            //print("initialProfile \(initialProfile)")
            
            // Log in and update consent after successful registration.
            UserManager.sharedManager.loginWithPush(initialProfile) { (error, reason) in
                guard !error else {
                    // Registration completed, but logging in failed.
                    // Pop this view to allow the user to try logging in again through the
                    // login/logout functionality on the main dashboard.
                    
                    UINotifications.loginFailed(self.navigationController!, pop: true, asNav: true, reason: reason)
                    Answers.logSignUpWithMethod("SPR", success: false, customAttributes: nil)
                    return
                }
                
                // save user profile image
                UserManager.sharedManager.setUserProfilePhoto(userRegistrationModel.photo)
                
                UserManager.sharedManager.pushConsent(consentPath) { _ in
                    ConsentManager.sharedManager.removeConsentFile(consentPath)
                    
                    self.doWelcome()
                    
                    self.performSegueWithIdentifier(self.segueRegistrationCompletionIndentifier, sender: nil)
                
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
        navigationController?.popViewControllerAnimated(true)
        Async.main {
            self.parentView?.view.dodo.style.bar.hideAfterDelaySeconds = 3
            self.parentView?.view.dodo.style.bar.hideOnTap = true
            self.parentView?.view.dodo.success("Welcome " + (UserManager.sharedManager.getUserId() ?? ""))
            self.parentView?.initializeBackgroundWork()
        }
    }
    
    func registartionComplete() {
        doWelcome()
        if let comp = self.registerCompletion { comp() }
    }
    
    // MARK: - Navigation

    private let segueRegistrationCompletionIndentifier = "completionRegistrationSeque"
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == segueRegistrationCompletionIndentifier {
            if let vc = segue.destinationViewController as? RegistrationComplitionViewController {
                vc.modalPresentationStyle = .OverCurrentContext
                vc.registerViewController = self
            }
            
        }
        
    }

}
