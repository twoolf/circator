//
//  RegisterRecommendedViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 2/11/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import CircatorKit
import Former

class ProfileSubviewController : FormViewController {

    var profileFields       : [String] = []
    var profilePlaceholders : [String] = []

    var profileUpdater : ((String, String, UIViewController?) -> Void)? = nil

    internal var subviewDesc : String = "Subview"
    internal var bgColor : UIColor = Theme.universityDarkTheme.backgroundColor
    internal var txtColor : UIColor = .whiteColor()
    internal var plcColor : UIColor = UIColor.lightGrayColor()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = bgColor

        let profileDoneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "updateProfile")
        navigationItem.rightBarButtonItem = profileDoneButton

        let profileFieldRows = (0..<profileFields.count).map { index -> RowFormer in
            let text = profileFields[index]
            let placeholder = profilePlaceholders[index]

            return TextFieldRowFormer<FormTextFieldCell>() {
                $0.backgroundColor = self.bgColor
                $0.tintColor = .blueColor()
                $0.titleLabel.text = text
                $0.titleLabel.textColor = self.txtColor
                $0.titleLabel.font = .boldSystemFontOfSize(16)
                $0.textField.textColor = self.txtColor
                $0.textField.font = .boldSystemFontOfSize(14)
                $0.textField.textAlignment = .Right
                $0.textField.returnKeyType = .Next

                $0.textField.autocorrectionType = UITextAutocorrectionType.No
                $0.textField.autocapitalizationType = UITextAutocapitalizationType.None
                $0.textField.keyboardType = UIKeyboardType.Default

                }.configure {
                    let attrs = [NSForegroundColorAttributeName: plcColor]
                    $0.attributedPlaceholder = NSAttributedString(string:placeholder, attributes: attrs)
                }.onTextChanged { [weak self] txt in
                    if let f = self?.profileUpdater {
                        log.info("Updating profile: \(text) = \(txt)")
                        f(text, txt, self?.navigationController)
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

    func updateProfile() {
        log.info("Updating profile..")
        navigationController?.popViewControllerAnimated(true)
    }
}