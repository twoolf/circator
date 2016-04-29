//
//  ForgotPasswordViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/29/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class ForgotPasswordViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var containerScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScroolViewForKeyboardsActions(containerScrollView)
        
        emailTxtField.delegate = self
        
        emailTxtField.attributedPlaceholder = NSAttributedString(string: "E-mail".localized,
                                                                      attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor()])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func resetAction(sender: UIButton) {
        
        if let email = emailTxtField.text {
            if email.isValidAsEmail() {
                // TODO: reset password
            }
            else {
                showAlert(withMessage: "Please, provide valid email".localized)
            }
        }
        else {
            showAlert(withMessage: "Please, enter your email".localized)
        }
        
    }

    @IBAction func backToLoginAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
}
