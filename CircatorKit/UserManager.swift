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
import Async

private let UMPrimaryUserKey = "UMPrimaryUserKey"
private let UMUserHashKey    = "UMUserHashKey"

// Profile entry keys
private let UMPHotwordKey    = "UMPHotwordKey"
private let UMPFrequencyKey  = "UMPFrequencyKey"

private let HMHRangeStartKey = "HKHRStart"
private let HMHRangeEndKey   = "HKHREnd"
private let HMHRangeMinKey   = "HKHRMin"
private let HMQueryTSKey     = "HKQueryTS"

private let UserSaltKey      = "UserSaltKey"

private let profileExcludes  = ["consent", "id"]

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
                if let _ = Locksmith.loadDataForUserAccount(UMPrimaryUserKey)
                {
                    try Locksmith.updateData(["userId" : newUser ?? ""], forUserAccount: UMPrimaryUserKey)
                } else {
                    try Locksmith.saveData(["userId" : newUser ?? ""], forUserAccount: UMPrimaryUserKey)
                }
            } catch {
                log.error("userId.set: \(error)")
            }
        }
    }

    var tokenExpiry : NSTimeInterval = NSDate().timeIntervalSince1970   // Expiry in time interval since 1970.
    var profileCache : [String: AnyObject] = [:]                        // Stormpath account dictionary cache.

    // Batched profile synchronization.
    var profileAsync : Async?
    let profileDelay = 1.0

    var acqAsync : Async?
    let acqDelay = 1.0

    init() {
        Stormpath.setUpWithURL(MCRouter.baseURLString)
        self.profileCache = [:]
        self.profileAsync = nil
        self.acqAsync = nil
    }

    // MARK: - Account status, and authentication

    public func hasUserId() -> Bool {
        if let user = userId {
            return !user.isEmpty
        }
        return false
    }

    public func getUserId() -> String?     { return userId }
    public func setUserId(userId: String)  { self.userId = userId }
    public func resetUserId()              { self.userId = nil }

    // MARK: - Account metadata accessors for fields stored in keychain.

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


    // MARK: - Stormpath-based account creation and authentication

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
                completion(false, nil)
            })
        }
    }

    public func loginWithPush(profile: [String: AnyObject], completion: SvcStringCompletion) {
        loginWithCompletion { (error, why) in
            guard !error else {
                completion(true, why)
                return
            }
            self.pushProfile(profile, completion: completion)
        }
    }

    public func loginWithPull(completion: SvcStringCompletion) {
        loginWithCompletion { (error, why) in
            guard !error else {
                completion(true, why)
                return
            }
            self.pullProfile { error, _ in
                if !error { self.pullConsent(completion) }
                else { completion(error, nil) }
            }
        }
    }

    public func login(userPass: String, completion: SvcStringCompletion) {
        withUserId { user in
            if !self.validateAccount(userPass) {
                self.resetAccount()
                self.createAccount(user, userPass: userPass)
            }
            self.loginWithPull(completion)
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

    public func register(firstName: String, lastName: String, completion: ((NSDictionary?, Bool) -> Void))
    {
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


    // MARK: - Stormpath token management.

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
                    self.loginWithPull { (error,_) in completion(error) }
                } else {
                    completion(true)
                }
                return
            }

            if let token = Stormpath.accessToken {
                log.verbose("Refreshed token: \(token)")
                MCRouter.OAuthToken = Stormpath.accessToken
                self.ensureAccessToken(tried+1, completion: completion)
            } else {
                log.error("RefreshAccessToken failed, please login manually.")
                completion(true)
            }
        }
    }

    public func refreshAccessToken(completion: (Bool -> Void)) {
        refreshAccessToken(0, completion: completion)
    }


    // MARK: - Consent accessors
    public func syncConsent(completion: SvcStringCompletion) {
        let dict = ["consent": profileCache["consent"] ?? ("" as AnyObject)]
        Service.string(MCRouter.SetConsent(dict), statusCode: 200..<300, tag: "SCONSENT") {
            _, response, result in completion(!result.isSuccess, result.value)
        }
    }

    public func pushConsent(consentFilePath: String?, completion: SvcStringCompletion) {
        if let path = consentFilePath {
            if let data = NSData(contentsOfFile: path) {
                let metadata = ["consent": data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())]
                refreshProfileCache(metadata)
                syncConsent(completion)
            } else {
                log.error("Failed to read consent file at: \(path)")
                completion(true, nil)
            }
        } else {
            log.error("Invalid consent file path: \(consentFilePath)")
            completion(true, nil)
        }

    }

    public func pullConsent(completion: SvcStringCompletion) {
        Service.string(MCRouter.GetConsent, statusCode: 200..<300, tag: "GCONSENT") {
            _, response, result in
            if result.isSuccess { self.profileCache["consent"] = result.value }
            completion(!result.isSuccess, "Retrieved consent")
        }
    }

    // MARK: - Profile (i.e., Stormpath account data) and metadata management

    public func syncProfile(completion: SvcStringCompletion) {
        // Post to the service.
        let dict = Dictionary(pairs: profileCache.filter { kv in return !profileExcludes.contains(kv.0) })
        Service.string(MCRouter.SetUserAccountData(dict), statusCode: 200..<300, tag: "UPDATEACC") {
            _, response, result in completion(!result.isSuccess, result.value)
        }
    }

    public func pushProfile(metadata: [String: AnyObject], completion: SvcStringCompletion) {
        // Refresh profile cache, and post to the backend.
        refreshProfileCache(metadata)
        syncProfile(completion)
    }

    public func pullProfile(completion: SvcObjectCompletion) {
        Service.json(MCRouter.GetUserAccountData, statusCode: 200..<300, tag: "ACCDATA") {
            _, _, result in
            if result.isSuccess {
                // Refresh cache.
                if let dict = result.value as? [String: AnyObject], id = dict["id"],
                    var profile = dict["profile"] as? [String: AnyObject]
                {
                    profile[UMUserHashKey] = id
                    self.refreshProfileCache(profile)
                }
            }

            // Evaluate the completion.
            completion(!result.isSuccess, result.value)
        }
    }

    public func pushProfileWithConsent(consentFilePath: String?, metadata: [String: AnyObject], completion: SvcStringCompletion) {
        if let path = consentFilePath {
            if let data = NSData(contentsOfFile: path) {
                var dict = metadata
                dict["consent"] = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
                refreshProfileCache(metadata)
                syncProfile { error, _ in
                    if !error { self.syncConsent(completion) }
                    else { completion(error, "Failed to sync profile") }
                }
            } else {
                log.error("Failed to read consent file at: \(path)")
                completion(true, nil)
            }
        } else {
            log.error("Invalid consent file path: \(consentFilePath)")
            completion(true, nil)
        }
    }

    public func pullProfileWithConsent(completion: SvcStringCompletion) {
        pullProfile { (error, _) in
            if !error { self.pullConsent(completion) }
            else { completion(error, "Failed to pull profile") }
        }
    }

    public func getProfileCache() -> [String: AnyObject] { return profileCache }

    public func resetProfileCache() { profileCache = [:] }

    func refreshProfileCache(dict: [String: AnyObject]) {
        for (k,v) in dict {
            profileCache[k] = v
        }
    }

    public func syncAcquisitionTimes(completion: SvcStringCompletion) {
        guard let ts = profileCache[HMQueryTSKey] as? [String: AnyObject] else {
            completion(true, "")
            return
        }

        Service.string(MCRouter.UploadHKTSAcquired(ts), statusCode: 200..<300, tag: "UPDATETS") {
            _, response, result in completion(!result.isSuccess, result.value)
        }
    }


    // MARK: - Profile accessors

    public func getUserIdHash() -> String? {
        return (profileCache[UMUserHashKey] as? String)
    }

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

    // Returns a global historical range over all HKSampleTypes.
    public func getHistoricalRange() -> (NSTimeInterval, NSTimeInterval)? {
        if let mdict = profileCache[HMHRangeMinKey] as? [String: AnyObject],
               edict = profileCache[HMHRangeEndKey] as? [String: AnyObject]
        {
            let start = mdict.minElement { (a, b) in return (a.1 as! NSTimeInterval) < (b.1 as! NSTimeInterval) }
            let end   = edict.maxElement { (a, b) in return (a.1 as! NSTimeInterval) < (b.1 as! NSTimeInterval) }

            if let s = start?.1 as? NSTimeInterval, e = end?.1 as? NSTimeInterval { return (s, e) }
        }
        return nil
    }

    public func getHistoricalRangeForType(key: String) -> (NSTimeInterval, NSTimeInterval)? {
        if let s = profileCache[HMHRangeStartKey]?[key] as? NSTimeInterval,
               e = profileCache[HMHRangeEndKey]?[key] as? NSTimeInterval
        {
            return (s, e)
        }
        return nil
    }

    public func initializeHistoricalRangeForType(key: String, sync: Bool = false) -> (NSTimeInterval, NSTimeInterval) {
        let (start, end) = (decrAnchorDate(NSDate()).timeIntervalSinceReferenceDate, NSDate().timeIntervalSinceReferenceDate)
        if profileCache[HMHRangeStartKey] == nil { profileCache[HMHRangeStartKey] = [:] }
        if profileCache[HMHRangeEndKey] == nil { profileCache[HMHRangeEndKey] = [:] }

        if var sdict = profileCache[HMHRangeStartKey] as? [String: AnyObject],
               edict = profileCache[HMHRangeEndKey] as? [String: AnyObject]
        {
            sdict.updateValue(start, forKey: key)
            edict.updateValue(end, forKey: key)
            profileCache[HMHRangeStartKey] = sdict
            profileCache[HMHRangeEndKey] = edict
            deferProfile(sync)
        }

        return (start, end)
    }


    public func getHistoricalRangeStartForType(key: String) -> NSTimeInterval? {
        return profileCache[HMHRangeStartKey]?[key] as? NSTimeInterval
    }

    public func decrHistoricalRangeStartForType(key: String, sync: Bool = false) {
        if var sdict = profileCache[HMHRangeStartKey] as? [String: AnyObject],
           let start = sdict[key] as? NSTimeInterval
        {
            sdict.updateValue(decrAnchorDate(NSDate(timeIntervalSinceReferenceDate: start)).timeIntervalSinceReferenceDate, forKey: key)
            profileCache[HMHRangeStartKey] = sdict
            deferProfile(sync)
        } else {
            log.error("Could not find historical sample range for \(key)")
        }
    }

    public func getHistoricalRangeMinForType(key: String) -> NSTimeInterval? {
        return profileCache[HMHRangeMinKey]?[key] as? NSTimeInterval
    }

    public func setHistoricalRangeMinForType(key: String, min: NSDate, sync: Bool = false) {
        if profileCache[HMHRangeMinKey] == nil { profileCache[HMHRangeMinKey] = [:] }
        if var mdict = profileCache[HMHRangeMinKey] as? [String: AnyObject] {
            mdict.updateValue(min.timeIntervalSinceReferenceDate, forKey: key)
            profileCache[HMHRangeMinKey] = mdict
            deferProfile(sync)
        }
    }

    public func decrAnchorDate(d: NSDate) -> NSDate {
        let region = Region()
        return (d - 1.months).startOf(.Day, inRegion: region).startOf(.Month, inRegion: region)
    }

    private func deferProfile(sync: Bool) {
        if sync {
            profileAsync?.cancel()
            profileAsync = Async.background(after: profileDelay) { self.syncProfile { _ in () } }
        }
    }

    // Last acquisition times.
    public func getAcquisitionTimes() -> [String: AnyObject]? {
        return profileCache[HMQueryTSKey] as? [String: AnyObject]
    }

    public func setAcquisitionTimes(timestamps: [String: AnyObject], sync: Bool = false) {
        profileCache[HMQueryTSKey] = timestamps
        deferAcquisitions(sync)
    }

    private func deferAcquisitions(sync: Bool) {
        if sync {
            acqAsync?.cancel()
            acqAsync = Async.background(after: acqDelay) { self.syncAcquisitionTimes { _ in () } }
        }
    }

    // MARK : - Utility functions

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

