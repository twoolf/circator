//
//  UserManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/13/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Alamofire
import Locksmith
import Stormpath
import CryptoSwift

private let UMPrimaryUserKey = "UMPrimaryUserKey"

// Profile entry keys
private let UMPHotwordKey   = "UMPHotwordKey"
private let UMPFrequencyKey = "UMPFrequencyKey"

public class UserManager {
    public static let sharedManager = UserManager()

    // Constants.
    public static let maxTokenRetries  = 2
    public static let defaultRefreshFrequency = 30
    public static let defaultHotwords = "food log"

    // Primary user
    public var userId: String? {
        get {
            if let dictionary = Locksmith.loadDataForUserAccount(UMPrimaryUserKey)
            {
                return dictionary["userId"] as? String
            } else {
                return nil
            }
        }
        set(newUser) {
            do {
                try Locksmith.updateData(["userId" : newUser ?? ""], forUserAccount: UMPrimaryUserKey)
            } catch {
                log.error("userId.set: \(error)")
            }
        }
    }

    var tokenExpiry : NSTimeInterval = NSDate().timeIntervalSince1970   // Expiry in time interval since 1970.
    var profileCache : [String: AnyObject] = [:]                        // Stormpath account dictionary cache.

    init() {
        Stormpath.setUpWithURL(MCRouter.baseURLString)
        self.profileCache = [:]
    }

    // Mark: - Account status, and authentication
    
    public func hasUserId() -> Bool {
        if let user = userId {
            return !user.isEmpty
        }
        return false
    }
    
    public func getUserId()     -> String? { return userId }
    public func getUserIdHash() -> String? { return userId?.md5() }
    public func setUserId(userId: String)  { self.userId = userId }
    public func resetUserId()              { self.userId = nil }

    // Mark: - Account metadata accessors for fields stored in keychain.
    
