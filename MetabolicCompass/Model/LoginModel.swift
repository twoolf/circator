//
//  LoginModel.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 4/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

class LoginModel : NSObject, UITableViewDataSource, UITextFieldDelegate {
    
    var loginTable: UITableView?
    var controllerView: UIView?
    private var textfields: Array<UITextField> = []
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(String(InputTableCellWithImage), forIndexPath: indexPath) as! InputTableCellWithImage
        cell.cellInput.delegate = self
        cell.cellInput.tag = indexPath.row
        if indexPath.row == 1 {
            cell.cellImage.image = UIImage(named: "icon-password")
            cell.cellInput.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
            cell.cellInput.secureTextEntry = true
        } else {
            cell.cellImage.image = UIImage(named: "icon-email")
            cell.cellInput.attributedPlaceholder = NSAttributedString(string: "E-mail", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
            cell.cellInput.keyboardType = UIKeyboardType.EmailAddress
        }
        textfields.append(cell.cellInput)
        return cell
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification:NSNotification){
        
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        keyboardFrame = self.controllerView!.convertRect(keyboardFrame, fromView: nil)
        
        var contentInset:UIEdgeInsets = self.loginTable!.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.loginTable!.contentInset = contentInset
    }
    
    func keyboardWillHide(notification:NSNotification) {
        
        let contentInset:UIEdgeInsets = UIEdgeInsetsZero
        self.loginTable!.contentInset = contentInset
    }
    
    
    // MARK: - Credentials
    
    func getCredentials() -> (email: String?, password: String?) {
        let emailTexfield = textfields[0]
        let passwordTextfield = textfields[1]
        return (emailTexfield.text!, passwordTextfield.text!)
    }
}