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
import SwiftyUserDefaults

// Helper typealiases to indicate whether the bool argument expects an error or success status.
public typealias ErrorCompletion = Bool -> Void
public typealias SuccessCompletion = Bool -> Void

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
public let UMDidLoginNotifiaction = "didLoginNotifiaction"
public let UMDidLogoutNotification = "didLogoutNotification"

// Error generators.
// These are public to allow other components to recreate and check error messages.
public let UMPushInvalidBinaryFileError : (AccountComponent, String?) -> String = { (component, path) in
    return "Invalid \(component) file at: \(path)"
}

public let UMPushReadBinaryFileError : (AccountComponent, String) -> String = { (component, path) in
    return "Failed to read \(component) file at: \(path)"
}

public let UMPullMultipleComponentsError : [String] -> String = { components in
    return "Failed to pull account components \(components.joinWithSeparator(","))"
}

// Inverts the text error for a failed multi-component access as an array of account components.
public let UMPullComponentErrorAsArray : String -> [AccountComponent] = { errorMsg in
    let prefix = "Failed to pull account components "
    var result : [AccountComponent] = []
    if errorMsg.hasPrefix(prefix) {
        let componentsStr = errorMsg.substringFromIndex(errorMsg.startIndex.advancedBy(prefix.characters.count - 1))
        result = componentsStr.componentsSeparatedByString(",").flatMap(getComponentByName)
    }
    return result
}

public let granularity1Min = 60.0
public let granularity5Mins = 300.0
public let granularity10Mins = 600.0