    public func getAccountData() -> [String:AnyObject]? {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            let lockbox = account.readFromSecureStore()
            return lockbox?.data
        }
        return nil
    }

    public func setAccountData(items: [String:AnyObject]) {
        withUserId { user in
            if var datadict = Locksmith.loadDataForUserAccount(user) {
                for (k,v) in items { datadict[k] = v }
                do {
                    try Locksmith.updateData(datadict, forUserAccount: user)
                } catch {
                    log.error("setAccountData: \(error)")
                }
            }
        }
    }

    public func getPassword() -> String? {
        if let data = getAccountData() {
            if let pass = data["password"] {
                return pass as? String
            }
        }
        return nil
    }
    
    public func hasAccount() -> Bool {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            return account.readFromSecureStore() != nil
        }
        return false
    }

    func createAccount(userId: String, userPass: String) {
        let account = UserAccount(username: userId, password: userPass)
        do {
            try account.createInSecureStore()
        } catch {
            log.error("createAccount: \(error)")
        }
    }

    func createAccount(userPass: String) {
        withUserId { user in
            let account = UserAccount(username: user, password: userPass)
            do {
                try account.createInSecureStore()
            } catch {
                log.error("createAccount: \(error)")
            }
        }
    }
    
    func validateAccount(userPass: String) -> Bool {
        if let pass = getPassword() {
            return pass == userPass
        }
        return false
    }
    
    func resetAccount() {
        withUserId { user in
            let account = UserAccount(username: user, password: "")
            do {
                try account.deleteFromSecureStore()
            } catch {
                log.warning("resetAccount: \(error)")
            }
        }
    }

    public func setAccountPassword(userPass: String) {
        createAccount(userPass)
    }

    // Override the username and password in the local store if we have nothing saved.
    public func ensureUserPass(user: String?, pass: String?) {
        if getUserId() == nil {
            if let currentUser = user {
                UserManager.sharedManager.setUserId(currentUser)
            }
        }
        
        if UserManager.sharedManager.getPassword() == nil {
            if let currentPass = pass {
                UserManager.sharedManager.setAccountPassword(currentPass)
            }
        }
    }
    
    // Set the username and password in keychain.
    public func overrideUserPass(user: String?, pass: String?) {
        withUserPass(user, password: pass) { (newUser, newPass) in
            UserManager.sharedManager.setUserId(newUser)
            UserManager.sharedManager.setAccountPassword(newPass)
        }
    }


    // Mark: - Stormpath-based account creation and authentication

    public func loginWithCompletion(completion: (String? -> Void)?) {
        withUserPass (getPassword()) { (user, pass) in
            Stormpath.login(username: user, password: pass, completionHandler: {
                (accessToken, err) -> Void in
                guard err == nil else {
                    log.error(err)
                    return
                }
                log.verbose("Access token: \(Stormpath.accessToken)")
                MCRouter.OAuthToken = Stormpath.accessToken
                Service.string(MCRouter.UserToken([:]), statusCode: 200..<300, tag: "LOGIN") {
                    _, response, result in
                        UserManager.sharedManager.pullProfile { _ in
                            if let comp = completion {
                                comp(result.value)
                            } else {
                                log.verbose("pullProfile result: \(result.value)")
                            }
                        }
                    }
            })
        }
    }
    
    public func login() {
        loginWithCompletion(nil)
    }

    public func login(userPass: String) {
        withUserId { user in
            if !self.validateAccount(userPass) { self.createAccount(user, userPass: userPass) }
            self.login()
        }
    }

    public func logoutWithCompletion(completion: (Void -> Void)?) {
        Stormpath.logout(completionHandler: { (error) -> Void in
            guard error == nil else {
                log.error("Error logging out of Stormpath: \(error)")
                return
            }
        })
        MCRouter.OAuthToken = nil
        resetUser()
        if let comp = completion { comp() }
    }

    public func logout() {
        logoutWithCompletion(nil)
    }
    
    public func register(firstName: String, lastName: String, completion: ((NSDictionary?, Bool) -> Void)) {
        withUserPass(getPassword()) { (user,pass) in
            let stormpathAccountDict : [String:String] = [
                "email": user,
                "password": pass,
                "givenName": firstName,
                "surname": lastName
            ]

            Stormpath.register(userDictionary: stormpathAccountDict, completionHandler: {
                (registerDict, error) -> Void in
                if error != nil { log.error("Register failed: \(error)") }
                completion(registerDict, error != nil)
            })
        }
    }

    
    // Mark: - Stormpath token management.
    
    public func getAccessToken() -> String? {
        return Stormpath.accessToken
    }
    
    public func ensureAccessToken(tried: Int, completion: (Bool -> Void)) {
        guard tried < UserManager.maxTokenRetries else {
            debugPrint("Failed to get access token within \(UserManager.maxTokenRetries) iterations")
            completion(true)
            return
        }
        
        Service.json(MCRouter.TokenExpiry([:]), statusCode: 200..<300, tag: "ACCTOK") {
            _, response, result in
                guard result.isSuccess else {
                    self.refreshAccessToken(tried, completion: completion)
                    return
                }
                guard let jwtDict = result.value as? [String:[String:AnyObject]],
                    expiry  = jwtDict["body"]?["exp"] as? NSTimeInterval
                    where expiry > NSDate().timeIntervalSince1970 else
                {
                    self.refreshAccessToken(tried, completion: completion)
                    return
                }
                self.tokenExpiry = expiry
                completion(false)
        }
    }
    
    public func ensureAccessToken(completion: (Bool -> Void)) {
        if let _ = Stormpath.accessToken {
            MCRouter.OAuthToken = Stormpath.accessToken
        }
        ensureAccessToken(0, completion: completion)
    }
    
    public func refreshAccessToken(tried: Int, completion: (Bool -> Void)) {
        Stormpath.refreshAccesToken { (_, error) in
            guard error == nil else {
                log.error("Refresh failed: \(error)")
                completion(true)
                return
            }
            if let token = Stormpath.accessToken {
                log.verbose("Refreshed token: \(token)")
                MCRouter.OAuthToken = Stormpath.accessToken
                Service.string(MCRouter.UserToken([:]), statusCode: 200..<300, tag: "REFTOK") {
                    _, response, result in
                        self.ensureAccessToken(tried+1, completion: completion)
                }
            } else {
                log.error("RefreshAccessToken failed, please login manually.")
            }
        }
    }
    
    public func refreshAccessToken(completion: (Bool -> Void)) {
        refreshAccessToken(0, completion: completion)
    }
    

    // Mark: - Profile (i.e., Stormpath account data) management

    public func syncProfile(completion: (String? -> Void)) {
        // Post to the service.
        Service.string(MCRouter.SetUserAccountData(profileCache), statusCode: 200..<300, tag: "UPDATEACC") {
            _, response, result in completion(result.value)
        }
    }

    public func pushProfile(metadata: [String: AnyObject], completion: (String? -> Void)) {
        // Refresh profile cache, and post to Stormpath.
        refreshProfileCache(metadata)
        syncProfile(completion)
    }
    
    public func pullProfile(completion: (AnyObject? -> Void)) {
        Service.json(MCRouter.GetUserAccountData(["exclude": ["consent"]]), statusCode: 200..<300, tag: "ACCDATA") {
            _, response, result in
                // Refresh cache.
                if let dict = result.value as? [String: AnyObject] { self.refreshProfileCache(dict) }
                
                // Evaluate the completion.
                completion(result.value)
        }
    }
    
    public func pushProfileWithConsent(consentFilePath: String?, metadata: [String: AnyObject], completion: (String? -> Void)) {
        if let path = consentFilePath {
            if let data = NSData(contentsOfFile: path) {
                var dict = metadata
                dict["consent"] = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
                pushProfile(dict, completion: completion)
            } else {
                log.error("Failed to read consent file at: \(path)")
            }
        } else {
            log.error("Invalid consent file path: \(consentFilePath)")
        }
    }
    
    public func getProfileCache() -> [String: AnyObject] { return profileCache }
    
    public func resetProfileCache() { profileCache = [:] }
    
    func refreshProfileCache(dict: [String: AnyObject]) {
        for (k,v) in dict {
            profileCache[k] = v
        }
    }
    
    
    // Mark : - Profile accessors

    public func getHotWords() -> String {
        return (profileCache[UMPHotwordKey] as? String) ?? UserManager.defaultHotwords
    }

    public func setHotWords(hotWords: String) {
        profileCache[UMPHotwordKey] = hotWords
        syncProfile { _ in () }
    }

    public func getRefreshFrequency() -> Int {
        return (profileCache[UMPFrequencyKey] as? Int) ?? UserManager.defaultRefreshFrequency
    }

    public func setRefreshFrequency(frequency: Int) {
        profileCache[UMPFrequencyKey] = frequency
        syncProfile { _ in () }
    }

    
    // Mark : - Utility functions
    
    func withUserId (completion: (String -> Void)) {
        if let user = userId { completion(user) }
        else { log.error("No user id available") }
    }

    func withUserPass (password: String?, completion: ((String, String) -> Void)) {
        if let user = userId, pass = password { completion(user, pass) }
        else { log.error("No user/password available") }
    }

    func withUserPass (username: String?, password: String?, completion: ((String, String) -> Void)) {
        if let user = username, pass = password { completion(user, pass) }
        else { log.error("No user/password available") }
    }
    
    // Resets all user-specific data, but preserves the last user id.
    public func resetUser() {
        resetAccount()
        resetProfileCache()
    }

    // Resets all user-related data, including the user id.
    public func resetFull() {
        resetAccount()
        resetProfileCache()
        resetUserId()
    }
}

