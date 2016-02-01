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
import SwiftDate

class SettingsViewController: UITableViewController, UITextFieldDelegate {

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    
    private var sectionSizes : [Int] = [2,2,6,4,2]
    private var sectionTitles : [String] = ["Login", "Settings", "Preview Rows", "Profile", "Bulk Upload"]

    private var formCells : [Int:[FormTextFieldCell?]] = [:]
    private var historySlider : FormSliderCell? = nil
    private var hMin = 0.0
    private var hMax = 0.0

    private var uploadButton: UIButton? = nil

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

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 4 && indexPath.row == 0 { return 65.0 }
        else { return 44.0 }
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

        if indexPath.section == 4 {
            if indexPath.row == 0 && historySlider == nil {
                historySlider = FormSliderCell()
                historySlider?.formSlider().minimumValue = 0.0
                historySlider?.formSlider().maximumValue = 100.0
                historySlider?.formSlider().continuous = true
                historySlider?.formSlider().value = 100.0
                historySlider?.formSlider().addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
                let disable : Void -> Void = { _ in
                    log.info("No historical range available")
                    self.hMin = 0.0
                    self.hMax = 0.0
                    self.historySlider?.formSlider().enabled = false
                    self.uploadButton?.enabled = false
                    self.historySlider?.formSlider().tintColor = UIColor.grayColor()
                    self.historySlider?.formTitleLabel()?.text = "No data to upload"
                }

                if let (start, end) = UserManager.sharedManager.getHistoricalRange() {
                    log.info("Historical range: \(start) --- \(end)")
                    hMin = start
                    hMax = end
                    if abs(hMax - hMin) < 10.0 {
                        disable()
                    } else {
                        historySlider?.formSlider().tintColor = UIColor.redColor()
                        historySlider?.formTitleLabel()?.text = NSDate(timeIntervalSinceReferenceDate: start).toString(DateFormat.Custom("MM/dd/YYYY"))
                    }
                } else {
                    disable()
                }

            } else if indexPath.row == 1 && uploadButton == nil {
                uploadButton = {
                    let button = MCButton(frame: cell.contentView.frame, buttonStyle: .Rounded)
                    button.cornerRadius = 4.0
                    button.buttonColor = UIColor.ht_emeraldColor()
                    button.shadowColor = UIColor.ht_nephritisColor()
                    button.shadowHeight = 4
                    button.setTitle("Upload Now", forState: .Normal)
                    button.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
                    button.addTarget(self, action: "doUpload:", forControlEvents: .TouchUpInside)
                    button.enabled = historySlider?.formSlider().enabled ?? false
                    return button
                }()
            }

            for sv in cell.contentView.subviews { sv.removeFromSuperview() }
            if indexPath.row == 0 { cell.contentView.addSubview(historySlider!) }
            else { cell.contentView.addSubview(uploadButton!) }
            return cell
        }

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
                    let cachedProfile : [String: AnyObject] = UserManager.sharedManager.getProfileCache()
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
                cell.textLabel?.text = PreviewManager.previewSampleTypes[indexPath.row].displayText
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

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let txt = textField.text {
            switch textField.tag {
            case 0:
                userCell?.textField.resignFirstResponder()
                passCell?.textField.becomeFirstResponder()
                UserManager.sharedManager.setUserId(txt)
            case 1:
                passCell?.textField.resignFirstResponder()
                userCell?.textField.becomeFirstResponder()

                // Take the current username text as well as the password.
                UserManager.sharedManager.ensureUserPass(userCell?.textField.text, pass: txt) { error in
                    guard !error else {
                        UINotifications.invalidUserPass(self.navigationController!)
                        return
                    }
                    UserManager.sharedManager.login(txt) { (error, reason) in
                        guard !error else {
                            UINotifications.loginFailed(self.navigationController!, pop: false, reason: reason)
                            return
                        }
                    }
                }
            case 2:
                UserManager.sharedManager.setHotWords(txt)
                textField.resignFirstResponder()
                UINotifications.profileUpdated(self.navigationController!)

            case 3:
                textField.resignFirstResponder()
                if let freq = Int(txt) {
                    UserManager.sharedManager.setRefreshFrequency(freq)
                    UINotifications.profileUpdated(self.navigationController!)
                }
                
            case 4:
                UserManager.sharedManager.pushProfile(["age":txt], completion: {_ in return})
                textField.resignFirstResponder()
                UINotifications.profileUpdated(self.navigationController!)

            case 5:
                UserManager.sharedManager.pushProfile(["weight":txt], completion: {_ in return})
                textField.resignFirstResponder()
                UINotifications.profileUpdated(self.navigationController!)

            case 6:
                UserManager.sharedManager.pushProfile(["height":txt], completion: {_ in return})
                textField.resignFirstResponder()
                UINotifications.profileUpdated(self.navigationController!)

            default:
                return false
            }
        }
        return false
    }

    func sliderValueDidChange(sender:UISlider!) {
        log.warning("Slider: \(sender.value)")
        if hMin != 0.0 {
            let d = NSDate(timeIntervalSinceReferenceDate: hMin + Double(1.0 - (sender.value / 100.0))  * (hMax - hMin))
            historySlider?.formTitleLabel()?.text = d.toString(DateFormat.Custom("MM/dd/YYYY"))
        } else {
            historySlider?.formTitleLabel()?.text = "\(sender.value)"
        }
    }

    func doUpload(sender: UIButton) {
        log.warning("Upload clicked")
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

        let accountCache = UserManager.sharedManager.getProfileCache()
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