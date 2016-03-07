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
import FileKit

private let lblFontSize = ScreenManager.sharedInstance.profileLabelFontSize()
private let inputFontSize = ScreenManager.sharedInstance.profileInputFontSize()

/**
 Used at end of consent flow to set-up Stormpath account and set initial metrics
 
 - note: should only be needed once as part of the electronic consent process
 */
class RegisterViewController : FormViewController {

    var profileValues : [String: String] = [:]

    var recommendedSubview : ProfileSubviewController! = nil
    var optionalSubview : ProfileSubviewController! = nil

    internal var consentOnLoad : Bool = false
    internal var registerCompletion : (Void -> Void)?
    internal var parentView: IntroViewController?

    private var stashedUserId : String?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "User Registration"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        let profileDoneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doSignup:")
        navigationItem.rightBarButtonItem = profileDoneButton

        var profileFieldRows = (0..<UserProfile.sharedInstance.profileFields.count).map { index -> RowFormer in
            let text = UserProfile.sharedInstance.profileFields[index]
            let placeholder = UserProfile.sharedInstance.profilePlaceholders[index]

            if text == "Sex" {
                return SegmentedRowFormer<FormSegmentedCell>() {
                        $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
                        $0.tintColor = .whiteColor()
                        $0.titleLabel.text = text
                        $0.titleLabel.textColor = .whiteColor()
                        $0.titleLabel.font = .boldSystemFontOfSize(lblFontSize)
                    }.configure {
                        $0.segmentTitles = ["Male", "Female"]
                    }.onSegmentSelected { [weak self] index, _ in
                        self?.profileValues[text] = index == 0 ? "Male" : "Female"
                }
            }

            return TextFieldRowFormer<FormTextFieldCell>() {
                $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
                    $0.tintColor = .blueColor()
                    $0.titleLabel.text = text
                    $0.titleLabel.textColor = .whiteColor()
                    $0.titleLabel.font = .boldSystemFontOfSize(lblFontSize)
                    $0.textField.textColor = .whiteColor()
                    $0.textField.font = .boldSystemFontOfSize(inputFontSize)
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

        let requiredFields = profileFieldRows[UserProfile.sharedInstance.requiredRange]
        let requiredHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.textColor = .whiteColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Required"
        }
        let requiredSection = SectionFormer(rowFormers: Array(requiredFields)).set(headerViewFormer: requiredHeader)

        let recFields = UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.recommendedRange]
        let recPlaceholders = UserProfile.sharedInstance.profilePlaceholders[UserProfile.sharedInstance.recommendedRange]

        let optFields = UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.optionalRange]
        let optPlaceholders = UserProfile.sharedInstance.profilePlaceholders[UserProfile.sharedInstance.optionalRange]

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

        if ( consentOnLoad ) { doConsent() }
    }

    override func viewDidDisappear(animated: Bool) {
        // Remove the consent file for any scenario where we leave this view.
        if let consentPath = ConsentManager.sharedManager.getConsentFilePath() {
            let cPath = Path(consentPath)
            if cPath.exists {
                ConsentManager.sharedManager.removeConsentFile(consentPath)
            }
        }
    }

    func validateProfile() -> (String, String, String, String)? {
        if let em = profileValues[UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.emailIdx]],
           let pw = profileValues[UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.passwIdx]],
           let fn = profileValues[UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.fnameIdx]],
           let ln = profileValues[UserProfile.sharedInstance.profileFields[UserProfile.sharedInstance.lnameIdx]]
        {
            return (em, pw, fn, ln)
        } else {
            return nil
        }
    }

    func doConsent() {
        stashedUserId = UserManager.sharedManager.getUserId()
        UserManager.sharedManager.resetFull()
        ConsentManager.sharedManager.checkConsentWithBaseViewController(self.navigationController!) {
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
        UINotifications.genericMsg(self.navigationController!, msg: "Registering account...")
        sender.enabled = false

        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            UINotifications.noConsent(self.navigationController!, pop: true, asNav: true)
            return
        }

        guard let (user, pass, fname, lname) = validateProfile() else {
            UINotifications.invalidProfile(self.navigationController!)
            sender.enabled = true
            return
        }

        UserManager.sharedManager.overrideUserPass(user, pass: pass)
        UserManager.sharedManager.register(fname, lastName: lname) { (_, error, errormsg) in
            guard !error else {
                // Return from this function to allow the user to try registering again with the 'Done' button.
                // We reset the user/pass so that any view exit leaves the app without a registered user.
                // Re-entering this function will use overrideUserPass above to re-establish the account being registered.
                UserManager.sharedManager.resetFull()
                if let user = self.stashedUserId {
                    UserManager.sharedManager.setUserId(user)
                }
                UINotifications.registrationError(self.navigationController!, msg: errormsg)
                BehaviorMonitor.sharedInstance.register(false)
                sender.enabled = true
                return
            }

            let initialProfile = Dictionary(pairs:
                self.profileValues.filter { (k,v) in UserProfile.sharedInstance.updateableMapping[k] != nil }.map { (k,v) in
                    (UserProfile.sharedInstance.updateableMapping[k]!, v)
                })

            // Log in and update consent after successful registration.
            UserManager.sharedManager.loginWithPush(initialProfile) { (error, reason) in
                guard !error else {
                    // Registration completed, but logging in failed. 
                    // Pop this view to allow the user to try logging in again through the
                    // login/logout functionality on the main dashboard.

                    UINotifications.loginFailed(self.navigationController!, pop: true, asNav: true, reason: reason)
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
            row.textLabel?.font = .boldSystemFontOfSize(lblFontSize)
            row.accessoryType = .DisclosureIndicator
            }.onSelected { _ in
                let subVC = ProfileSubviewController()
                subVC.profileFields = fields
                subVC.profilePlaceholders = placeholders
                subVC.profileUpdater = { kvv in self.updateProfile(kvv) }
                subVC.subviewDesc = "\(text) inputs"
                self.navigationController?.pushViewController(subVC, animated: true)
        }
    }

    func updateProfile(kvv: (String, String, UIViewController?)) {
        if let mappedK = UserProfile.sharedInstance.profileMapping[kvv.0] {
            UserManager.sharedManager.pushProfile([mappedK:kvv.1], completion: {_ in return})
        } else {
            log.error("No mapping found for profile update: \(kvv.0) = \(kvv.1)")
            if let vc = kvv.2 { UINotifications.genericError(vc, msg: "Invalid profile field") }
        }
    }
}
