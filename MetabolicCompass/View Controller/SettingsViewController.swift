//
//  SettingsViewController.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import Former
import HTPressableButton
import Crashlytics
import SwiftDate
import SafariServices

private let fieldCount           : Int   = UserProfile.sharedInstance.updateableReqRange.count+4

private let debugSectionSizes    : [Int] = [2,2,7,fieldCount,2,2,1]
private let releaseSectionSizes  : [Int] = [2,2,7,fieldCount,2,2]

private let debugSectionTitles    : [String] = ["Login", "Settings", "Preview Rows", "Profile", "Bulk Upload", "Account Management", "Debug"]
private let releaseSectionTitles  : [String] = ["Login", "Settings", "Preview Rows", "Profile", "Bulk Upload", "Account Management"]

class MCButton : HTPressableButton {

}

/**
 This class enables the settings view (top right corner of the App) by letting the user choose between different metrics, different default options, different ways to interact with Siri, and even whether to remain within the study.

 - note: this view controls bulk upload from HealthKit history
 */
class SettingsViewController: UITableViewController, UITextFieldDelegate, SFSafariViewControllerDelegate {

    var introView : IntroViewController! = nil

    private var formCells : [Int:[FormCell?]] = [:]

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    private var measureCells : [UIStackView?]?
    private var debugCell: FormLabelCell?
    private var historySlider : FormSliderCell? = nil

    private var sectionSizes  : [Int]    = Deployment.sharedInstance.withDebugView ? debugSectionSizes  : releaseSectionSizes
    private var sectionTitles : [String] = Deployment.sharedInstance.withDebugView ? debugSectionTitles : releaseSectionTitles

    private var hMin = 0.0
    private var hMax = 0.0

    private var uploadButton: UIButton? = nil
    private var resetPassButton: UIButton? = nil
    private var withdrawButton: UIButton? = nil

    private var profile : [(String, String, String, Int)] = []
    private var subviews = ["Consent", "Recommended", "Optional", "Repeated Events"]

    init() {
        super.init(style: UITableViewStyle.Grouped)
        initProfile()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initProfile()
    }