public func floorDate(date: NSDate, granularity: Double) -> NSDate {
    return NSDate(timeIntervalSinceReferenceDate:
        (floor(date.timeIntervalSinceReferenceDate / granularity) * granularity))
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
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
    public static let initialProfileDataKey = "initialProfileData"
    public static let additionalInfoDataKey = "additionalInfoData"
    private static let firstLoginKey = "firstLoginKey"
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
        StormpathConfiguration.defaultConfiguration.APIURL = MCRouter.baseURL
    }

    // MARK: - Account status, and authentication

    public func hasUserId() -> Bool {
        if let user = userId {
            return !user.isEmpty
        }
        return false
    }
    
    public func isLoggedIn () -> Bool {
        return Stormpath.sharedSession.accessToken != nil
    }
    
    public func removeFirstLogin () {
        Defaults.removeObjectForKey(UserManager.firstLoginKey + "." + userId!)
        Defaults.synchronize()
    }
    
    public func setAsFirstLogin () {
        Defaults.setObject("1", forKey: UserManager.firstLoginKey + "." + userId!)
        Defaults.synchronize()
    }
    
    public func isItFirstLogin () -> Bool {
        let firstLoginObject = Defaults.objectForKey(UserManager.firstLoginKey + "." + userId!)
        return firstLoginObject != nil
    }
    
    public func saveAdditionalProfileData (data: [String: AnyObject]) {
        Defaults.setObject(data, forKey: UserManager.additionalInfoDataKey + "." + userId!)
        Defaults.synchronize()
    }
    
    public func getAdditoinalProfileData () -> [String: AnyObject]? {
        return Defaults.objectForKey(UserManager.additionalInfoDataKey + "." + userId!) as? [String: AnyObject]
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
            } else {
                print("\(Locksmith.loadDataForUserAccount(user))")
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
                Stormpath.sharedSession.logout()
                ConsentManager.sharedManager.resetConsentFilePath()
                HealthManager.sharedManager.reset()
                PopulationHealthManager.sharedManager.resetAggregates()
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
    public func ensureUserPass(user: String?, pass: String?, completion: ErrorCompletion) {
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

    public func loginWithCompletion(completion: SvcResultCompletion) {
        withUserPass (getPassword()) { (user, pass) in
            Stormpath.sharedSession.login(user, password: pass) {
                (success, err) -> Void in
                guard success && err == nil else {
                    log.error("Stormpath login failed: \(err!.localizedDescription)")
                    self.resetFull()
                    completion(RequestResult(error:err!))
                    return
                }

                log.verbose("Access token: \(Stormpath.sharedSession.accessToken)")
                MCRouter.updateAuthToken(Stormpath.sharedSession.accessToken)
                completion(RequestResult())
            }
        }
    }

    public func loginWithPush(profile: [String: AnyObject], completion: SvcResultCompletion) {
        loginWithCompletion { res in
            guard res.ok else {
                completion(res)
                return
            }
            self.pushProfile(profile, completion: completion)
        }
    }

    public func loginWithPull(completion: SvcResultCompletion) {
        loginWithCompletion { res in
            guard res.ok  else {
                completion(res)
                return
            }
            self.pullFullAccount(completion)
        }
    }

    public func login(userPass: String, completion: SvcResultCompletion) {
        withUserId { user in
            if !self.validateAccount(userPass) {
                self.resetAccount()
                self.createAccount(user, userPass: userPass)
            }
            self.loginWithPull(completion)
        }
    }

    public func logoutWithCompletion(completion: (Void -> Void)?) {
        Stormpath.sharedSession.logout()
        MCRouter.updateAuthToken(nil)
        resetUser()
        if let comp = completion { comp() }
    }

    public func logout() {
        logoutWithCompletion(nil)
    }

    public func register(firstName: String, lastName: String, consentPath: String, initialData: [String: String], completion: ((Account?, Bool, String?) -> Void)) {
        withUserPass(getPassword()) { (user,pass) in
            let account = RegistrationModel(email: user, password: pass)
            account.givenName = firstName
            account.surname = lastName
            if let data = NSData(contentsOfFile: consentPath) {
                let consentStr = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
                account.customFields = ["consent": consentStr]
                account.customFields.update(initialData)
                Stormpath.sharedSession.register(account) { (account, error) -> Void in
                    if error != nil { log.error("Register failed: \(error)") }
                    completion(account, error != nil, error?.localizedDescription)
                }
            } else {
                let msg = UMPushReadBinaryFileError(.Consent, consentPath)
                log.error(msg)
                completion(nil, true, msg)
            }
        }
    }

    public func withdraw(keepData: Bool, completion: SuccessCompletion) {
        let params = ["keepData": keepData]
        Service.string(MCRouter.DeleteAccount(params), statusCode: 200..<300, tag: "WITHDRAW") {
            _, response, result in
            if result.isSuccess { self.resetFull() }
            completion(result.isSuccess)
        }
    }


    public func resetPassword(email: String, completion: ((Bool, String?) -> Void)) {
        Stormpath.sharedSession.resetPassword(email) { (success, error) -> Void in
            if error != nil { log.error("Reset Password failed: \(error)") }
            completion(success, error?.localizedDescription)
        }
    }

    // MARK: - Stormpath token management.

    public func getAccessToken() -> String? {
        return Stormpath.sharedSession.accessToken
    }

    // Recursive checking of the access token's expiry.
    // This method retrieves the expiry time for the current access token using the
    // REST API's expiry route.
    //
    // If the token has expired, we refresh it with the refreshAccessToken method, and
    // recursively enter this function with an incremented 'tried' counter.
    //
    // Once we hit our maximum number of retries, we attempt to decode the token locally
    // to check whether it has expired.
    //
    // TODO: Yanif: remove checking local expiration, since this should never be feasible.
    //
    public func ensureAccessToken(tried: Int, completion: ErrorCompletion) {
        guard tried < UserManager.maxTokenRetries else {
            log.error("Failed to get access token within \(UserManager.maxTokenRetries) iterations")
            // Get the expiry time locally from the token if available.
            // TODO: this is a temporary workaround for issue #30, to support auto-login:
            // https://github.com/yanif/circator/issues/30
            var doReset = true
            if let token = Stormpath.sharedSession.accessToken {
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
            NSNotificationCenter.defaultCenter().postNotificationName(UMDidLogoutNotification, object: nil)
            return
        }

        Service.json(MCRouter.TokenExpiry, statusCode: 200..<300, tag: "ACCTOK") {
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

    public func ensureAccessToken(completion: ErrorCompletion) {
        if let token = Stormpath.sharedSession.accessToken {
            MCRouter.updateAuthToken(token)
            ensureAccessToken(0, completion: completion)
        } else {
            self.refreshAccessToken(completion)
        }
    }

    public func refreshAccessToken(tried: Int, completion: ErrorCompletion) {
        Stormpath.sharedSession.refreshAccessToken { (success, error) in
            guard success && error == nil else {
                log.warning("Refresh failed: \(error!.localizedDescription)")
                log.warning("Attempting login: \(self.hasAccount()) \(self.hasPassword())")

                if self.hasAccount() && self.hasPassword() {
                    self.loginWithPull { res in completion(res.fail) }
                } else {
                    completion(true)
                }
                return
            }

            if let token = Stormpath.sharedSession.accessToken {
                log.verbose("Refreshed token: \(token)")
                MCRouter.updateAuthToken(Stormpath.sharedSession.accessToken)
                self.ensureAccessToken(tried+1, completion: completion)
            } else {
                log.error("RefreshAccessToken failed, please login manually.")
                completion(true)
            }
        }
    }

    public func refreshAccessToken(completion: ErrorCompletion) {
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
                fallthrough
            default: break
//                return [componentName: self.uploadLastAcquiredExtractor(componentData)]
            }
        }
        return nil
    }

    // Returns an unwrapped component as dictionary, stripping any component name from the argument.
    // This is used when downloading data from the backend service.
    // Consent and photo data are returned in wrapped form.
    private func unwrapResponse(component: AccountComponent, response: [String:AnyObject]) -> [String:AnyObject]?
    {
        let componentName = getComponentName(component)
        switch component {
        case .Consent:
            fallthrough
        case .Photo:
            if let componentData = response[componentName] as? String {
                return [componentName: componentData]
            }
            return nil

        case .Profile:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadProfileExtractor(componentData)
            }
            return nil

        case .Settings:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadSettingsExtractor(componentData)
            }
            return nil

        case .ArchiveSpan:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadArchiveSpanExtractor(componentData)
            }
            return nil

        case .LastAcquired:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return componentData
            }
            return nil
        }
    }

    // Retrieves the currently cached account component, wraps it, and pushes it to the backend.
    private func syncAccountComponent(component: AccountComponent, completion: SvcResultCompletion)
    {
        let componentData = wrapCache(component)
        if let _componentData = componentData {
            Service.string(MCRouter.SetUserAccountData(_componentData), statusCode: 200..<300, tag: "SYNCACC") {
                _, response, result in completion(RequestResult(afStringResult:result))
            }
        }
    }

    private func deferredSyncOnAccountComponent(component: AccountComponent, sync: Bool)
    {
        if sync {
            requestAsyncs[component]!.0?.cancel()
            let componentDelay = requestAsyncs[component]!.1
            let newAsync = Async.background(after: componentDelay) {
                self.syncAccountComponent(component) { _ in () }
            }
            requestAsyncs[component] = (newAsync, componentDelay)
        }
    }

    // Sets the component data in the cache as requested, and then synchronizes with the backend.
    private func pushAccountComponent(component: AccountComponent,
                                      refresh: Bool,
                                      componentData: [String:AnyObject],
                                      completion: SvcResultCompletion)
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
                                                refresh: Bool, completion: SvcResultCompletion)
    {
        if let path = filePath {
            if let data = NSData(contentsOfFile: path) {
                let componentName = getComponentName(component)
                let cache = [componentName: data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())]
                pushAccountComponent(component, refresh: true, componentData: cache, completion: completion)
            } else {
                let msg = UMPushReadBinaryFileError(component, path)
                log.error(msg)
                completion(RequestResult(errorMessage:msg))
            }
        } else {
            let msg = UMPushInvalidBinaryFileError(component, filePath)
            log.error(msg)
            completion(RequestResult(errorMessage:msg))
        }
    }

    // Retrieves an account component from the backend service.
    private func pullAccountComponent(component: AccountComponent, completion: SvcResultCompletion)
    {
        print("!!! pullAccountComponent \(component)")
        Service.json(MCRouter.GetUserAccountData([component]), statusCode: 200..<300, tag: "GACC\(component)") {
            _, _, result in
            var pullSuccess = result.isSuccess
            if pullSuccess {
                // All account component routes return a JSON object.
                // Use this to refresh the component cache.
                if let dict = result.value as? [String: AnyObject],
                       refreshVal = self.unwrapResponse(component, response: dict)
                {
                    self.refreshComponentCache(component, componentData: refreshVal)
                    self.lastComponentLoadDate[component] = NSDate()
                } else {
                    // Indicate a failure if we cannot unwrap the component from the response.
                    pullSuccess = false
                }
            }
            completion(RequestResult(afObjectResult:result))
        }
    }

    // Retrieves an account component if it is stale.
    private func pullAccountComponentIfNeeded(component: AccountComponent, completion: SvcResultCompletion)
    {
        if isAccountComponentOutdated(component) {
            pullAccountComponent(component, completion: completion)
        } else {
            print("pull component \(component) skipped")
            completion(RequestResult())
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
    private func pullMultipleAccountComponents(components: [AccountComponent], requiredComponents: [AccountComponent], completion: SvcResultCompletion) {
        Service.json(MCRouter.GetUserAccountData(components), statusCode: 200..<300, tag: "GALLACC") {
            _, _, result in
            var pullSuccess = result.isSuccess
            var failedComponents : [String] = []
            if pullSuccess {
                // All account component routes return a JSON object.
                // Use this to refresh the component cache.
                if let dict = result.value as? [String: AnyObject] {
                    for component in components {
                        if let refreshVal = self.unwrapResponse(component, response: dict) {
                            self.refreshComponentCache(component, componentData: refreshVal)
                            self.lastComponentLoadDate[component] = NSDate()
                        } else if requiredComponents.contains(component) {
                            // Indicate a failure if we cannot unwrap a required component from the response.
                            failedComponents.append(getComponentName(component))
                            pullSuccess = false
                            break
                        }
                    }
                }
            }
            let infoMsg = failedComponents.isEmpty ? "" : UMPullMultipleComponentsError(failedComponents)
            completion(RequestResult(ok: pullSuccess, message:infoMsg))
        }
    }

    public func pullFullAccount(completion: SvcResultCompletion) {
        pullMultipleAccountComponents([ .Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired],
                                      requiredComponents: [.Consent, .Profile, .Settings],
                                      completion: completion)
    }


    // MARK: - Consent accessors
    public func getConsent() -> [String: AnyObject] { return getCachedComponent(.Consent) }

    public func syncConsent(completion: SvcResultCompletion) {
        syncAccountComponent(.Consent, completion: completion)
    }

    public func pushConsent(filePath: String?, completion: SvcResultCompletion) {
        pushBinaryFileAccountComponent(filePath, component: .Consent, refresh: true, completion: completion)
    }

    public func pullConsent(completion: SvcResultCompletion) {
        pullAccountComponent(.Consent, completion: completion)
    }

    // MARK: - Photo accessors
    public func getPhoto() -> [String: AnyObject] { return getCachedComponent(.Photo) }

    public func syncPhoto(completion: SvcResultCompletion) {
        syncAccountComponent(.Photo, completion: completion)
    }

    public func pushPhoto(filePath: String?, completion: SvcResultCompletion) {
        pushBinaryFileAccountComponent(filePath, component: .Photo, refresh: true, completion: completion)
    }

    public func pullPhoto(completion: SvcResultCompletion) {
        pullAccountComponent(.Photo, completion: completion)
    }


    // MARK: - Profile accessors

    public func getProfileCache() -> [String: AnyObject] { return getCachedComponent(.Profile) }

    public func syncProfile(completion: SvcResultCompletion) {
        syncAccountComponent(.Profile, completion: completion)
    }

    public func pushProfile(componentData: [String: AnyObject], completion: SvcResultCompletion) {
        pushAccountComponent(.Profile, refresh: true, componentData: componentData, completion: completion)
    }

    public func pullProfile(completion: SvcResultCompletion) {
        pullAccountComponent(.Profile, completion: completion)
    }

    public func isProfileOutdated() -> Bool {
        return isAccountComponentOutdated(.Profile)
    }

    public func pullProfileIfNeeded(completion: SvcResultCompletion) {
        pullAccountComponentIfNeeded(.Profile, completion: completion)
    }

    public func getUserIdHash() -> String? {
        return (getProfileCache()[UMUserHashKey] as? String)
    }


    // MARK: - Settings accessors

    public func getSettingsCache() -> [String: AnyObject] { return getCachedComponent(.Settings) }

    public func resetSettingsCache() { resetCachedComponent(.Settings) }

    public func syncSettings(completion: SvcResultCompletion) {
        syncAccountComponent(.Settings, completion: completion)
    }

    public func pushSettings(componentData: [String: AnyObject], completion: SvcResultCompletion) {
        pushAccountComponent(.Settings, refresh: true, componentData: componentData, completion: completion)
    }

    public func pullSettings(completion: SvcResultCompletion) {
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

    public func getAcquisitionSeq() -> [String: AnyObject] { return getCachedComponent(.LastAcquired) }

    public func getAcquisitionSeq(key: String) -> AnyObject? { return getCachedComponent(.LastAcquired)[key] }

    public func resetAcquisitionSeq() { resetCachedComponent(.LastAcquired) }

    public func setAcquisitionSeq(seqids: [String: AnyObject], sync: Bool = false) {
        deferredPushOnAccountComponent(.LastAcquired, refresh: true, sync: sync, componentData: seqids)
    }

    public func syncAcquisitionSeq(completion: SvcResultCompletion) {
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

    public func getUserInfo(completion: ((Account?, NSError?) -> Void)) {
        Stormpath.sharedSession.me(completion)
    }

    // MARK: - User units preferences

    public func useMetricUnits() -> Bool {
        if let metricObj = getProfileCache()["metric"] {
            if let metricI = metricObj as? Int {
                return metricI > 0
            } else if let metricB = metricObj as? Bool {
                return metricB
            } else if let metricS = metricObj as? String {
                return !(metricS == "false")
            }
        }
        return HMConstants.sharedInstance.defaultToMetricUnits
    }

    // MARK: - Default meal & activity times

    //setting usual time when user goes to sleep
    public func setUsualWhenToSleepTime(date: NSDate) {
        if let user = userId {
            let key = "usualWhenToSleepTime"+user
            Defaults.setObject(date, forKey: key)
            Defaults.synchronize()
        }
    }
    //setting usual duration user sleeping
    public func setUsualWokeUpTime(date: NSDate) {
        if let user = userId {
            let key = "usualSleepDuration"+user
            Defaults.setObject(date, forKey: key)
            Defaults.synchronize()
        }
    }

    public func getUsualWhenToSleepTime() -> NSDate? {
        if let user = userId {
            let key = "usualWhenToSleepTime"+user
            let date = Defaults.objectForKey(key)
            if let d = date as? NSDate {
                return floorDate(d, granularity: granularity5Mins)
            }
        }
        return nil
    }

    public func getUsualWokeUpTime() -> NSDate? {
        if let user = userId {
            let key = "usualSleepDuration"+user
            let duration = Defaults.objectForKey(key)
            if let d = duration as? NSDate {
                return floorDate(d, granularity: granularity5Mins)
            }
        }
        return nil
    }

    //setting ususal date for meals
    public func setUsualMealTime(mealType: String, forDate date: NSDate) {
        if let user = userId {
            let key = mealType+user
            Defaults.setObject(date, forKey: key)
            Defaults.synchronize()
        }
    }

    //get usual date for meals
    public func getUsualMealTime(mealType: String) -> NSDate? {
        if let user = userId where Defaults.hasKey(mealType+user) {
            let key = mealType+user
            let dateOfMeal = Defaults.objectForKey(key)
            if let d = dateOfMeal as? NSDate {
                return floorDate(d, granularity: granularity5Mins)
            }

        }
        return nil
    }

}
