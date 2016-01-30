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


    static let profileFields = ["Email", "Password", "First name", "Last name", "Age", "Weight", "Height"]
    static let profilePlaceholders = ["example@gmail.com", "Required", "Jane or John", "Doe", "24", "160lb" ,"180cm"]
    var profileValues : [String: String] = [:]

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

        var profileFieldRows = (0..<RegisterViewController.profileFields.count).map { index -> RowFormer in
            let text = RegisterViewController.profileFields[index]
            let placeholder = RegisterViewController.profilePlaceholders[index]

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

        let requiredFields = profileFieldRows[0...3]
        let requiredHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.textColor = .whiteColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Required"
        }
        let requiredSection = SectionFormer(rowFormers: Array(requiredFields)).set(headerViewFormer: requiredHeader)

        let optionalFields = profileFieldRows[4...6]
        let optionalHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.textColor = .whiteColor()
            }.configure { view in
                view.viewHeight = 44
                view.text = "Optional"
        }
        let optionalSection = SectionFormer(rowFormers: Array(optionalFields)).set(headerViewFormer: optionalHeader)
        
        former.append(sectionFormer: requiredSection, optionalSection)
    }

    func validateProfile() -> (String, String, String, String)? {
        if let em = profileValues["Email"],
           let pw = profileValues["Password"],
           let fn = profileValues["First name"],
           let ln = profileValues["Last name"]
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
    
    func noConsent() {
        navigationController?.popViewControllerAnimated(true)
        Async.main {
            self.parentView?.view.dodo.style.bar.hideAfterDelaySeconds = 3
            self.parentView?.view.dodo.style.bar.hideOnTap = true
            self.parentView?.view.dodo.error("ResearchKit study not consented!")
        }
    }

    func registrationError() {
        navigationController?.popViewControllerAnimated(true)
        Async.main {
            self.parentView?.view.dodo.style.bar.hideAfterDelaySeconds = 3
            self.parentView?.view.dodo.style.bar.hideOnTap = true
            self.parentView?.view.dodo.error("Error in signing up, please try later.")
        }
    }

    func invalidProfile() {
        self.view.dodo.style.bar.hideAfterDelaySeconds = 3
        self.view.dodo.style.bar.hideOnTap = true
        self.view.dodo.error("Please fill in all required fields!")
    }

    func doSignup(sender: UIButton) {
        guard let consentPath = ConsentManager.sharedManager.getConsentFilePath() else {
            noConsent()
            return
        }
        
        guard let (user, pass, fname, lname) = validateProfile() else {
            invalidProfile()
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
                self.registrationError()
                return
            }

            // Log in and update profile metadata after successful registration.
            UserManager.sharedManager.loginWithCompletion { _ in
                let userKeys = ["Age": "age", "Weight": "weight", "Height": "height"]
                let userDict = self.profileValues.filter { (k,v) in userKeys[k] != nil }.map { (k,v) in (userKeys[k]!, v) }
                UserManager.sharedManager.pushProfileWithConsent(consentPath, metadata: Dictionary(pairs: userDict)) { _ in
                    ConsentManager.sharedManager.removeConsentFile(consentPath)
                    self.doWelcome()
                    if let comp = self.registerCompletion {
                        comp()
                    }
                }
            }
        }
    }
}
