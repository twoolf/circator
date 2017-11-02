//
//  PKCEFlowManager.swift
//  MetabolicCompass
//
//  Created by Olena Ostrozhynska on 31/10/2017.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit


class PKCEFlowManager {
    static let shared = PKCEFlowManager()
    var codeVerifier: String
    var codeChallenge: String
    let redirectUri = "edu.jhu.cs.damsl.MetabolicCompass.app://metaboliccompass.auth0.com/ios/edu.jhu.cs.damsl.MetabolicCompass.app/callback"
    let audience = "https://api-dev.metaboliccompass.com"
    let scope = "openid"
    let responseType = "code"
    let clientId = "FIwBsUv2cxpj1xoX3sjIeOyzm0Lq2Rqk"
    let codeChallengeMethod = "S256"
    
    private init? () {
        var buffer_ver = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer_ver.count, &buffer_ver)
       codeVerifier = Data(bytes: buffer_ver).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        guard let data = codeVerifier.data(using: .utf8) else { return nil }
        var buffer_chal = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &buffer_chal)
        }
        let hash = Data(bytes: buffer_chal)
       codeChallenge = hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    func receiveAutorizationCode(_ callback: @escaping (Data?) -> ()) {
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
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
                DispatchQueue.main.async {
                    callback(data)
                }
            }
        })
        
        dataTask.resume()
    }
    
    func receiveAccessToken(autorizationCode: String) {
        let headers = ["content-type": "application/json"]
        let body = """
            {
                "grant_type":"autorization_code",
                "client_id": "FIwBsUv2cxpj1xoX3sjIeOyzm0Lq2Rqk",
                "code_verifier": "Gi8lVllfjkRY850aUq8KD1qiazGTKzl06bZ9Q4y-ipg",
                "code": "autorizationCode",
                "redirect_uri": "redirectUri"
            }
        """
        
        var request = URLRequest(url: URL(string: "https://metaboliccompass.auth0.com/oauth/token")!,
                                  cachePolicy: .useProtocolCachePolicy,
                              timeoutInterval: 10.0)
  
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body.data(using: .utf8)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })

        dataTask.resume()
    }
}
