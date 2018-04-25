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
    
    public var mcRefreshTokenToken : String? {
        return keychain.string(forKey: "refresh_token")
    }
    
    public var auth0IdToken : String? {
        return keychain.string(forKey: "auth0_id_token")
    }
    
    private func cleanupTokens() {
        self.keychain.clearAll()
    }
    
    func storeAuth0IdToken(idToken: String) {
        self.keychain.setString(idToken, forKey: "auth0_id_token")
    }

   func storeTokens(_ accessToken: String, refreshToken: String? = nil) {
        self.keychain.setString(accessToken, forKey: "access_token")
        if let refreshToken = refreshToken {
            self.keychain.setString(refreshToken, forKey: "refresh_token")
        }
    }

    func logout() {
        cleanupTokens()
    }

}
