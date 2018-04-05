//
//  PKCEFlowManager.swift
//  MetabolicCompass
//
//  Created by Olena Ostrozhynska on 31/10/2017.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

import Auth0

class PKCEFlowManager {
    static let shared = PKCEFlowManager()
    let redirectUri = "edu.jhu.cs.damsl.MetabolicCompass.app://metaboliccompass.auth0.com/ios/edu.jhu.cs.damsl.MetabolicCompass.app/callback"
//    let audience = "https://api-dev.metaboliccompass.com"
    let audience = "https://metaboliccompass.auth0.com/api/v2/"
    
    let scope = "openid profile offline_access update:current_user_metadata"
    let responseType = "code"
    let clientId = "FIwBsUv2cxpj1xoX3sjIeOyzm0Lq2Rqk"
    let codeChallengeMethod = "S256"
    var codeVerifier: String?
    var codeChallenge: String?
    
    private init? () {}

    func generateCodeVerifierAndCodeChallenge() {
        var buffer_ver = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer_ver.count, &buffer_ver)
        let verifier = Data(bytes: buffer_ver).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
        codeVerifier = verifier
        
        guard let data = codeVerifier?.data(using: .utf8) else { return }
        var buffer_chal = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &buffer_chal)
        }
        let hash = Data(bytes: buffer_chal)
        codeChallenge = hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
        localLog.debug("codeVerifier: '\(codeVerifier!)'")
        localLog.debug("codeChallenge: '\(codeChallenge!)'")
//        print("codeVerifier: '\(codeVerifier!)'")
//        print("codeChallenge: '\(codeChallenge!)'")
    }
    
    func receiveAutorizationCode(_ callback: @escaping (Data?) -> ()) {
        generateCodeVerifierAndCodeChallenge()
        var components = URLComponents(string: "https://metaboliccompass.auth0.com/authorize")
        let audienceItem = URLQueryItem(name: "audience", value: audience)
        let scopeItem = URLQueryItem(name: "scope", value: scope)
        let responseTypeItem = URLQueryItem(name: "response_type", value: responseType)
        let clientIdItem = URLQueryItem(name: "client_id", value: clientId)
        let codeChallengeItem = URLQueryItem(name: "code_challenge", value: codeChallenge)
        let codeChallengeMethodItem = URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod)
        let redirectUrlItem = URLQueryItem(name: "redirect_uri", value: redirectUri)
        components?.queryItems = [audienceItem, scopeItem, responseTypeItem, clientIdItem, codeChallengeItem, codeChallengeMethodItem, redirectUrlItem]
        
        let url = components?.url
        var request = URLRequest(url: url!,
                         cachePolicy: .useProtocolCachePolicy,
                     
                         timeoutInterval: 10.0)
        request.httpMethod = "GET"
        
        print("\n\nRequesting Authorization code with URL: '\(url!)\n\n'")
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                localLog.debug("Authorization code request error '\(error!)'")
            } else {
                let httpResponse = response as? HTTPURLResponse
                localLog.debug("Authorization code response '\(httpResponse!)'")
                DispatchQueue.main.async {
                    callback(data)
                }
            }
        })
        
        dataTask.resume()
    }
    
    func receiveAccessToken(authorizationCode: String, _ callback: @escaping (Data?) -> ()) {
        let headers = ["content-type": "application/json"]
        let parameterDictionary = ["grant_type" : "authorization_code", "client_id" : clientId,  "code_verifier": codeVerifier, "code": authorizationCode, "redirect_uri": redirectUri]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            //TODO: add proper error support
            return
        }
        var request = URLRequest(url: URL(string: "https://metaboliccompass.auth0.com/oauth/token")!,
                                  cachePolicy: .useProtocolCachePolicy,
                              timeoutInterval: 10.0)
  
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = httpBody
        
        localLog.debug("Access Token Request JSON dictionary source:\n \(parameterDictionary)")
        
        localLog.debug("""
            \n\nRequesting Access Token with URL: '\(request.url!)\n
            headers: '\(headers)'\n
            HTTP Body: '\(httpBody)'\n\n
            """)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                localLog.debug("Authentication Token request error '\(error!)'")
            } else {
                
                localLog.debug("Data: \(data)")
                
                DispatchQueue.main.async {
                    callback(data)
                }
                let httpResponse = response as? HTTPURLResponse
                localLog.debug("Authentication Token request response '\(httpResponse!)'")
            }
        })
        dataTask.resume()
    }
}
