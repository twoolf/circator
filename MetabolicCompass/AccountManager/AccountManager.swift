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

class AccountManager: NSObject {
    
    private let didCompleteLoginNotification = "registrationCompleteNotification"
    
    static let shared = AccountManager()
    var rootViewController: UINavigationController?
    var contentManager = ContentManager()
    
    
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
    
    func doLogin(completion: (Void -> Void)?) {
        
        Async.main() {
            let registerLandingStroyboard = UIStoryboard(name: "RegisterLoginProcess", bundle: nil)
            let registerLogingLandingController = registerLandingStroyboard.instantiateViewControllerWithIdentifier("landingLoginRegister") as! RegisterLoginLandingViewController
            
            registerLogingLandingController.completion = completion
            
            self.rootViewController?.pushViewController(registerLogingLandingController, animated: UserManager.sharedManager.hasUserId())
        }
        
    }
    
    func doLogout(completion: (Void -> Void)?) {
        
        UserManager.sharedManager.logoutWithCompletion(completion)
        self.contentManager.stopBackgroundWork()
        PopulationHealthManager.sharedManager.resetAggregates()
        
    }
    
    private func loginComplete () {
        
        Async.main() {
            self.contentManager.initializeBackgroundWork();
            NSNotificationCenter.defaultCenter().postNotificationName(self.didCompleteLoginNotification, object: nil)
            
        }
    }
    
    func isLogged() -> Bool {
        return UserManager.sharedManager.hasAccount()
    }
    
    func loginAndInitialize() {
        
        assert(self.rootViewController != nil, "Please, specify root navigation controller")
        
        guard UserManager.sharedManager.hasAccount() else {
            self.doLogin { self.loginComplete() }
            return
        }
        
        withHKCalAuth {
            UserManager.sharedManager.ensureAccessToken { error in
                guard !error else {
                    self.loginComplete()
                    return
                }
                
                UserManager.sharedManager.pullProfileWithConsent { (error, msg) in
                    if !error {
                        self.loginComplete()
                    } else {
                        log.error("Failed to retrieve initial profile and consent: \(msg)")
                    }
                }
            }
        }
    }
    
    func withHKCalAuth(completion: Void -> Void) {
        
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                log.error("no healthkit \(error)")
                return
            }
            
            EventManager.sharedManager.checkCalendarAuthorizationStatus(completion)
        }
    }

    
}
