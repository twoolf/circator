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

//#if DEVSERVICE
private let srvURL = NSURL(string: "https://api-dev.metaboliccompass.com")!
private let wwwURL = NSURL(string: "https://www-dev.metaboliccompass.com")!
//#else
//private let srvURL = NSURL(string: "https://api.metaboliccompass.com")!
//private let wwwURL = NSURL(string: "https://www.metaboliccompass.com")!
//#endif


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
            return ((afRes?.error)! as Error).localizedDescription ?? ""
        case .AFString:
            let afRes = _obj as? Alamofire.Result<String>
            return ((afRes?.error)! as Error).localizedDescription ?? ""
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

    static var OAuthToken: String?
    static var tokenExpireTime: TimeInterval = 0

    static func updateAuthToken (token: String?) {
        OAuthToken = token
        tokenExpireTime = token != nil ? Date().timeIntervalSince1970 + 3600: 0
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

        case .TokenExpiry:
            return .get

        case .RLogConfig:
            return .get
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

    public func asURLRequest() throws -> URLRequest {
//        let mutableURLRequest = NSMutableURLRequest(URL: MCRouter.apiURL!.URLByAppendingPathComponent(path)!)
        let baseURL = try MCRouter.baseURL
        var mutableURLRequest = URLRequest(url: baseURL.appendingPathComponent(path)!)
//        mutableURLRequest.appendingPathComponent(method.rawValue)

        mutableURLRequest.httpMethod = method.rawValue
        if let token = MCRouter.OAuthToken {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        switch self {
        case .GetMeasures(let parameters):
//            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .AddMeasures(let parameters):
//            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
//            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .AddSeqMeasures(let parameters):
//            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .RemoveMeasures(let parameters):
//            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .AggregateMeasures(let parameters):
//            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .StudyStats:
            return try mutableURLRequest

        case .DeleteAccount(let parameters):
//            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .GetUserAccountData(let components):
            let parameters = ["components": components.map(getComponentName)]
            return try URLEncoding.default.encode(mutableURLRequest as URLRequestConvertible, with: parameters)

        case .SetUserAccountData(let parameters):
//            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            return try URLEncoding.default.encode(mutableURLRequest, with: parameters)

        case .TokenExpiry:
            return try mutableURLRequest
//            return try URLEncoding.default.encode(<#T##urlRequest: URLRequestConvertible##URLRequestConvertible#>, with: <#T##Parameters?#>)

        case .RLogConfig:
            return mutableURLRequest
        }
    }

}

public protocol ServiceRequestResultDelegate {
    func didFinishJSONRequest(request:NSURLRequest?, response:HTTPURLResponse?, result:Alamofire.Result<Any>)
    func didFinishStringRequest(request:NSURLRequest?, response:HTTPURLResponse?, result:Alamofire.Result<String>)
}


public class Service {
    public static var delegate:ServiceRequestResultDelegate?
    internal static func string<S: Sequence>
        (route: MCRouter, statusCode: S, tag: String,
         completion: @escaping (NSURLRequest?, HTTPURLResponse?, Alamofire.Result<String>) -> Void)
        -> Alamofire.Request where S.Iterator.Element == Int
    {
        return Alamofire.request(route).validate(statusCode: statusCode).responseString { response in
            log.debug("\(tag): " + (response.result.isSuccess ? "SUCCESS" : "FAILED"))
            if Service.delegate != nil{
                Service.delegate!.didFinishStringRequest(request: response.request as NSURLRequest?, response:response.response, result:response.result)
            }
            log.debug("\n***result:\(response.result)")
            completion(response.request as NSURLRequest?, response.response, response.result)
        }
    }
    
    internal static func json<S: Sequence>
        (route: MCRouter, statusCode: S, tag: String,
         completion: @escaping (NSURLRequest?, HTTPURLResponse?, Alamofire.Result<Any>) -> Void)
        -> Alamofire.Request where S.Iterator.Element == Int
    {
        return Alamofire.request(route).validate(statusCode: statusCode).responseJSON { response in
            log.debug("\(tag): " + (response.result.isSuccess ? "SUCCESS" : "FAILED"))
            if let json = response.result.value {
                if Service.delegate != nil{
                    Service.delegate!.didFinishJSONRequest(request: response.request as NSURLRequest?, response:response.response, result:response.result)
                }
                log.debug("\n***result:\(response.result)")
            completion(response.request as NSURLRequest?, response.response, response.result)
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
