//
//  RegisterRecommendedViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/11/16. 
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import MetabolicCompassKit
import Former
import Async

private let lblFontSize = ScreenManager.sharedInstance.profileLabelFontSize()
private let inputFontSize = ScreenManager.sharedInstance.profileInputFontSize()

/**
 This class deals with our default (starting) values for each user on their set of measurements.  We generally expect that real user data will quickly supersede these values. But, enabling the user to think about their best estimates of these numbers and their goals for where they should end up is already an initial 'good' from the onboarding process.
 
 - note: used in RegisterViewController and in SettingsViewController
 */
class ProfileSubviewController : FormViewController {

    var profileFields       : [String] = []
    var profilePlaceholders : [String] = []

    var profileUpdateAsyncs : [Async?] = []
    var profileUpdater : ((String, String, UIViewController?) -> Void)? = nil

    internal var subviewDesc : String = "Subview"
    internal var bgColor : UIColor = Theme.universityDarkTheme.backgroundColor
    internal var txtColor : UIColor = .white
    internal var plcColor : UIColor = UIColor.lightGray

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = bgColor

        let profileDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.updateProfile))
        navigationItem.rightBarButtonItem = profileDoneButton

        profileUpdateAsyncs = Array(repeating: nil, count: profileFields.count)

        let profileFieldRows = (0..<profileFields.count).map { index -> RowFormer in
            let text = profileFields[index]
            let placeholder = profilePlaceholders[index]
            let profile = UserManager.sharedManager.getProfileCache()

            return TextFieldRowFormer<FormTextFieldCell>() {
                $0.backgroundColor = self.bgColor
                $0.tintColor = .blue
                $0.titleLabel.text = text
                $0.titleLabel.textColor = self.txtColor
                $0.titleLabel.font = .boldSystemFont(ofSize: lblFontSize)
                $0.textField.textColor = self.txtColor
                $0.textField.font = .boldSystemFont(ofSize: inputFontSize)
                $0.textField.textAlignment = .right
                $0.textField.returnKeyType = .next

                $0.textField.autocorrectionType = UITextAutocorrectionType.no
                $0.textField.autocapitalizationType = UITextAutocapitalizationType.none
                $0.textField.keyboardType = UIKeyboardType.default

                }.configure {
                    let attrs = [NSAttributedStringKey.foregroundColor: plcColor]
                    $0.attributedPlaceholder = NSAttributedString(string:placeholder, attributes: attrs)

                    if let k = UserProfile.sharedInstance.profileMapping[text], let v = profile[k] as? String {
                        $0.text = v
                    }
                }.onTextChanged { [weak self] txt in
                    if let f = self?.profileUpdater {
                        if let s = self {
                            if let a = s.profileUpdateAsyncs[index] { a.cancel() }
                            s.profileUpdateAsyncs[index] = Async.background(after: 4.0) { f(text, txt, s.navigationController) }
                        } else {
                            f(text, txt, self?.navigationController)
                        }
                    }
            }
        }

        let profileHeader = LabelViewFormer<FormLabelHeaderView> {
            $0.contentView.backgroundColor = self.bgColor
            $0.titleLabel.backgroundColor = self.bgColor
            $0.titleLabel.textColor = self.txtColor
            }.configure { view in
                view.viewHeight = 44
                view.text = subviewDesc
        }

        let profileSection = SectionFormer(rowFormers: Array(profileFieldRows)).set(headerViewFormer: profileHeader)
        former.append(sectionFormer: profileSection)
    }

    @objc func updateProfile() {
//        log.info("Updating profile..")
        navigationController?.popViewController(animated: true)
    }
}
