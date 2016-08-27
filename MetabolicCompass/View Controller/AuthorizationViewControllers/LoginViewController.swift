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
import SwiftyUserDefaults

/**
 This class is used to control the Login screens for the App.  By separating the logic into this view controller we enable changes to the login process to be clearly defined in this block of code.

- note: for both signup and login; uses Stormpath for authentication
 */
class LoginViewController: BaseViewController {

    @IBOutlet weak var containerScrollView: UIScrollView!

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

        loginModel.loginTable = loginTable
        loginModel.controllerView = self.view
        loginTable.dataSource = loginModel

        self.setupScrollViewForKeyboardsActions(containerScrollView)
    }


    func uploadLostConsentFile() {
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(self.navigationController!, pop: true, asNav: true)
            return
        }

        UserManager.sharedManager.pushConsent(consentPath) { res in
            if res.ok {
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
            NSNotificationCenter.defaultCenter().postNotificationName(UMDidLoginNotifiaction, object: nil)
        }
    }

    // MARK: - Actions

    @IBAction func loginAction() {
        startAction()
        
        let loginCredentials = loginModel.getCredentials()

        UserManager.sharedManager.ensureUserPass(loginCredentials.email, pass: loginCredentials.password) { error in
            guard !error else {
                UINotifications.invalidUserPass(self.navigationController!)
                return
            }
            UserManager.sharedManager.loginWithPull { res in
                guard res.ok else {
                    if res.info.hasContent {
                        let components = UMPullComponentErrorAsArray(res.info)
                        
                        // Try to upload the consent file if we encounter a consent pull error.
                        if components.contains(.Consent) {
                            self.uploadLostConsentFile()
                            // Raise a notification if there are other errors.
                            if components.count > 1 {
                                Answers.logLoginWithMethod("SPL", success: false, customAttributes: nil)
                                let componentNames = components.map { getComponentName($0) }.joinWithSeparator(", ")
                                let reason = components.isEmpty ? "" : " (missing \(componentNames))"
                                UINotifications.loginFailed(self, reason: "Failed to get account\(reason)")
                            }
                        } else {
                            Answers.logLoginWithMethod("SPL", success: false, customAttributes: nil)
                            let componentNames = components.map { getComponentName($0) }.joinWithSeparator(", ")
                            let reason = components.isEmpty ? "" : " (missing \(componentNames))"
                            UINotifications.loginFailed(self, reason: "Failed to get account\(reason)")
                        }
                    } else {
                        Answers.logLoginWithMethod("SPL", success: false, customAttributes: nil)
                        UINotifications.invalidUserPass(self)
                    }

                    // Explicitly logout on an error to clear the UserManager's userid.
                    // This way the user does not see the dashboard on app relaunch.
                    UserManager.sharedManager.logout()
                    return
                }
                if UserManager.sharedManager.isItFirstLogin() {//if it's first login
                    if let additionalInfo = UserManager.sharedManager.getAdditionalProfileData() {//and user has an additional data. we will push it to the server
                        UserManager.sharedManager.pushProfile(additionalInfo , completion: { _ in
                            UserManager.sharedManager.removeFirstLogin()
                        })
                    } else {//in other case we just remove marker for first login
                        UserManager.sharedManager.removeFirstLogin()
                    }
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
