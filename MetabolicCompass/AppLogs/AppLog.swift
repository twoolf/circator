//
//  AppLog.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/23/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
//import AppLogManager
import Alamofire
import MetabolicCompassKit

public class SALogger {
    public static let sharedLogger = SALogger()
    
    init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.didReceiveAppLogNotification(_:)), name: "ncAppLogNotification", object: nil)
    }
    
    @objc func didReceiveAppLogNotification(notif:NSNotification){
        print("received notif:\(notif)")
        if let userInfo = notif.userInfo{
            let title = userInfo["title"] as? String ?? ""
            let err = userInfo["error"] as? NSError
            if err != nil{
                addSAError(title, error:err!)
            }
            else{
                if let obj = userInfo["obj"] as? CustomStringConvertible{
                    addSALogObj(title, obj)
                }
                else{
                    addSALog(title)
                }
            }
//            for (key, value) in userInfo{
//                if let strKey = key as? String{
//                    if let printable = value as? CustomStringConvertible{
//                        addSALogObj(strKey, printable)
//                    }
//                }
//            }
        }
        
    }
}

extension SALogger: ServiceRequestResultDelegate {
    public func didFinishJSONRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<AnyObject>) {
        addSARequestLog(request, response: response, result: result)
    }
    public func didFinishStringRequest(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<String>) {
        addSARequestLog(request, response: response, result: result)
    }
    public func myFunc(){}
}

public func addSALog(str:String){
    //print("ok log:\(title)")
    //[[AppLogManager sharedInstance] addAppLogItem:[AppLogMethodItem newWithValues:@{kAppLogNotShownTitleKey: str ?: @""}]];
    let item = AppLogMethodItem.newWithValues([kAppLogNotShownTitleKey: str])
    AppLogManager.sharedInstance().addAppLogItem(item)
}

public func addSAError(title:String, error:NSError){
    //print("ok log:\(title)")
    //[[AppLogManager sharedInstance] addAppLogItem:[AppLogMethodItem newWithValues:@{kAppLogNotShownTitleKey: str ?: @""}]];
    //let err = NSError(domain: "App error", code: 0, userInfo: [NSLocalizedDescriptionKey:errorInfo])
    let item = AppLogMethodItem.newWithTitle(title, error: error)
    AppLogManager.sharedInstance().addAppLogItem(item)
}


public func addSALogObj(title:String, _ obj:CustomStringConvertible){
    //print("ok log:\(title)")
    //[[AppLogManager sharedInstance] addAppLogItem:[AppLogMethodItem newWithValues:@{kAppLogNotShownTitleKey: str ?: @""}]];
    let item = AppLogMethodItem.newWithValues([kAppLogNotShownTitleKey: String(format: "%@:%@", title, obj.description)])
    AppLogManager.sharedInstance().addAppLogItem(item)
}

public func addSARequestLog(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<String>){
    let reqResult = NetworkRequestResult()
    reqResult.request = request
    reqResult.response = response
    reqResult.responseObject = result.value
    reqResult.error = result.error as? NSError
    let item = AppLogNetworkRequestItem.newWithRequestResult(reqResult)
    AppLogManager.sharedInstance().addAppLogItem(item)
}

public func addSARequestLog(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<AnyObject>){
    let reqResult = NetworkRequestResult()
    reqResult.request = request
    reqResult.response = response
    reqResult.error = result.error as? NSError
    reqResult.responseObject = result.value
    let item = AppLogNetworkRequestItem.newWithRequestResult(reqResult)
    AppLogManager.sharedInstance().addAppLogItem(item)
}

