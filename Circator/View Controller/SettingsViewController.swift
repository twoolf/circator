//
//  SettingsViewController.swift
//  Circator
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import CircatorKit
import UIKit
import Former

class SettingsViewController: UITableViewController, UITextFieldDelegate {

    private lazy var former: Former = Former(tableView: self.tableView)
    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    
    init() {
        super.init(style: UITableViewStyle.Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Settings"
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source & delegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var result = 0
        switch section {
        case 0:
            result = 2
        case 1:
            result = 2
        case 2:
            result = 6
        default:
            result = 0
        }
        return result
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var result = ""
        switch section {
        case 0:
            result = "Login"
        case 1:
            result = "Settings"
        case 2:
            result = "Preview Rows"
        default:
            result = ""
        }
        return result
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)
        switch indexPath.section {
        case 0, 1:
            let formCell = FormTextFieldCell()
            let cellInput = formCell.formTextField()
            let cellLabel = formCell.formTitleLabel()

            cellInput.textColor = UIColor.blackColor()
            cellInput.backgroundColor = UIColor.whiteColor()

            cellInput.textAlignment = NSTextAlignment.Right
            cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
            cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support

            switch indexPath.section {
            case 0:
                if (indexPath.row == 0) {
                    cellInput.keyboardType = UIKeyboardType.EmailAddress
                    cellInput.returnKeyType = UIReturnKeyType.Next
                    cellInput.placeholder = "User"
                    cellInput.text = UserManager.sharedManager.getUserId()
                    cellLabel?.text = "User"
                    userCell = formCell
                    cellInput.tag = 0
                }
                else {
                    cellInput.keyboardType = UIKeyboardType.Default
                    cellInput.returnKeyType = UIReturnKeyType.Done
                    cellInput.secureTextEntry = true
                    cellInput.placeholder = "Password"
                    cellInput.text = UserManager.sharedManager.getPassword()
                    cellLabel?.text = "Password"
                    passCell = formCell
                    cellInput.tag = 1
                }

            case 1:
                if (indexPath.row == 0) {
                    cellInput.placeholder = "Siri hotword"
                    cellInput.text = UserManager.sharedManager.getHotWords()
                    cellLabel?.text = "Siri hotword"
                    cellInput.tag = 2
                } else {
                    let freq = UserManager.sharedManager.getRefreshFrequency() ?? UserManager.defaultRefreshFrequency
                    cellInput.placeholder = "Data refresh"
                    cellInput.text = String(freq)
                    cellLabel?.text = "Data refresh"
                    cellInput.tag = 3
                }

                cellInput.keyboardType = UIKeyboardType.Alphabet
                cellInput.returnKeyType = UIReturnKeyType.Done

            default:
                print("Invalid settings tableview section")
            }

            cell.contentView.addSubview(formCell)

            cellInput.enabled = true
            cellInput.delegate = self


        case 2:
            cell.tintColor = Theme.universityDarkTheme.backgroundColor
            cell.imageView?.image = PreviewManager.rowIcons[indexPath.row]
            cell.textLabel?.text = PreviewManager.previewSampleTypes[indexPath.row].displayText
            cell.accessoryType = .DisclosureIndicator

        default:
            print("Invalid settings tableview section")
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if ( indexPath.section == 0 ) {

        } else {
            let rowSettingsVC = RowSettingsViewController()
            rowSettingsVC.selectedRow = indexPath.row
            navigationController?.pushViewController(rowSettingsVC, animated: true)
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let txt = textField.text {
            switch textField.tag {
            case 0:
                UserManager.sharedManager.setUserId(txt)
                userCell?.textField.resignFirstResponder()
                passCell?.textField.becomeFirstResponder()
            case 1:
                // Take any text entered as the username if we have nothing saved.
                if UserManager.sharedManager.getUserId() == nil {
                    if let currentUser = userCell?.textField.text {
                        UserManager.sharedManager.setUserId(currentUser)
                    }
                }
                UserManager.sharedManager.login(txt)
                passCell?.textField.resignFirstResponder()
                userCell?.textField.becomeFirstResponder()
            case 2:
                UserManager.sharedManager.setHotWords(txt)
            case 3:
                if let freq = Int(txt) {
                    UserManager.sharedManager.setRefreshFrequency(freq)
                }
            default:
                return false
            }
        }
        return false
    }

}