/*
 * User profiles
 */

public struct UserProfile {
    public static let emailIdx = 0
    public static let passwIdx = 1
    public static let fnameIdx = 2
    public static let lnameIdx = 3
    public static let updateableIdx = 4

    public static let requiredRange = 0..<7
    public static let updateableReqRange = 4..<7
    public static let recommendedRange = 7..<12
    public static let optionalRange = 12..<29
    public static let updateableRange = 4..<29

    public static let profileFields = [
        "Email",
        "Password",
        "First name",
        "Last name",
        "Age",
        "Weight",
        "Height",
        "Usual sleep",
        "Estimated bmi",
        "Resting heartrate",
        "Systolic blood pressure",
        "Step count",
        "Active energy",
        "Awake time w/light",
        "Fasting",
        "Eating",
        "Calorie intake",
        "Protein intake",
        "Carbohydrate intake",
        "Sugar intake",
        "Fiber intake",
        "Fat intake",
        "Saturated fat",
        "Monounsaturated fat",
        "Polyunsaturated fat",
        "Cholesterol",
        "Salt",
        "Caffeine",
        "Water"]

    public static let profilePlaceholders = [
        "example@gmail.com",
        "Required",
        "Jane or John",
        "Doe",
        "24",
        "160 lbs",
        "180 cm",
        "7 hours",
        "25",
        "60 bpm",
        "120",
        "6000 steps",
        "2750 calories",
        "12 hours",
        "12 hours",
        "12 hours",
        "2757(m) or 1957(f)",
        "88.3(m) or 71.3(f)",
        "327(m) or 246.3(f)",
        "143.3(m) or 112(f)",
        "20.6(m) or 16.2(f)",
        "103.2(m) or 73.1(f)",
        "33.4(m) or 23.9(f)",
        "36.9(m) or 25.7(f)",
        "24.3(m) or 17.4(f)",
        "352(m) or 235.7(f)",
        "4560.7(m) or 3187.3(f)",
        "166.4(m) or 142.7(f)",
        "5(m) or 4.7(f)"
    ]

