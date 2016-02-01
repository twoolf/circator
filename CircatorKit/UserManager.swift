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
import SwiftDate

private let UMPrimaryUserKey = "UMPrimaryUserKey"

// Profile entry keys
private let UMPHotwordKey    = "UMPHotwordKey"
private let UMPFrequencyKey  = "UMPFrequencyKey"

private let HMHRangeStartKey = "HKHRStart"
private let HMHRangeEndKey   = "HKHREnd"
private let HMHRangeMinKey   = "HKHRMin"

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

    func validateAccount(userPass: String) -> Bool {
        if let pass = getPassword() { return pass == userPass }
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

    public func getPassword() -> String? {
        if let data = getAccountData(), pass = data["password"] as? String {
            return pass
        }
        return nil
    }

    public func hasPassword() -> Bool {
        if let data = getAccountData(), pass = data["password"] as? String {
            return !pass.isEmpty
        }
        return false
    }

    public func setPassword(userPass: String) {
        if hasAccount() {
            setAccountData(["password": userPass])
        } else {
            withUserId { user in self.createAccount(user, userPass: userPass) }
        }
    }

    // Set a username and password in keychain, invoking a completion with an error status.
    public func ensureUserPass(user: String?, pass: String?, completion: Bool -> Void) {
        if let u = user, p = pass {
            guard !(u.isEmpty || p.isEmpty) else {
                completion(true)
                return
            }
            UserManager.sharedManager.setUserId(u)
            UserManager.sharedManager.setPassword(p)
            completion(false)
        }
    }
    
    // Set the username and password in keychain.
    public func overrideUserPass(user: String?, pass: String?) {
        withUserPass(user, password: pass) { (newUser, newPass) in
            UserManager.sharedManager.setUserId(newUser)
            UserManager.sharedManager.setPassword(newPass)
        }
    }


    // Mark: - Stormpath-based account creation and authentication

    public func loginWithCompletion(completion: SvcStringCompletion) {
        withUserPass (getPassword()) { (user, pass) in
            Stormpath.login(username: user, password: pass, completionHandler: {
                (accessToken, err) -> Void in
                guard err == nil else {
                    log.error("Stormpath login failed: \(err!.localizedDescription)")
                    self.resetFull()
                    completion(true, err!.localizedDescription)
                    return
                }

                log.verbose("Access token: \(Stormpath.accessToken)")
                MCRouter.OAuthToken = Stormpath.accessToken
                Service.string(MCRouter.UserToken([:]), statusCode: 200..<300, tag: "LOGIN") {
                    _, response, result in
                        UserManager.sharedManager.pullProfile { _ in
                            completion(!result.isSuccess, result.value)
                        }
                    }
            })
        }
    }

    public func login(userPass: String, completion: SvcStringCompletion) {
        withUserId { user in
            if !self.validateAccount(userPass) {
                self.resetAccount()
                self.createAccount(user, userPass: userPass)
            }
            self.loginWithCompletion(completion)
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
            log.error("Failed to get access token within \(UserManager.maxTokenRetries) iterations")
            self.resetFull()
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
                log.warning("Refresh failed: \(error!.localizedDescription)")
                log.warning("Attempting login: \(self.hasAccount()) \(self.hasPassword())")

                if self.hasAccount() && self.hasPassword() {
                    self.loginWithCompletion { (error,_) in completion(error) }
                } else {
                    completion(true)
                }
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
                completion(true)
            }
        }
    }
    
    public func refreshAccessToken(completion: (Bool -> Void)) {
        refreshAccessToken(0, completion: completion)
    }
    

    // Mark: - Profile (i.e., Stormpath account data) management

    public func syncProfile(completion: SvcStringCompletion) {
        // Post to the service.
        Service.string(MCRouter.SetUserAccountData(profileCache), statusCode: 200..<300, tag: "UPDATEACC") {
            _, response, result in completion(!result.isSuccess, result.value)
        }
    }

    public func pushProfile(metadata: [String: AnyObject], completion: SvcStringCompletion) {
        // Refresh profile cache, and post to Stormpath.
        refreshProfileCache(metadata)
        syncProfile(completion)
    }
    
    public func pullProfile(completion: SvcObjectCompletion) {
        Service.json(MCRouter.GetUserAccountData(["exclude": ["consent"]]), statusCode: 200..<300, tag: "ACCDATA") {
            _, response, result in
                // Refresh cache.
                if let dict = result.value as? [String: AnyObject] { self.refreshProfileCache(dict) }
                
                // Evaluate the completion.
                completion(!result.isSuccess, result.value)
        }
    }
    
    public func pushProfileWithConsent(consentFilePath: String?, metadata: [String: AnyObject], completion: SvcStringCompletion) {
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

    // MARK: - Historical ranges for anchor query bulk ingestion

    private let hrk = { (key1:String, key2:String) in return key1 + ":" + key2 }

    // Returns a global historical range over all HKSampleTypes.
    public func getHistoricalRange() -> (NSTimeInterval, NSTimeInterval)? {
        let start = profileCache.filter { (key,_) -> Bool in key.hasPrefix(HMHRangeMinKey) }.minElement { (a, b) in
            return (a.1 as! NSTimeInterval) < (b.1 as! NSTimeInterval)
        }

        let end = profileCache.filter { (key,_) -> Bool in key.hasPrefix(HMHRangeEndKey) }.maxElement { (a, b) in
            return (a.1 as! NSTimeInterval) < (b.1 as! NSTimeInterval)
        }

        if let s = start?.1 as? NSTimeInterval, e = end?.1 as? NSTimeInterval { return (s, e) }
        return nil
    }

    public func getHistoricalRangeForType(key: String) -> (NSTimeInterval, NSTimeInterval)? {
        if let s = profileCache[hrk(HMHRangeStartKey, key)] as? NSTimeInterval,
               e = profileCache[hrk(HMHRangeEndKey, key)] as? NSTimeInterval
        {
            return (s, e)
        }
        return nil
    }

    public func initializeHistoricalRangeForType(key: String) -> (NSTimeInterval, NSTimeInterval) {
        let (start, end) = (decrAnchorDate(NSDate()).timeIntervalSinceReferenceDate, NSDate().timeIntervalSinceReferenceDate)
        profileCache[hrk(HMHRangeStartKey, key)] = start
        profileCache[hrk(HMHRangeEndKey, key)] = end
//        syncProfile { _ in () }
        return (start, end)
    }


    public func getHistoricalRangeStartForType(key: String) -> NSTimeInterval? {
        return profileCache[hrk(HMHRangeStartKey, key)] as? NSTimeInterval
    }

    public func decrHistoricalRangeStartForType(key: String) {
        let skey = hrk(HMHRangeStartKey, key)
        if let start = profileCache[skey] as? NSTimeInterval {
            profileCache[skey] = decrAnchorDate(NSDate(timeIntervalSinceReferenceDate: start)).timeIntervalSinceReferenceDate
//            syncProfile { _ in () }
        } else {
            log.error("Could not find historical sample range for \(key)")
        }
    }

    public func getHistoricalRangeMinForType(key: String) -> NSTimeInterval? {
        return profileCache[hrk(HMHRangeMinKey, key)] as? NSTimeInterval
    }

    public func setHistoricalRangeMinForType(key: String, min: NSDate) {
        profileCache[hrk(HMHRangeMinKey, key)] = min.timeIntervalSinceReferenceDate
//        syncProfile { _ in () }
    }

    public func decrAnchorDate(d: NSDate) -> NSDate {
        let region = Region()
        return (d - 1.months).startOf(.Day, inRegion: region).startOf(.Month, inRegion: region)
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

