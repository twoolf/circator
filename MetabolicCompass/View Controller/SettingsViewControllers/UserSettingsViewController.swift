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
import Async
import Former
import SwiftDate
import SwiftyUserDefaults

let USNDidUpdateBlackoutNotification = "USNDidUpdateBlackoutNotification"

let userSettingsHeaderFontSize: CGFloat = 20.0
let userSettingsFontSize: CGFloat = 16.0

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

    var reminder: Int! = nil
    var blackoutTimes: [NSDate] = []

    // Reminder period in minutes
    static let reminderOptions: [Int] = [ /*1, 2, 5, 10,*/ 120, 240, 360, 480, 720, 1440, 2880, 4320, -1 ]

    // UI Components
    var hotwordInput: TextFieldRowFormer<FormTextFieldCell>! = nil
    var syncInput: TextFieldRowFormer<FormTextFieldCell>! = nil
    var reminderInput: InlinePickerRowFormer<FormInlinePickerCell, Int>! = nil
    var blackoutStartInput: InlineDatePickerRowFormer<FormInlineDatePickerCell>! = nil
    var blackoutEndInput: InlineDatePickerRowFormer<FormInlineDatePickerCell>! = nil
    var remoteLogSwitchRow: SwitchRowFormer<FormSwitchCell>! = nil
    var remoteLogConfigLabel: LabelRowFormer<FormLabelCell>! = nil

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

        reminder = getNotificationReminderFrequency()
        blackoutTimes = getNotificationBlackoutTimes()
    }

    func reloadData() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Right

        let placeholderAttrs: [String: AnyObject] = [
            NSForegroundColorAttributeName: UIColor.lightGrayColor(),
            NSParagraphStyleAttributeName: paragraphStyle
        ]

        hotwordInput.attributedPlaceholder = NSAttributedString(string: hotword, attributes: placeholderAttrs)
        syncInput.attributedPlaceholder = NSAttributedString(string: "\(refresh)", attributes: placeholderAttrs)

        if reminder != nil {
            let index = UserSettingsViewController.reminderOptions.indexOf(reminder)!
            reminderInput.selectedRow = index
        }

        blackoutStartInput.date = blackoutTimes[0]
        blackoutEndInput.date = blackoutTimes[1]

        hotwordInput.update()
        syncInput.update()
        reminderInput.update()
        blackoutStartInput.update()
        blackoutEndInput.update()
    }

    func dataChanged() -> Bool {
        let partial = hotword == UserManager.sharedManager.getHotWords()
                        && refresh == UserManager.sharedManager.getRefreshFrequency()

        let savedReminder = Defaults.objectForKey(USNReminderFrequencyKey) as? Int
        let savedTimes = Defaults.objectForKey(USNBlackoutTimesKey) as? [NSDate]

        return !(partial && (savedReminder == nil ? true : (savedReminder! == reminder))
                         && (savedTimes == nil ? true : (savedTimes! == blackoutTimes)) )
    }

    private func setupNavBar() {
        if rightButton == nil { rightButton = createBarButtonItem(lsSaveTitle, action: #selector(rightAction)) }
        if leftButton == nil { leftButton = createBarButtonItem(lsCancelTitle, action: #selector(leftAction)) }
        self.navigationItem.rightBarButtonItem = edited ? rightButton : nil
        self.navigationItem.leftBarButtonItem = edited ? leftButton : nil
    }

    func doReset() {
        setupSettings()
        reloadData()
    }

    func doSave() {
        // Validate
        if hotword.isEmpty {
            let emptyHotword = "Empty Siri hotword, please enter a valid phrase"
            self.showAlert(withMessage: emptyHotword, title: "Failed to save settings".localized)
            return
        }

        if refresh < 30 {
            let tooLowRefresh = "The cloud refresh value must be at least 30 seconds"
            self.showAlert(withMessage: tooLowRefresh, title: "Failed to save settings".localized)
            return
        }

        // Saving
        if reminder != nil { Defaults.setObject(reminder!, forKey: USNReminderFrequencyKey) }
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

        // Post to recalculate local notification firing times.
        NSNotificationCenter.defaultCenter().postNotificationName(USNDidUpdateBlackoutNotification, object: nil)
    }

    func rightAction(sender: UIBarButtonItem) {
        doSave()
    }

    func leftAction(sender: UIBarButtonItem) {
        if dataChanged() {
            let lsConfirmTitle = "Confirm cancel".localized
            let lsConfirmMessage = "Your changes have not been saved yet. Continue without saving?".localized
            let confirmAlert = UIAlertController(title: lsConfirmTitle, message: lsConfirmMessage, preferredStyle: UIAlertControllerStyle.Alert)
            confirmAlert.addAction(UIAlertAction(title: "Yes".localized, style: .Default, handler: { (action: UIAlertAction!) in
                self.doReset()
                self.toggleEditing(false)
            }))
            confirmAlert.addAction(UIAlertAction(title: "No".localized, style: .Cancel, handler: nil))
            presentViewController(confirmAlert, animated: true, completion: nil)
        } else {
            self.toggleEditing(false)
        }
    }

    func setupFormer() {
        tableView.backgroundView = UIImageView(image: UIImage(named: "university_logo"))
        tableView.backgroundView?.contentMode = .Center
        tableView.backgroundView?.layer.opacity = 0.02

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

        hotwordInput = appRows[0]
        syncInput = appRows[1]

        let reminderRow =
            InlinePickerRowFormer<FormInlinePickerCell, Int>() {
                $0.backgroundColor = .clearColor()
                $0.titleLabel.text = "Data Entry Reminder"
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                $0.displayLabel.textColor = .lightGrayColor()
                $0.displayLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                }.configure {
                    $0.pickerItems = UserSettingsViewController.reminderOptions.map {
                        var label = ""
                        if $0 < 0          { label = "Never" }
                        else if $0 == 1440 { label = "Every day" }
                        else if $0 == 60   { label = "Every hour" }
                        else if $0 > 1440  { label = "\($0/1440) days" }
                        else if $0 > 60    { label = "\($0/60) hours" }
                        else               { label = "\($0) minutes" }
                        return InlinePickerItem(title: label, value: $0)
                    }
                    $0.displayEditingColor = .whiteColor()
            }

        let reminderIndex = self.reminder == nil ? 0 : (UserSettingsViewController.reminderOptions.indexOf(self.reminder) ?? 0)
        reminderRow.selectedRow = reminderIndex
        reminderRow.update()

        reminderRow.onValueChanged {
            self.toggleEditing()
            self.reminder = $0.value
        }

        reminderInput = reminderRow

        let blackoutTimesRows = ["Blackout Start Time", "Blackout End Time"].enumerate().map { (index, rowName) in
            return InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
                $0.backgroundColor = .clearColor()
                $0.titleLabel.text = rowName
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                $0.displayLabel.textColor = .lightGrayColor()
                $0.displayLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
                }.inlineCellSetup {
                    $0.datePicker.datePickerMode = .Time
                    $0.datePicker.minuteInterval = 5
                    $0.datePicker.date = self.blackoutTimes[index]
                }.configure {
                    $0.displayEditingColor = .whiteColor()
                    $0.date = self.blackoutTimes[index]
                }.displayTextFromDate(mediumTimeNoDate)
        }

        blackoutTimesRows[0].onDateChanged { self.toggleEditing(); self.blackoutTimes[0] = $0 }
        blackoutTimesRows[1].onDateChanged { self.toggleEditing(); self.blackoutTimes[1] = $0 }

        blackoutStartInput = blackoutTimesRows[0]
        blackoutEndInput = blackoutTimesRows[1]

        var notificationsRows: [RowFormer] = [reminderRow]
        blackoutTimesRows.forEach { notificationsRows.append($0) }

        let headers = ["Application", "Notifications", "Debug"].map { sectionName in
            return LabelViewFormer<FormLabelHeaderView> {
                $0.contentView.backgroundColor = .clearColor()
                $0.titleLabel.backgroundColor = .clearColor()
                $0.titleLabel.textColor = .lightGrayColor()
                $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsHeaderFontSize)!

                if sectionName == "Debug" {
                    let button: MCButton = {
                        let button = MCButton(frame: CGRectMake(0, 0, 66, 66), buttonStyle: .Rounded)
                        button.buttonColor = .clearColor()
                        button.shadowColor = .clearColor()
                        button.shadowHeight = 0
                        button.setImage(UIImage(named: "icon-debug-refresh"), forState: .Normal)
                        button.imageView?.contentMode = .ScaleAspectFit
                        button.addTarget(self, action: #selector(self.refreshRemoteLogConfig(_:)), forControlEvents: .TouchUpInside)
                        return button
                    }()

                    button.translatesAutoresizingMaskIntoConstraints = false
                    $0.contentView.addSubview(button)

                    let buttonConstraints : [NSLayoutConstraint] = [
                        $0.contentView.topAnchor.constraintEqualToAnchor(button.topAnchor),
                        $0.contentView.bottomAnchor.constraintEqualToAnchor(button.bottomAnchor),
                        $0.contentView.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor, constant: 10),
                        button.widthAnchor.constraintEqualToConstant(66),
                        button.heightAnchor.constraintEqualToConstant(66),
                        $0.titleLabel.heightAnchor.constraintEqualToAnchor(button.heightAnchor)
                    ]
                    
                    $0.contentView.addConstraints(buttonConstraints)
                }

                }.configure { view in
                    view.viewHeight = 66
                    view.text = sectionName
            }
        }

        remoteLogSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.backgroundColor = .clearColor()
            $0.titleLabel.text = "Remote Logging"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
            }.configure {
                $0.switched = RemoteLogManager.sharedManager.log.remote()
            }.onSwitchChanged { switched in ()
                if switched { self.remoteLogAction(switched) }
                else { RemoteLogManager.sharedManager.log.setRemote(switched) }
        }

        remoteLogConfigLabel = LabelRowFormer<FormLabelCell>() {
            $0.backgroundColor = .clearColor()
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
            $0.subTextLabel.textColor = .lightGrayColor()
            $0.subTextLabel.font = UIFont(name: "GothamBook", size: userSettingsFontSize)!
            }.configure { form in
                form.text = "Log configuration"
                form.subText = RemoteLogManager.sharedManager.log.configName
        }

        let debugRows: [RowFormer] = [remoteLogSwitchRow, remoteLogConfigLabel]

        let appSection = SectionFormer(rowFormers: appRows).set(headerViewFormer: headers[0])
        let notificationsSection = SectionFormer(rowFormers: notificationsRows).set(headerViewFormer: headers[1])
        let debugSection = SectionFormer(rowFormers: debugRows).set(headerViewFormer: headers[2])
        former.append(sectionFormer: appSection, notificationsSection, debugSection)
    }

    func remoteLogAction(activate: Bool) {
        let alertController = UIAlertController(title: nil, message: "Remote logging can use lots of data, we recommend you connect over WIFI first. Do you want to proceed?", preferredStyle: .Alert)

        let proceedAction = UIAlertAction(title: "Yes", style: .Default) {
            (alertAction: UIAlertAction!) in
            RemoteLogManager.sharedManager.log.setRemote(activate)
        }

        let cancelAction = UIAlertAction(title: "No", style: .Cancel) {
            (alertAction: UIAlertAction!) in
            self.remoteLogSwitchRow.cell.formSwitch().setOn(false, animated: true)
        }

        alertController.addAction(proceedAction)
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func refreshRemoteLogConfig(sender: UIButton) {
        if RemoteLogManager.sharedManager.log.remote() {
            log.info("RemoteLogManager reconfiguring...")
            RemoteLogManager.sharedManager.reconfigure { success in
                log.info("RemoteLogManager reconfiguration \(success ? "successful" : "failed")!")
                Async.main(after: 0.2) {
                    log.info("RemoteLogManager config name \(RemoteLogManager.sharedManager.log.configName)")
                    self.remoteLogConfigLabel.cellUpdate {
                        $0.subTextLabel.text = RemoteLogManager.sharedManager.log.configName
                        $0.subTextLabel.setNeedsDisplay()
                    }
                }
            }
        } else {
            log.info("Skipping RemoteLogManager configuration refresh (not in remote mode)")
        }
    }
}