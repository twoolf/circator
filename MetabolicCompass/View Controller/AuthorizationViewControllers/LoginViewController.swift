//
//  LoginViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/17/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import Async
import Former
import Crashlytics
import Dodo

/**
 This class is used to control the Login screens for the App.  By separating the logic into this view controller we enable changes to the login process to be clearly defined in this block of code.
 
- note: for both signup and login; uses Stormpath for authentication
 */
class LoginViewController: BaseViewController {

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    let loginModel: LoginModel = LoginModel()
    
    @IBOutlet weak var loginTable: UITableView!
    
    var parentView: IntroViewController?
    var completion: (Void -> Void)?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(loginModel, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(loginModel, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil)
        
        loginModel.loginTable = loginTable
        loginModel.controllerView = self.view
        loginTable.dataSource = loginModel
    }
    
    
    func uploadLostConsentFile() {
        
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(self.navigationController!, pop: true, asNav: true)
            return
        }
        
        UserManager.sharedManager.pushConsent(consentPath) { (error, text) in
            
            if (!error) {
                ConsentManager.sharedManager.removeConsentFile(consentPath)
            }
            
            self.loginComplete()
        }
    }
    
    func loginComplete() {
        if let comp = self.completion { comp() }
        //UINotifications.doWelcome(self.parentView!, pop: true, user: UserManager.sharedManager.getUserId() ?? "")
        
        self.navigationController?.popToRootViewControllerAnimated(true)
        
        Async.main {
            Answers.logLoginWithMethod("SPL", success: true, customAttributes: nil)
            self.parentView?.initializeBackgroundWork()
        }
    }

    // MARK: - Actions
    
    @IBAction func loginAction() {
        let loginCredentials = loginModel.getCredentials()
        
        UserManager.sharedManager.ensureUserPass(loginCredentials.email, pass: loginCredentials.password) { error in
            guard !error else {
                UINotifications.invalidUserPass(self.navigationController!)
                return
            }
            UserManager.sharedManager.loginWithPull { (error, text) in
                guard !error else {
                    
                    if (text == UMConsentInfoString) {
                        self.uploadLostConsentFile()
                    }
                    else {
                        Answers.logLoginWithMethod("SPL", success: false, customAttributes: nil)
                        //UINotifications.invalidUserPass(self.navigationController!)
                        UINotifications.invalidUserPass(self)
                    }
                    
                    return
                }
                
                self.loginComplete()
            }
        }
    }
    
    func doSignup(sender: UIButton) {
        let registerVC = RegisterViewController()
        registerVC.parentView = parentView
        registerVC.consentOnLoad = true
        self.navigationController?.pushViewController(registerVC, animated: true)
    }
}
