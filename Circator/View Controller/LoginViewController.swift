//
//  LoginViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/17/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import CircatorKit
import Async
import Former
import Dodo

class LoginViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    var parentView: IntroViewController?
    var completion: (Void -> Void)?

    lazy var logoImageView: UIImageView = {
        let img = UIImageView(frame: CGRectMake(0,0,100,100))
        img.image = UIImage(named: "image-logo")
        img.autoresizingMask = UIViewAutoresizing.FlexibleBottomMargin
        img.clipsToBounds = true
        img.contentMode = UIViewContentMode.ScaleAspectFit
        img.contentScaleFactor = 2.0
        return img
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRectMake(0, 0, 1000, 1000), style: UITableViewStyle.Plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "loginCell")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.scrollEnabled = false
        return tableView
    }()

    lazy var loginLabelButton : UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Login", forState: .Normal)
        button.addTarget(self, action: "doLogin:", forControlEvents: .TouchUpInside)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
        button.setTitleColor(Theme.universityDarkTheme.titleTextColor, forState: .Normal)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var signupLabelButton : UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Signup", forState: .Normal)
        button.addTarget(self, action: "doSignup:", forControlEvents: .TouchUpInside)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightSemibold)
        button.setTitleColor(Theme.universityDarkTheme.titleTextColor, forState: .Normal)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var loginContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews:
                            [self.loginLabelButton, self.signupLabelButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 20
        return stackView
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        tableView.layoutIfNeeded()
    }

    private func configureViews() {
        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        loginContainerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoImageView)
        view.addSubview(tableView)
        view.addSubview(loginContainerView)

        let constraints: [NSLayoutConstraint] = [
            logoImageView.topAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.topAnchor, constant: 110),
            logoImageView.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor),
            logoImageView.widthAnchor.constraintEqualToConstant(100),
            logoImageView.heightAnchor.constraintEqualToConstant(100),
            tableView.topAnchor.constraintEqualToAnchor(logoImageView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.bottomAnchor, constant: -30),

            loginContainerView.topAnchor.constraintEqualToAnchor(logoImageView.bottomAnchor, constant: 110),
            loginContainerView.centerXAnchor.constraintEqualToAnchor(tableView.centerXAnchor),
            loginContainerView.widthAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.widthAnchor, multiplier: 0.7),
            loginContainerView.heightAnchor.constraintEqualToConstant(44)
        ]

        view.addConstraints(constraints)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: self.view.frame.width, bottom: 0, right: 0)
    }

    func doLogin(sender: UIButton) {
        UserManager.sharedManager.ensureUserPass(userCell?.textField.text, pass: passCell?.textField.text) {
            error in
            guard !error else {
                UINotifications.invalidUserPass(self.navigationController!)
                return
            }
            UserManager.sharedManager.loginWithCompletion { (error, _) in
                guard !error else {
                    UINotifications.invalidUserPass(self.navigationController!)
                    return
                }
                if let comp = self.completion { comp() }
                UINotifications.doWelcome(self.parentView!, pop: true, user: UserManager.sharedManager.getUserId() ?? "")
                Async.main { self.parentView?.initializeBackgroundWork() }
            }
        }
    }

    func doSignup(sender: UIButton) {
        let registerVC = RegisterViewController()
        registerVC.parentView = parentView
        registerVC.consentOnLoad = true
        self.navigationController?.pushViewController(registerVC, animated: true)
    }

    // MARK: - Table View

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("loginCell", forIndexPath: indexPath)

        let formCell = FormTextFieldCell()
        let cellInput = formCell.formTextField()
        let cellLabel = formCell.formTitleLabel()

        cell.backgroundColor = Theme.universityDarkTheme.backgroundColor
        cellInput.textColor = Theme.universityDarkTheme.titleTextColor
        cellInput.backgroundColor = Theme.universityDarkTheme.backgroundColor
        cellLabel?.textColor = Theme.universityDarkTheme.titleTextColor
        cellLabel?.backgroundColor = Theme.universityDarkTheme.backgroundColor

        cellInput.textAlignment = NSTextAlignment.Right
        cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
        cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support

        switch indexPath.section {
        case 0:
            if (indexPath.row == 0) {
                cellInput.keyboardType = UIKeyboardType.EmailAddress
                cellInput.returnKeyType = UIReturnKeyType.Next
                cellInput.attributedPlaceholder = NSAttributedString(string:"example@gmail.com",
                    attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
                cellInput.text = UserManager.sharedManager.getUserId()
                cellLabel?.text = "User"
                userCell = formCell
                cellInput.tag = 0
            }
            else {
                cellInput.keyboardType = UIKeyboardType.Default
                cellInput.returnKeyType = UIReturnKeyType.Done
                cellInput.secureTextEntry = true
                cellInput.attributedPlaceholder = NSAttributedString(string:"Required",
                    attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
                cellInput.text = UserManager.sharedManager.getPassword()
                cellLabel?.text = "Password"
                passCell = formCell
                cellInput.tag = 1
            }

        default:
            print("Invalid settings tableview section")
        }

        cell.contentView.addSubview(formCell)

        cellInput.enabled = true
        cellInput.delegate = self
        return cell
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
                }
            default:
                return false
            }
        }
        return false
    }
}
