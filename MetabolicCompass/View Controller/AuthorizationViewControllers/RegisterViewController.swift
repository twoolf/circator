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

 class RegisterViewController : BaseViewController, UIWebViewDelegate {

    override class var storyboardName : String {
        return "RegisterLoginProcess"
    }

    var dataSource = RegisterModelDataSource()

    @IBOutlet weak var collectionView: UICollectionView!

    internal var consentOnLoad : Bool = false
    internal var registerCompletion : (() -> Void)?
    private var stashedUserId : String?
    private var webView: UIWebView?
    
    //MARK: View life circle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(self.auth0LoginPKCEFlowReceivingTokens(_:)), name: NSNotification.Name("AuthorizationCodeReceived"), object: nil)
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
    
override func viewDidDisappear(_ animated: Bool) {
    NotificationCenter.default.removeObserver(self)
}
    func auth0authorizationFailed(){
        webView?.removeFromSuperview()
        //alert
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
            self?.updateUserProfile()
        })
    }
    
    func updateUserProfile() {
        guard let accessToken = AuthSessionManager.shared.keychain.string(forKey: "access_token") else {
            return            
        }

        let headers = [
            "authorization": "Bearer \(accessToken)",
            "content-type": "application/json"
        ]
        let parameters = [
            "user_metadata": ["hobby": "surfing"]
            ] as [String : Any]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return
        }
        
        var request = URLRequest(url: URL(string: "https://metaboliccompass.auth0.com/api/v2/users/user_id")!,
                                     cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = headers
        request.httpBody = httpBody
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })
        dataTask.resume()

    }
    //MARK: Actions
    @IBAction func registerAction(_ sender: UIButton) {
        startAction()
        auth0LoginPKCEFlowReceivingAuthorizationCode()
 
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
        let initialProfile = self.dataSource.model.profileItems()
//        UserManager.sharedManager.registerAuth0(firstName: userRegistrationModel.firstName!,
//                                                 lastName: userRegistrationModel.lastName!,
//                                              consentPath: consentPath,
//                                              initialData: initialProfile)
        
        UserManager.sharedManager.register(firstName: userRegistrationModel.firstName!,
                                            lastName: userRegistrationModel.lastName!,
                                         consentPath: consentPath,
                                         initialData: initialProfile) { (_, error, errormsg) in
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
            if let s = self {
                let updatedData = firstName != nil || lastName != nil
                    if firstName != nil { s.dataSource.model.setAtItem(itemIndex: s.dataSource.model.firstNameIndex + 1, newValue: firstName! as AnyObject?) }
                    if lastName != nil { s.dataSource.model.setAtItem(itemIndex: s.dataSource.model.lastNameIndex + 1, newValue: lastName! as AnyObject?) }
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
