//
//  PKCEFlowManager.swift
//  MetabolicCompass
//
//  Created by Olena Ostrozhynska on 31/10/2017.
//  Copyright © 2017 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation


class PKCEFlowManager {
    static let shared = PKCEFlowManager()
    var codeVerifier: String
    var codeChallenge: String
    
    
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
}
