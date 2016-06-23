//
//  AccountManager.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit
import Async

class UserInfo : NSObject {
    var firstName: String?
    var lastName: String?
}

class AccountManager: NSObject {

    private let didCompleteLoginNotification = "registrationCompleteNotification"

    static let shared = AccountManager()

    var rootViewController    : UINavigationController?
    var contentManager        = ContentManager()
    var uploadInProgress      = false
    var isAuthorized: Bool  {
        get {            
            return UserManager.sharedManager.isLoggedIn()
        }
    }
    var isHealthKitAuthorized = false

    private(set) var userInfo: UserInfo?

    func loginOrRegister() {
        loginAndInitialize()
    }

    private func registerParticipant() {
        let registerVC = RegisterViewController.viewControllerFromStoryboard() as! RegisterViewController
        registerVC.consentOnLoad = true
        registerVC.registerCompletion = {
            self.loginComplete()
        }
        self.rootViewController?.pushViewController(registerVC, animated: true)
    }

    func doLogin(animated: Bool = true, completion: (Void -> Void)?) {
        assert(NSThread.isMainThread(), "can be called from main thread only")
        let registerLandingStroyboard = UIStoryboard(name: "RegisterLoginProcess", bundle: nil)
        let registerLogingLandingController = registerLandingStroyboard.instantiateViewControllerWithIdentifier("landingLoginRegister") as! RegisterLoginLandingViewController
        
        registerLogingLandingController.completion = completion
        
        Async.main(after: 1) {//select the first controller of the main tabbar contoller
            let mainTabbarController = self.rootViewController?.viewControllers[0] as! MainTabController
            mainTabbarController.selectedIndex = 0
        }
        
        self.rootViewController?.pushViewController(registerLogingLandingController, animated: animated)
    }

    func doLogout(completion: (Void -> Void)?) {
//        self.isAuthorized = false
        UserManager.sharedManager.logoutWithCompletion(completion)
        self.contentManager.stopBackgroundWork()
        PopulationHealthManager.sharedManager.resetAggregates()
    }

    private func loginComplete () {
        // TODO: Yanif: this currently pulls from Stormpath, and is no longer needed.
        // The profile will contain directly this information.
        UserManager.sharedManager.getUserInfo({ accountOpt, error in
            // try parse user info
            self.userInfo = nil

            if error == nil {
                if let account = accountOpt {
                    self.userInfo = UserInfo()
                    self.userInfo?.firstName = account.givenName as? String
                    self.userInfo?.lastName = account.surname as? String
                }
            }

            Async.main() {
//                self.isAuthorized = true
                self.contentManager.initializeBackgroundWork();
                NSNotificationCenter.defaultCenter().postNotificationName(self.didCompleteLoginNotification, object: nil)
            }
        })
    }

    func isLogged() -> Bool {
        return UserManager.sharedManager.hasAccount()
    }

    func loginAndInitialize(animated: Bool = true) {

        assert(self.rootViewController != nil, "Please, specify root navigation controller")
        
        guard isAuthorized else {
            self.doLogin (animated) { self.loginComplete() }
            return
        }

        withHKCalAuth {
            UserManager.sharedManager.ensureAccessToken { error in
                guard !error else {
                    Async.main() {
                        self.doLogin (animated) { self.loginComplete() }
                    }
                    return
                }
                
                // TODO: Yanif: handle partial failures when a subset of account components
                // failures beyond the consent component.
                UserManager.sharedManager.pullFullAccount { res in
                    if res.ok {
                        self.loginComplete()
                        return
                    } else {
                        if res.info.hasContent {
                            var components = UMPullComponentErrorAsArray(res.info)

                            // Try to upload the consent file if we encounter a consent pull error.
                            if components.contains(.Consent) {
                                self.uploadLostConsentFile()

                                if components.count == 1 {
                                    // Complete the login if pulling consent was the only error.
                                    self.loginComplete()
                                } else {
                                    components = components.filter { $0 != .Consent }
                                    log.error(UMPullMultipleComponentsError(components.map(getComponentName)))
                                }
                            } else {
                                log.error(res.info)
                            }
                        } else {
                            log.error("Failed to get initial user account")
                        }
                    }
                }
            }
        }
    }

    func withHKCalAuth(completion: Void -> Void) {
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                self.isHealthKitAuthorized = false
                log.error("no healthkit \(error)")
                return
            }

            self.isHealthKitAuthorized = true
            EventManager.sharedManager.checkCalendarAuthorizationStatus(completion)
        }
    }

    func uploadLostConsentFile() {
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            return
        }

        if (self.uploadInProgress) {
            return
        }

        self.uploadInProgress = true
        UserManager.sharedManager.pushConsent(consentPath) { [weak self]res in
            if res.ok {
                ConsentManager.sharedManager.removeConsentFile(consentPath)
            }
            self?.uploadInProgress = false
        }
    }
}
