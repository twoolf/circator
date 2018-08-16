//
//  ServiceAPI.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/14/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import Alamofire
import Auth0

public typealias SvcResultCompletion = (RequestResult) -> Void

private let apiPathComponent = "/api/v1"

#if DEVSERVICE
private let srvURL = NSURL(string: "https://api-dev.metaboliccompass.com")!
private let wwwURL = NSURL(string: "https://www-dev.metaboliccompass.com")!
#else
private let srvURL = NSURL(string: "https://api.metaboliccompass.com")!
private let wwwURL = NSURL(string: "https://www.metaboliccompass.com")!
#endif
private let auth0URL = NSURL(string: "https://metaboliccompass.auth0.com")!

public class  RequestResult{
    private var _obj:Any? = nil
    //private var infoMsg:String? = nil
    private var _ok:Bool?
    
    enum ResultType{
        case BoolWithMessage
        case Error
        case AFObject
        case AFString
    }
    private var resType:ResultType
    
    public var error:Error? = nil
    public var ok:Bool {
        switch resType {
        case .BoolWithMessage:
            return _ok ?? false
        case .AFObject:
            let afObjRes = _obj as? Alamofire.Result<Any>
            return afObjRes?.isSuccess ?? false
        case .AFString:
            let afStrRes = _obj as? Alamofire.Result<String>
            return afStrRes?.isSuccess ?? false
        case .Error:
            let err = _obj as? Error
            return (err == nil)
        }
    }
    
    public var fail:Bool {
        return !ok
    }
    
    public var info:String {
        switch resType {
        case .BoolWithMessage:
            return _obj as? String ?? ""
        case .AFObject:
            let afRes = _obj as? Alamofire.Result<Any>
            return ((afRes?.error)! as Error).localizedDescription
        case .AFString:
            let afRes = _obj as? Alamofire.Result<String>
            return ((afRes?.error)! as Error).localizedDescription
        case .Error:
            let err = _obj as? Error
            return err?.localizedDescription ?? ""
        }
    }
    
    init() {
        resType = .BoolWithMessage
        _ok = true
    }
    init(ok:Bool, message:String) {
        resType = .BoolWithMessage
        _ok = ok
        _obj = message
    }
    init(errorMessage: String) {
        resType = .BoolWithMessage
        _ok = false
        _obj = errorMessage
    }
    init(afObjectResult: Alamofire.Result<Any>) {
        resType = .AFObject
        _obj = afObjectResult
    }
    init(afStringResult: Alamofire.Result<String>) {
        resType = .AFString
        _obj = afStringResult
    }
    init(error: Error) {
        resType = .Error
        _obj = error
    }
    

}


/**
 This class sets up the needed API for all of the reads/writes to our cloud data store.  This is needed to support our ability to add new aggregate information into the data store and to update the display on our participants screens as new information is deposited into the store.

 - note: uses Alamofire/JSON
 - remark: authentication using OAuthToken
 */
public enum MCRouter : URLRequestConvertible {
    public static let baseURL          = srvURL
    public static let apiURL           = srvURL.appendingPathComponent(apiPathComponent)
    public static let resetPassURL     = srvURL.appendingPathComponent("forgot")
    public static let aboutURL         = wwwURL.appendingPathComponent("about")
    public static let privacyPolicyURL = wwwURL.appendingPathComponent("privacy")
    public static let auth0apiURL         = auth0URL

    // Data API
    case GetMeasures([String: AnyObject])
    case AddMeasures([String: AnyObject])
    case AddSeqMeasures([String: AnyObject])
    case RemoveMeasures([String: AnyObject])
    case AggregateMeasures([String: AnyObject])
    case StudyStats

    // User and profile management API
    case GetUserAccountData([AccountComponent])

    case SetUserAccountData([String: AnyObject])
        // For SetUserAccountData, the caller is responsible for constructing
        // the component-specific nesting (e.g, ["consent": "<base64 string>"])

    case DeleteAccount([String: AnyObject])
    
    // Remote logging API 
    case RLogConfig
  
    case Auth0login([Auth0Component])
    
    var method: HTTPMethod {
        switch self {
        case .GetMeasures:
            return .get

        case .AddMeasures:
            return .post

        case .AddSeqMeasures:
            return .post

        case .RemoveMeasures:
            return .post

        case .AggregateMeasures:
            return .get

        case .StudyStats:
            return .get

        case .DeleteAccount:
            return .post

        case .GetUserAccountData:
            return .get

        case .SetUserAccountData:
            return .post

        case .RLogConfig:
            return .get
            
        case .Auth0login:
            return .post
        }
    }

    var path: String {
        switch self {
        case .GetMeasures:
            return "/measures/mc"

        case .AddMeasures:
            return "/measures"

        case .AddSeqMeasures:
            return "/measures/granolalog"

        case .RemoveMeasures:
            return "/measures/mc/delete"

        case .AggregateMeasures:
            return "/measures/mc/dbavg"

        case .StudyStats:
            return "/user/studystats"

        case .DeleteAccount:
            return "/user/withdraw"

        case .GetUserAccountData(_), .SetUserAccountData(_):
            return "/user/account"

        case .RLogConfig:
            return "/user/rlogconfig"
            
        case .Auth0login:
            return ""
        }
    }

    // MARK: URLRequestConvertible

    public func asURLRequest() throws -> URLRequest {
        var mutableURLRequest = URLRequest(url: MCRouter.baseURL.appendingPathComponent(path)!)

        mutableURLRequest.httpMethod = method.rawValue
        
        switch self {
        case .GetMeasures(let parameters):
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .AddMeasures(let parameters):
            return try Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)

        case .AddSeqMeasures(let parameters):
            return try Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)

