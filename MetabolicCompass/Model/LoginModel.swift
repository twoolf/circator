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
 //   @available(iOS 2.0, *)
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        return 2
//    }


    var loginTable: UITableView?
    var controllerView: UIView?
    private var textfields: Array<UITextField> = []

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputTableCellWithImage()), for: indexPath as IndexPath) as! InputTableCellWithImage
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: NSIndexPath) -> UITableViewCell {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputTableCellWithImage.self), for: indexPath) as! InputTableCellWithImage
//        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: InputTableCellWithImage()), for: indexPath as IndexPath) as! InputTableCellWithImage
        cell.cellInput.delegate = self
        cell.cellInput.tag = indexPath.row
        cell.cellInput.textColor = ScreenManager.sharedInstance.appBrightTextColor()

        if indexPath.row == 1 {
            cell.cellImage.image = UIImage(named: "icon-password")
            cell.cellInput.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appUnBrightTextColor()])
            cell.cellInput.isSecureTextEntry = true
        } else {
            cell.cellImage.image = UIImage(named: "icon-email")
            cell.cellInput.attributedPlaceholder = NSAttributedString(string: "E-mail", attributes: [NSForegroundColorAttributeName : ScreenManager.sharedInstance.appUnBrightTextColor()])
            cell.cellInput.keyboardType = UIKeyboardType.emailAddress
        }
        textfields.append(cell.cellInput)
        return cell
    }

    // MARK: - UITextFieldDelegate

    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
