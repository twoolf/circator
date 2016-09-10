//
//  RegistrationComplitionViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Crashlytics

class RegistrationCompletionViewController: BaseViewController {

    weak var registerViewController: RegisterViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = view.backgroundColor?.colorWithAlphaComponent(0.93)
        view.opaque = false
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UINotifications.genericMsg(self, msg: "We've emailed you an account verification link. Please check your inbox.", pop: false, asNav: true, nohide: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    @IBAction func noThanksAction(sender: UIButton) {
        // back
        self.dismissViewControllerAnimated(true, completion: nil)
        if let regVC = registerViewController {
            Answers.logCustomEventWithName("Register Additional", customAttributes: ["WithAdditional": false])
            regVC.registrationComplete()
        }
    }
    
    private let segueRegistrationCompletionIdentifier = "AdditionInfoController"
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueRegistrationCompletionIdentifier {
            if let vc = segue.destinationViewController as? AdditionalInfoViewController {
                vc.registerViewController = self.registerViewController
            }
        }
    }
}
