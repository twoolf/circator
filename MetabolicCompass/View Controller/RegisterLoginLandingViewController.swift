//
//  RegisterLoginLandingViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 4/22/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

class RegisterLoginLandingViewController: UIViewController {
    
    @IBOutlet weak var logoTopMargin: NSLayoutConstraint!
    @IBOutlet weak var registerButtonBottomMargin: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(UIScreen.mainScreen().nativeBounds.height == 960 ||
           UIScreen.mainScreen().nativeBounds.height == 1136 ) {//iPhone4 and iPhone5 screen
            self.logoTopMargin.constant = 5;
            self.registerButtonBottomMargin.constant = 30;
        }
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent;
    }
}