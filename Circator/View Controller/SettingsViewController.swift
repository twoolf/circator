//
//  SettingsViewController.swift
//  Circator
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import CircatorKit
import UIKit
import Async
import Former

class SettingsViewController: UITableViewController, UITextFieldDelegate {

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    
    private var sectionSizes : [Int] = [2,2,6,4]
    private var sectionTitles : [String] = ["Login", "Settings", "Preview Rows", "Profile"]

    private var formCells : [Int:[FormTextFieldCell?]] = [:]
    
    let profile : [(String, String, String, Int)] = [
            ("Age",     "age",     "Not specified/Offline", 4),
            ("Weight",  "weight",  "Not specified/Offline", 5),
            ("Height",  "height",  "Not specified/Offline", 6),
            ("Consent", "consent", "PDF",     7)
        ]

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
        return sectionSizes.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section < sectionSizes.count ? sectionSizes[section] : 0
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section < sectionTitles.count ? sectionTitles[section] : ""
    }

    func formInput() -> FormTextFieldCell {
        let formCell = FormTextFieldCell()
        let cellInput = formCell.formTextField()
        
        cellInput.textColor = UIColor.blackColor()
        cellInput.backgroundColor = UIColor.whiteColor()
        
        cellInput.textAlignment = NSTextAlignment.Right
        cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
        cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support
        
        return formCell
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)

        if formCells[indexPath.section] == nil {
            formCells[indexPath.section] = [FormTextFieldCell?](count: self.sectionSizes[indexPath.section], repeatedValue: nil)
        }

        if formCells[indexPath.section]![indexPath.row] == nil
        {
            switch indexPath.section {
            case 0, 1, 3:
                let formCell = formInput()
                let cellInput = formCell.formTextField()
                let cellLabel = formCell.formTitleLabel()

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
                    
                    cellInput.enabled = true
                    cellInput.delegate = self
                    
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
                    
                    cellInput.enabled = true
                    cellInput.delegate = self
                    
                case 3:
                    let cachedProfile : [String: AnyObject] = UserManager.sharedManager.getAccountDataCache()
                    cellLabel?.text = profile[indexPath.row].0
                    cellInput.placeholder = profile[indexPath.row].2
                    cellInput.tag = profile[indexPath.row].3
                    cellInput.delegate = self
                    
                    // Consent PDF viewer.
                    if ( indexPath.row == 3 ) {
                        cellInput.text = nil
                        cellInput.enabled = false
                    } else {
                        cellInput.text = cachedProfile[profile[indexPath.row].1] as? String
                        cellInput.keyboardType = UIKeyboardType.Alphabet
                        cellInput.returnKeyType = UIReturnKeyType.Done
                        cellInput.enabled = true
                    }
                    
                default:
                    print("Invalid settings tableview section")
                }

                formCells[indexPath.section]!.insert(formCell, atIndex: indexPath.row)

            case 2:
                cell.tintColor = Theme.universityDarkTheme.backgroundColor
                
                cell.imageView?.image = PreviewManager.rowIcons[indexPath.row]
               // cell.textLabel?.text = //PreviewManager.previewSampleTypes[indexPath.row].displayText
                cell.accessoryType = .DisclosureIndicator
                
            default:
                print("Invalid settings tableview section")
            }
        }

        for sv in cell.contentView.subviews { sv.removeFromSuperview() }

        switch indexPath.section {
        case 0, 1, 3:
            if let cellArray = formCells[indexPath.section],
                   formCell = cellArray[indexPath.row]
            {
                if indexPath.section == 3 && indexPath.row == 3 {
                    cell.accessoryType = .DisclosureIndicator
                } else {
                    cell.accessoryType = .None
                }
                cell.contentView.addSubview(formCell)
            }

        case 2:
            cell.tintColor = Theme.universityDarkTheme.backgroundColor
            cell.imageView?.image = PreviewManager.rowIcons[indexPath.row]
            cell.textLabel?.text = PreviewManager.previewSampleTypes[indexPath.row].displayText
            //cell.contentView.preservesSuperviewLayoutMargins = false;
            cell.accessoryType = .DisclosureIndicator

        default:
            print("Invalid settings tableview section")
        }

        cell.clipsToBounds = true
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if ( indexPath.section == 2 ) {
            let rowSettingsVC = RowSettingsViewController()
            rowSettingsVC.selectedRow = indexPath.row
            navigationController?.pushViewController(rowSettingsVC, animated: true)
        }
        else if ( indexPath.section == 3 && indexPath.row == 3 ) {
            let consentVC = ConsentViewController()
            navigationController?.pushViewController(consentVC, animated: true)
        }
    }

    func profileUpdated() {
        self.navigationController!.view.dodo.style.bar.hideAfterDelaySeconds = 3
        self.navigationController!.view.dodo.style.bar.hideOnTap = true
        self.navigationController!.view.dodo.success("Profile updated")
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
                
            case 4:
                UserManager.sharedManager.updateAccountData(["age":txt], completion: {_ in return})
                textField.resignFirstResponder()
                Async.main { self.profileUpdated() }

            case 5:
                UserManager.sharedManager.updateAccountData(["weight":txt], completion: {_ in return})
                textField.resignFirstResponder()
                Async.main { self.profileUpdated() }

            case 6:
                UserManager.sharedManager.updateAccountData(["height":txt], completion: {_ in return})
                textField.resignFirstResponder()
                Async.main { self.profileUpdated() }

            default:
                return false
            }
        }
        return false
    }

}

class ConsentViewController : UIViewController {
    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Consent Form"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "consentViewDone")
        navigationItem.rightBarButtonItem = doneButton

        let accountCache = UserManager.sharedManager.getAccountDataCache()
        if let pdfstr = accountCache["consent"] as? String,
               pdfdata = NSData(base64EncodedString: pdfstr, options: NSDataBase64DecodingOptions())
        {
            let webView = UIWebView(frame: CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height))
            let url = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath)
            webView.loadData(pdfdata, MIMEType: "application/pdf", textEncodingName: "UTF-8", baseURL: url)
            self.view.addSubview(webView)
        } else {
            let label = UILabel()
            label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
            label.textColor = .blackColor()
            label.textAlignment = .Center
            label.text = "Unable to show consent PDF"
            
            label.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(label)
            self.view.addConstraints([
                label.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor),
                label.centerYAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerYAnchor),
                label.heightAnchor.constraintEqualToConstant(100)
            ])
        }
    }
    
    func consentViewDone() {
        navigationController?.popViewControllerAnimated(true)
    }
}