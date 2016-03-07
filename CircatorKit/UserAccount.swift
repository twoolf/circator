//
//  UserAccount.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/14/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Locksmith

/**
 sets up user accounts
 
 - note: uses Stormpath for authentication
 */
struct UserAccount : ReadableSecureStorable,
                     CreateableSecureStorable,
                     DeleteableSecureStorable,
                     GenericPasswordSecureStorable
{
    let username: String
    let password: String
    
    let service = "MetabolicCompass"

    var account: String { return username }

    var data: [String: AnyObject] {
        return ["password" : password]
    }
}
