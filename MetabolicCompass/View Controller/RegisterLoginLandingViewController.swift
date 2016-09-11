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
import SafariServices
import ReachabilitySwift

class RegisterLoginLandingViewController: BaseViewController {
    
    var completion: (Void -> Void)?
    let loginSegue = "LoginSegue"
    let registerSegue = "RegisterSegue"
    var reachability: Reachability! = nil

    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            let msg = "Failed to create reachability detector"
            log.error(msg)
            fatalError(msg)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
    
    //MARK: Actions
    @IBAction func onLogin(sender: AnyObject) {
        self.performSegueWithIdentifier(self.loginSegue, sender: self)
    }
    
    @IBAction func onRegister(sender: AnyObject) {
        switch reachability.currentReachabilityStatus {
        case .NotReachable:
            UINotifications.genericError(self, msg: "We cannot register a new account without internet connectivity. Please try later.", pop: false, asNav: true)

        default:
            self.performSegueWithIdentifier(self.registerSegue, sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == self.loginSegue) {
            let loginViewController = segue.destinationViewController as! LoginViewController
            loginViewController.completion = self.completion
        } else if (segue.identifier == self.registerSegue) {
            let regViewController = segue.destinationViewController as! RegisterViewController
            regViewController.registerCompletion = { _ in
                UINotifications.genericMsg(self, msg: "Please remember to check your email for our account verification link.", pop: false, asNav: true, nohide: true)
            }
        }        
    }
    
    @IBAction func privacyPolicy() {
        let svc = SFSafariViewController(URL: MCRouter.privacyPolicyURL)
        self.presentViewController(svc, animated: true, completion: nil)
    }

}