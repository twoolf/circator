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
        view.backgroundColor = view.backgroundColor?.withAlphaComponent(0.93)
        view.isOpaque = false
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UINotifications.genericMsg(vc: self, msg: "We've emailed you an account verification link. Please check your inbox.", pop: false, asNav: true, nohide: true)
    }
        
    @IBAction func noThanksAction(_ sender: UIButton) {
        // back
        self.dismiss(animated: true, completion: nil)
        if let regVC = registerViewController {
            Answers.logCustomEvent(withName: "Register Additional", customAttributes: ["WithAdditional": false])
            regVC.registrationComplete()
        }
    }
    
    private let segueRegistrationCompletionIdentifier = "AdditionInfoController"
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueRegistrationCompletionIdentifier {
            if let vc = segue.destination as? AdditionalInfoViewController {
                vc.registerViewController = self.registerViewController
            }
        }
    }
}
