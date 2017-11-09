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
    static let shared = AuthSessionManager()
    let keychain = A0SimpleKeychain(service: "Auth0")
    var profile: UserInfo?
    var userProfile: Profile?

    private init () { }

   func storeTokens(_ accessToken: String, refreshToken: String? = nil) {
        self.keychain.setString(accessToken, forKey: "access_token")
        if let refreshToken = refreshToken {
            self.keychain.setString(refreshToken, forKey: "refresh_token")
        }
    }

    func retrieveProfile(_ callback: @escaping (Error?) -> ()) {
        guard let accessToken = self.keychain.string(forKey: "access_token") else {
            return callback(SessionManagerError.noAccessToken)
        }
        Auth0
            .authentication()
            .userInfo(withAccessToken: accessToken)
            .start { result in
                switch(result) {
                case .success(let profile):
                    self.profile = profile
                    callback(nil)
                case .failure(_):
                    self.refreshToken(callback)
                }
        }
    }

    func refreshToken(_ callback: @escaping (Error?) -> ()) {
        guard let refreshToken = self.keychain.string(forKey: "refresh_token") else {
            return callback(SessionManagerError.noRefreshToken)
        }
        Auth0
            .authentication()
            .renew(withRefreshToken: refreshToken, scope: "openid profile offline_access")
            .start { result in
                switch(result) {
                case .success(let credentials):
                    guard let accessToken = credentials.accessToken else { return }
                    self.storeTokens(accessToken)
                    self.retrieveProfile(callback)
                case .failure(let error):
                    callback(error)
                    self.logout()
                }
        }
    }

    func logout() {
        self.keychain.clearAll()
    }

}

func plistValues(bundle: Bundle) -> (clientId: String, domain: String)? {
    guard
        let path = bundle.path(forResource: "Auth0", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
    }

    guard
        let clientId = values["ClientId"] as? String,
        let domain = values["Domain"] as? String
        else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            print("File currently has the following entries: \(values)")
            return nil
    }
    return (clientId: clientId, domain: domain)
}
