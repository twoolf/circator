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

private let UserManagerAccStateKey  = "UMAccStateKey"
private let UserManagerLoginKey     = "UMLoginKey"
private let UserManagerHotwordKey   = "UMHotwordKey"
private let UserManagerFrequencyKey = "UMFrequencyKey"

public enum AccountState : Int {
    case Unregistered
    case Registered
    case Validated
}

private let maxTokenRetries = 2

public class UserManager {
    public static let sharedManager = UserManager()

    // Defaults.
    public static let defaultRefreshFrequency = 30

    var userId: String?
    var hotWords: String?
    var refreshFrequency: Int? // Aggregate refresh frequency in seconds.

    var accountDataCache : [String: AnyObject] = [:]
    var accountStatus : AccountState = .Unregistered

    public var validated : Bool {
        get { return accountStatus == AccountState.Validated }
    }

    public var registered : Bool {
        get { return (accountStatus == AccountState.Registered) || validated }
    }

    // Expiry in time interval since 1970.
    var tokenExpiry : NSTimeInterval = NSDate().timeIntervalSince1970

    init() {
        self.setupStormpath()
        self.accountStatus = AccountState(rawValue: NSUserDefaults.standardUserDefaults().integerForKey(UserManagerAccStateKey))!
        self.userId        = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerLoginKey)
        self.hotWords      = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerHotwordKey)
        
        let freq = NSUserDefaults.standardUserDefaults().integerForKey(UserManagerFrequencyKey)
        self.refreshFrequency = freq == 0 ? UserManager.defaultRefreshFrequency : freq

        if ( self.hotWords == nil ) { self.setHotWords("food log") }
        self.accountDataCache = [:]
    }

    // Mark: - Stormpath initialization

    public func setupStormpath() {
        Stormpath.setUpWithURL(MCRouter.baseURLString)
        if Stormpath.accessToken == nil {
            print("Logging into Stormpath...")
            self.login()
        }
        
        if let token = Stormpath.accessToken {
            MCRouter.OAuthToken = Stormpath.accessToken
            print("User token: \(token)")
        } else {
            print("Login failed, please do so manually.")
        }
    }

    // Mark: - Account status, and authentication

    public func setRegistered() {
        NSUserDefaults.standardUserDefaults().setInteger(AccountState.Registered.rawValue, forKey: UserManagerAccStateKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    public func setValidated() {
        NSUserDefaults.standardUserDefaults().setInteger(AccountState.Validated.rawValue, forKey: UserManagerAccStateKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    public func getUserId() -> String? {
        return self.userId
    }

    public func getUserIdHash() -> String? {
        return self.userId?.md5()
    }

    public func setUserId(userId: String) {
        self.userId = userId
        NSUserDefaults.standardUserDefaults().setValue(self.userId, forKey: UserManagerLoginKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    public func resetUserId() {
        self.userId = nil
        NSUserDefaults.standardUserDefaults().removeObjectForKey(UserManagerLoginKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    public func getAccountData() -> [String:AnyObject]? {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            let lockbox = account.readFromSecureStore()
            return lockbox?.data
        }
        return nil
    }

    public func getPassword() -> String? {
        if let data = getAccountData() {
            if let pass = data["password"] {
                return pass as? String
            }
        }
        return nil
    }

    public func getAccessToken() -> String? {
        return Stormpath.accessToken
    }

    public func setAccountData(items: [String:AnyObject]) {
        if let user = userId {
            if var datadict = Locksmith.loadDataForUserAccount(user) {
                for (k,v) in items { datadict[k] = v }
                do {
                    try Locksmith.updateData(datadict, forUserAccount: user)
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
    
    public func setPassword(userPass: String) {
        createAccount(userPass)
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
            debugPrint(error)
        }
    }

    func createAccount(userPass: String) {
        if let user = userId {
            let account = UserAccount(username: user, password: userPass)
            do {
                try account.createInSecureStore()
            } catch {
                debugPrint(error)
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
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            do {
                try account.deleteFromSecureStore()
            } catch {
                debugPrint(error)
            }
        }
    }

    public func loginWithCompletion(completion: (String? -> Void)?) {
        if let user = userId, pass = getPassword() {
            Stormpath.login(username: user, password: pass, completionHandler: {
                (accessToken, err) -> Void in
                guard err == nil else {
                    debugPrint(err)
                    return
                }
                MCRouter.OAuthToken = Stormpath.accessToken
                print("Access token: \(Stormpath.accessToken)")
                Alamofire.request(MCRouter.UserToken([:]))
                    .validate(statusCode: 200..<300)
                    .responseString {_, response, result in
                        print("LOGIN: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                        UserManager.sharedManager.accountData { _ in
                            if let comp = completion {
                                comp(result.value)
                            } else {
                                print(result.value)
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
        if let user = userId {
            if !validateAccount(userPass) { createAccount(user, userPass: userPass) }
            login()
        }
    }

    public func logoutWithCompletion(completion: (Void -> Void)?) {
        Stormpath.logout(completionHandler: { (error) -> Void in
            if error == nil { return }
            else { print("Error logging out of Stormpath") }
        })
        MCRouter.OAuthToken = nil
        resetAccount()
        resetUserId()
        resetAccountDataCache()
        if let comp = completion { comp() }
    }

    public func logout() {
        logoutWithCompletion(nil)
    }
    
    public func register(firstName: String, lastName: String, completion: (NSDictionary? -> Void)) {
        if let user = userId, pass = getPassword()
        {
            let stormpathAccountDict : [String:String] = [
                "email": user,
                "password": pass,
                "givenName": firstName,
                "surname": lastName
            ]

            Stormpath.register(userDictionary: stormpathAccountDict, completionHandler: {
                (registerDict, error) -> Void in
                if error == nil {
                    completion(registerDict)
                } else {
                    debugPrint(error)
                }
            })
        }
    }

    public func updateAccountConsent(consentFilePath: String?, completion: (String? -> Void)) {
        if let path = consentFilePath {
            if let data = NSData(contentsOfFile: path) {
                let dict = ["consent": data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())]
                updateAccountData(dict, completion: completion)
            } else {
                debugPrint("Failed to read consent file at: \(path)")
            }
        } else {
            debugPrint("Invalid consent file path: \(consentFilePath)")
        }
    }

    public func updateAccountData(metadata: [String: AnyObject], completion: (String? -> Void)) {
        // Refresh cache.
        refreshAccountCache(metadata)

        // Post to the service.
        Alamofire.request(MCRouter.SetUserAccountData(metadata))
            .validate(statusCode: 200..<300)
            .responseString {_, response, result in
                print("UPDATEACC: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                completion(result.value)
            }
    }
    
    public func accountData(completion: (AnyObject? -> Void)) {
        Alamofire.request(MCRouter.GetUserAccountData(["exclude": ["consent"]]))
            .validate(statusCode: 200..<300)
            .responseJSON {_, response, result in
                print("ACCDATA: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                // Refresh cache.
                if let dict = result.value as? [String: AnyObject] { self.refreshAccountCache(dict) }
                
                // Evaluate the completion.
                completion(result.value)
        }
    }
    
    public func getAccountDataCache() -> [String: AnyObject] { return accountDataCache }
    
    public func resetAccountDataCache() { accountDataCache = [:] }
    
    func refreshAccountCache(dict: [String: AnyObject]) {
        for (k,v) in dict {
            accountDataCache[k] = v
        }
    }
    
    // Mark: - token refreshing.
    public func ensureAccessToken(tried: Int, completion: (Bool -> Void)) {
        guard tried < maxTokenRetries else {
            debugPrint("Failed to get access token within \(maxTokenRetries) iterations")
            completion(true)
            return
        }
        
        Alamofire.request(MCRouter.TokenExpiry([:]))
            .validate(statusCode: 200..<300)
            .responseJSON {_, response, result in
                print("ACCTOK: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
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
        ensureAccessToken(0, completion: completion)
    }
    
    public func refreshAccessToken(tried: Int, completion: (Bool -> Void)) {
        Stormpath.refreshAccesToken { (_, error) in
            guard error == nil else {
                print("Refresh failed: \(error)")
                return
            }
            if let token = Stormpath.accessToken {
                MCRouter.OAuthToken = Stormpath.accessToken
                print("Refreshed token: \(token)")
                Alamofire.request(MCRouter.UserToken([:]))
                    .validate(statusCode: 200..<300)
                    .responseString {_, response, result in
                        self.ensureAccessToken(tried+1, completion: completion)
                }
            } else {
                print("Login failed, please do so manually.")
            }
        }
    }
    
    public func refreshAccessToken(completion: (Bool -> Void)) {
        refreshAccessToken(0, completion: completion)
    }

    // Mark : - Configuration

    public func getHotWords() -> String? {
        return self.hotWords
    }

    public func setHotWords(hotWords: String) {
        self.hotWords = hotWords
        NSUserDefaults.standardUserDefaults().setValue(self.hotWords, forKey: UserManagerHotwordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    public func getRefreshFrequency() -> Int? {
        return self.refreshFrequency
    }

    public func setRefreshFrequency(frequency: Int) {
        self.refreshFrequency = frequency
        NSUserDefaults.standardUserDefaults().setValue(self.refreshFrequency, forKey: UserManagerFrequencyKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // Mark : - Utility functions

    // Override the username and password in the local store if we have nothing saved.
    public func ensureUserPass(user: String?, pass: String?) {
        if getUserId() == nil {
            if let currentUser = user {
                UserManager.sharedManager.setUserId(currentUser)
            }
        }
        
        if UserManager.sharedManager.getPassword() == nil {
            if let currentPass = pass {
                UserManager.sharedManager.setPassword(currentPass)
            }
        }
    }
}