    public static let profileMapping = [
        "Email"                    : "email",
        "Password"                 : "password",
        "First name"               : "firstname",
        "Last name"                : "lastname",
        "Age"                      : "age",
        "Weight"                   : "weight",
        "Height"                   : "height",
        "Usual sleep"              : "sleep",
        "Estimated bmi"            : "bmi",
        "Resting heartrate"        : "heartrate",
        "Systolic blood pressure"  : "systolic",
        "Step count"               : "steps",
        "Active energy"            : "energy",
        "Awake time w/light"       : "awake",
        "Fasting"                  : "fasting",
        "Eating"                   : "eating",
        "Calorie intake"           : "calories",
        "Protein intake"           : "protein",
        "Carbohydrate intake"      : "carbs",
        "Sugar intake"             : "sugar",
        "Fiber intake"             : "fiber",
        "Fat intake"               : "fat",
        "Saturated fat"            : "satfat",
        "Monounsaturated fat"      : "monfat",
        "Polyunsaturated fat"      : "polyfat",
        "Cholesterol"              : "cholesterol",
        "Salt"                     : "salt",
        "Caffeine"                 : "caffeine",
        "Water"                    : "water"
    ]

    public static let updateableMapping = {
        return Dictionary(pairs: profileFields[4..<29].map { k in (k, profileMapping[k]!) })
    }()

}

