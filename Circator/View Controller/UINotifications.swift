//
//  DodoMessages.swift
//  Circator
//
//  Created by Yanif Ahmad on 1/31/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import CircatorKit
import UIKit
import Async

/*
 * A library of standard user notifications, implemented with Dodo.
 */
public class UINotifications {

    public static func doWelcome(vc: UIViewController, pop: Bool = false, user: String = "") {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.success("Welcome \(user)")
            }
        }
    }

    public static func invalidProfile(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("Please fill in all required fields!")
            }
        }
    }

    public static func invalidUserPass(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("Invalid username/password")
            }
        }
    }

    public static func loginGoodbye(vc: UIViewController, pop: Bool = false, user: String = "") {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("Goodbye \(user)")
            }
        }
    }

    public static func loginFailed(vc: UIViewController, pop: Bool = false, reason: String? = nil) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("Login failed " + (reason ?? ""))
            }
        }
    }

    public static func loginRequest(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("Please log in")
            }
        }
    }

    public static func noConsent(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("ResearchKit study not consented!")
            }
        }
    }

    public static func noHealthKit(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("HealthKit not authorized!")
            }
        }
    }

    public static func profileUpdated(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.success("Profile updated")
            }
        }
    }

    public static func registrationError(vc: UIViewController, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.error("Error in signing up, please try later.")
            }
        }
    }

    public static func showCount(vc: UIViewController, count: Int, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.info("Count: \(count)")
            }
        }
    }

    public static func genericMsg(vc: UIViewController, msg: String, pop: Bool = false) {
        withPop(vc, pop: pop) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = 3
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.info(msg)
            }
        }
    }

    private static func withPop(vc: UIViewController, pop: Bool, msg: () -> ()) {
        if pop {
            vc.navigationController?.popViewControllerAnimated(true)
        }
        msg()
    }
}