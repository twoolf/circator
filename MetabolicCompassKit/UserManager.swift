//
//  UserManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/13/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MCCircadianQueries
import Alamofire
import Locksmith
import Stormpath
import CryptoSwift
import SwiftDate
import Async
import AsyncKit
import JWTDecode
import SwiftyUserDefaults
import Auth0

// Helper typealiases to indicate whether the bool argument expects an error or success status.
public typealias ErrorCompletion = (Bool) -> Void
public typealias SuccessCompletion = (Bool) -> Void

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
    return "Invalid \(component) file at: \(String(describing: path))"
}

public let UMPushReadBinaryFileError : (AccountComponent, String) -> String = { (component, path) in
    return "Failed to read \(component) file at: \(path)"
}

public let UMPullMultipleComponentsError : ([String]) -> String = { components in
    return "Failed to pull account components \(components.joined(separator: ","))"
}

// Inverts the text error for a failed multi-component access as an array of account components.
public let UMPullComponentErrorAsArray : (String) -> [AccountComponent] = { errorMsg in
    let prefix = "Failed to pull account components "
    var result : [AccountComponent] = []
    if errorMsg.hasPrefix(prefix) {
        let intOffSet = prefix.characters.count - 1
        let indexString = errorMsg.index(errorMsg.startIndex, offsetBy: intOffSet)
        let componentsStr = errorMsg.substring(from: indexString)
        result = componentsStr.components(separatedBy: ",").flatMap(getComponentByName)
    }
    return result
}

public let granularity1Min = 60.0
public let granularity5Mins = 300.0
public let granularity10Mins = 600.0
public let granularity15Mins = 900.0

public func floorDate(date: Date, granularity: Double) -> Date {
    return Date(timeIntervalSinceReferenceDate:
        (floor(date.timeIntervalSinceReferenceDate / granularity) * granularity))
}

public func roundDate(date: Date, granularity: Double) -> Date {
    return Date(timeIntervalSinceReferenceDate:
        (round(date.timeIntervalSinceReferenceDate / granularity) * granularity))
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

// Namespace helpers.
internal func seqIdOfSampleTypeId(typeIdentifier: String) -> String? {
    if let key = HMConstants.sharedInstance.hkToMCDB[typeIdentifier.hashValue] {
        return key
    }
    else if let (category,_) = HMConstants.sharedInstance.hkQuantityToMCDBActivity[typeIdentifier] {
        return category
    }
    else if typeIdentifier == HKWorkoutType.workoutType().identifier {
        return "activity"
    }
    return nil
}

internal func sampleTypeIdOfSeqId(anchorIdentifier: String) -> String? {
    if anchorIdentifier == "activity" {
        return HKWorkoutType.workoutType().identifier
    }
    else if let (_,typeIdentifier) = HMConstants.sharedInstance.mcdbActivityToHKQuantity[anchorIdentifier] {
        return typeIdentifier
    }
    else if let typeIdentifier = HMConstants.sharedInstance.mcdbToHK[anchorIdentifier.description] {
        return typeIdentifier.description
    }
    return nil
}

internal func sampleTypeOfTypeId(typeIdentifier: String) -> HKSampleType? {
    if typeIdentifier == HKWorkoutType.workoutType().identifier {
        return HKWorkoutType.workoutType()
    }
    else if typeIdentifier == HKCategoryTypeIdentifier.appleStandHour.rawValue
                || typeIdentifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue
    {
        return HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: typeIdentifier))
    } else {
        return HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: typeIdentifier))
    }

}

