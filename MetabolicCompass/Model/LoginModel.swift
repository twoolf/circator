//
//  LoginModel.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 4/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit

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
        cell.cellInput.textColor = ScreenManager.sharedInstance.appBrightTextColor()
        
        if indexPath.row == 1 {
            cell.cellImage.image = UIImage(named: "icon-password")
            cell.cellInput.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appUnBrightTextColor()])
            cell.cellInput.secureTextEntry = true
        } else {
            cell.cellImage.image = UIImage(named: "icon-email")
            cell.cellInput.attributedPlaceholder = NSAttributedString(string: "E-mail", attributes: [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appUnBrightTextColor()])
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
    
    
    // MARK: - Credentials
    
    func getCredentials() -> (email: String?, password: String?) {
        let emailTexfield = textfields[0]
        let passwordTextfield = textfields[1]
        return (emailTexfield.text!, passwordTextfield.text!)
    }
}