    func initProfile() {
        profile = UserProfile.sharedInstance.updateableReqRange.enumerate().map { (i, j) in
            let k = UserProfile.sharedInstance.profileFields[j]
            let v = UserProfile.sharedInstance.updateableMapping[k]!
            let p = UserProfile.sharedInstance.profilePlaceholders[j]
            return (k, v, p, 4+i)
        }
        let n = profile.count
        profile.append(("Consent", "consent",  "PDF", 4 + n))
        profile.append(("Recommended", "",     "",    5 + n))
        profile.append(("Optional",    "",     "",    6 + n))
        profile.append(("Repeated Events", "", "",    7 + n))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Settings"
        tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("Settings",
            contentType: "",
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
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
        if (indexPath.section == 4 && indexPath.row == 0) { return 65.0 }
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

        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero

        if Deployment.sharedInstance.withDebugView && indexPath.section == 6 {
            if debugCell == nil {
                debugCell = FormLabelCell()
                debugCell?.tintColor = Theme.universityDarkTheme.backgroundColor
                debugCell?.formTextLabel()?.text = "Debug"
            }

            cell.imageView?.image = nil
            cell.accessoryType = .DisclosureIndicator

            for sv in cell.contentView.subviews { sv.removeFromSuperview() }
            cell.contentView.addSubview(debugCell!)
            return cell
        }

        if indexPath.section == 5 {
            if indexPath.row == 0 && resetPassButton == nil {
                resetPassButton = {
                    let button = MCButton(frame: cell.contentView.frame, buttonStyle: .Rounded)
                    button.cornerRadius = 4.0
                    button.buttonColor = UIColor.ht_sunflowerColor()
                    button.shadowColor = UIColor.ht_citrusColor()
                    button.shadowHeight = 4
                    button.setTitle("Reset Password", forState: .Normal)
                    button.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
                    button.addTarget(self, action: "doResetPassword:", forControlEvents: .TouchUpInside)
                    button.enabled = UserManager.sharedManager.hasUserId()
                    return button
                }()
            } else if indexPath.row == 1 && withdrawButton == nil {
                withdrawButton = {
                    let button = MCButton(frame: cell.contentView.frame, buttonStyle: .Rounded)
                    button.cornerRadius = 4.0
                    button.buttonColor = UIColor.ht_alizarinColor()
                    button.shadowColor = UIColor.ht_pomegranateColor()
                    button.shadowHeight = 4
                    button.setTitle("Delete Account", forState: .Normal)
                    button.titleLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightRegular)
                    button.addTarget(self, action: "doDeleteAccount:", forControlEvents: .TouchUpInside)
                    button.enabled = UserManager.sharedManager.hasUserId()
                    return button
                }()
            }

            for sv in cell.contentView.subviews { sv.removeFromSuperview() }
            cell.textLabel?.hidden = true
            cell.imageView?.image = nil
            cell.accessoryType = .None
            cell.selectionStyle = .None

            let button = indexPath.row == 0 ? resetPassButton : withdrawButton
            button!.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(button!)
            let constraints: [NSLayoutConstraint] = [
                button!.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                button!.leadingAnchor.constraintEqualToAnchor(cell.contentView.leadingAnchor),
                button!.trailingAnchor.constraintEqualToAnchor(cell.contentView.trailingAnchor),
                button!.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor)
            ]
            cell.contentView.addConstraints(constraints)
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
            cell.selectionStyle = .None

            if indexPath.row == 0 {
                historySlider!.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(historySlider!)
                let constraints: [NSLayoutConstraint] = [
                    historySlider!.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    historySlider!.leadingAnchor.constraintEqualToAnchor(cell.contentView.leadingAnchor),
                    historySlider!.trailingAnchor.constraintEqualToAnchor(cell.contentView.trailingAnchor),
                    historySlider!.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor)
                ]
                cell.contentView.addConstraints(constraints)
            }
            else {
                uploadButton!.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(uploadButton!)
                let constraints: [NSLayoutConstraint] = [
                    uploadButton!.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    uploadButton!.leadingAnchor.constraintEqualToAnchor(cell.contentView.leadingAnchor),
                    uploadButton!.trailingAnchor.constraintEqualToAnchor(cell.contentView.trailingAnchor),
                    uploadButton!.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor)
                ]
                cell.contentView.addConstraints(constraints)
            }
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
                    stackView.spacing = 15
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
                    img.widthAnchor.constraintEqualToConstant(32),
                    img.heightAnchor.constraintEqualToAnchor(measureCells![indexPath.row]!.heightAnchor),
                    lbl.trailingAnchor.constraintEqualToAnchor(measureCells![indexPath.row]!.trailingAnchor),
                    measureCells![indexPath.row]!.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    measureCells![indexPath.row]!.leadingAnchor.constraintEqualToAnchor(cell.contentView.layoutMarginsGuide.leadingAnchor),
                    measureCells![indexPath.row]!.trailingAnchor.constraintEqualToAnchor(cell.contentView.layoutMarginsGuide.trailingAnchor),
                    measureCells![indexPath.row]!.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor)
                ]
                cell.contentView.addConstraints(constraints)
            }
            cell.accessoryType = .DisclosureIndicator
            return cell
        }

        if formCells[indexPath.section] == nil {
            formCells[indexPath.section] = [FormCell?](count: self.sectionSizes[indexPath.section], repeatedValue: nil)
        }

        if indexPath.section == 3
            && profile[indexPath.row].0 == "Sex"
            && formCells[indexPath.section]![indexPath.row] == nil
        {
            let formCell = FormSegmentedCell()
            let cellLabel = formCell.formTitleLabel()
            let cellSegment = formCell.formSegmented()

            cellLabel?.text = profile[indexPath.row].0
            cellLabel?.textColor = UIColor.blackColor()
            cellLabel?.backgroundColor = UIColor.whiteColor()

            cellSegment.tintColor = Theme.universityDarkTheme.backgroundColor
            cellSegment.addTarget(self, action: "sexValueChanged:", forControlEvents: .ValueChanged);
            cellSegment.removeAllSegments()
            cellSegment.insertSegmentWithTitle("Male",   atIndex: 0, animated: false)
            cellSegment.insertSegmentWithTitle("Female", atIndex: 1, animated: false)

            let cachedProfile : [String: AnyObject] = UserManager.sharedManager.getProfileCache()
            if let s = cachedProfile[profile[indexPath.row].1] as? String {
                cellSegment.selectedSegmentIndex = s == "Male" ? 0 : ( s == "Female" ? 1 : -1)
            } else {
                cellSegment.selectedSegmentIndex = -1
            }

            formCells[indexPath.section]!.insert(formCell, atIndex: indexPath.row)
        }
        else if formCells[indexPath.section]![indexPath.row] == nil
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
                cell.selectionStyle = .None
            }

            formCell.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(formCell)
            let constraints: [NSLayoutConstraint] = [
                formCell.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                formCell.leadingAnchor.constraintEqualToAnchor(cell.contentView.layoutMarginsGuide.leadingAnchor),
                formCell.trailingAnchor.constraintEqualToAnchor(cell.contentView.layoutMarginsGuide.trailingAnchor, constant: -(ScreenManager.sharedInstance.settingsCellTrailing())),
                formCell.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor)
            ]
            cell.contentView.addConstraints(constraints)
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if ( indexPath.section == 2 ) {
            let rowSettingsVC = RowSettingsViewController()
            rowSettingsVC.selectedRow = indexPath.row
            navigationController?.pushViewController(rowSettingsVC, animated: true)
        }
        else if (indexPath.section == 3) {
            switch profile[indexPath.row].0 {
            case "Consent":
                let consentVC = ConsentViewController()
                navigationController?.pushViewController(consentVC, animated: true)
            case "Recommended":
                profileSubview("Recommended",
                fields: Array(UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.recommendedRange]),
                placeholders: Array(UserProfile.sharedInstance.profilePlaceholders[UserProfile.sharedInstance.recommendedRange]))
            case "Optional":
                profileSubview("Optional",
                fields: Array(UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.optionalRange]),
                placeholders: Array(UserProfile.sharedInstance.profilePlaceholders[UserProfile.sharedInstance.optionalRange]))
            case "Repeated Events":
                let repeatedEventsVC = CircadianBehaviorViewController()
                navigationController?.pushViewController(repeatedEventsVC, animated: true)
            default:
                fatalError()
            }

        }
        else if ( Deployment.sharedInstance.withDebugView && indexPath.section == 6 ) {
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
                    UserManager.sharedManager.login(txt) { res in
                        guard res.ok else {
                            UINotifications.loginFailed(self.navigationController!, reason: res.info)
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

            case 4...7:
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

    func sexValueChanged(sender: UISegmentedControl!) {
        let k = "sex"
        let v = sender.selectedSegmentIndex == 0 ? "Male" : "Female"
        UserManager.sharedManager.pushProfile([k:v], completion: {_ in return})
        UINotifications.profileUpdated(self.navigationController!)
    }

    func profileSubview(txt: String, fields: [String], placeholders: [String]) {
        let subVC = ProfileSubviewController()
        subVC.subviewDesc = "\(txt) inputs"
        subVC.bgColor = .whiteColor()
        subVC.txtColor = .blackColor()
        subVC.plcColor = .grayColor()
        subVC.profileFields = fields
        subVC.profilePlaceholders = placeholders
        subVC.profileUpdater = { kvv in self.updateProfile(kvv) }
        navigationController?.pushViewController(subVC, animated: true)
    }

    func updateProfile(kvv: (String, String, UIViewController?)) {
        if let mappedK = UserProfile.sharedInstance.profileMapping[kvv.0] {
            UserManager.sharedManager.pushProfile([mappedK:kvv.1], completion: {_ in return})
        } else {
            log.error("No mapping found for profile update: \(kvv.0) = \(kvv.1)")
            if let vc = kvv.2 { UINotifications.genericError(vc, msg: "Invalid profile field") }
        }
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

    func doDeleteAccount(sender: UIButton) {
        let sheet = UIAlertController(title: "Withdraw from Metabolic Compass", message: "Are you sure you want to delete your account?", preferredStyle: .Alert)
        let yes = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
            UserManager.sharedManager.withdraw(false) { success in
                if success {
                    PopulationHealthManager.sharedManager.resetAggregates()
                    if let iv = self.introView {
                        log.info("Resetting IntroView on deletion")
                        iv.doDataRefresh()
                    }
                    let msg = "Thanks for using Metabolic Compass!"
                    UINotifications.genericMsg(self.navigationController!, msg: msg, pop: true, asNav: true)
                } else {
                    let msg = "Failed to delete account, please try again later"
                    UINotifications.genericError(self.navigationController!, msg: msg, pop: false, asNav: true)
                }
            }
        }
        let no = UIAlertAction(title: "No", style: .Cancel) { action -> Void in () }
        sheet.addAction(yes)
        sheet.addAction(no)
        self.presentViewController(sheet, animated: true, completion: nil)
    }

    func doResetPassword(sender: UIButton) {
        let vc = SFSafariViewController(URL: resetPassURL, entersReaderIfAvailable: true)
        vc.delegate = self
        presentViewController(vc, animated: true, completion: nil)
    }

    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
