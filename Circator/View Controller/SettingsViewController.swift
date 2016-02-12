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

private let fieldCount           : Int   = UserProfile.updateableReqRange.count+3
private let debugSectionSizes    : [Int] = [2,2,6,fieldCount,2,1]
private let releaseSectionSizes  : [Int] = [2,2,6,fieldCount,2]

private let debugSectionTitles    : [String] = ["Login", "Settings", "Preview Rows", "Profile", "Bulk Upload", "Debug"]
private let releaseSectionTitles  : [String] = ["Login", "Settings", "Preview Rows", "Profile", "Bulk Upload"]

private let withDebugView = true

class SettingsViewController: UITableViewController, UITextFieldDelegate {

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    private var measureCells : [UIStackView?]?
    private var debugCell: FormLabelCell?

    private var sectionSizes  : [Int]    = withDebugView ? debugSectionSizes  : releaseSectionSizes
    private var sectionTitles : [String] = withDebugView ? debugSectionTitles : releaseSectionTitles

    private var formCells : [Int:[FormCell?]] = [:]
    private var historySlider : FormSliderCell? = nil
    private var hMin = 0.0
    private var hMax = 0.0

    private var uploadButton: UIButton? = nil

    private var profile : [(String, String, String, Int)] = []
    private var subviews = ["Consent", "Recommended", "Optional"]

    init() {
        super.init(style: UITableViewStyle.Grouped)
        initProfile()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initProfile()
    }

    func initProfile() {
        profile = UserProfile.updateableReqRange.enumerate().map { (i, j) in
            let k = UserProfile.profileFields[j]
            let v = UserProfile.updateableMapping[k]!
            let p = UserProfile.profilePlaceholders[j]
            return (k, v, p, 4+i)
        }
        let n = profile.count
        profile.append(("Consent", "consent", "PDF", 4 + n))
        profile.append(("Recommended", "",    "",    5 + n))
        profile.append(("Optional",    "",    "",    6 + n))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Settings"
        tableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BehaviorMonitor.sharedInstance.showView("Settings", contentType: "")
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

    func formLabel() -> FormLabelCell {
        let formCell = FormLabelCell()

        let cellLabel = formCell.formTextLabel()
        cellLabel?.textColor = UIColor.blackColor()
        cellLabel?.backgroundColor = UIColor.whiteColor()

        let cellSLabel = formCell.formSubTextLabel()
        cellSLabel?.textColor = UIColor.blackColor()
        cellSLabel?.backgroundColor = UIColor.whiteColor()

        return formCell
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)

        if withDebugView && indexPath.section == 5 {
            if debugCell == nil {
                debugCell = FormLabelCell()
                debugCell?.tintColor = Theme.universityDarkTheme.backgroundColor
                debugCell?.formTextLabel()?.text = "Debug"
            }

            cell.imageView?.image = nil
            cell.accessoryType = .DisclosureIndicator

            for sv in cell.contentView.subviews { sv.removeFromSuperview() }
            cell.contentView.addSubview(debugCell!)
            cell.clipsToBounds = true
            return cell
        }

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
            cell.textLabel?.hidden = true
            cell.imageView?.image = nil
            cell.accessoryType = .None

            if indexPath.row == 0 { cell.contentView.addSubview(historySlider!) }
            else { cell.contentView.addSubview(uploadButton!) }
            return cell
        }

