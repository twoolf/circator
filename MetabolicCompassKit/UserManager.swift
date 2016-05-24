//
//  UserManager.swift
//  MetabolicCompass
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
import AsyncKit
import JWTDecode

private let UMPrimaryUserKey = "UMPrimaryUserKey"
private let UMUserHashKey    = "UMUserHashKey"

// Profile entry keys
private let UMPHotwordKey    = "UMPHotwordKey"
private let UMPFrequencyKey  = "UMPFrequencyKey"

private let HMHRangeStartKey = "HKHRStart"
private let HMHRangeEndKey   = "HKHREnd"
private let HMHRangeMinKey   = "HKHRMin"

private let profileExcludes  = ["userid"]

public let UMConsentInfoString         = "Retrieved consent"
public let UMPhotoInfoString           = "Retrieved photo"
public let UMPullComponentsInfoString  = "Retrieved account components"
public let UMPullFullAccountInfoString = "Retrieved full account"

// Error generators.
// These are public to allow other components to recreate and check error messages.
public let UMPushInvalidBinaryFileError : (AccountComponent, String?) -> String = { (component, path) in
    return "Invalid \(component) file at: \(path)"
}

public let UMPushReadBinaryFileError : (AccountComponent, String) -> String = { (component, path) in
    return "Failed to read \(component) file at: \(path)"
}

public let UMPullComponentError : AccountComponent -> String = { component in
    return "Failed to pull account component \(component)"
}

