//
//  SessionManager.swift
//  MetabolicCompass
//
//  Created by Olena Ostrozhynska on 16.08.17.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import SimpleKeychain
import Auth0

enum SessionManagerError: Error {
    case noAccessToken
    case noRefreshToken
}

class AuthSessionManager {
    private static let wasCleanedUpOnFirstLaunchKey = "AuthSessionManager_WasCleanedUpOnFirstLaunch"
    static let shared = AuthSessionManager()
    private let keychain = A0SimpleKeychain(service: "Auth0")
    var profile: UserInfo?
    var userProfile: Profile?

    private init () {
        if !UserDefaults.standard.bool(forKey: AuthSessionManager.wasCleanedUpOnFirstLaunchKey) {
            cleanupTokens()
            UserDefaults.standard.set(true, forKey: AuthSessionManager.wasCleanedUpOnFirstLaunchKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public var mcAccessToken : String? {
        return keychain.string(forKey: "access_token")
    }
    
    private func cleanupTokens() {
        self.keychain.clearAll()
    }

   func storeTokens(_ accessToken: String, refreshToken: String? = nil) {
        self.keychain.setString(accessToken, forKey: "access_token")
        if let refreshToken = refreshToken {
            self.keychain.setString(refreshToken, forKey: "refresh_token")
        }
    }

//    func retrieveProfile(_ callback: @escaping (Error?) -> ()) {
//        guard let accessToken = self.keychain.string(forKey: "access_token") else {
//            return callback(SessionManagerError.noAccessToken)
//        }
//        Auth0
//            .authentication()
//            .userInfo(withAccessToken: accessToken)
//            .start { result in
//                switch(result) {
//                case .success(let profile):
//                    self.profile = profile
//                    callback(nil)
//                case .failure(_):
//                    self.refreshToken(callback)
//                }
//        }
//    }
//
//    func refreshToken(_ callback: @escaping (Error?) -> ()) {
//        guard let refreshToken = self.keychain.string(forKey: "refresh_token") else {
//            return callback(SessionManagerError.noRefreshToken)
//        }
//        Auth0
//            .authentication()
//            .renew(withRefreshToken: refreshToken, scope: "openid profile offline_access")
//            .start { result in
//                switch(result) {
//                case .success(let credentials):
//                    guard let accessToken = credentials.accessToken else { return }
//                    self.storeTokens(accessToken)
//                    self.retrieveProfile(callback)
//                case .failure(let error):
//                    callback(error)
//                    self.logout()
//                }
//        }
//    }

    func logout() {
        cleanupTokens()
    }

}