        if indexPath.section == 2 {
            if measureCells == nil {
                measureCells = [UIStackView?](count: self.sectionSizes[indexPath.section], repeatedValue: nil)
            }

            let sampleType = PreviewManager.previewSampleTypes[indexPath.row]

            if measureCells![indexPath.row] == nil {
                let cellImage : UIImageView = {
                    let image: UIImageView = UIImageView()
                    image.tintColor = Theme.universityDarkTheme.backgroundColor
                    image.image = PreviewManager.iconForSampleType(sampleType)
                    image.contentMode = .ScaleAspectFit
                    return image
                }()

                let cellLabel : UILabel = {
                    let label: UILabel = UILabel()
                    label.textColor = .blackColor()
                    label.text = sampleType.displayText
                    return label
                }()

                measureCells![indexPath.row] = {
                    let stackView: UIStackView = UIStackView(arrangedSubviews: [cellImage, cellLabel])
                    stackView.axis = .Horizontal
                    stackView.distribution = UIStackViewDistribution.FillProportionally
                    stackView.alignment = UIStackViewAlignment.Fill
                    stackView.spacing = 10
                    return stackView
                }()
            }

            for sv in cell.contentView.subviews { sv.removeFromSuperview() }
            if let msv = measureCells![indexPath.row]
            {
                let img = msv.arrangedSubviews[0] as! UIImageView
                let lbl = msv.arrangedSubviews[1] as! UILabel
                img.image = PreviewManager.iconForSampleType(sampleType)
                lbl.text = sampleType.displayText

                measureCells![indexPath.row]!.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(measureCells![indexPath.row]!)
                let constraints: [NSLayoutConstraint] = [
                    img.widthAnchor.constraintEqualToConstant(44),
                    img.heightAnchor.constraintEqualToConstant(44),
                    img.leadingAnchor.constraintEqualToAnchor(cell.contentView.leadingAnchor),
                    lbl.leadingAnchor.constraintEqualToAnchor(img.trailingAnchor, constant: 10),
                    measureCells![indexPath.row]!.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    measureCells![indexPath.row]!.leadingAnchor.constraintEqualToAnchor(cell.contentView.leadingAnchor),
                    measureCells![indexPath.row]!.widthAnchor.constraintEqualToAnchor(cell.contentView.widthAnchor),
                    measureCells![indexPath.row]!.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor),
                ]
                cell.contentView.addConstraints(constraints)
            }
            cell.accessoryType = .DisclosureIndicator


            cell.clipsToBounds = true
            return cell
        }

        if formCells[indexPath.section] == nil {
            formCells[indexPath.section] = [FormCell?](count: self.sectionSizes[indexPath.section], repeatedValue: nil)
        }

        if formCells[indexPath.section]![indexPath.row] == nil
        {
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

                // Subviews (incl. recommended and optional fields, as well as consent PDF viewer).
                if ( subviews.contains(profile[indexPath.row].0) ) {
                    cellInput.text = nil
                    cellInput.enabled = false
                } else {
                    cellInput.text = cachedProfile[profile[indexPath.row].1] as? String
                    cellInput.keyboardType = UIKeyboardType.Alphabet
                    cellInput.returnKeyType = UIReturnKeyType.Done
                    cellInput.enabled = true
                }

            default:
                log.error("Invalid settings tableview section")
            }

            formCells[indexPath.section]!.insert(formCell, atIndex: indexPath.row)
        }

        for sv in cell.contentView.subviews { sv.removeFromSuperview() }
        if let cellArray = formCells[indexPath.section], formCell = cellArray[indexPath.row]
        {
            if indexPath.section == 3 && subviews.contains(profile[indexPath.row].0) {
                cell.accessoryType = .DisclosureIndicator
            } else {
                cell.accessoryType = .None
            }
            cell.contentView.addSubview(formCell)
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
        else if ( indexPath.section == 3 && profile[indexPath.row].0 == "Consent" ) {
            let consentVC = ConsentViewController()
            navigationController?.pushViewController(consentVC, animated: true)
        }
        else if ( indexPath.section == 3 && profile[indexPath.row].0 == "Recommended" ) {
            profileSubview("Recommended",
                fields: Array(UserProfile.profileFields[UserProfile.recommendedRange]),
                placeholders: Array(UserProfile.profilePlaceholders[UserProfile.recommendedRange]))
        }
        else if ( indexPath.section == 3 && profile[indexPath.row].0 == "Optional" ) {
            profileSubview("Optional",
                fields: Array(UserProfile.profileFields[UserProfile.optionalRange]),
                placeholders: Array(UserProfile.profilePlaceholders[UserProfile.optionalRange]))
        }
        else if ( withDebugView && indexPath.section == 5 ) {
            let debugVC = DebugViewController()
            navigationController?.pushViewController(debugVC, animated: true)
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
                
            case 4...6:
                let key = profile[textField.tag - 4].1
                UserManager.sharedManager.pushProfile([key:txt], completion: {_ in return})
                textField.resignFirstResponder()
                UINotifications.profileUpdated(self.navigationController!)

            default:
                return false
            }
        }
        return false
    }

    func profileSubview(txt: String, fields: [String], placeholders: [String]) {
        let subVC = ProfileSubviewController()
        subVC.subviewDesc = "\(txt) profile"
        subVC.bgColor = .whiteColor()
        subVC.txtColor = .blackColor()
        subVC.plcColor = .grayColor()
        subVC.profileFields = fields
        subVC.profilePlaceholders = placeholders
        subVC.profileUpdater = { (k,v) in UserManager.sharedManager.pushProfile([k:v], completion: {_ in return}) }
        navigationController?.pushViewController(subVC, animated: true)
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

    // TODO: Dodo dialog for wifi-availability warning
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