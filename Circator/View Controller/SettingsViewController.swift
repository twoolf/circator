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
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0 ? 2 : 6)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 0 ? "Login" : "Preview Rows")
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)
        if ( indexPath.section == 0 ) {

            let cellInput = UITextField()
            cell.detailTextLabel?.hidden = true
            cellInput.adjustsFontSizeToFitWidth = true
            cellInput.textColor = UIColor.blackColor()
            cellInput.backgroundColor = UIColor.whiteColor()
            cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
            cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support
            cellInput.textAlignment = NSTextAlignment.Left

            if (indexPath.row == 0) {
                cellInput.text = UserManager.sharedManager.getUserId()
                cellInput.keyboardType = UIKeyboardType.EmailAddress
                cellInput.returnKeyType = UIReturnKeyType.Next
                cellInput.tag = 0
            }
            else {
                cellInput.placeholder = "Required"
                cellInput.keyboardType = UIKeyboardType.Default
                cellInput.returnKeyType = UIReturnKeyType.Done
                cellInput.secureTextEntry = true
                cellInput.tag = 1
            }

            cellInput.clearButtonMode = UITextFieldViewMode.Never // no clear 'x' button to the right
            cellInput.enabled = true
            cellInput.delegate = self

            cell.textLabel?.text = (indexPath.row == 0 ? "User" : "Password")
            cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false

            cellInput.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(cellInput)

            cell.addConstraint(NSLayoutConstraint(
                item:cell.textLabel!, attribute: NSLayoutAttribute.Width,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Width, multiplier:0.3, constant:0))

            cell.addConstraint(NSLayoutConstraint(
                item: cellInput, attribute:NSLayoutAttribute.Width,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Width, multiplier:0.7, constant:0))

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
                attribute:NSLayoutAttribute.Top, multiplier:1, constant:8))

            cell.addConstraint(NSLayoutConstraint(
                item: cellInput, attribute: NSLayoutAttribute.Bottom,
                relatedBy:NSLayoutRelation.Equal, toItem:cell.contentView,
                attribute:NSLayoutAttribute.Bottom, multiplier:1, constant:-8))
            

        } else {
            cell.tintColor = Theme.universityDarkTheme.backgroundColor
            cell.imageView?.image = PreviewManager.rowIcons[indexPath.row]
            cell.textLabel?.text = PreviewManager.previewSampleTypes[indexPath.row].displayText
            cell.accessoryType = .DisclosureIndicator
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
            if ( textField.tag == 0 ) {
                UserManager.sharedManager.setUserId(txt)
            } else if ( textField.tag == 1 ) {
                UserManager.sharedManager.userLogin(txt)
            }
        }
        return false
    }

}