internal func sampleTypeOfSeqId(anchorIdentifier: String) -> HKSampleType? {
    if let typeId = sampleTypeIdOfSeqId(anchorIdentifier: anchorIdentifier) {
        return sampleTypeOfTypeId(typeIdentifier: typeId)
    }
    return nil
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
            if let dictionary = Locksmith.loadDataForUserAccount(userAccount: UMPrimaryUserKey)
            {
                return dictionary["userId"] as? String
            } else {
                return nil
            }
        }
        set(newUser) {
            do {
                if let _newUser = newUser {
                    if let _ = Locksmith.loadDataForUserAccount(userAccount: UMPrimaryUserKey)
                    {
                        try Locksmith.updateData(data: ["userId" : _newUser], forUserAccount: UMPrimaryUserKey)
                    } else {
                        try Locksmith.saveData(data: ["userId" : _newUser], forUserAccount: UMPrimaryUserKey)
                    }
                }
                else {
                    if let _ = Locksmith.loadDataForUserAccount(userAccount: UMPrimaryUserKey) {
                        try Locksmith.deleteDataForUserAccount(userAccount: UMPrimaryUserKey)
                    }
                }
            } catch {
                log.error("userId.set: \(error)")
            }
        }
    }

    var tokenExpiry : TimeInterval = Date().timeIntervalSince1970   // Expiry in time interval since 1970.
    
    // Account component dictionary cache.
    private(set) public var componentCache : [AccountComponent: [String: AnyObject]] = [
        .Consent      : [:],
        .Photo        : [:],
        .Profile      : [:],
        .Settings     : [:],
        .ArchiveSpan  : [HMHRangeMinKey: [String:AnyObject]() as AnyObject, HMHRangeStartKey: [String:AnyObject]() as AnyObject, HMHRangeEndKey: [String:AnyObject]() as AnyObject],
        .LastAcquired : [:]
    ]

    // Track when the remote account component was last retrieved
    var lastComponentLoadDate : [AccountComponent: Date?] = [
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

    // Custom component update task queue
    var componentUpdateQueue = DispatchQueue(label:"UserManangerUpdateQueue", attributes: .concurrent)

    init() {
        StormpathConfiguration.defaultConfiguration.APIURL = MCRouter.baseURL as URL
        self.componentUpdateQueue = DispatchQueue(label: "UserManangerUpdateQueue")
//        self.serialQueue = DispatchQueue(label: "UserManangerUpdateQueue")
//        self.componentUpdateQueue = dispatch_queue_create("UserManangerUpdateQueue", DISPATCH_QUEUE_SERIAL)
//        self.componentUpdateQueue.async {
//            StormpathConfiguration.defaultConfiguration.APIURL = MCRouter.baseURL as URL
//        }
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
        Defaults.removeObject(forKey: UserManager.firstLoginKey + "." + userId!)
        Defaults.synchronize()
    }
    
    public func setAsFirstLogin () {
        if (userId == nil)  {return}
        Defaults.set("1", forKey: UserManager.firstLoginKey + "." + userId!)
        Defaults.synchronize()
    }
    
    public func isItFirstLogin () -> Bool {
        if (userId == nil)  {return false}
        guard let firstLoginObject = Defaults.object(forKey: UserManager.firstLoginKey + "." + userId!) else {return false}
        return firstLoginObject != nil
    }
    
    public func saveAdditionalProfileData (data: [String: AnyObject]) {
        // Initialize constants for adding events.
        let defaultSleepStart = Date().startOf(component: .day) - 1.hours
        if let i = data["sleep_duration"] as? Int {
            let defaultSleepEnd = defaultSleepStart + i.seconds
            setUsualWhenToSleepTime(date: defaultSleepStart)
            setUsualWokeUpTime(date: defaultSleepEnd)
        }
        else if let s = data["sleep_duration"] as? String, let i = Int(s) {
            let defaultSleepEnd = defaultSleepStart + i.seconds
            setUsualWhenToSleepTime(date: defaultSleepStart)
            setUsualWokeUpTime(date: defaultSleepEnd)
        }
        if (userId == nil) {return}
        Defaults.set(data, forKey: UserManager.additionalInfoDataKey + "." + userId!)
        Defaults.synchronize()
    }
    
    public func getAdditionalProfileData () -> [String: AnyObject]? {
        if userId == nil {return [:]}
        return Defaults.object(forKey: UserManager.additionalInfoDataKey + "." + userId!) as? [String: AnyObject]
    }
    
    public func getUserId() -> String?     { return userId }
    public func setUserId(userId: String)  { self.userId = userId }
    public func resetUserId()              { self.userId = nil }

    // MARK: - Account metadata accessors for fields stored in keychain.

    public func getAccountData() -> [String:AnyObject]? {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            let lockbox = account.readFromSecureStore()
            return lockbox?.data as [String : AnyObject]?
        }
        return nil
    }

    public func setAccountData(items: [String:AnyObject]) {
        withUserId { user in
            if var datadict = Locksmith.loadDataForUserAccount(userAccount: user) {
                for (k,v) in items { datadict[k] = v }
                do {
                    try Locksmith.updateData(data: datadict, forUserAccount: user)
                } catch {
                    log.error("setAccountData: \(error)")
                }
            } else {
                print("\(String(describing: Locksmith.loadDataForUserAccount(userAccount: user)))")
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
                IOSHealthManager.sharedManager.reset()
                PopulationHealthManager.sharedManager.reset()
            } catch {
                log.warning("resetAccount: \(error)")
            }
        }
    }

    public func getPassword() -> String? {
        if let data = getAccountData(), let pass = data["password"] as? String {
            return pass
        }
        return nil
    }

    public func hasPassword() -> Bool {
        if let data = getAccountData(), let pass = data["password"] as? String {
            return !pass.isEmpty
        }
        return false
    }
    
    public func setPassword(userPass: String) {
        if hasAccount() {
            setAccountData(items: ["password": userPass as AnyObject])
        } else {
            withUserId { user in self.createAccount(userId: user, userPass: userPass) }
        }
    }

    // Set a username and password in keychain, invoking a completion with an error status.
    public func ensureUserPass(user: String?, pass: String?, completion: ErrorCompletion) {
        if let u = user, let p = pass {
            guard !(u.isEmpty || p.isEmpty) else {
                completion(true)
                return
            }
            UserManager.sharedManager.setUserId(userId: u)
            UserManager.sharedManager.setPassword(userPass: p)
            completion(false)
        }
    }

    // Set the username and password in keychain.
    public func overrideUserPass(user: String?, pass: String?) {
        withUserPass(username: user, password: pass) { (newUser, newPass) in
            UserManager.sharedManager.setUserId(userId: newUser)
            UserManager.sharedManager.setPassword(userPass: newPass)
        }
    }


    // MARK: - Stormpath-based account creation and authentication

    public func loginWithCompletion(completion: @escaping SvcResultCompletion) {
     //   withUserPass (password: getPassword()) { (user, pass) in
            let token = AuthSessionManager.shared.keychain.string(forKey: "access_token")
            MCRouter.updateAuthToken(token: token)
            let result = RequestResult()
            completion(result)
   //     }
    }

    public func loginWithPush(profile: [String: AnyObject], completion: @escaping SvcResultCompletion) {
        loginWithCompletion { res in
            guard res.ok else {
                completion(res)
                return
            }
            self.pushProfile(componentData: profile, completion: completion)
        }
    }

    public func loginWithPull(completion: @escaping SvcResultCompletion) {
        loginWithCompletion { res in
            guard res.ok  else {
                completion(res)
                return
            }
            self.pullFullAccount(completion: completion)
        }
    }

    public func login(userPass: String, completion: @escaping SvcResultCompletion) {
        withUserId { user in
            if !self.validateAccount(userPass: userPass) {
                self.resetAccount()
                self.createAccount(userId: user, userPass: userPass)
            }
            self.loginWithPull(completion: completion)
        }
    }

    public func logoutWithCompletion(completion: (() -> Void)?) {
        Stormpath.sharedSession.logout()
        MCRouter.updateAuthToken(token: nil)
        resetUser()
        if let comp = completion { comp() }
    }

    public func logout() {
        logoutWithCompletion(completion: nil)
    }

    public func register(firstName: String, lastName: String, consentPath: String, initialData: [String: String], completion: @escaping ((Account?, Bool, String?) -> Void)) {
 
        
        
        
        
        
        
        

        withUserPass(password: getPassword()) { (user,pass) in
//            let account = RegistrationModel(email: user, password: pass)
            let account = RegistrationForm(email: user, password: pass)
            account.givenName = firstName
            account.surname = lastName
            if let data = NSData(contentsOfFile: consentPath) {
                let consentStr = data.base64EncodedString(options: NSData.Base64EncodingOptions())
                account.customFields = ["consent": consentStr]
                account.customFields.update(other: initialData)
                Stormpath.sharedSession.register(account: account) { (account, error) -> Void in
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

    public func registerAuth0(firstName: String, lastName: String, consentPath: String, initialData: [String: String]) {
        withUserPass(password: getPassword()) { (user,pass) in
            let data = NSData(contentsOfFile: consentPath)
            let consentStr = data?.base64EncodedString(options: NSData.Base64EncodingOptions())
            let userMetadata = ["first_name": firstName,
                                 "last_name": lastName]
        Auth0
            .authentication()
            .createUser(
                email: user,
                password: pass,
                connection: "Username-Password-Authentication",
                userMetadata: userMetadata
            )
            .start { result in
                switch result {
                case .success(let user):
                    print("User Signed up: \(user)")
                case .failure(let error):
                    print("Failed with \(error)")
                }
            }
        }
    }

    public func withdraw(keepData: Bool, completion: @escaping SuccessCompletion) {
        let params = ["keep": keepData]
        Service.string(route: MCRouter.DeleteAccount(params as [String : AnyObject]), statusCode: 200..<300, tag: "WITHDRAW") {
            _, response, result in
            if result.isSuccess { self.resetFull() }
            completion(result.isSuccess)
        }
    }


    public func resetPassword(email: String, completion: @escaping ((Bool, String?) -> Void)) {
        Stormpath.sharedSession.resetPassword(email: email) { (success, error) -> Void in
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
    public func ensureAccessToken(tried: Int, completion: @escaping ErrorCompletion) {
        guard tried < UserManager.maxTokenRetries else {
            log.error("Failed to get access token within \(UserManager.maxTokenRetries) iterations")
            // Get the expiry time locally from the token if available.
            // TODO: this is a temporary workaround for issue #30, to support auto-login:
            // https://github.com/yanif/circator/issues/30
            var doReset = true
            if let token = Stormpath.sharedSession.accessToken {
                do {
                    let jwt = try decode(jwt: token)
                    if let expiry = jwt.expiresAt?.timeIntervalSince1970 {
                        doReset = false
                        self.tokenExpiry = expiry
                        log.info("Setting expiry as \(expiry)")
                    }
                } catch {}
            }
            if doReset { self.resetFull() }
            completion(doReset)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: UMDidLogoutNotification), object: nil)
            return
        }

        Service.json(route: MCRouter.TokenExpiry, statusCode: 200..<300, tag: "ACCTOK") {
            _, response, result in
            guard result.isSuccess else {
                self.refreshAccessToken(tried: tried, completion: completion)
                return
            }
            guard let jwtDict = result.value as? [String:[String:AnyObject]],
                let expiry  = jwtDict["body"]?["exp"] as? TimeInterval, expiry > Date().timeIntervalSince1970 else
            {
                self.refreshAccessToken(tried: tried, completion: completion)
                return
            }
            self.tokenExpiry = expiry
            completion(false)
        }
    }

    public func ensureAccessToken(completion: @escaping ErrorCompletion) {
        if let token = Stormpath.sharedSession.accessToken {
            MCRouter.updateAuthToken(token: token)
            ensureAccessToken(tried: 0, completion: completion)
        } else {
            self.refreshAccessToken(completion: completion)
        }
    }

    public func refreshAccessToken(tried: Int, completion: @escaping ErrorCompletion) {
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
                log.debug("Refreshed token: \(token)")
                MCRouter.updateAuthToken(token: Stormpath.sharedSession.accessToken)
                self.ensureAccessToken(tried: tried+1, completion: completion)
            } else {
                log.error("RefreshAccessToken failed, please login manually.")
                completion(true)
            }
        }
    }

    public func refreshAccessToken(completion: @escaping ErrorCompletion) {
        refreshAccessToken(tried: 0, completion: completion)
    }

    // MARK: - Account component extractors
    private func uploadProfileExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.filter { kv in return !profileExcludes.contains(kv.0) })
    }

    private func downloadProfileExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        if let id = data["userid"] {
            var profile = data
            profile.removeValue(forKey: "userid")
            profile[UMUserHashKey] = id
            return profile
        }
        return data
    }

    private func uploadSettingsExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (settingsServerId(key: kv.0), kv.1) })
    }

    private func downloadSettingsExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (settingsClientId(key: kv.0), kv.1)} )
    }

    private func uploadArchiveSpanExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (archiveSpanServerId(key: kv.0), kv.1) })
    }

    private func downloadArchiveSpanExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        return Dictionary(pairs: data.map { kv in return (archiveSpanClientId(key: kv.0), kv.1)} )
    }

    public func uploadLastAcquiredExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        let pairs: [(String, AnyObject)] = data.flatMap { kv in
            if let serverKey = lastAcquiredServerId(key: kv.0) { return (serverKey, kv.1) }
            log.error("USM no server key found for last acquired extractor on \(kv.0)")
            let attrs: [String: AnyObject] = ["Type": "Upload" as AnyObject, "Key": kv.0 as AnyObject]
            let info: [NSObject: AnyObject] = ["event" as NSObject: "LastAcquiredExtractor" as AnyObject, "attrs" as NSObject: attrs as AnyObject]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MCRemoteErrorNotification), object: nil, userInfo: info)
            return nil
        }
        return Dictionary(pairs: pairs)
    }

    public func downloadLastAcquiredExtractor(data: [String:AnyObject]) -> [String:AnyObject] {
        let pairs: [(String, AnyObject)] = data.flatMap { kv in
            if let clientKey = lastAcquiredClientId(key: kv.0) { return (clientKey, kv.1) }
            log.error("USM no client key found for last acquired extractor on \(kv.0)")
            let attrs: [String: AnyObject] = ["Type": "Download" as AnyObject, "Key": kv.0 as AnyObject]
            let info: [NSObject: AnyObject] = ["event" as NSObject: "LastAcquiredExtractor" as AnyObject, "attrs" as NSObject: attrs as AnyObject]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: MCRemoteErrorNotification), object: nil, userInfo: info)
            return nil
        }
        return Dictionary(pairs: pairs)
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
                return [componentName: self.uploadProfileExtractor(data: componentData) as AnyObject]
            case .Settings:
                return [componentName: self.uploadSettingsExtractor(data: componentData) as AnyObject]
            case .ArchiveSpan:
                return [componentName: self.uploadArchiveSpanExtractor(data: componentData) as AnyObject]
            case .LastAcquired:
                return [componentName: self.uploadLastAcquiredExtractor(data: componentData) as AnyObject]
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
                return [componentName: componentData as AnyObject]
            }
            return nil

        case .Profile:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadProfileExtractor(data: componentData)
            }
            return nil

        case .Settings:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadSettingsExtractor(data: componentData)
            }
            return nil

        case .ArchiveSpan:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadArchiveSpanExtractor(data: componentData)
            }
            return nil

        case .LastAcquired:
            if let componentData = response[componentName] as? [String:AnyObject] {
                return self.downloadLastAcquiredExtractor(data: componentData)
            }
            return nil
        }
    }

    // Retrieves the currently cached account component, wraps it, and pushes it to the backend.
    private func syncAccountComponent(component: AccountComponent, completion: @escaping SvcResultCompletion)
    {
        let componentData = wrapCache(component: component)
        if let _componentData = componentData {
            Service.string(route: MCRouter.SetUserAccountData(_componentData), statusCode: 200..<300, tag: "SYNCACC") {
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
                self.syncAccountComponent(component: component) { _ in () }
            }
            requestAsyncs[component] = (newAsync, componentDelay)
        }
    }

    // Sets the component data in the cache as requested, and then synchronizes with the backend.
    private func pushAccountComponent(component: AccountComponent,
                                      refresh: Bool,
                                      componentData: [String:AnyObject],
                                      completion: @escaping SvcResultCompletion)
    {
        // Refresh cache, and post to the backend.
        if refresh { refreshComponentCache(component: component, componentData: componentData) }
        syncAccountComponent(component: component, completion: completion)
    }

    // Sets the component data in the cache as requested, and batches synchronization requests.
    private func deferredPushOnAccountComponent(component: AccountComponent,
                                                refresh: Bool, sync: Bool,
                                                componentData: [String:AnyObject])
    {
        if refresh { refreshComponentCache(component: component, componentData: componentData) }
        deferredSyncOnAccountComponent(component: component, sync: sync)
    }

    // A helper function for a binary account component that retrieves the component data from a file.
    // This is common to both the consent pdf and the profile pic.
    private func pushBinaryFileAccountComponent(filePath: String?, component: AccountComponent,
                                                refresh: Bool, completion: @escaping SvcResultCompletion)
    {
        if let path = filePath {
            if let data = NSData(contentsOfFile: path) {
                let componentName = getComponentName(component)
                let cache = [componentName: data.base64EncodedString(options: NSData.Base64EncodingOptions())]
                pushAccountComponent(component: component, refresh: true, componentData: cache as [String : AnyObject], completion: completion)
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
    private func pullAccountComponent(component: AccountComponent, completion: @escaping SvcResultCompletion)
    {
        Service.json(route: MCRouter.GetUserAccountData([component]), statusCode: 200..<300, tag: "GACC\(component)") {
            _, _, result in
            var pullSuccess = result.isSuccess
            if pullSuccess {
                // All account component routes return a JSON object.
                // Use this to refresh the component cache.
                if let dict = result.value as? [String: AnyObject],
                    let refreshVal = self.unwrapResponse(component: component, response: dict)
                {
                    self.refreshComponentCache(component: component, componentData: refreshVal)
                    self.lastComponentLoadDate[component] = Date()
                } else {
                    // Indicate a failure if we cannot unwrap the component from the response.
                    pullSuccess = false
                }
            }
            completion(RequestResult(afObjectResult:result))
        }
    }

    // Retrieves an account component if it is stale.
    private func pullAccountComponentIfNeeded(component: AccountComponent, completion: @escaping SvcResultCompletion)
    {
        if isAccountComponentOutdated(component: component) {
            pullAccountComponent(component: component, completion: completion)
        } else {
            completion(RequestResult())
        }
    }

    private func isAccountComponentOutdated(component: AccountComponent) -> Bool {
        if let lastDateOpt = lastComponentLoadDate[component], let lastDate = lastDateOpt {
            return lastDate.timeIntervalSinceNow < -300.0 // sec
        } else {
            return true
        }
    }

    private func refreshComponentCache(component: AccountComponent, componentData: [String:AnyObject]) {
        for (k,v) in componentData {
            componentCache[component]?.updateValue(v, forKey: k)
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
        for component in components { resetCachedComponent(component: component) }
    }

    // Retrieves multiple account components in a single request.
    private func pullMultipleAccountComponents(components: [AccountComponent], requiredComponents: [AccountComponent], completion: @escaping SvcResultCompletion) {
        Service.json(route: MCRouter.GetUserAccountData(components), statusCode: 200..<300, tag: "GALLACC") {
            _, response, result in
            var pullSuccess = result.isSuccess
            var failedComponents : [String] = []
            if pullSuccess {
                // All account component routes return a JSON object.
                // Use this to refresh the component cache.
                if let dict = result.value as? [String: AnyObject] {
                    for component in components {
                        if let refreshVal = self.unwrapResponse(component: component, response: dict) {
                            self.refreshComponentCache(component: component, componentData: refreshVal)
                            self.lastComponentLoadDate[component] = Date()
                        } else if requiredComponents.contains(component) {
                            // Indicate a failure if we cannot unwrap a required component from the response.
                            failedComponents.append(getComponentName(component))
                            pullSuccess = false
                            break
                        }
                    }
                }
            }
            //REMOVE AFTER TESTING!!!!!!!!!
            pullSuccess = true
            let infoMsg = failedComponents.isEmpty ? "" : UMPullMultipleComponentsError(failedComponents)
            completion(RequestResult(ok: pullSuccess, message:infoMsg))
        }
    }

    public func pullFullAccount(completion: @escaping SvcResultCompletion) {
        pullMultipleAccountComponents(components: [ .Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired],
                                      requiredComponents: [.Consent, .Profile, .Settings],
                                      completion: completion)
    }


    // MARK: - Consent accessors
    public func getConsent() -> [String: AnyObject] { return getCachedComponent(component: .Consent) }

    public func syncConsent(completion: @escaping SvcResultCompletion) {
        syncAccountComponent(component: .Consent, completion: completion)
    }

    public func pushConsent(filePath: String?, completion: @escaping SvcResultCompletion) {
        pushBinaryFileAccountComponent(filePath: filePath, component: .Consent, refresh: true, completion: completion)
    }

    public func pullConsent(completion: @escaping SvcResultCompletion) {
        pullAccountComponent(component: .Consent, completion: completion)
    }

    // MARK: - Photo accessors
    public func getPhoto() -> [String: AnyObject] { return getCachedComponent(component: .Photo) }

    public func syncPhoto(completion: @escaping SvcResultCompletion) {
        syncAccountComponent(component: .Photo, completion: completion)
    }

    public func pushPhoto(filePath: String?, completion: @escaping SvcResultCompletion) {
        pushBinaryFileAccountComponent(filePath: filePath, component: .Photo, refresh: true, completion: completion)
    }

    public func pullPhoto(completion: @escaping SvcResultCompletion) {
        pullAccountComponent(component: .Photo, completion: completion)
    }


    // MARK: - Profile accessors

    public func getProfileCache() -> [String: AnyObject] { return getCachedComponent(component: .Profile) }

    public func syncProfile(completion: @escaping SvcResultCompletion) {
        syncAccountComponent(component: .Profile, completion: completion)
    }

    public func pushProfile(componentData: [String: AnyObject], completion: @escaping SvcResultCompletion) {
        pushAccountComponent(component: .Profile, refresh: true, componentData: componentData, completion: completion)
    }

    public func pullProfile(completion: @escaping SvcResultCompletion) {
        pullAccountComponent(component: .Profile, completion: completion)
    }

    public func isProfileOutdated() -> Bool {
        return isAccountComponentOutdated(component: .Profile)
    }

    public func pullProfileIfNeeded(completion: @escaping SvcResultCompletion) {
        pullAccountComponentIfNeeded(component: .Profile, completion: completion)
    }

    public func getUserIdHash() -> String? {
        return (getProfileCache()[UMUserHashKey] as? String)
    }


    // MARK: - Settings accessors 

    public func getSettingsCache() -> [String: AnyObject] { return getCachedComponent(component: .Settings) }

    public func resetSettingsCache() { resetCachedComponent(component: .Settings) }

    public func syncSettings(completion: @escaping SvcResultCompletion) {
        syncAccountComponent(component: .Settings, completion: completion)
    }

    public func pushSettings(componentData: [String: AnyObject], completion: @escaping SvcResultCompletion) {
        pushAccountComponent(component: .Settings, refresh: true, componentData: componentData, completion: completion)
    }

    public func pullSettings(completion: @escaping SvcResultCompletion) {
        pullAccountComponent(component: .Settings, completion: completion)
    }

    public func getHotWords() -> String {
        return (getSettingsCache()[UMPHotwordKey] as? String) ?? UserManager.defaultHotwords
    }

    public func setHotWords(hotWords: String) {
        pushSettings(componentData: [UMPHotwordKey: hotWords as AnyObject]) { _ in () }
    }

    public func getRefreshFrequency() -> Int {
        return (getSettingsCache()[UMPFrequencyKey] as? Int) ?? UserManager.defaultRefreshFrequency
    }

    public func setRefreshFrequency(frequency: Int) {
        pushSettings(componentData: [UMPFrequencyKey: frequency as AnyObject]) { _ in () }
    }


    // MARK: - Historical ranges for anchor query bulk ingestion

    public func getArchiveSpanCache() -> [String: AnyObject] { return getCachedComponent(component: .ArchiveSpan) }

    public func resetArchiveSpanCache() { resetCachedComponent(component: .ArchiveSpan) }

    // Returns a global historical range over all HKSampleTypes.
    public func getHistoricalRange() -> (TimeInterval, TimeInterval)? {
        let cache = getArchiveSpanCache()
        if let mdict = cache[HMHRangeMinKey] as? [String: AnyObject],
               let edict = cache[HMHRangeEndKey] as? [String: AnyObject]
        {
            let start = mdict.min { (a, b) in return (a.1 as! TimeInterval) < (b.1 as! TimeInterval) }
            let end   = edict.max { (a, b) in return (a.1 as! TimeInterval) < (b.1 as! TimeInterval) }

            if let s = start?.1 as? TimeInterval, let e = end?.1 as? TimeInterval { return (s, e) }
        }
        return nil
    }

    public func getHistoricalRangeForType(type: HKSampleType) -> (TimeInterval, TimeInterval)? {

        let cache = getArchiveSpanCache()
        if let k = seqIdOfSampleTypeId(typeIdentifier: type.identifier),
               let s = cache[HMHRangeStartKey]?[k] as? TimeInterval,
               let e = cache[HMHRangeEndKey]?[k] as? TimeInterval
        {
            return (s, e)
        }
        return nil
    }

    public func initializeHistoricalRangeForType(type: HKSampleType, sync: Bool = false) -> (TimeInterval, TimeInterval) {
        let (start, end) = (decrAnchorDate(d: Date()).timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)

        Async.custom(queue: self.componentUpdateQueue) {
            var cache = self.getArchiveSpanCache()
            if let k = seqIdOfSampleTypeId(typeIdentifier: type.identifier),
               var sdict = cache[HMHRangeStartKey] as? [String: Any],
               var edict = cache[HMHRangeEndKey] as? [String: Any]
            {
                sdict.updateValue(start, forKey: k)
                edict.updateValue(end, forKey: k)
                let newSpan = [HMHRangeStartKey: sdict, HMHRangeEndKey: edict]
                self.deferredPushOnAccountComponent(component: .ArchiveSpan, refresh: true, sync: sync, componentData: newSpan as [String : AnyObject])
            }
        }

        return (start, end)
    }

    public func getHistoricalRangeStartForType(type: HKSampleType) -> TimeInterval? {
        let cache = getArchiveSpanCache()
        if let k = seqIdOfSampleTypeId(typeIdentifier: type.identifier) {
            return cache[HMHRangeStartKey]?[k] as? TimeInterval
        }
        return nil
    }

    public func decrHistoricalRangeStartForType(type: HKSampleType, sync: Bool = false) {
        Async.custom(queue: self.componentUpdateQueue) {
            let cache = self.getArchiveSpanCache()
            if let k = seqIdOfSampleTypeId(typeIdentifier: type.identifier),
                var sdict = cache[HMHRangeStartKey] as? [String: Any],
                let start = sdict[k] as? TimeInterval
            {
                let newDate = self.decrAnchorDate(d: Date(timeIntervalSinceReferenceDate: start)).timeIntervalSinceReferenceDate
                sdict.updateValue(newDate, forKey: k)
                let newSpan = [HMHRangeStartKey: sdict]
                self.deferredPushOnAccountComponent(component: .ArchiveSpan, refresh: true, sync: sync, componentData: newSpan as [String : AnyObject])
            } else {
                log.error("Could not find historical sample range for \(type.identifier)")
            }
        }
    }

    public func getHistoricalRangeMinForType(type: HKSampleType) -> TimeInterval? {
        let cache = getArchiveSpanCache()
        if let k = seqIdOfSampleTypeId(typeIdentifier: type.identifier) {
            return cache[HMHRangeMinKey]?[k] as? TimeInterval
        }
        return nil
    }

    public func setHistoricalRangeMinForType(type: HKSampleType, min: Date, sync: Bool = false) {
        Async.custom(queue: self.componentUpdateQueue) {
            var cache = self.getArchiveSpanCache()
//            if cache[HMHRangeMinKey] == nil { cache[HMHRangeMinKey]   }
            if let k = seqIdOfSampleTypeId(typeIdentifier: type.identifier), var mdict = cache[HMHRangeMinKey] as? [String: AnyObject]
            {
                mdict.updateValue(min.timeIntervalSinceReferenceDate as AnyObject, forKey: k)
                let newSpan = [HMHRangeMinKey: mdict]
                self.deferredPushOnAccountComponent(component: .ArchiveSpan, refresh: true, sync: sync, componentData: newSpan as [String : AnyObject])
            }
        }
    }

    public func decrAnchorDate(d: Date) -> Date {
//        let region = Region()
        return (d - 2.weeks).startOf(component: .day)
    }


    // MARK : - Last acquisition times.

    public func getAcquisitionSeq() -> [HKSampleType: AnyObject] {
        let mcdbSeqs = getCachedComponent(component: .LastAcquired)
        var typedSeqs: [HKSampleType: AnyObject] = [:]
        for (typeId, seqData) in mcdbSeqs {
            if let type = sampleTypeOfTypeId(typeIdentifier: typeId) {
                typedSeqs.updateValue(seqData, forKey: type)
            }
            else {
                log.error("UserManager could not retrieve seq for: \(typeId)")
            }
        }
        return typedSeqs
    }

    public func getAcquisitionSeq(type: HKSampleType) -> AnyObject? {
        return getCachedComponent(component: .LastAcquired)[type.identifier]
    }

    public func resetAcquisitionSeq() { resetCachedComponent(component: .LastAcquired) }

    public func pullAcquisitionSeq(completion: @escaping SvcResultCompletion) {
        pullAccountComponent(component: .LastAcquired, completion: completion)
    }

    public func syncAcquisitionSeq(completion: @escaping SvcResultCompletion) {
        syncAccountComponent(component: .LastAcquired, completion: completion)
    }

    public func setAcquisitionSeq(_ seqs: [String: AnyObject], sync: Bool = false) {
        deferredPushOnAccountComponent(component: .LastAcquired, refresh: true, sync: sync, componentData: seqs)
    }

    public func setAcquisitionSeq(_ typedSeqs: [HKSampleType: AnyObject], sync: Bool = false) {
        var seqs: [String: AnyObject] = [:]
        for (type, seqData) in typedSeqs {
            seqs.updateValue(seqData, forKey: type.identifier)
        }
        setAcquisitionSeq(seqs, sync: sync)
//        setAcquisitionSeq(seqs: seqs, sync: type.identifier)
    }


    // MARK : - Naming functions
//    func hkToMCDB(key: String) -> String? { return HMConstants.sharedInstance.hkToMCDB[key] }
//    func mcdbToHK(key: String) -> String? { return HMConstants.sharedInstance.mcdbToHK[key] }

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

    func lastAcquiredClientId(key: String) -> String? { return sampleTypeIdOfSeqId(anchorIdentifier: key) }
    func lastAcquiredServerId(key: String) -> String? { return seqIdOfSampleTypeId(typeIdentifier: key) }


    // MARK : - Utility functions

    func withUserId (completion: ((String) -> Void)) {
        if let user = userId { completion(user) }
        else { log.error("No user id available") }
    }

    func withUserPass (password: String?, completion: ((String, String) -> Void)) {
        if let user = userId, let pass = password { completion(user, pass) }
        else { log.error("No user/password available") }
    }

    func withUserPass (username: String?, password: String?, completion: ((String, String) -> Void)) {
        if let user = username, let pass = password { completion(user, pass) }
        else { log.error("No user/password available") }
    }

    // Resets all user-specific data, but preserves the last user id.
    public func resetUser() {
        resetAccount()
        resetAccountComponents(components: [.Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired])
    }

    // Resets all user-related data, including the user id.
    public func resetFull() {
        resetAccount()
        resetAccountComponents(components: [.Consent, .Photo, .Profile, .Settings, .ArchiveSpan, .LastAcquired])
        resetUserId()
    }


    // MARK: - User Profile photo

    // set profile photo - return is success result
    public func setUserProfilePhoto(photo: UIImage?) -> Bool {
        var result = false

        if let url = userProfilePhotoUrl() {

            if let ph = photo {
                // save photo
                _ = UIImagePNGRepresentation(ph)
//                result = imageData!.writeToURL(url, atomically: false)
            }

            else {
                // remove if exists

                let fileManager = FileManager.default

                let urlPathStr = url.absoluteString

                if fileManager.fileExists(atPath: urlPathStr!) {
                    do {
                        try fileManager.removeItem(atPath: urlPathStr!)
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
            _ =  user + ".png"

            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

//            let imageURL = documentsURL.URLByAppendingPathComponent(photoFileName)

//            return imageURL
        }

        return nil
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
        return HMConstants.sharedInstance.defaultToMetricUnits!
    }

    public func userUnitsForType(type: HKSampleType) -> HKUnit? {
        return type.unitForSystem(useMetricUnits())
    }

    // MARK: - Default meal & activity times

    //setting usual time when user goes to sleep
    public func setUsualWhenToSleepTime(date: Date) {
        if let user = userId {
            let key = "usualWhenToSleepTime"+user
            Defaults.set(date, forKey: key)
            Defaults.synchronize()
        }
    }
    //setting usual duration user sleeping
    public func setUsualWokeUpTime(date: Date) {
        if let user = userId {
            let key = "usualSleepDuration"+user
            Defaults.set(date, forKey: key)
            Defaults.synchronize()
        }
    }

    public func getUsualWhenToSleepTime() -> Date? {
        if let user = userId {
            let key = "usualWhenToSleepTime"+user
            let date = Defaults.object(forKey: key)
            if let d = date as? Date {
                return floorDate(date: d, granularity: granularity5Mins)
            }
        }
        return nil
    }

    public func getUsualWokeUpTime() -> Date? {
        if let user = userId {
            let key = "usualSleepDuration"+user
            let duration = Defaults.object(forKey: key)
            if let d = duration as? Date {
                return floorDate(date: d, granularity: granularity5Mins)
            }
        }
        return nil
    }

    //setting ususal date for meals
    public func setUsualMealTime(mealType: String, forDate date: Date) {
        if let user = userId {
            let key = mealType+user
            Defaults.set(date, forKey: key)
            Defaults.synchronize()
        }
    }

    //get usual date for meals
    public func getUsualMealTime(mealType: String) -> Date? {
        if let user = userId, Defaults.hasKey(mealType+user) {
            let key = mealType+user
            let dateOfMeal = Defaults.object(forKey: key)
            if let d = dateOfMeal as? Date {
                return floorDate(date: d, granularity: granularity5Mins)
            }

        }
        return nil
    }

}
