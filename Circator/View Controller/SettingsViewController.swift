//
//  SettingsViewController.swift
//  Circator
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import CircatorKit
import UIKit

class SettingsViewController: UITableViewController, UITextFieldDelegate {

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
            let cellInput = UITextField()
            cell.detailTextLabel?.hidden = true
            cellInput.adjustsFontSizeToFitWidth = true
            cellInput.textColor = UIColor.blackColor()
            cellInput.backgroundColor = UIColor.whiteColor()
            cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
            cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support
            cellInput.textAlignment = NSTextAlignment.Left

            switch indexPath.section {
            case 0:
                if (indexPath.row == 0) {
                    cellInput.text = UserManager.sharedManager.getUserId()
                    cellInput.keyboardType = UIKeyboardType.EmailAddress
                    cellInput.returnKeyType = UIReturnKeyType.Next
                    cellInput.tag = 0
                    cell.textLabel?.text = "User"
                }
                else {
                    if let pass = UserManager.sharedManager.getPassword() {
                        cellInput.text = pass
                    } else {
                        cellInput.placeholder = "Required"
                    }
                    cellInput.keyboardType = UIKeyboardType.Default
                    cellInput.returnKeyType = UIReturnKeyType.Done
                    cellInput.secureTextEntry = true
                    cellInput.tag = 1
                    cell.textLabel?.text = "Password"
                }

            case 1:
                if (indexPath.row == 0) {
                    cellInput.text = UserManager.sharedManager.getHotWords()
                    cell.textLabel?.text = "Siri hotword"
                    cellInput.tag = 2
                } else {
                    let freq = UserManager.sharedManager.getRefreshFrequency() ?? UserManager.defaultRefreshFrequency
                    cellInput.text = String(freq)
                    cell.textLabel?.text = "Refresh"
                    cellInput.tag = 3
                }

                cellInput.keyboardType = UIKeyboardType.Alphabet
                cellInput.returnKeyType = UIReturnKeyType.Done

            default:
                print("Invalid settings tableview section")
            }

            cellInput.clearButtonMode = UITextFieldViewMode.Never // no clear 'x' button to the right
            cellInput.enabled = true
            cellInput.delegate = self

            cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false

            cellInput.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(cellInput)

            cell.addConstraint(NSLayoutConstraint(
                item:cell.textLabel!, attribute: NSLayoutAttribute.Width,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Width, multiplier:0.33, constant:0))

            cell.addConstraint(NSLayoutConstraint(
                item: cellInput, attribute:NSLayoutAttribute.Width,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Width, multiplier:0.67, constant:0))

            cell.addConstraint(NSLayoutConstraint(
                item:cellInput, attribute: NSLayoutAttribute.Leading,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.textLabel,
                attribute:NSLayoutAttribute.Trailing, multiplier:1, constant:8))

            cell.addConstraint(NSLayoutConstraint(
                item: cellInput, attribute:NSLayoutAttribute.Trailing,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Trailing, multiplier:1, constant:0))

            cell.addConstraint(NSLayoutConstraint(
                item: cellInput, attribute: NSLayoutAttribute.Top,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Top, multiplier:1, constant:8.5))

            cell.addConstraint(NSLayoutConstraint(
                item: cellInput, attribute: NSLayoutAttribute.Bottom,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Bottom, multiplier:1, constant:-7.5))

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
            case 1:
                UserManager.sharedManager.login(txt)
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
