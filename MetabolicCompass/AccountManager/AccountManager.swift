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
    var isAuthorized          = false
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

        let registerLandingStoryboard = UIStoryboard(name: "RegisterLoginProcess", bundle: nil)
        let registerLoginLandingController = registerLandingStoryboard.instantiateViewControllerWithIdentifier("landingLoginRegister") as! RegisterLoginLandingViewController

        registerLoginLandingController.completion = completion

        self.rootViewController?.pushViewController(registerLoginLandingController, animated: animated)
    }

    func doLogout(completion: (Void -> Void)?) {
        self.isAuthorized = false
        UserManager.sharedManager.logoutWithCompletion(completion)
        self.contentManager.stopBackgroundWork()
        PopulationHealthManager.sharedManager.resetAggregates()
    }

    private func loginComplete () {
        // TODO:
        // Yanif: this currently pulls from Stormpath, and is no longer needed.
        // The profile will contain directly this information.
        UserManager.sharedManager.getUserInfo({ dict, error in
            // try parse user info
            self.userInfo = nil

            if error == nil {
                if let info = dict {
                    self.userInfo = UserInfo()
                    self.userInfo?.firstName = info["givenName"] as? String
                    self.userInfo?.lastName = info["surname"] as? String
                }
            }

            Async.main() {
                self.isAuthorized = true
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

        guard UserManager.sharedManager.hasAccount() else {
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

                // TODO: handle partial failures when a subset of account components
                // failures beyond the consent component.
                UserManager.sharedManager.pullFullAccount { (error, msg) in
                    if !error {
                        self.loginComplete()
                    }
                    else if (msg == UMPullComponentError(.Consent)) {
                        self.uploadLostConsentFile()
                        self.loginComplete()
                    }
                    else {
                        log.error("Failed to retrieve initial profile and consent: \(msg)")
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
        UserManager.sharedManager.pushConsent(consentPath) { [weak self](error, text) in
            if (!error) {
                ConsentManager.sharedManager.removeConsentFile(consentPath)
            }
            self?.uploadInProgress = false
        }
    }
}
