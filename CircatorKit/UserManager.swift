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

private let UserManagerLoginKey = "UMLoginKey"
private let UserManagerHotwordKey = "UMHotwordKey"

public class UserManager {
    public static let sharedManager = UserManager()
    
    var userId: String?
    var hotWords: String?
    
    init() {
        Stormpath.setUpWithURL(MCRouter.baseURLString)
        self.userId = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerLoginKey)
        self.hotWords = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerHotwordKey)
        if ( self.hotWords == nil ) {
            self.setHotWords("food log")
        }
    }

    // Mark: - Authentication
    
    public func getUserId() -> String? {
        return self.userId
    }
    
    public func setUserId(userId: String) {
        self.userId = userId
        NSUserDefaults.standardUserDefaults().setValue(self.userId, forKey: UserManagerLoginKey)
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
            debugPrint("error: \(error)")
        }
    }
    
    func validateAccount(userPass: String) -> Bool {
        if let pass = getPassword() {
            return pass == userPass
        }
        return false
    }
    
    public func login() {
        if let user = userId, pass = getPassword() {
            Stormpath.login(username: user, password: pass, completionHandler: {
                (accessToken, err) -> Void in
                guard err == nil else {
                    debugPrint(err)
                    return
                }
                print("Access token: \(Stormpath.accessToken)")
            })
        }
    }

    public func login(userPass: String) {
        if let user = userId {
            if !validateAccount(userPass) { createAccount(user, userPass: userPass) }
            login()
        }
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

}