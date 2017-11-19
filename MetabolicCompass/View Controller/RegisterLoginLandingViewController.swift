//
//  RegisterLoginLandingViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 4/22/16. 
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit
import SafariServices
import ReachabilitySwift
import Async
import Crashlytics

class RegisterLoginLandingViewController: BaseViewController, UIWebViewDelegate {
    
    var completion: ((Void) -> Void)?
    let loginSegue = "LoginSegue"
    let registerSegue = "RegisterSegue"
    var reachability: Reachability! = nil
//    var reachability: Bool = true
    private var webView: UIWebView?

    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black;
        self.navigationController?.navigationBar.tintColor = UIColor.white

        do {
//            reachability = try Reachability.reachabilityForInternetConnection()
            reachability = try Reachability()
        } catch {
            let msg = "Failed to create reachability detector"
//            log.error(msg)
            fatalError(msg)
        }        
        NotificationCenter.default.addObserver(self, selector: #selector(self.auth0LoginPKCEFlowReceivingTokens(_:)), name: NSNotification.Name("AuthorizationCodeReceived"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    /*func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent;
    } */
    
    //MARK: Actions
    @IBAction func onLogin(_ sender: AnyObject) {
        auth0LoginPKCEFlowReceivingAuthorizationCode()
    }


/*    @IBAction func onRegister(sender: AnyObject) {
        switch reachability.currentReachabilityStatus {
//        case .isNotReachable:
//            UINotifications.genericError(vc: self, msg: "We cannot register a new account without internet connectivity. Please try later.", pop: false, asNav: true)

        default:
            self.performSegue(withIdentifier: self.registerSegue, sender: self)
        }
    }   /* was BrightButton */ */

    @IBAction func onRegister(_ sender: AnyObject) {
        switch reachability.currentReachabilityStatus {
            //        case .isNotReachable:
            //            UINotifications.genericError(vc: self, msg: "We cannot register a new account without internet connectivity. Please try later.", pop: false, asNav: true)
            
        default:
            self.performSegue(withIdentifier: self.registerSegue, sender: self)
        }
    }
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == self.loginSegue) {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.completion = self.completion
        } else if (segue.identifier == self.registerSegue) {
            let regViewController = segue.destination as! RegisterViewController
            regViewController.registerCompletion = {
                UINotifications.genericMsg(vc: self, msg: "Please remember to check your email for our account verification link.", pop: false, asNav: true, nohide: true)
            }
        }        
    }
    
    @IBAction func privacyPolicy() {
        let svc = SFSafariViewController(url: MCRouter.privacyPolicyURL!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func auth0LoginPKCEFlowReceivingAuthorizationCode() {
        PKCEFlowManager.shared?.receiveAuthorizationCode { [weak self] data in
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
            guard let json = try? JSONSerialization.jsonObject(with: data!) as? [String: Any] else {
                self?.auth0authorizationFailed()
                return
            }
            guard let accessToken = json!["access_token"] as? String else {
                self?.auth0authorizationFailed()
                return
            }
            guard let refreshToken = json!["refresh_token"] as? String else {
                self?.auth0authorizationFailed()
                return
            }
            guard let idToken = json!["id_token"] as? String? else {
                self?.auth0authorizationFailed()
                return
            }
            AuthSessionManager.shared.storeTokens(accessToken , refreshToken: refreshToken)
            self?.webView?.removeFromSuperview()
            self?.login()
        })
    }
    
    func auth0authorizationFailed(){
        webView?.removeFromSuperview()
        //alert
    }
    
    func login() {
        startAction()
//        let loginCredentials = loginModel.getCredentials()
        
//        UserManager.sharedManager.ensureUserPass(user: loginCredentials.email, pass: loginCredentials.password) { error in
//            guard !error else {
//                UINotifications.invalidUserPass(vc: self.navigationController!)
//                return
//            }
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
     //   }
    }
    
    func loginComplete() {
        if let comp = self.completion { comp(()) }
        self.navigationController?.popToRootViewController(animated: true)
        
        Async.main {
            Answers.logLogin(withMethod: "SPL", success: true, customAttributes: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: UMDidLoginNotifiaction), object: nil)
        }
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
}