        case .RemoveMeasures(let parameters):
            return try Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)

        case .AggregateMeasures(let parameters):
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .StudyStats:
            return mutableURLRequest

        case .DeleteAccount(let parameters):
            return try Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)

        case .GetUserAccountData(let components):
            let parameters = ["components": components.map(getComponentName)]
            return try URLEncoding.default.encode(mutableURLRequest as URLRequestConvertible, with: parameters)

        case .SetUserAccountData(let parameters):
            return try Alamofire.JSONEncoding.default.encode(mutableURLRequest, with: parameters)

        case .RLogConfig:
            return mutableURLRequest
            
        case .Auth0login:
            return try URLEncoding.default.encode(mutableURLRequest, with: nil)
        }
    }

}

public protocol ServiceRequestResultDelegate {
    func didFinishJSONRequest(request:NSURLRequest?, response:HTTPURLResponse?, result:Alamofire.Result<Any>)
    func didFinishStringRequest(request:NSURLRequest?, response:HTTPURLResponse?, result:Alamofire.Result<String>)
}

public class Service: RequestRetrier, RequestAdapter {
    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        tokenLockQueue.sync {
            if let token = OAuthToken {
                urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        return urlRequest
    }
    
    
    private var OAuthToken: String?
    private var OAuthRefreshToken: String?
    
    func updateAuthToken (token: String?, refreshToken: String?) {
        tokenLockQueue.sync {
            OAuthToken = token
            OAuthRefreshToken = refreshToken
        }
    }
    
    private let tokenLockQueue = DispatchQueue(label: "sessionManagerLockQueue")
    static let shared = Service()
    public var delegate:ServiceRequestResultDelegate?
    private let sessionManager: SessionManager
    
    init() {
//        sessionManager = SessionManager.default
        sessionManager = SessionManager(configuration: URLSessionConfiguration.default, serverTrustPolicyManager: ServerTrustPolicyManager(policies: ["api-dev.metaboliccompass.com": .disableEvaluation]))
        sessionManager.retrier = self
        sessionManager.adapter = self
    }
    
    internal func string<S: Sequence>(route: MCRouter, statusCode: S, tag: String,
                                             tokenRefreshed: Bool = false,
                                            completion: @escaping (NSURLRequest?, HTTPURLResponse?, Alamofire.Result<String>) -> Void)
        -> Alamofire.Request where S.Iterator.Element == Int
    {
        return sessionManager.request(route).validate(statusCode: statusCode).responseString { response in
            log.debug("\(tag): " + (response.result.isSuccess ? "SUCCESS" : "FAILED"))
            if self.delegate != nil{
                self.delegate!.didFinishStringRequest(request: response.request as NSURLRequest?, response:response.response, result:response.result)
            }
            log.debug("\n***result:\(response.result)")
            completion(response.request as NSURLRequest?, response.response, response.result)
        }
    }
    
    internal func json<S: Sequence>(route: MCRouter, statusCode: S, tag: String,
                                           tokenRefreshed: Bool = false,
                                           completion: @escaping (NSURLRequest?, HTTPURLResponse?, Alamofire.Result<Any>) -> Void)
                                           -> Alamofire.Request where S.Iterator.Element == Int
    {
        return sessionManager.request(route)
            .validate(statusCode: statusCode)
            .responseJSON { response in
                log.debug("\(tag): " + (response.result.isSuccess ? "SUCCESS" : "FAILED"))
                if response.result.value != nil {
                    if self.delegate != nil{
                        self.delegate!.didFinishJSONRequest(request: response.request as NSURLRequest?, response:response.response, result:response.result)
                    }
                    log.debug("\n***result:\(response.result)")
                    completion(response.request as NSURLRequest?, response.response, response.result)
                } else {
                    completion(response.request as NSURLRequest?, response.response, response.result)
                }
            }
    }
    
    typealias RenewCallback = (Bool)->()
    let renewLockQueue = DispatchQueue(label: "syncCallbacksQueue")
    var renewCallbacks = [RenewCallback]()
    private let maxRetryCount = 1
    
    // MARK:
    public func should(_ manager: SessionManager, retry request: Alamofire.Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        if let response = request.task?.response as? HTTPURLResponse,
            (response.statusCode == 401), (request.retryCount < maxRetryCount) {
            self.renewToken { success in
                if success {
                    completion(true, 0.1)
                } else {
                    completion(false, 0.0)
                }
            }
        } else {
            let shouldRetry = (request.retryCount < maxRetryCount)
            completion(shouldRetry, shouldRetry ? 0.1 : 0.0)
        }
    }

    private func renewToken(callback : @escaping RenewCallback) {
        renewLockQueue.sync {
            self.renewCallbacks.append(callback)
            if self.renewCallbacks.count == 1 {
                Auth0
                    .authentication()
                    .renew(withRefreshToken: self.OAuthRefreshToken ?? "")
                    .start { result in
                        switch(result) {
                        case .success(let credentials):
                            AuthSessionManager.shared.storeTokens(credentials.accessToken ?? "")
                            self.updateAuthToken(token: credentials.accessToken, refreshToken: self.OAuthRefreshToken)
                            self.renewLockQueue.sync {
                                self.renewCallbacks.forEach { $0(true) }
                                self.renewCallbacks.removeAll()
                            }
                        case .failure:
                            self.renewLockQueue.sync {
                                self.renewCallbacks.forEach { $0(false) }
                                self.renewCallbacks.removeAll()
                            }
                        }
                }
            }
        }
    }
}
