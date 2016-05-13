//
//  RegisterLoginLandingViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 4/22/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit

class RegisterLoginLandingViewController: BaseViewController {
    
    @IBOutlet weak var logoTopMargin: NSLayoutConstraint!
    @IBOutlet weak var registerButtonBottomMargin: NSLayoutConstraint!
    
    var completion: (Void -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(UIScreen.mainScreen().nativeBounds.height == 960 ||
           UIScreen.mainScreen().nativeBounds.height == 1136 ) {//iPhone4 and iPhone5 screen
            self.logoTopMargin.constant = 5;
            self.registerButtonBottomMargin.constant = 30;
        }
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        if ConsentManager.sharedManager.getConsentFilePath() == nil {
            self.doConsent {}
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    let loginSegue = "LoginSegue"
    let registerSegue = "RegisterSegue"
    
    @IBAction func onLogin(sender: AnyObject) {
        
        if ConsentManager.sharedManager.getConsentFilePath() == nil {
            self.doConsent {
                self.performSegueWithIdentifier(self.loginSegue, sender: self)
            }
        }
        else {
            self.performSegueWithIdentifier(self.loginSegue, sender: self)
        }
        
    }
    
    @IBAction func onRegister(sender: AnyObject) {
        
        if ConsentManager.sharedManager.getConsentFilePath() == nil {
            self.doConsent {
                self.performSegueWithIdentifier(self.registerSegue, sender: self)
            }
        }
        else {
            self.performSegueWithIdentifier(self.registerSegue, sender: self)
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == self.loginSegue) {
            
            let loginViewController = segue.destinationViewController as! LoginViewController
            loginViewController.completion = self.completion
            
        } else if (segue.identifier == self.registerSegue) {
            
            let regViewController = segue.destinationViewController as! RegisterViewController
            regViewController.registerCompletion = completion
            
            if ConsentManager.sharedManager.getConsentFilePath() == nil {
                regViewController.consentOnLoad = true
            }
        }
        
    }
    
    
    func doConsent(completion: Void -> Void) {
        let stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(self.navigationController!) {
            [weak self] (consented) -> Void in
            guard consented else {
                UserManager.sharedManager.resetFull()
                if let user = stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                
                return
            }
            
            completion()
        }
    }
}