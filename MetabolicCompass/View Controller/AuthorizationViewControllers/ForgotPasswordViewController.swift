//
//  ForgotPasswordViewController.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/29/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit

class ForgotPasswordViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var containerScrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScroolViewForKeyboardsActions(containerScrollView)
        
        emailTxtField.delegate = self
        
        emailTxtField.attributedPlaceholder = NSAttributedString(string: "E-mail".localized,
                                                                      attributes: [NSForegroundColorAttributeName : unselectedTextColor])
        
        emailTxtField.textColor = selectedTextColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private let resetPasswordEmailEmptyMessage = "Please, enter your email".localized
    private let resetPasswordEmailInvalidMessage = "Please, provide valid email".localized
    private let resetPasswordTitle = "Reset Password".localized
    private let resetPasswordErrorGeneralMessage = "Reset Password error occurs. Please, try later.".localized
    private let resetPasswordSuccessMessage = "Reset Password request was done succesfully. Please, check your email to reset password.".localized
    
    @IBAction func resetAction(sender: UIButton) {
        
        startAction()
        
        self.alertControllerOkButtonHandler = nil
        
        if let email = emailTxtField.text?.trimmed() {
            
            if email.isEmpty {
                showAlert(withMessage: resetPasswordEmailEmptyMessage)
                return
            }
            
            if email.isValidAsEmail() {
                
                sender.enabled = false
                
                UserManager.sharedManager.resetPassword(email, completion: { (success, errorMessage) in
                    if success {
                        
                        self.alertControllerOkButtonHandler = {
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                        
                        self.showAlert(withMessage: self.resetPasswordSuccessMessage, title: self.resetPasswordTitle)
                    }
                    else {
                        let message = errorMessage == nil ? self.resetPasswordErrorGeneralMessage : errorMessage!
                        self.showAlert(withMessage: message, title: self.resetPasswordTitle)
                    }
                    
                    sender.enabled = true
                })
                
            }
            else {
                showAlert(withMessage: resetPasswordEmailInvalidMessage)
            }
        }
        else {
            showAlert(withMessage: resetPasswordEmailEmptyMessage)
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
