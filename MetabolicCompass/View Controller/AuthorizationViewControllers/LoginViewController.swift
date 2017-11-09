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
import Auth0
import SimpleKeychain


/**
 This class is used to control the Login screens for the App.  By separating the logic into this view controller we enable changes to the login process to be clearly defined in this block of code.

- note: for both signup and login; uses Stormpath for authentication
 */
 class  LoginViewController: BaseViewController, UIWebViewDelegate {

    @IBOutlet weak var containerScrollView: UIScrollView!

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    let loginModel: LoginModel = LoginModel()
    
    private var webView: UIWebView?

    @IBOutlet weak var loginTable: UITableView!

    var completion: ((Void) -> Void)?

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
        loginModel.loginTable = loginTable
        loginModel.controllerView = self.view
        loginTable.dataSource = loginModel
        self.setupScrollViewForKeyboardsActions(view: containerScrollView)
        modalPresentationCapturesStatusBarAppearance = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.auth0LoginPKCEFlowReceivingTokens(_:)), name: NSNotification.Name("AuthorizationCodeReceived"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func uploadLostConsentFile() {
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(vc: self.navigationController!, pop: true, asNav: true)
            return
        }

        UserManager.sharedManager.pushConsent(filePath: consentPath) { res in
            if res.ok {
                ConsentManager.sharedManager.removeConsentFile(consentFilePath: consentPath)
            }
            self.loginComplete()
        }
    }

    func loginComplete() {
        if let comp = self.completion { comp(()) }
        self.navigationController?.popToRootViewController(animated: true)
        
        Async.main {
            Answers.logLogin(withMethod: "SPL", success: true, customAttributes: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: UMDidLoginNotifiaction), object: nil)
        }
    }

    // MARK: - Actions

    @IBAction func loginAction() {
        auth0LoginPKCEFlowReceivingAuthorizationCode()
    }

    func doSignup(sender: UIButton) {
        let registerVC = RegisterViewController()
        registerVC.consentOnLoad = true
        self.navigationController?.pushViewController(registerVC, animated: true)
    }

    func auth0LoginPKCEFlowReceivingAuthorizationCode() {
        PKCEFlowManager.shared?.receiveAutorizationCode { [weak self] data in
            let htmlString = String(data: data!, encoding: .utf8)
            self?.webView = UIWebView(frame: (self?.view.bounds)!)
            self?.webView?.loadHTMLString(htmlString!, baseURL: nil)
            self?.webView?.delegate = self
            self?.view.addSubview((self?.webView)!)
        }
    }

    @objc public func auth0LoginPKCEFlowReceivingTokens(_ notification: NSNotification) {
        let authorizationCode = notification.userInfo?["authorization_code"] as? String
        PKCEFlowManager.shared?.receiveAccessToken(authorizationCode: authorizationCode!,  { [weak self] data in
            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any] else {return}
            guard let accessToken = json!["access_token"] as? String else {return}
            guard let refreshToken = json!["refresh_token"] as? String else {return}
            guard let idToken = json!["id_token"] as! String? else {return}
            AuthSessionManager.shared.storeTokens(accessToken , refreshToken: refreshToken)
            self?.webView?.removeFromSuperview()
            self?.login()
        })
    }
    
    func login() {
        startAction()
        let loginCredentials = loginModel.getCredentials()

        UserManager.sharedManager.ensureUserPass(user: loginCredentials.email, pass: loginCredentials.password) { error in
            guard !error else {
                UINotifications.invalidUserPass(vc: self.navigationController!)
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
                                Answers.logLogin(withMethod: "SPL", success: false, customAttributes: nil)
                                let componentNames = components.map { getComponentName($0) }.joined(separator: ", ")
                                let reason = components.isEmpty ? "" : " (missing \(componentNames))"
                                UINotifications.loginFailed(vc: self, reason: "Failed to get account\(reason)")
                            }
                        } else {
                            Answers.logLogin(withMethod: "SPL", success: false, customAttributes: nil)
                            let componentNames = components.map { getComponentName($0) }.joined(separator: ", ")
                            let reason = components.isEmpty ? "" : " (missing \(componentNames))"
                            UINotifications.loginFailed(vc: self, reason: "Failed to get account\(reason)")
                        }
                    } else {
                        Answers.logLogin(withMethod: "SPL", success: false, customAttributes: nil)
                        UINotifications.invalidUserPass(vc: self)
                    }

                    // Explicitly logout on an error to clear the UserManager's userid.
                    // This way the user does not see the dashboard on app relaunch.
                    //                    log.info(res.info)
                    UserManager.sharedManager.logout()
                    return
                }
                if UserManager.sharedManager.isItFirstLogin() {//if it's first login
                    if let additionalInfo = UserManager.sharedManager.getAdditionalProfileData() {//and user has an additional data. we will push it to the server
                        UserManager.sharedManager.pushProfile(componentData: additionalInfo , completion: { _ in
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
}
