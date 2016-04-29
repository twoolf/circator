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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func noThacksAction(sender: UIButton) {
        // back 
        
        self.dismissViewControllerAnimated(true, completion: nil)
        if let regVC = registerViewController {
            regVC.registartionComplete()
        }
        
    }
    
}
