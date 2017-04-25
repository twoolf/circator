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
    
    var completion: ((Void) -> Void)?
    let loginSegue = "LoginSegue"
    let registerSegue = "RegisterSegue"
    var reachability: Reachability! = nil

    //MARK: View life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black;
        self.navigationController?.navigationBar.tintColor = UIColor.white

        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            let msg = "Failed to create reachability detector"
            log.error(msg)
            fatalError(msg)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent;
    }
    
    //MARK: Actions
    @IBAction func onLogin(sender: AnyObject) {
        self.performSegue(withIdentifier: self.loginSegue, sender: self)
    }
    
    @IBAction func onRegister(sender: AnyObject) {
        switch reachability.currentReachabilityStatus {
        case .isNotReachable:
            UINotifications.genericError(vc: self, msg: "We cannot register a new account without internet connectivity. Please try later.", pop: false, asNav: true)

        default:
            self.performSegue(withIdentifier: self.registerSegue, sender: self)
        }
    }
    
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == self.loginSegue) {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.completion = self.completion
        } else if (segue.identifier == self.registerSegue) {
            let regViewController = segue.destination as! RegisterViewController
            regViewController.registerCompletion = { _ in
                UINotifications.genericMsg(vc: self, msg: "Please remember to check your email for our account verification link.", pop: false, asNav: true, nohide: true)
            }
        }        
    }
    
    @IBAction func privacyPolicy() {
        let svc = SFSafariViewController(url: MCRouter.privacyPolicyURL!)
        self.present(svc, animated: true, completion: nil)
    }

}
