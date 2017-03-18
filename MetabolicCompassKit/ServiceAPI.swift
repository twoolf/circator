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

public typealias SvcResultCompletion = (RequestResult) -> Void

private let apiPathComponent = "/api/v1"

#if DEVSERVICE
private let srvURL = NSURL(string: "https://api-dev.metaboliccompass.com")!
private let wwwURL = NSURL(string: "https://www-dev.metaboliccompass.com")!
#else
private let srvURL = NSURL(string: "https://api.metaboliccompass.com")!
private let wwwURL = NSURL(string: "https://www.metaboliccompass.com")!
#endif


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
            let afObjRes = _obj as? Alamofire.Result<AnyObject, NSError>
            return afObjRes?.isSuccess ?? false
        case .AFString:
            let afStrRes = _obj as? Alamofire.Result<String, NSError>
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
            let afRes = _obj as? Alamofire.Result<AnyObject, NSError>
            return ((afRes?.error)! as NSError).localizedDescription ?? ""
        case .AFString:
            let afRes = _obj as? Alamofire.Result<String, NSError>
            return ((afRes?.error)! as NSError).localizedDescription ?? ""
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
    init(afObjectResult: Alamofire.Result<AnyObject, NSError>) {
        resType = .AFObject
        _obj = afObjectResult
    }
    init(afStringResult: Alamofire.Result<String, NSError>) {
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
public enum MCRouter : URLRequestConvertible {
    public static let baseURL          = srvURL
    public static let apiURL           = srvURL.URLByAppendingPathComponent(apiPathComponent)
    public static let resetPassURL     = srvURL.URLByAppendingPathComponent("forgot")
    public static let aboutURL         = wwwURL.URLByAppendingPathComponent("about")
    public static let privacyPolicyURL = wwwURL.URLByAppendingPathComponent("privacy")

    static var OAuthToken: String?
    static var tokenExpireTime: NSTimeInterval = 0

    static func updateAuthToken (token: String?) {
        OAuthToken = token
        tokenExpireTime = token != nil ? NSDate().timeIntervalSince1970 + 3600: 0
    }

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

    // Token management API
    case TokenExpiry

    // Remote logging API
    case RLogConfig

    var method: Alamofire.Method {
        switch self {
        case .GetMeasures:
            return .GET

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

        case .RLogConfig:
            return .GET
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

        case .TokenExpiry:
            return "/user/expiry"

        case .RLogConfig:
            return "/user/rlogconfig"
        }
    }

    // MARK: URLRequestConvertible

    public var URLRequest: NSMutableURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: MCRouter.apiURL!.URLByAppendingPathComponent(path)!)
        mutableURLRequest.HTTPMethod = method.rawValue

        if let token = MCRouter.OAuthToken {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        switch self {
        case .GetMeasures(let parameters):
            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0

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

        case .RLogConfig:
            return mutableURLRequest
        }
    }

}

public protocol ServiceRequestResultDelegate {
    func didFinishJSONRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<AnyObject, NSError>)
    func didFinishStringRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<String, NSError>)
}



public class Service {
    public static var delegate:ServiceRequestResultDelegate?
    internal static func string<S: SequenceType where S.Generator.Element == Int>
        (route: MCRouter, statusCode: S, tag: String,
         completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<String, NSError>) -> Void)
        -> Alamofire.Request
    {
        return Alamofire.request(route).validate(statusCode: statusCode).responseString { response in
            log.debug("\(tag): " + (response.result.isSuccess ? "SUCCESS" : "FAILED"))
            if Service.delegate != nil{
                Service.delegate!.didFinishStringRequest(response.request, response:response.response, result:response.result)
            }
            log.debug("\n***result:\(response.result)")
            completion(response.request, response.response, response.result)
        }
    }
    
    internal static func json<S: SequenceType where S.Generator.Element == Int>
        (route: MCRouter, statusCode: S, tag: String,
         completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<AnyObject,NSError>) -> Void)
        -> Alamofire.Request
    {
        return Alamofire.request(route).validate(statusCode: statusCode).responseJSON { response in
            log.debug("\(tag): " + (response.result.isSuccess ? "SUCCESS" : "FAILED"))
            if let json = response.result.value {
                if Service.delegate != nil{
                    Service.delegate!.didFinishJSONRequest(response.request, response:response.response, result:response.result)
                }
                log.debug("\n***result:\(response.result)")
            completion(response.request, response.response, response.result)
        }
    }
  }
}

/*extension Alamofire.Request {
    public func logResponseString(tag: String, completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<String,NSError>) -> Void)
        ->
    {
        return self.responseString() { req, resp, result in
            log.debug("\(tag): " + (result.isSuccess ? "SUCCESS" : "FAILED"))
            if Service.delegate != nil{
                Service.delegate!.didFinishStringRequest(req, response:resp, result:result)
            }
            log.debug("\n***result:\(result)")
            completion(req, resp, result)
        }
    } */
    
/*    public func logResponseJSON(tag: String, completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<AnyObject,NSError>) -> Void)
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
}*/

/*extension Alamofire.Request {
    public func logResponseString(tag: String, completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<String, NSError>) -> Void)
         -> Self
         {
         return self.responseString() { req, resp, result.value in
         log.debug("\(tag): " + (result.isSuccess ? "SUCCESS" : "FAILED"))
         if Service.delegate != nil{
         Service.delegate!.didFinishStringRequest(req, response:resp, result:result)
         }
         log.debug("\n***result:\(result)")
         completion(req, resp, result)
         }
         }
         
    public func logResponseJSON(tag: String, completion: (NSURLRequest?, NSHTTPURLResponse?, Alamofire.Result<AnyObject, NSError>) -> Void)
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
} */

/*        return Alamofire.request(route).validate(statusCode: statusCode).responseString { response in
 switch response.result {
 case .Success(let value):
 completion(response.request!, response.response!, value)
 case .Failure:
 completion(response.request!, response.response!, response.result as! String)
 } */

/*        return Alamofire.request(route).validate(statusCode: statusCode).responseJSON { response in
 switch response.result {
 case .Success(let value):
 completion(response.request!, response.response!, value)
 case .Failure(let error):
 completion(response.request!, response.response!, error)
 } */
