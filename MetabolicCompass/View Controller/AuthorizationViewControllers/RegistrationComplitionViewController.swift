//
//  RegistrationComplitionViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class RegistrationComplitionViewController: BaseViewController {

    weak var registerViewController: RegisterViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = view.backgroundColor?.colorWithAlphaComponent(0.93)
        view.opaque = false
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UINotifications.genericMsg(self, msg: "We just sent you an email. Please verify your account", pop: false, asNav: true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    @IBAction func noThacksAction(sender: UIButton) {
        // back
        self.dismissViewControllerAnimated(true, completion: nil)
        if let regVC = registerViewController {
            regVC.registartionComplete()
        }
    }
    
    private let segueRegistrationCompletionIndentifier = "AdditionInfoController"
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueRegistrationCompletionIndentifier {
            if let vc = segue.destinationViewController as? AdditionalInfoViewController {
                vc.registerViewController = self.registerViewController
            }
        }
    }
}
