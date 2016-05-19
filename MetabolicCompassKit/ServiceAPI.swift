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
private let asDevService = false

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
    case MealMeasures([String: AnyObject])

    // Timestamps API
    case UploadHKTSAcquired([String: AnyObject])

    // User and profile management API
    case GetUserAccountData
    case SetUserAccountData([String: AnyObject])
    case DeleteAccount

    case GetConsent
    case SetConsent([String: AnyObject])

    case TokenExpiry([String: AnyObject])

    var method: Alamofire.Method {
        switch self {
        case .UploadHKMeasures:
            return .POST

        case .AggMeasures:
            return .POST

        case .MealMeasures:
            return .GET

        case .UploadHKTSAcquired:
            return .POST

        case .DeleteAccount:
            return .POST

        case .GetUserAccountData:
            return .GET

        case .SetUserAccountData:
            return .POST

        case GetConsent:
            return .GET

        case SetConsent:
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
            return "/measures/aggregates"

        case .MealMeasures:
            return "/measures/meals"

        case .UploadHKTSAcquired:
            return "/timestamps/acquired"

        case .DeleteAccount:
            return "/user/withdraw"

        case .GetUserAccountData, .SetUserAccountData:
            return "/user/profile"

        case .GetConsent, .SetConsent:
            return "/user/consent"

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
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .MealMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .UploadHKTSAcquired(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .DeleteAccount:
            return mutableURLRequest

        case .GetUserAccountData:
            return mutableURLRequest

        case .SetUserAccountData(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .GetConsent:
            return mutableURLRequest

        case .SetConsent(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .TokenExpiry(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        }
    }

}

public class Service {
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
            log.debug("\n***Req:\(req)")
            if let data = req?.HTTPBody{
                log.debug("\n***Request body:\( String(data:data, encoding:NSUTF8StringEncoding))")
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
            completion(req, resp, result)
        }
    }
}
