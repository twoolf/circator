//
//  ServiceAPI.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/14/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Alamofire

enum MCRouter : URLRequestConvertible {
    static let baseURLString = "https://app.metaboliccompass.com"
    static var OAuthToken: String?
    
    case UploadHKMeasures([String: AnyObject])
    case DownloadAggMeasures([String: AnyObject])

    var method: Alamofire.Method {
        switch self {
        case .UploadHKMeasures:
            return .POST
        case .DownloadAggMeasures:
            return .GET
        }
    }
    
    var path: String {
        switch self {
        case .UploadHKMeasures:
            return "/measures"
        case .DownloadAggMeasures:
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

        case .DownloadAggMeasures(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        }
    }
}