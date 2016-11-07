//
//  BackEnd.swift
//  MetabolicCompassNutritionManager
//
//  Created by Edwin L. Whitman on 7/27/16.
//  Copyright © 2016 Edwin L. Whitman. All rights reserved.
//

import Foundation

class HTTPBackEnd {
    
    var session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        //configuration.timeoutIntervalForRequest = 10.0
        return NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()
    
    func parseErrorFromResponse(response: NSURLResponse?, error: NSError?) -> String? {
        guard let httpResponse = response as? NSHTTPURLResponse else {
            return "Unexpected error: not an HTTP response"
        }
        if httpResponse.statusCode == 200 {
            return nil
        }
        return "HTTP Error \(httpResponse.statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode))"
    }
    
    func sendRequest(url: NSURL, rawDataDidArrive: (data: NSData?, errorMsg: String?) -> Void) {
        let task = session.dataTaskWithURL(url) { (data: NSData?, response: NSURLResponse?, netError: NSError?) in
            let errorMsg = self.parseErrorFromResponse(response, error: netError)
            rawDataDidArrive(data: data, errorMsg: errorMsg)
        }
        task.resume()
    }
}

class JSONBackEnd: HTTPBackEnd {

    func encodeKeyOrVal(kv: AnyObject) -> String {
        let allowed = NSMutableCharacterSet()
        allowed.formUnionWithCharacterSet(NSCharacterSet.URLQueryAllowedCharacterSet())
        allowed.removeCharactersInString("=?")
        return "\(kv)".stringByAddingPercentEncodingWithAllowedCharacters(allowed)!
    }
    
    func encodeDictionary(vals: [String: AnyObject]) -> String {
        let result = Array(vals.keys).reduce("") {
            (accumulator, key) in
            let prefix = (accumulator == "") ? "?" : "&"
            return "\(accumulator)\(prefix)\(encodeKeyOrVal(key))=\(encodeKeyOrVal(vals[key]!))"
        }
        return result
    }
    
    
    func ajaxRequest(url: NSURL, parameters: [String: AnyObject], jsonDataDidArrive: (dataDict: NSDictionary?, errorMsg: String?) -> ()) {
        
        guard let queryURL = NSURL(string: "\(url.absoluteString)\(self.encodeDictionary(parameters))") else {
            jsonDataDidArrive(dataDict: nil, errorMsg: "Internal library error")
            return
        }
        
        self.sendRequest(queryURL) { (data, errorMsg) in
            
            guard let rawData = data else {
                jsonDataDidArrive(dataDict: nil, errorMsg: errorMsg)
                return
            }
            
            // de-serialization
            let json: AnyObject?
            
            do {
                //do not allow fragments
                json = try NSJSONSerialization.JSONObjectWithData(rawData, options: NSJSONReadingOptions())
            } catch let error as NSError {

                jsonDataDidArrive(dataDict: nil, errorMsg: "\(error.localizedDescription)")
                return
            }
            
            guard let validParsedData = json as? NSDictionary else {
                jsonDataDidArrive(dataDict: nil, errorMsg: "Valid JSON data was not in dictionary form")
                return
            }
            
            jsonDataDidArrive(dataDict: validParsedData, errorMsg: nil)
        }
    }
}