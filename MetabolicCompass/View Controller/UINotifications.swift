//
//  DodoMessages.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 1/31/16.  
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import MetabolicCompassKit
import UIKit
import Async
import Dodo

let positiveNotificationDelay = 3.0
let negativeNotificationDelay = 5.0

/**
 This class contains a library of our standard user notifications, implemented with Dodo.  By putting these UI notifications in one place, it makes it easier to maintain the usage and to keep a consistent style.

- note: used broadly in code-base to report interactions 
*/
public class UINotifications {

    public static func configureNotifications() {
        let screenSize = UIScreen.main.bounds.size
//        log.warning("UINOTIFICATIONS screen height \(screenSize.height) \(screenSize.width)")
        DodoLabelDefaultStyles.font = UIFont(name: "GothamBook", size: ScreenManager.sharedInstance.dodoFontSize())!
    }

    public static func doWelcome(vc: UIViewController, pop: Bool = false, asNav: Bool = false, user: String = "") {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.success("Welcome \(user)")
            }
        }
    }

    public static func invalidProfile(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("Please fill in all required fields.")
            }
        }
    }

    public static func invalidUserPass(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("Invalid username/password")
            }
        }
    }

    public static func loginGoodbye(vc: UIViewController, pop: Bool = false, asNav: Bool = false, user: String = "") {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("Goodbye \(user)")
            }
        }
    }

    public static func loginFailed(vc: UIViewController, pop: Bool = false, asNav: Bool = false, reason: String? = nil) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("Login failed: " + (reason ?? ""))
            }
        }
    }

    public static func loginRequest(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("Please log in")
            }
        }
    }

    public static func noConsent(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("ResearchKit study not consented!")
            }
        }
    }

    public static func noHealthKit(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("HealthKit not authorized!")
            }
        }
    }

    public static func profileFetchFailed(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error("Could not fetch your profile")
            }
        }
    }

    public static func profileUpdated(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.success("Profile updated")
            }
        }
    }

    public static func registrationError(vc: UIViewController, pop: Bool = false, asNav: Bool = false, msg: String? = nil) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                let vmsg = msg ?? "Please try again"
                vc.view.dodo.error("Registration failed (\(vmsg))")
            }
        }
    }

    public static func retryingHealthkit(vc: UIViewController, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.warning("Waiting to access HealthKit...")
            }
        }
    }

    public static func showCount(vc: UIViewController, count: Int, pop: Bool = false, asNav: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.info("Count: \(count)")
            }
        }
    }

    public static func genericMsg(vc: UIViewController, msg: String, pop: Bool = false, asNav: Bool = false, nohide: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                if !nohide { vc.view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay }
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.info(msg)
            }
        }
    }

    public static func genericError(vc: UIViewController, msg: String, pop: Bool = false, asNav: Bool = false, nohide: Bool = false) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                if !nohide { vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay }
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                vc.view.dodo.error(msg)
            }
        }
    }

    public static func genericMsgOnView(view: UIView, msg: String, nohide: Bool = false) {
        Async.main {
            if !nohide { view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay }
            view.dodo.style.bar.hideOnTap = true
            view.dodo.info(msg)
        }
    }

    public static func genericSuccessMsgOnView(view: UIView, msg: String, nohide: Bool = false) {
        Async.main {
            if !nohide { view.dodo.style.bar.hideAfterDelaySeconds = positiveNotificationDelay }
            view.dodo.style.bar.hideOnTap = true
            view.dodo.success(msg)
        }
    }

    public static func genericErrorOnView(view: UIView, msg: String, nohide: Bool = false) {
        Async.main {
            if !nohide { view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay }
            view.dodo.style.bar.hideOnTap = true
            view.dodo.error(msg)
        }
    }

    private static func withPop(vc: UIViewController, pop: Bool, asNav: Bool = false, msg: () -> ()) {
        if pop {
            if asNav {
                if let ctlr = vc as? UINavigationController {
                    ctlr.popViewController(animated: true)
                }
            } else {
                vc.navigationController?.popViewController(animated: true)
            }
        }
        msg()
    }
    
    public static func showError(vc: UIViewController, pop: Bool = false, asNav: Bool = false, msg: String? = nil, title: String? = nil) {
        withPop(vc: vc, pop: pop, asNav: asNav) {
            Async.main {
                vc.view.dodo.style.bar.hideAfterDelaySeconds = negativeNotificationDelay
                vc.view.dodo.style.bar.hideOnTap = true
                vc.view.dodo.topLayoutGuide = vc.topLayoutGuide
                vc.view.dodo.bottomLayoutGuide = vc.bottomLayoutGuide
                var vmsg = msg ?? "Please try again"
                if let alertTitle = title {
                    vmsg = alertTitle + ": " + vmsg
                }
                
                vc.view.dodo.error(vmsg)
            }
        }
    }
}
