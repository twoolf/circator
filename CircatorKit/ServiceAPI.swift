//
//  ServiceAPI.swift
//  Circator
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

enum MCRouter : URLRequestConvertible {
    static let baseURLString = "https://app.metaboliccompass.com"
    static var OAuthToken: String?

    // Data API
    case UploadHKMeasures([String: AnyObject])
    case AggMeasures([String: AnyObject])
    case MealMeasures([String: AnyObject])

    // User management API
    case UserToken([String: AnyObject])

    // Stormpath wrapper API
    case GetUserAccountData([String: AnyObject])
    case SetUserAccountData([String: AnyObject])
    case TokenExpiry([String: AnyObject])

    var method: Alamofire.Method {
        switch self {
        case .UploadHKMeasures:
            return .POST

        case .AggMeasures:
            return .POST

        case .MealMeasures:
            return .GET

        case .UserToken:
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
            return "/measures/aggregates"

        case .MealMeasures:
            return "/measures/meals"

        case .UserToken:
            return "/measures"

        case .GetUserAccountData, .SetUserAccountData:
            return "/profile"

        case .TokenExpiry:
            return "/expiry"
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
            parameters["userid"] = MCRouter.OAuthToken ?? ""
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .AggMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .MealMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .UserToken(var parameters):
            parameters["userid"] = UserManager.sharedManager.getUserIdHash() ?? ""
            parameters["token"] = MCRouter.OAuthToken ?? ""
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .GetUserAccountData(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .SetUserAccountData(let parameters):
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

// A simple struct to store derived quantities computed at the server.
public class DerivedQuantity : Result {
    var quantity : Double? = nil
    var quantityType : HKSampleType? = nil

    public init(quantity: Double?, quantityType: HKSampleType?) {
        self.quantity = quantity
        self.quantityType = quantityType
    }
}
