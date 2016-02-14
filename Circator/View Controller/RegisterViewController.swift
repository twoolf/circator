//
//  RegisterViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/21/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import CircatorKit
import UIKit
import Async
import Former

class RegisterViewController : FormViewController {

    var profileValues : [String: String] = [:]

    var recommendedSubview : ProfileSubviewController! = nil
    var optionalSubview : ProfileSubviewController! = nil

    // TODO: gender, race, marital status, education level, annual income

    internal var consentOnLoad : Bool = false
    internal var registerCompletion : (Void -> Void)?
    internal var parentView: IntroViewController?

    private var stashedUserId : String?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "User Registration"
    }

    func doConsent() {
        stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(self) {
            [weak self] (consented) -> Void in
            guard consented else {
                UserManager.sharedManager.resetFull()
                if let user = self!.stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                self!.navigationController?.popViewControllerAnimated(true)
                return
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if ( consentOnLoad ) { doConsent() }

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        let profileDoneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doSignup:")
        navigationItem.rightBarButtonItem = profileDoneButton

        var profileFieldRows = (0..<UserProfile.profileFields.count).map { index -> RowFormer in
            let text = UserProfile.profileFields[index]
            let placeholder = UserProfile.profilePlaceholders[index]

            return TextFieldRowFormer<FormTextFieldCell>() {
                $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
                $0.tintColor = .blueColor()
                $0.titleLabel.text = text
                $0.titleLabel.textColor = .whiteColor()
                $0.titleLabel.font = .boldSystemFontOfSize(16)
                $0.textField.textColor = .whiteColor()
                $0.textField.font = .boldSystemFontOfSize(14)
                $0.textField.textAlignment = .Right
                $0.textField.returnKeyType = .Next

                $0.textField.autocorrectionType = UITextAutocorrectionType.No
                $0.textField.autocapitalizationType = UITextAutocapitalizationType.None
                $0.textField.keyboardType = UIKeyboardType.Default

                if text == "Password" {
                    $0.textField.secureTextEntry = true
                }
                else if text == "Email" {
                    $0.textField.keyboardType = UIKeyboardType.EmailAddress
                }

                }.configure {
                    let attrs = [NSForegroundColorAttributeName: UIColor.lightGrayColor()]
                    $0.attributedPlaceholder = NSAttributedString(string:placeholder, attributes: attrs)
                }.onTextChanged { [weak self] txt in
                    self?.profileValues[text] = txt
            }
        }

        let requiredFields = profileFieldRows[UserProfile.requiredRange]
        let requiredHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.textColor = .whiteColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Required"
        }
        let requiredSection = SectionFormer(rowFormers: Array(requiredFields)).set(headerViewFormer: requiredHeader)

        let recFields = UserProfile.profileFields[UserProfile.recommendedRange]
        let recPlaceholders = UserProfile.profilePlaceholders[UserProfile.recommendedRange]

        let optFields = UserProfile.profileFields[UserProfile.optionalRange]
        let optPlaceholders = UserProfile.profilePlaceholders[UserProfile.optionalRange]

        let submenuFields = [ submenu("Recommended", fields: Array(recFields), placeholders: Array(recPlaceholders)),
                              submenu("Optional", fields: Array(optFields), placeholders: Array(optPlaceholders))
                            ]

        let submenuHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.textColor = .whiteColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Physiological Profile"
        }
        let submenuSection = SectionFormer(rowFormers: Array(submenuFields)).set(headerViewFormer: submenuHeader)

        former.append(sectionFormer: requiredSection, submenuSection)
    }

    func validateProfile() -> (String, String, String, String)? {
        if let em = profileValues[UserProfile.profileFields[UserProfile.emailIdx]],
           let pw = profileValues[UserProfile.profileFields[UserProfile.passwIdx]],
           let fn = profileValues[UserProfile.profileFields[UserProfile.fnameIdx]],
           let ln = profileValues[UserProfile.profileFields[UserProfile.lnameIdx]]
        {
            return (em, pw, fn, ln)
        } else {
            return nil
        }
    }

    func doWelcome() {
        navigationController?.popViewControllerAnimated(true)
        Async.main {
            self.parentView?.view.dodo.style.bar.hideAfterDelaySeconds = 3
            self.parentView?.view.dodo.style.bar.hideOnTap = true
            self.parentView?.view.dodo.success("Welcome " + (UserManager.sharedManager.getUserId() ?? ""))
            self.parentView?.initializeBackgroundWork()
        }
    }

    func doSignup(sender: UIButton) {
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(self, pop: true)
            return
        }

        guard let (user, pass, fname, lname) = validateProfile() else {
            UINotifications.invalidProfile(self)
            return
        }

        UserManager.sharedManager.overrideUserPass(user, pass: pass)
        UserManager.sharedManager.register(fname, lastName: lname) { (_, error) in
            guard !error else {
                // Reset to previous user id, and clean up any partial consent document on registration errors.
                UserManager.sharedManager.resetFull()
                if let user = self.stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                ConsentManager.sharedManager.removeConsentFile(consentPath)
                UINotifications.registrationError(self, pop: true)
                BehaviorMonitor.sharedInstance.register(false)
                return
            }

            let initialProfile = Dictionary(pairs:
                self.profileValues.filter { (k,v) in UserProfile.updateableMapping[k] != nil }.map { (k,v) in
                    (UserProfile.updateableMapping[k]!, v)
                })

            // Log in and update consent after successful registration.
            UserManager.sharedManager.loginWithPush(initialProfile) { (error, reason) in
                guard !error else {
                    UINotifications.loginFailed(self, pop: true, reason: reason)
                    BehaviorMonitor.sharedInstance.register(false)
                    return
                }

                UserManager.sharedManager.pushConsent(consentPath) { _ in
                    ConsentManager.sharedManager.removeConsentFile(consentPath)
                    self.doWelcome()
                    if let comp = self.registerCompletion { comp() }
                    BehaviorMonitor.sharedInstance.register(true)
                }
            }
        }
    }

    func submenu(text: String, fields: [String], placeholders: [String]) -> RowFormer {
        return LabelRowFormer<FormLabelCell>() { row in
            row.backgroundColor = Theme.universityDarkTheme.backgroundColor
            row.tintColor = .blueColor()
            row.textLabel?.text = text
            row.textLabel?.textColor = .whiteColor()
            row.textLabel?.font = .boldSystemFontOfSize(16)
            row.accessoryType = .DisclosureIndicator
            }.onSelected { _ in
                let subVC = ProfileSubviewController()
                subVC.profileFields = fields
                subVC.profilePlaceholders = placeholders
                subVC.profileUpdater = { kvv in self.updateProfile(kvv) }
                subVC.subviewDesc = "\(text) profile"
                self.navigationController?.pushViewController(subVC, animated: true)
        }
    }

    func updateProfile(kvv: (String, String, UIViewController?)) {
        if let mappedK = UserProfile.profileMapping[kvv.0] {
            UserManager.sharedManager.pushProfile([mappedK:kvv.1], completion: {_ in return})
        } else {
            log.error("No mapping found for profile update: \(kvv.0) = \(kvv.1)")
            if let vc = kvv.2 { UINotifications.genericError(vc, msg: "Invalid profile field") }
        }
    }
}
