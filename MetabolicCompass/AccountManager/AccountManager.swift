//
//  AccountManager.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved. 
//

import UIKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import SwiftyUserDefaults

internal let AMNotificationsKey = "AMNotificationsKey"

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

    func doLogin(_ animated: Bool = true, completion: (() -> Void)?) {
        assert(Thread.isMainThread, "can be called from main thread only")
        let registerLandingStoryboard = UIStoryboard(name: "RegisterLoginProcess", bundle: nil)
        let registerLoginLandingController = registerLandingStoryboard.instantiateViewController(withIdentifier: "landingLoginRegister") as! RegisterLoginLandingViewController
        
        registerLoginLandingController.completion = completion
        
        OperationQueue.main.addOperation {
            let mainTabbarController = self.rootViewController?.viewControllers[0] as! MainTabController
            mainTabbarController.selectedIndex = 0
        }
        
        self.rootViewController?.pushViewController(registerLoginLandingController, animated: animated)
    }

    func doLogout(completion: (() -> Void)?) {
        log.debug("User logging out", feature: "accountExec")
        UserManager.sharedManager.logoutWithCompletion(completion: completion)
        IOSHealthManager.sharedManager.reset()
        self.contentManager.stopBackgroundWork()
        PopulationHealthManager.sharedManager.reset()
    }

    func doWithdraw(_ keepData: Bool, completion: @escaping (Bool) -> Void) {
        log.debug("User withdrawing", feature: "accountExec")
        UserManager.sharedManager.withdraw(keepData: keepData, completion: completion)
        IOSHealthManager.sharedManager.reset()
        self.contentManager.stopBackgroundWork()
        PopulationHealthManager.sharedManager.reset()
    }

    private func loginComplete () {
        log.debug("User login complete", feature: "loginExec")

        OperationQueue.main.addOperation {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.didCompleteLoginNotification), object: nil)
        }
    }

    func isLogged() -> Bool {
        return UserManager.sharedManager.hasAccount()
    }

    func loginAndInitialize(animated: Bool = true) {

        assert(self.rootViewController != nil, "Please, specify root navigation controller")
        
        log.debug("Login start", feature: "loginExec")
        guard isAuthorized else {
            log.debug("Login: No token found, launching dialog", feature: "loginExec")
            self.doLogin (animated) { self.loginComplete() }
            return
        }

        log.debug("Login: checking HK/Cal auth", feature: "loginExec")
        withHKCalAuth {
            UserManager.sharedManager.ensureAccessToken { error in
                guard !error else {
                    log.debug("Login: HK/Cal auth failed, relaunching dialog", feature: "loginExec")
                    Async.main() { self.doLogin (animated) { self.loginComplete() } }
                    return
                }

                // TODO: Yanif: handle partial failures when a subset of account components
                // failures beyond the consent component.
                log.debug("Login: pulling account", feature: "loginExec")
                UserManager.sharedManager.pullFullAccount { res in
                    log.debug("Login pull account result: \(res)", feature: "loginExec")
                    if res.ok { self.loginComplete() }
                    else {
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
                            }
                            else {
                                log.error(res.info)
                            }
                        }
                        else {
                            log.error("Failed to get initial user account")
                        }
                    }
                }
            }
            log.debug("before end of section")
        }
    }

    func withHKCalAuth(completion: @escaping (Void) -> Void) {
        MCHealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                self.isHealthKitAuthorized = false
                log.error("HealthKit is not available: \(error!.localizedDescription)")
                return
            }

            self.isHealthKitAuthorized = true
            self.checkLocalNotifications()
            EventManager.sharedManager.checkCalendarAuthorizationStatus(completion: completion)
            log.debug("after EventManager in withHKCalAuth")
        }
    }

    func registerLocalNotifications() {
        log.debug("Registering for local notifications", feature: "notifications")
        resetLocalNotifications()
        let notificationType: UIUserNotificationType = [.alert, .badge, .sound]
//        let notificationSettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationType, categories: nil)
        let notificationSettings: UIUserNotificationSettings = UIUserNotificationSettings(types: notificationType, categories: nil)
        DispatchQueue.main.async {
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        }
    }

    func resetLocalNotifications() {
        log.debug("Resetting local notifications", feature: "notifications")
        Defaults.remove(AMNotificationsKey)
        Defaults.synchronize()
    }

    func checkLocalNotifications() {
        log.debug("Notifications status: \(Defaults.object(forKey: AMNotificationsKey) ?? no_argument as! AnyObject)", feature: "notifications")
        if let notificationsOn = Defaults.object(forKey: AMNotificationsKey) as? Bool, notificationsOn {
            return
        }

        registerLocalNotifications()
    }

    func uploadLostConsentFile() {
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            return
        }

        if (self.uploadInProgress) {
            log.debug("Skipping consent upload, already in progress", feature: "uploadConsent")
            return
        }

        log.debug("Uploading consent file", feature: "uploadConsent")
        self.uploadInProgress = true
        UserManager.sharedManager.pushConsent(filePath: consentPath) { [weak self]res in
            if res.ok {
                ConsentManager.sharedManager.removeConsentFile(consentFilePath: consentPath)
            }
            self?.uploadInProgress = false
        }
    }
}
