//
//  UserAccount.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/14/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Locksmith

/**
 This class sets up the user accounts. This information needs to be kept separate from the anonymous aggregated data.  For this reason we use a third party authenticator to enable the personally identifiable information to be kept separately from the longitudinal study data.

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

public enum AccountComponent {
    case Consent
    case Photo
    case Profile
    case Settings
    case ArchiveSpan
    case LastAcquired
}

public func getComponentName(component: AccountComponent) -> String {
    switch component {
    case .Consent:
        return "consent"
    case .Photo:
        return "photo"
    case .Profile:
        return "profile"
    case .Settings:
        return "settings"
    case .ArchiveSpan:
        return "archive_span"
    case .LastAcquired:
        return "last_acquired"
    }
}

public func getComponentByName(name: String) -> AccountComponent? {
    switch name {
    case "consent":
        return .Consent
    case "photo":
        return .Photo
    case "settings":
        return .Settings
    case "archive_span":
        return .ArchiveSpan
    case "last_acquired":
        return .LastAcquired
    default:
        return nil
    }
}
