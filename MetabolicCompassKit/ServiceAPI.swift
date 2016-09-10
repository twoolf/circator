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
import SwiftyBeaver

let log = SwiftyBeaver.self


public typealias SvcResultCompletion = (RequestResult) -> Void


private let apiPathComponent = "/api/v1"

private let asDevService   = false
private let devServiceURL  = NSURL(string: "https://api-dev.metaboliccompass.com")!
private let devApiURL      = devServiceURL.URLByAppendingPathComponent(apiPathComponent)
private let prodServiceURL = NSURL(string: "https://api.metaboliccompass.com")!
private let prodApiURL     = prodServiceURL.URLByAppendingPathComponent(apiPathComponent)


private let resetPassDevURL  = devServiceURL.URLByAppendingPathComponent("/forgot")
private let resetPassProdURL = prodServiceURL.URLByAppendingPathComponent("/forgot")
public  let resetPassURL     = asDevService ? resetPassDevURL : resetPassProdURL

public let aboutURL         = (asDevService ? devServiceURL : prodServiceURL).URLByAppendingPathComponent("about")
public let privacyPolicyURL = (asDevService ? devServiceURL : prodServiceURL).URLByAppendingPathComponent("privacy")

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
    
    public var error:NSError? = nil
    public var ok:Bool {
        switch resType {
        case .BoolWithMessage:
            return _ok ?? false
        case .AFObject:
            let afObjRes = _obj as? Alamofire.Result<AnyObject>
            return afObjRes?.isSuccess ?? false
        case .AFString:
            let afStrRes = _obj as? Alamofire.Result<String>
            return afStrRes?.isSuccess ?? false
        case .Error:
            let err = _obj as? NSError
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
            let afRes = _obj as? Alamofire.Result<AnyObject>
            return (afRes?.error as? NSError)?.localizedDescription ?? ""
        case .AFString:
            let afRes = _obj as? Alamofire.Result<String>
            return (afRes?.error as? NSError)?.localizedDescription ?? ""
        case .Error:
            let err = _obj as? NSError
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
    init(afObjectResult: Alamofire.Result<AnyObject>) {
        resType = .AFObject
        _obj = afObjectResult
    }
    init(afStringResult: Alamofire.Result<String>) {
        resType = .AFString
        _obj = afStringResult
    }
    init(error: NSError) {
        resType = .Error
        _obj = error
    }
    

}


/**
 This class sets up the needed API for all of the reads/writes to our cloud data store.  This is needed to support our ability to add new aggregate information into the data store and to update the display on our participants screens as new information is deposited into the store.

 - note: uses Alamofire/JSON
 - remark: authentication using OAuthToken
 */
enum MCRouter : URLRequestConvertible {
    static let baseURL = asDevService ? devServiceURL : prodServiceURL
    static let apiURL  = asDevService ? devApiURL : prodApiURL
    static var OAuthToken: String?
    static var tokenExpireTime: NSTimeInterval = 0

    static func updateAuthToken (token: String?) {
        OAuthToken = token
        tokenExpireTime = token != nil ? NSDate().timeIntervalSince1970 + 3600: 0
    }

    // Data API
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

    // Token management API
    case TokenExpiry

    var method: Alamofire.Method {
        switch self {
        case .AddMeasures:
            return .POST

        case .AddSeqMeasures:
            return .POST

        case .RemoveMeasures:
            return .POST

        case .AggregateMeasures:
            return .GET

        case .StudyStats:
            return .GET

        case .DeleteAccount:
            return .POST

        case .GetUserAccountData:
            return .GET

        case .SetUserAccountData:
            return .POST

        case .TokenExpiry:
            return .GET
        }
    }

    var path: String {
        switch self {
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

        case .TokenExpiry:
            return "/user/expiry"
        }
    }

    // MARK: URLRequestConvertible

    var URLRequest: NSMutableURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: MCRouter.apiURL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue

        if let token = MCRouter.OAuthToken {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        switch self {
        case .AddMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .AddSeqMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .RemoveMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .AggregateMeasures(let parameters):
            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0

        case .StudyStats:
            return mutableURLRequest

        case .DeleteAccount(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .GetUserAccountData(let components):
            let parameters = ["components": components.map(getComponentName)]
            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0

        case .SetUserAccountData(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .TokenExpiry:
            return mutableURLRequest
        }
    }

}

public protocol ServiceRequestResultDelegate {
    func didFinishJSONRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<AnyObject>)
    func didFinishStringRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<String>)
}

public class Service {
    public static var delegate:ServiceRequestResultDelegate?
    internal static func string<S: SequenceType where S.Generator.Element == Int>
        (route: MCRouter, statusCode: S, tag: String,
        completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<String>) -> Void)
        -> Alamofire.Request
    {
        return Alamofire.request(route).validate(statusCode: statusCode).logResponseString(tag, completion: completion)
    }

    internal static func json<S: SequenceType where S.Generator.Element == Int>
        (route: MCRouter, statusCode: S, tag: String,
        completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<AnyObject>) -> Void)
        -> Alamofire.Request
    {
        return Alamofire.request(route).validate(statusCode: statusCode).logResponseJSON(tag, completion: completion)
    }
}

extension Alamofire.Request {
    public func logResponseString(tag: String, completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<String>) -> Void)
        -> Self
    {
        return self.responseString() { req, resp, result in
            log.debug("\(tag): " + (result.isSuccess ? "SUCCESS" : "FAILED"))
            if Service.delegate != nil{
                Service.delegate!.didFinishStringRequest(req, response:resp, result:result)
            }
            log.debug("\n***result:\(result)")
            completion(req, resp, result)
        }
    }

    public func logResponseJSON(tag: String, completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<AnyObject>) -> Void)
        -> Self
    {
        return self.responseJSON() { req, resp, result in
            log.debug("\(tag): " + (result.isSuccess ? "SUCCESS" : "FAILED"))
            if Service.delegate != nil{
                Service.delegate!.didFinishJSONRequest(req, response:resp, result:result)
            }
            log.debug("\n***result:\(result)")
            if !result.isSuccess {
                log.debug("\n***response:\(resp)")
                log.debug("\n***error:\(result.error)")
            }
            completion(req, resp, result)
        }
    }
}