/**
 This manages the users for Metabolic Compass. We need to enable users to maintain access to their data and to delete themselves from the study if they so desire. In addition we maintain, in this class, the ability to do this securely, using OAuth and our third party authenticator (Stormpath)

 - note: We use Stormpath and tokens for authentication
 */
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
                if let _newUser = newUser {
                    if let _ = Locksmith.loadDataForUserAccount(UMPrimaryUserKey)
                    {
                        try Locksmith.updateData(["userId" : _newUser], forUserAccount: UMPrimaryUserKey)
                    } else {
                        try Locksmith.saveData(["userId" : _newUser], forUserAccount: UMPrimaryUserKey)
                    }
                }
                else {
                    if let _ = Locksmith.loadDataForUserAccount(UMPrimaryUserKey) {
                        try Locksmith.deleteDataForUserAccount(UMPrimaryUserKey)
                    }
                }
            } catch {
                log.error("userId.set: \(error)")
            }
        }
    }

    var tokenExpiry : NSTimeInterval = NSDate().timeIntervalSince1970   // Expiry in time interval since 1970.

    // Account component dictionary cache.
    private(set) public var componentCache : [AccountComponent: [String: AnyObject]] = [
        .Consent      : [:],
        .Photo        : [:],
        .Profile      : [:],
        .Settings     : [:],
        .ArchiveSpan  : [:],
        .LastAcquired : [:]
    ]

    // Track when the remote account component was last retrieved
    var lastComponentLoadDate : [AccountComponent: NSDate?] = [
        .Consent      : nil,
        .Photo        : nil,
        .Profile      : nil,
        .Settings     : nil,
        .ArchiveSpan  : nil,
        .LastAcquired : nil
    ]

    // Batched synchronization for account components.
    // These are async optional and double pairs, with the double representing the batch delay.
    var requestAsyncs : [AccountComponent: (Async?, Double)] = [
        .Consent      : (nil, 1.0),
        .Photo        : (nil, 1.0),
        .Profile      : (nil, 1.0),
        .Settings     : (nil, 1.0),
        .ArchiveSpan  : (nil, 1.0),
        .LastAcquired : (nil, 1.0)
    ]

    init() {
        Stormpath.setUpWithURL(MCRouter.baseURLString)
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
                MCRouter.updateAuthToken(Stormpath.accessToken)
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
            self.pullFullAccount(completion)
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
        MCRouter.updateAuthToken(nil)
        resetUser()
        if let comp = completion { comp() }
    }

    public func logout() {
        logoutWithCompletion(nil)
    }

    public func register(firstName: String, lastName: String, completion: ((NSDictionary?, Bool, String?) -> Void))
    {
        withUserPass(getPassword()) { (user,pass) in
            let stormpathAccountDict : [String:String] = [
                "email": user,
                "password": pass,
                "givenName": firstName,
                "surname": lastName
            ]

            print("account dict: \(stormpathAccountDict)")

            Stormpath.register(userDictionary: stormpathAccountDict, completionHandler: {
                (registerDict, error) -> Void in
                if error != nil { log.error("Register failed: \(error)") }
                completion(registerDict, error != nil, error?.localizedDescription)
            })
        }
    }

    public func withdraw(completion: (Bool -> Void)) {
        Service.string(MCRouter.DeleteAccount, statusCode: 200..<300, tag: "WITHDRAW") {
            _, response, result in
            if result.isSuccess { self.resetFull() }
            completion(result.isSuccess)
        }
    }


    public func resetPassword(email: String, completion: ((Bool, String?) -> Void)) {
        Stormpath.resetPassword(email: email, completionHandler: { (error) -> Void in
            if error == nil {
                completion(true, nil)
            }
            else {
                log.error("Reset Password failed: \(error)")
                completion(false, error!.localizedDescription)
            }
        })
    }

    // MARK: - Stormpath token management.

    public func getAccessToken() -> String? {
        return Stormpath.accessToken
    }

    public func ensureAccessToken(tried: Int, completion: (Bool -> Void)) {
        guard tried < UserManager.maxTokenRetries else {
            log.error("Failed to get access token within \(UserManager.maxTokenRetries) iterations")
            // Get the expiry time locally from the token if available.
            // TODO: this is a temporary workaround for issue #30, to support auto-login:
            // https://github.com/yanif/circator/issues/30
            var doReset = true
            if let token = Stormpath.accessToken {
                do {
                    let jwt = try decode(token)
                    if let expiry = jwt.expiresAt?.timeIntervalSince1970 {
                        doReset = false
                        self.tokenExpiry = expiry
                        log.info("Setting expiry as \(expiry)")
                    }
                } catch {}
            }
            if doReset { self.resetFull() }
            completion(doReset)
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
        if (MCRouter.tokenExpireTime - NSDate().timeIntervalSince1970 > 0) {
            completion(false)
        }
        else {
            self.refreshAccessToken(completion)
        }

        // temporary disabled, waiting for server api clarification
        // ensureAccessToken(0, completion: completion)
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
                MCRouter.updateAuthToken(Stormpath.accessToken)

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

    // MARK: - Account component extractors
    private func uploadProfileExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.filter { kv in return !profileExcludes.contains(kv.0) })
    }

    private func downloadProfileExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        if let id = data["userid"] {
            var profile = data
            profile.removeValueForKey("userid")
            profile[UMUserHashKey] = id
            return profile
        }
        return data
    }

    private func uploadSettingsExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (settingsServerId(kv.0), kv.1) })
    }

    private func downloadSettingsExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (settingsClientId(kv.0), kv.1)} )
    }

    private func uploadArchiveSpanExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (archiveSpanServerId(kv.0), kv.1) })
    }

    private func downloadArchiveSpanExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (archiveSpanClientId(kv.0), kv.1)} )
    }

    public func uploadLastAcquiredExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (lastAcquiredServerId(kv.0)!, kv.1) })
    }


    // MARK: - Account component accessors

    // Returns a component as a dictionary, where the dictionary key corresponds to the component name.
    // This is used for uploading data to the backend.
    // Consent and photo data are stored in wrapped form, and thus need no additional wrapping.
    private func wrapCache(component: AccountComponent) -> [String:AnyObject]?
    {
        let componentName = getComponentName(component)
        if let componentData = componentCache[component] {
            switch component {
            case .Consent:
                return componentData
            case .Photo:
                return componentData
            case .Profile:
                return [componentName: self.uploadProfileExtractor(componentData)]
            case .Settings:
                return [componentName: self.uploadSettingsExtractor(componentData)]
            case .ArchiveSpan:
                return [componentName: self.uploadArchiveSpanExtractor(componentData)]
            case .LastAcquired:
                return [componentName: self.uploadLastAcquiredExtractor(componentData)]
            }
        }
        return nil
    }

    // Returns an unwrapped component as dictionary, stripping any component name from the argument.
    // This is used when downloading data from the backend service.
    // Consent and photo data are returned in wrapped form.
    private func unwrapResponse(component: AccountComponent,
                                response: [String:AnyObject],
                                extractor: ([String:AnyObject] -> [String:AnyObject])?)
                    -> [String:AnyObject]?
    {
        let componentName = getComponentName(component)
        if let componentData = response[componentName] {
            switch component {
            case .Consent:
                return [componentName: componentData]
            case .Photo:
                return [componentName: componentData]
            case .Profile:
                return self.downloadProfileExtractor(componentData)
            case .Settings:
                return self.downloadSettingsExtractor(componentData)
            case .ArchiveSpan:
                return self.downloadArchiveSpanExtractor(componentData)
            case .LastAcquired:
                return componentData
            }
        }
        return nil
    }

    // Retrieves the currently cached account component, wraps it, and pushes it to the backend.
    private func syncAccountComponent(component: AccountComponent, completion: SvcStringCompletion)
    {
        let componentData = wrapCache(component, extractor: extractor)
        Service.string(MCRouter.SetUserAccountData(payload), statusCode: 200..<300, tag: "SYNCACC") {
            _, response, result in completion(!result.isSuccess, result.value)
        }
    }

    private func deferredSyncOnAccountComponent(component: AccountComponent, sync: Bool)
    {
        if sync {
            requestAsyncs[component]!.0?.cancel()
            let componentDelay = requestAsyncs[component]!.1
            let newAsync = Async.background(after: componentDelay) {
                self.syncAccountComponent(component, extractor: extractor) { _ in () }
            }
            requestAsyncs[component] = (newAsync, componentDelay)
        }
    }

    // Sets the component data in the cache as requested, and then synchronizes with the backend.
    private func pushAccountComponent(component: AccountComponent,
                                      refresh: Bool,
                                      componentData: [String:AnyObject],
                                      completion: SvcStringCompletion)
    {
        // Refresh cache, and post to the backend.
        if refresh { refreshComponentCache(component, componentData: componentData) }
        syncAccountComponent(component, completion: completion)
    }

    // Sets the component data in the cache as requested, and batches synchronization requests.
    private func deferredPushOnAccountComponent(component: AccountComponent,
                                                refresh: Bool, sync: Bool,
                                                componentData: [String:AnyObject])
    {
        if refresh { refreshComponentCache(component, componentData: componentData) }
        deferredSyncOnAccountComponent(component, sync: sync)
    }

    // A helper function for a binary account component that retrieves the component data from a file.
    // This is common to both the consent pdf and the profile pic.
    private func pushBinaryFileAccountComponent(filePath: String?, component: AccountComponent,
                                                refresh: Bool, completion: SvcStringCompletion)
    {
        if let path = filePath {
            if let data = NSData(contentsOfFile: path) {
                let componentName = getComponentName(component)
                let cache = [componentName: data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())]
                pushAccountComponent(component, refresh: true, componentData: cache, completion: completion)
            } else {
                let msg = UMPushReadBinaryFileError(component, path)
                log.error(msg)
                completion(true, msg)
            }
        } else {
            let msg = UMPushInvalidBinaryFileError(component, filePath)
            log.error(msg)
            completion(true, msg)
        }
    }

    // Retrieves an account component from the backend service.
    private func pullAccountComponent(component: AccountComponent, completion: SvcObjectCompletion)
    {
        print("!!! pullAccountComponent \(component)")
        Service.json(MCRouter.GetUserAccountData([component]), statusCode: 200..<300, tag: "GACC\(component)") {
            _, _, result in
            var pullSuccess = result.isSuccess
            if pullSuccess {
                // All account component routes return a JSON object.
                // Use this to refresh the component cache.
                if let dict = result.value as? [String: AnyObject],
                       refreshVal = unwrapResponse(component, response: dict)
                {
                    self.refreshComponentCache(component, componentData: refreshVal)
                    self.lastComponentLoadDate[component] = NSDate()
                } else {
                    // Indicate a failure if we cannot unwrap the component from the response.
                    pullSuccess = false
                }
            }
            completion(!pullSuccess, result.value)
        }
    }

    // Retrieves an account component if it is stale.
    private func pullAccountComponentIfNeeded(component: AccountComponent, completion: SvcObjectCompletion)
    {
        if isAccountComponentOutdated(component) {
            pullAccountComponent(component, completion: completion)
        } else {
            print("pull component \(component) skipped")
            completion(false, nil)
        }
    }

    private func isAccountComponentOutdated(component: AccountComponent) -> Bool {
        if let lastDateOpt = lastComponentLoadDate[component], lastDate = lastDateOpt {
            return lastDate.timeIntervalSinceNow < -300.0 // sec
        } else {
            return true
        }
    }

    private func refreshComponentCache(component: AccountComponent, componentData: [String:AnyObject]) {
        if var cache = componentCache[component] {
            for (k,v) in componentData {
                cache.updateValue(v, forKey: k)
            }
            componentCache[component] = cache
        }
    }

    private func getCachedComponent(component: AccountComponent) -> [String: AnyObject] {
        return componentCache[component]!
    }

    private func resetCachedComponent(component: AccountComponent) {
        componentCache.updateValue([:], forKey: component)
    }

    // Batch reset of all components.
    private func resetAccountComponents(components: [AccountComponent]) {
        for component in components { resetCachedComponent(component) }
    }

    // Retrieves multiple account components in a single request.
    // TODO: track which components succeeded or failed.
    private func pullMultipleAccountComponents(components: [AccountComponent], completion: SvcStringCompletion) {
        Service.json(MCRouter.GetUserAccountData(components), statusCode: 200..<300, tag: "GACC\(component)") {
            _, _, result in
            var pullSuccess = result.isSuccess
            if pullSuccess {
                // All account component routes return a JSON object.
                // Use this to refresh the component cache.
                if let dict = result.value as? [String: AnyObject] {
                    for component in components {
                        if let refreshVal = unwrapResponse(component, dict) {
                            self.refreshComponentCache(component, componentData: refreshVal)
                            self.lastComponentLoadDate[component] = NSDate()
                        } else {
                            // Indicate a failure if we cannot unwrap any component from the response.
                            pullSuccess = false
                            break
                        }
                    }
                }
            }
            completion(!pullSuccess, result.value)
        }
    }

    public func pullFullAccount(completion: SvcStringCompletion) {
        pullMultipleAccountComponents([ .Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired]) {
            (error, msg) in
            completion(error, (!error && msg == UMPullComponentsInfoString) ? UMPullComponentsInfoString : msg)
        }
    }


    // MARK: - Consent accessors
    public func getConsent() -> [String: AnyObject] { return getCachedComponent(.Consent) }

    public func syncConsent(completion: SvcStringCompletion) {
        syncAccountComponent(.Consent, completion: completion)
    }

    public func pushConsent(filePath: String?, completion: SvcStringCompletion) {
        pushBinaryFileAccountComponent(filePath, component: .Consent, refresh: true, completion: completion)
    }

    public func pullConsent(completion: SvcObjectCompletion) {
        pullAccountComponent(.Consent, completion: completion)
    }

    // MARK: - Photo accessors
    public func getPhoto() -> [String: AnyObject] { return getCachedComponent(.Photo) }

    public func syncPhoto(completion: SvcStringCompletion) {
        syncAccountComponent(.Photo, completion: completion)
    }

    public func pushPhoto(filePath: String?, completion: SvcStringCompletion) {
        pushBinaryFileAccountComponent(filePath, component: .Photo, refresh: true, completion: completion)
    }

    public func pullPhoto(completion: SvcObjectCompletion) {
        pullAccountComponent(.Photo, completion: completion)
    }


    // MARK: - Profile accessors

    public func getProfileCache() -> [String: AnyObject] { return getCachedComponent(.Profile) }

    public func syncProfile(completion: SvcStringCompletion) {
        syncAccountComponent(.Profile, completion: completion)
    }

    public func pushProfile(componentData: [String: AnyObject], completion: SvcStringCompletion) {
        pushAccountComponent(.Profile, refresh: true, componentData: componentData, completion: completion)
    }

    public func pullProfile(completion: SvcObjectCompletion) {
        pullAccountComponent(.Profile, completion: completion)
    }

    public func isProfileOutdated() -> Bool {
        return isAccountComponentOutdated(.Profile)
    }

    public func pullProfileIfNeeded(completion: SvcObjectCompletion) {
        pullAccountComponentIfNeeded(.Profile, completion: completion)
    }

    public func pullProfileWithConsent(completion: SvcStringCompletion) {
        pullMultipleAccountComponents([.Profile, .Consent], completion: completion)
    }

    public func getUserIdHash() -> String? {
        return (getProfileCache()[UMUserHashKey] as? String)
    }


    // MARK: - Settings accessors

    public func getSettingsCache() -> [String: AnyObject] { return getCachedComponent(.Settings) }

    public func resetSettingsCache() { resetCachedComponent(.Settings) }

    public func syncSettings(completion: SvcStringCompletion) {
        syncAccountComponent(.Settings, completion: completion)
    }

    public func pushSettings(componentData: [String: AnyObject], completion: SvcStringCompletion) {
        pushAccountComponent(.Settings, refresh: true, componentData: componentData, completion: completion)
    }

    public func pullSettings(completion: SvcObjectCompletion) {
        pullAccountComponent(.Settings, completion: completion)
    }

    public func getHotWords() -> String {
        return (getSettingsCache()[UMPHotwordKey] as? String) ?? UserManager.defaultHotwords
    }

    public func setHotWords(hotWords: String) {
        pushSettings([UMPHotwordKey: hotWords]) { _ in () }
    }

    public func getRefreshFrequency() -> Int {
        return (getSettingsCache()[UMPFrequencyKey] as? Int) ?? UserManager.defaultRefreshFrequency
    }

    public func setRefreshFrequency(frequency: Int) {
        pushSettings([UMPFrequencyKey: frequency]) { _ in () }
    }


    // MARK: - Historical ranges for anchor query bulk ingestion

    public func getArchiveSpanCache() -> [String: AnyObject] { return getCachedComponent(.ArchiveSpan) }

    public func resetArchiveSpanCache() { resetCachedComponent(.ArchiveSpan) }

    // Returns a global historical range over all HKSampleTypes.
    public func getHistoricalRange() -> (NSTimeInterval, NSTimeInterval)? {
        let cache = getArchiveSpanCache()
        if let mdict = cache[HMHRangeMinKey] as? [String: AnyObject],
               edict = cache[HMHRangeEndKey] as? [String: AnyObject]
        {
            let start = mdict.minElement { (a, b) in return (a.1 as! NSTimeInterval) < (b.1 as! NSTimeInterval) }
            let end   = edict.maxElement { (a, b) in return (a.1 as! NSTimeInterval) < (b.1 as! NSTimeInterval) }

            if let s = start?.1 as? NSTimeInterval, e = end?.1 as? NSTimeInterval { return (s, e) }
        }
        return nil
    }

    public func getHistoricalRangeForType(key: String) -> (NSTimeInterval, NSTimeInterval)? {
        let cache = getArchiveSpanCache()
        if let k = hkToMCDB(key),
               s = cache[HMHRangeStartKey]?[k] as? NSTimeInterval,
               e = cache[HMHRangeEndKey]?[k] as? NSTimeInterval
        {
            return (s, e)
        }
        return nil
    }

    public func initializeHistoricalRangeForType(key: String, sync: Bool = false) -> (NSTimeInterval, NSTimeInterval) {
        var cache = getArchiveSpanCache()
        let (start, end) = (decrAnchorDate(NSDate()).timeIntervalSinceReferenceDate, NSDate().timeIntervalSinceReferenceDate)
        if cache[HMHRangeStartKey] == nil { cache[HMHRangeStartKey] = [:] }
        if cache[HMHRangeEndKey]   == nil { cache[HMHRangeEndKey]   = [:] }

        if let k = hkToMCDB(key),
           var sdict = cache[HMHRangeStartKey] as? [String: AnyObject],
           var edict = cache[HMHRangeEndKey] as? [String: AnyObject]
        {
            sdict.updateValue(start, forKey: k)
            edict.updateValue(end, forKey: k)
            let newSpan = [HMHRangeStartKey: sdict, HMHRangeEndKey: edict]
            deferredPushOnAccountComponent(.ArchiveSpan, refresh: true, sync: sync, componentData: newSpan)
        }

        return (start, end)
    }

    public func getHistoricalRangeStartForType(key: String) -> NSTimeInterval? {
        let cache = getArchiveSpanCache()
        if let k = hkToMCDB(key) { return cache[HMHRangeStartKey]?[k] as? NSTimeInterval }
        return nil
    }

    public func decrHistoricalRangeStartForType(key: String, sync: Bool = false) {
        let cache = getArchiveSpanCache()
        if let k = hkToMCDB(key),
           var sdict = cache[HMHRangeStartKey] as? [String: AnyObject],
           let start = sdict[k] as? NSTimeInterval
        {
            let newDate = decrAnchorDate(NSDate(timeIntervalSinceReferenceDate: start)).timeIntervalSinceReferenceDate
            sdict.updateValue(newDate, forKey: k)
            let newSpan = [HMHRangeStartKey: sdict]
            deferredPushOnAccountComponent(.ArchiveSpan, refresh: true, sync: sync, componentData: newSpan)
        } else {
            log.error("Could not find historical sample range for \(key)")
        }
    }

    public func getHistoricalRangeMinForType(key: String) -> NSTimeInterval? {
        let cache = getArchiveSpanCache()
        if let k = hkToMCDB(key) { return cache[HMHRangeMinKey]?[k] as? NSTimeInterval }
        return nil
    }

    public func setHistoricalRangeMinForType(key: String, min: NSDate, sync: Bool = false) {
        var cache = getArchiveSpanCache()
        if cache[HMHRangeMinKey] == nil { cache[HMHRangeMinKey] = [:] }
        if let k = hkToMCDB(key),
           var mdict = cache[HMHRangeMinKey] as? [String: AnyObject]
        {
            mdict.updateValue(min.timeIntervalSinceReferenceDate, forKey: k)
            let newSpan = [HMHRangeMinKey: mdict]
            deferredPushOnAccountComponent(.ArchiveSpan, refresh: true, sync: sync, componentData: newSpan)
        }
    }

    public func decrAnchorDate(d: NSDate) -> NSDate {
        let region = Region()
        return (d - 1.months).startOf(.Day, inRegion: region).startOf(.Month, inRegion: region)
    }


    // MARK : - Last acquisition times.

    public func getAcquisitionTimes() -> [String: AnyObject] { return getCachedComponent(.LastAcquired) }

    public func resetAcquisitionTimes() { resetCachedComponent(.LastAcquired) }

    public func setAcquisitionTimes(timestamps: [String: AnyObject], sync: Bool = false) {
        deferredPushOnAccountComponent(.LastAcquired, refresh: true, sync: sync, componentData: timestamps)
    }

    public func syncAcquisitionTimes(completion: SvcStringCompletion) {
        syncAccountComponent(.LastAcquired, completion: completion)
    }


    // MARK : - Naming functions
    func hkToMCDB(key: String) -> String? { return HMConstants.sharedInstance.hkToMCDB[key] }
    func mcdbToHK(key: String) -> String? { return HMConstants.sharedInstance.mcdbToHK[key] }

    private static let settingsClient = [
        "hotword"           : UMPHotwordKey,
        "refresh_frequency" : UMPFrequencyKey
    ]

    private static let settingsServer = [
        UMPHotwordKey   : "hotword",
        UMPFrequencyKey : "refresh_frequency"
    ]

    private static let archiveSpanClient = [
        "start_ts" : HMHRangeStartKey,
        "end_ts"   : HMHRangeEndKey,
        "min_ts"   : HMHRangeMinKey
    ]

    private static let archiveSpanServer = [
        HMHRangeStartKey : "start_ts",
        HMHRangeEndKey   : "end_ts",
        HMHRangeMinKey   : "min_ts"
    ]

    func settingsClientId(key: String) -> String { return UserManager.settingsClient[key]! }
    func settingsServerId(key: String) -> String { return UserManager.settingsServer[key]! }

    func archiveSpanClientId(key: String) -> String { return UserManager.archiveSpanClient[key]! }
    func archiveSpanServerId(key: String) -> String { return UserManager.archiveSpanServer[key]! }

    func lastAcquiredClientId(key: String) -> String? { return hkToMCDB(key) }
    func lastAcquiredServerId(key: String) -> String? { return mcdbToHK(key) }


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
        resetAccountComponents([.Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired])
    }

    // Resets all user-related data, including the user id.
    public func resetFull() {
        resetAccount()
        resetAccountComponents([.Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired])
        resetUserId()
    }


    // MARK: - User Profile photo

    // set profile photo - return is success result
    public func setUserProfilePhoto(photo: UIImage?) -> Bool {
        var result = false

        if let url = userProfilePhotoUrl() {

            if let ph = photo {
                // save photo
                let imageData = UIImagePNGRepresentation(ph)
                result = imageData!.writeToURL(url, atomically: false)
            }

            else {
                // remove if exists

                let fileManager = NSFileManager.defaultManager()

                let urlPathStr = url.absoluteString

                if fileManager.fileExistsAtPath(urlPathStr) {
                    do {
                        try fileManager.removeItemAtPath(urlPathStr)
                        result = true
                    } catch {
                        print("File does not exists \(error)")
                        result = false
                    }
                }
                else {
                    result = true
                }
            }
        }

        print("Set user profile. Result \(result)")

        return result
    }

    public func userProfilePhoto() -> UIImage? {
        if let url = userProfilePhotoUrl() {
            let image = UIImage(contentsOfFile: url.path!)
            return image
        }
        return nil
    }

    private func userProfilePhotoUrl() -> NSURL? {

        if let user = self.userId {
            let photoFileName =  user + ".png"

            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]

            let imageURL = documentsURL.URLByAppendingPathComponent(photoFileName)

            return imageURL
        }

        return nil
    }

    // MARK: - User Info : first & last names

    public func getUserInfo(completion: ((NSDictionary?, NSError?) -> Void)) {
        Stormpath.me(completionHandler: { dict, error in
            completion(dict, error)
        })
    }

}
