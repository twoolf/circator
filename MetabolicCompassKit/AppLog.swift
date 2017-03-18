//
//  AppLog.swift
//  MetabolicCompass
//
//  Created by Vladimir on 5/23/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

/*
import Foundation
import AppLogManager
import Alamofire

func addSALog(str:String){
    //print("ok log:\(title)")
    //[[AppLogManager sharedInstance] addAppLogItem:[AppLogMethodItem newWithValues:@{kAppLogNotShownTitleKey: str ?: @""}]];
    let item = AppLogMethodItem.newWithValues([kAppLogNotShownTitleKey: str])
    AppLogManager.sharedInstance().addAppLogItem(item)
}

func addSARequestLog(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<String>){
    let reqResult = NetworkRequestResult()
    reqResult.request = request
    reqResult.response = response
    reqResult.responseObject = (result as! AnyObject) ?? ""
    let item = AppLogNetworkRequestItem.newWithRequestResult(reqResult)
    AppLogManager.sharedInstance().addAppLogItem(item)
}

func addSARequestLog(request:NSURLRequest?, response:NSHTTPURLResponse?, result:Alamofire.Result<AnyObject>){
    let reqResult = NetworkRequestResult()
    reqResult.request = request
    reqResult.response = response
    reqResult.responseObject = (result as! AnyObject) ?? ""
    let item = AppLogNetworkRequestItem.newWithRequestResult(reqResult)
    AppLogManager.sharedInstance().addAppLogItem(item)
}

//NSMutableDictionary * mDict = [NSMutableDictionary new];
//if (requestResult.error != nil){
//    mDict[kAppLogNetworkKeyError] = requestResult.error.localizedDescription;
//}
//mDict[kAppLogNetworkKeyRequestInfo] = [NSString stringWithFormat:@"%@ %@", requestResult.request.HTTPMethod, requestResult.request.URL.absoluteString ?: @"?"];
//mDict[kAppLogNetworkKeyStatusCode] = [NSString stringWithFormat:@"%@", @(requestResult.httpResponse.statusCode)];
//mDict[kAppLogNetworkKeyHeaders] = [[requestResult.request allHTTPHeaderFields] description] ?: @"";
//mDict[kAppLogNetworkKeyResponseObject] = [requestResult.responseObject description] ?: @"";
//mDict[kAppLogNetworkKeyRequestBody] = requestResult.requestBodyText ?: @"";
//
//AppLogNetworkRequestItem * item = [super newWithValues:[NSDictionary dictionaryWithDictionary:mDict]];
//item.requestResult = requestResult;
//return item;

//func arithmeticMean(numbers: Double...) -> Double {
//    var total: Double = 0
//    for number in numbers {
//        total += number
//    }
//    return total / Double(numbers.count)
//} */
