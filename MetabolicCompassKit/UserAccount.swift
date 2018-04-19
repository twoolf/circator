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
//    public var data: [String : Any]
    let username: String

    let service = "MetabolicCompass"

    var account: String { return username }

    public var data: [String: Any] {
        return [:]
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

public enum Auth0Component {
    case GrantType
    case ClientId
    case CodeVerifier
    case Code
    case RedirectUrl
}

public func getComponentName(_ component: AccountComponent) -> String {
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

public func getComponentByName(_ name: String) -> AccountComponent? {
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

public func getAuth0ComponentName(_ component: Auth0Component) -> String {
    switch component {
    case .GrantType:
        return "grant_type"
    case .ClientId:
        return "client_id"
    case .CodeVerifier:
        return "code_verifier"
    case .Code:
        return "code"
    case .RedirectUrl:
        return "redirect_uri"
    }
}
