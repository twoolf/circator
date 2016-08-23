//
//  UserSettingsViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 8/22/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import MetabolicCompassKit
import Former
import SwiftDate
import SwiftyUserDefaults

let USNBlackoutTimesKey = "USNBlackoutTimes"

let userSettingsHeaderFontSize: CGFloat = 20.0
let userSettingsFontSize: CGFloat = 16.0

// Default blackout times: 10pm - 6am
func defaultNotificationBlackoutTimes() -> [NSDate] {
    let today = NSDate().startOf(.Day)
    return [today + 22.hours - 1.days, today + 6.hours]
}

class UserSettingsViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!

    private var former: Former! = nil

    var rightButton:UIBarButtonItem?
    var leftButton:UIBarButtonItem?

    let lsSaveTitle = "Save".localized
    let lsCancelTitle = "Cancel".localized

    var edited = false

    var hotword: String! = nil
    var refresh: Int! = nil

    var blackoutTimes: [NSDate] = []

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setupSettings()
        toggleEditing(false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettings()
        self.setupFormer()
    }

    func toggleEditing(asEdited: Bool = true) {
        edited = asEdited
        setupNavBar()
    }

    func setupSettings() {
        hotword = UserManager.sharedManager.getHotWords()
        refresh = UserManager.sharedManager.getRefreshFrequency()
        if let t = Defaults.objectForKey(USNBlackoutTimesKey) as? [NSDate] {
            blackoutTimes = t
        } else {
            blackoutTimes = defaultNotificationBlackoutTimes()
            Defaults.setObject(blackoutTimes, forKey: USNBlackoutTimesKey)
            Defaults.synchronize()
        }
    }

    func dataChanged() -> Bool {
        let partial = hotword == UserManager.sharedManager.getHotWords()
                        && refresh == UserManager.sharedManager.getRefreshFrequency()

        if let times = Defaults.objectForKey(USNBlackoutTimesKey) as? [NSDate] {
            return !(partial && times == blackoutTimes)
        }
        return !partial
    }

    private func setupNavBar() {
        if rightButton == nil { rightButton = createBarButtonItem(lsSaveTitle, action: #selector(rightAction)) }
        if leftButton == nil { leftButton = createBarButtonItem(lsCancelTitle, action: #selector(leftAction)) }
        self.navigationItem.rightBarButtonItem = edited ? rightButton : nil
        self.navigationItem.leftBarButtonItem = edited ? leftButton : nil
    }

    func doReset() {
        setupSettings()
    }

    func doSave() {
        // Validate
        if hotword.isEmpty || refresh < 0 {
            let emptyHotword = "Empty Siri hotword, please enter a valid phrase"
            let subzeroRefresh = "The cloud refresh value must be greater than 0"
            let message = hotword.isEmpty ? emptyHotword : subzeroRefresh
            self.showAlert(withMessage: message, title: "Failed to save settings".localized)
            return
        }

        // Saving
        Defaults.setObject(blackoutTimes, forKey: USNBlackoutTimesKey)
        Defaults.synchronize()

        UserManager.sharedManager.setHotWords(hotword)
        UserManager.sharedManager.setRefreshFrequency(refresh)
        UserManager.sharedManager.syncSettings { res in
            if !res.ok {
                let message = res.info.hasContent ? res.info : "Unable to sync your settings remotely. Please, try later".localized
                self.showAlert(withMessage: message)
            } else {
                UINotifications.genericSuccessMsgOnView(self.view, msg: "Saved your settings")
            }
            self.toggleEditing(false)
        }
    }

    func rightAction(sender: UIBarButtonItem) {
        doSave()
    }

    func leftAction(sender: UIBarButtonItem) {
        if dataChanged() {
            let lsConfirmTitle = "Confirm cancel".localized
            let lsConfirmMessage = "Your changes have not been saved yet. Exit without saving?".localized
            let confirmAlert = UIAlertController(title: lsConfirmTitle, message: lsConfirmMessage, preferredStyle: UIAlertControllerStyle.Alert)
            confirmAlert.addAction(UIAlertAction(title: "Yes".localized, style: .Default, handler: { (action: UIAlertAction!) in
                self.doReset()
            }))
            confirmAlert.addAction(UIAlertAction(title: "No".localized, style: .Cancel, handler: nil))
            presentViewController(confirmAlert, animated: true, completion: nil)
        }
    }

    func setupFormer() {
        tableView.backgroundView = UIImageView(image: UIImage(named: "university_logo"))
        tableView.backgroundView?.contentMode = .Center
        tableView.backgroundView?.layer.opacity = 0.03

        former = Former(tableView: tableView)

        let mediumTimeNoDate: NSDate -> String = { date in
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = .currentLocale()
            dateFormatter.timeStyle = .MediumStyle
            dateFormatter.dateStyle = .NoStyle
            return dateFormatter.stringFromDate(date)
        }

        let appRows = [
            ("Siri Hotword", hotword),
            ("Cloud Sync Rate (secs)", "\(refresh)")
            ].enumerate().map { (index: Int, rowSpec: (String, String)) in
            return TextFieldRowFormer<FormTextFieldCell>() {
                $0.backgroundColor = .clearColor()
                $0.titleLabel.text = rowSpec.0
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                $0.textField.textColor = .whiteColor()
                $0.textField.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                $0.textField.returnKeyType = .Next
                $0.textField.textAlignment = .Right
                }.configure {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .Right

                    let placeholderAttrs: [String: AnyObject] = [
                        NSForegroundColorAttributeName: UIColor.lightGrayColor(),
                        NSParagraphStyleAttributeName: paragraphStyle
                    ]

                    $0.attributedPlaceholder = NSAttributedString(string: rowSpec.1, attributes: placeholderAttrs)
                }.onTextChanged {
                    self.toggleEditing()
                    if index == 0 {
                        UserManager.sharedManager.setHotWords($0)
                    } else if index == 1 {
                        UserManager.sharedManager.setRefreshFrequency(Int($0) ?? 600)
                    }
            }
        }


        let notificationsRows = ["Blackout Start Time", "Blackout End Time"].enumerate().map { (index, rowName) in
            return InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
                $0.backgroundColor = .clearColor()
                $0.titleLabel.text = rowName
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                $0.displayLabel.textColor = .lightGrayColor()
                $0.displayLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                }.inlineCellSetup {
                    $0.datePicker.datePickerMode = .Time
                    $0.datePicker.minuteInterval = 15
                    $0.datePicker.date = self.blackoutTimes[index]
                }.configure {
                    $0.displayEditingColor = .whiteColor()
                    $0.date = self.blackoutTimes[index]
                }.displayTextFromDate(mediumTimeNoDate)
        }

        notificationsRows[0].onDateChanged { self.toggleEditing(); self.blackoutTimes[0] = $0 }
        notificationsRows[1].onDateChanged { self.toggleEditing(); self.blackoutTimes[1] = $0 }

        let headers = ["Application", "Notifications"].map { sectionName in
            return LabelViewFormer<FormLabelHeaderView> {
                $0.contentView.backgroundColor = .clearColor()
                $0.titleLabel.backgroundColor = .clearColor()
                $0.titleLabel.textColor = .lightGrayColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsHeaderFontSize)!

                }.configure { view in
                    view.viewHeight = 66
                    view.text = sectionName
            }
        }

        let appSection = SectionFormer(rowFormers: appRows).set(headerViewFormer: headers[0])
        let notificationsSection = SectionFormer(rowFormers: notificationsRows).set(headerViewFormer: headers[1])
        former.append(sectionFormer: appSection, notificationsSection)

    }
}