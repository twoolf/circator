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

enum MCRouter : URLRequestConvertible {
    static let baseURLString = "https://app.metaboliccompass.com"
    static var OAuthToken: String?

    case UploadHKMeasures([String: AnyObject])
    case AggMeasures([String: AnyObject])
    case MealMeasures([String: AnyObject])

    var method: Alamofire.Method {
        switch self {
        case .UploadHKMeasures:
            return .POST
        case .AggMeasures:
            return .POST
        case .MealMeasures:
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
        case .UploadHKMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .AggMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0

        case .MealMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
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
