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

public typealias SvcStringCompletion = (Bool, String?) -> Void
public typealias SvcObjectCompletion = (Bool, AnyObject?) -> Void

private let devServiceURL = "https://dev.metaboliccompass.com"
private let prodServiceURL = "https://app.metaboliccompass.com"
private let asDevService = true

private let resetPassDevURL = devServiceURL + "/forgot"
private let resetPassProdURL = prodServiceURL + "/forgot"
public  let resetPassURL = asDevService ? resetPassDevURL : resetPassProdURL

/**
 This class sets up the needed API for all of the reads/writes to our cloud data store.  This is needed to support our ability to add new aggregate information into the data store and to update the display on our participants screens as new information is deposited into the store.

 - note: uses Alamofire/JSON
 - remark: authentication using OAuthToken
 */
enum MCRouter : URLRequestConvertible {
    static let baseURLString = asDevService ? devServiceURL : prodServiceURL
    static var OAuthToken: String?
    static var tokenExpireTime: NSTimeInterval = 0

    static func updateAuthToken (token: String?) {
        OAuthToken = token
        tokenExpireTime = token != nil ? NSDate().timeIntervalSince1970 + 3600: 0
    }

    // Data API
    case UploadHKMeasures([String: AnyObject])
    case AggMeasures([String: AnyObject])

    // User and profile management API
    case GetUserAccountData([AccountComponent])

    case SetUserAccountData([String: AnyObject])
        // For SetUserAccountData, the caller is responsible for constructing
        // the component-specific nesting (e.g, ["consent": "<base64 string>"])

    case DeleteAccount

    // Token management API
    case TokenExpiry([String: AnyObject])

    var method: Alamofire.Method {
        switch self {
        case .UploadHKMeasures:
            return .POST

        case .AggMeasures:
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
        case .UploadHKMeasures:
            return "/measures"

        case .AggMeasures:
            return "/measures/mc/avg"

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
        let URL = NSURL(string: MCRouter.baseURLString)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(path))
        mutableURLRequest.HTTPMethod = method.rawValue

        if let token = MCRouter.OAuthToken {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        switch self {
        case .UploadHKMeasures(var parameters):
            parameters["userid"] = UserManager.sharedManager.getUserIdHash() ?? ""
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .AggMeasures(let parameters):
            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0

        case .DeleteAccount:
            return mutableURLRequest

        case .GetUserAccountData(let components):
            let parameters = ["components": components.map(getComponentName)]
            return Alamofire.ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters).0

        case .SetUserAccountData(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .TokenExpiry(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        }
    }

}

public protocol ServiceRequestResultDelegate {
    func didFinishJSONRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<AnyObject>)
    func didFinishStringRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<String>)
//      func myFunc()
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
//            if let data = req?.HTTPBody{
//                log.debug("\n***Request body:\( String(data:data, encoding:NSUTF8StringEncoding))")
//            }
            
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
        
//            print("request:\(req), response:\(resp)")
//            if req?.URL?.absoluteString == "https://app.metaboliccompass.com/user/expiry"{
//                print("expiry request:\(req), response:\(resp)")
//            }
            if Service.delegate != nil{
                Service.delegate!.didFinishJSONRequest(req, response:resp, result:result)
            }
            log.debug("\(tag): " + (result.isSuccess ? "SUCCESS" : "FAILED"))
            completion(req, resp, result)
        }
    }
}
