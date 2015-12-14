//
//  UserManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/13/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Alamofire

private let MCServiceURL = "http://app.metaboliccompass.com"
private let UserManagerLoginKey = "UMLoginKey"

public class UserManager {
    public static let sharedManager = UserManager()
    
    var userId : String = ""
    
    init() {
        self.userId = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerLoginKey) ?? "example@gmail.com"
    }

    public func getUserId() -> String {
        return self.userId
    }

    public func setUserId(userId: String) {
        self.userId = userId
        NSUserDefaults.standardUserDefaults().setValue(userId, forKey: UserManagerLoginKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    public func userLogin(userId: String, userPass: String) {
        let params = [ "grant_type" : "password",
                       "username"   : userId,
                       "password"   : userPass ]
    
        Alamofire.request(.POST, MCServiceURL + "/oauth/token", parameters: params, encoding: .URL)
                 .responseString {_, response, result in
                    print("POST: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                    print(response)
                    print(result.value)
                 }
    }

    public func userLogin(userPass: String) {
        self.userLogin(self.userId, userPass: userPass)
    }
}