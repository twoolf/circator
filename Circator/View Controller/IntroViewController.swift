//
//  IntroViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf, Sihao Lu. All rights reserved.
//

import UIKit
import HealthKit
import CircatorKit
import Async
import Dodo
import HTPressableButton
import ResearchKit
import Pages
import Charts
import SwiftDate

let IntroViewTableViewCellIdentifier = "IntroViewTableViewCellIdentifier"
private let mcControlButtonHeight = ScreenManager.sharedInstance.dashboardButtonHeight()

private let hkAccessTimeout = 60.seconds

class IntroViewController: UIViewController,
                           UITableViewDataSource, UIPickerViewDataSource,
                           UITableViewDelegate, UIPickerViewDelegate
{
    private var hkAccessTime : NSDate? = nil         // Time of initial access attempt.
    private var hkAccessAsync : Async? = nil         // Background task to notify if HealthKit is slow to access.
    private var aggregateFetchTask : Async? = nil    // Background task to fetch population aggregates.

    private var pagesController: PagesController!

    lazy var radarController: RadarViewController = { return RadarViewController() }()
    lazy var mealController: EventTimeViewController = { return EventTimeViewController() }()
    private var mealCIndex : Int = 0

    lazy var logoImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "logo_university")!)
        view.tintColor = Theme.universityDarkTheme.foregroundColor
        view.autoresizingMask = UIViewAutoresizing.FlexibleBottomMargin
        view.clipsToBounds = true
        view.contentMode = UIViewContentMode.ScaleAspectFit
        view.contentScaleFactor = 0.2
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(22, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Dashboard", comment: "Metabolic Compass")
        return label
    }()

    lazy var plotButton: UIButton = {
        let image = UIImage(named: "icon_plot") as UIImage?
        let button = MCButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(13,12,12,13)
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = UIColor.ht_emeraldColor()
        button.shadowColor = UIColor.ht_nephritisColor()
        button.shadowHeight = 6
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var plotLabel : UILabel = {
        let pLabel = UILabel()
        pLabel.font = UIFont.systemFontOfSize(10, weight: UIFontWeightRegular)
        pLabel.textColor = Theme.universityDarkTheme.titleTextColor
        pLabel.textAlignment = .Center
        pLabel.text = NSLocalizedString("Plot", comment: "Plot Statistics")
        return pLabel
    }()

    lazy var plotbStack: UIStackView = {
        let pStack = UIStackView(arrangedSubviews: [self.plotButton, self.plotLabel])
        pStack.axis = .Vertical
        pStack.spacing = 2
        return pStack
    }()


    lazy var mealButton: UIButton = {
        let image = UIImage(named: "icon_meal") as UIImage?
        let button = MCButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(11,11,10,10)
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = UIColor.ht_sunflowerColor()
        button.shadowColor = UIColor.ht_citrusColor()
        button.shadowHeight = 6
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var mealLabel : UILabel = {
        let mLabel = UILabel()
        mLabel.font = UIFont.systemFontOfSize(10, weight: UIFontWeightRegular)
        mLabel.textColor = Theme.universityDarkTheme.titleTextColor
        mLabel.textAlignment = .Center
        mLabel.text = NSLocalizedString("Track Meal", comment: "Track Meal")
        return mLabel
    }()

    lazy var mealbStack: UIStackView = {
        let mStack = UIStackView(arrangedSubviews: [self.mealButton, self.mealLabel])
        mStack.axis = .Vertical
        mStack.spacing = 2
        return mStack
    }()

    lazy var correlateButton: UIButton = {
        let image = UIImage(named: "icon_correlate") as UIImage?

        let button = MCButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(11,12,11,11)
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = UIColor.ht_peterRiverColor()
        button.shadowColor = UIColor.ht_belizeHoleColor()
        button.shadowHeight = 6
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var correlateLabel : UILabel = {
        let cLabel = UILabel()
        cLabel.font = UIFont.systemFontOfSize(10, weight: UIFontWeightRegular)
        cLabel.textColor = Theme.universityDarkTheme.titleTextColor
        cLabel.textAlignment = .Center
        cLabel.text = NSLocalizedString("Correlate", comment: "Correlate Statistics")
        return cLabel
    }()

    lazy var correlatebStack: UIStackView = {
        let cStack = UIStackView(arrangedSubviews: [self.correlateButton, self.correlateLabel])
        cStack.axis = .Vertical
        cStack.spacing = 2
        return cStack
    }()

    lazy var logoutButton: UIButton = {
        let image = UIImage(named: "icon_logout") as UIImage?
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: "toggleLogin:", forControlEvents: .TouchUpInside)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var queryButton: UIButton = {
        let image = UIImage(named: "icon_query") as UIImage?
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: "showQuery:", forControlEvents: .TouchUpInside)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var settingsButton: UIButton = {
        let image = UIImage(named: "icon_settings") as UIImage?
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: "showSettings:", forControlEvents: .TouchUpInside)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var timerStashDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightLight)
        label.textColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.01)
        label.textAlignment = .Center
        label.text = NSLocalizedString("Last Meal Duration", comment: "Last Meal Duration")
        return label
    }()

    lazy var timerStashLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(24, weight: UIFontWeightLight)
        label.textColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.01)
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Last Meal")
        return label
    }()

    lazy var activeTimerDescLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Meal Duration", comment: "Meal Duration")
        return label
    }()

    lazy var activeTimerLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Meal Timer")
        return label
    }()

    lazy var startButton: UIButton = {
        let image = UIImage(named: "icon_timer") as UIImage?
        let button = MCButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(10,11,10,10)
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = UIColor.ht_mediumColor()
        button.shadowColor = UIColor.ht_mediumDarkColor()
        button.shadowHeight = 6
        button.addTarget(self, action: "toggleTimer:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var startLabel : UILabel = {
        let sLabel = UILabel()
        sLabel.font = UIFont.systemFontOfSize(10, weight: UIFontWeightRegular)
        sLabel.textColor = Theme.universityDarkTheme.titleTextColor
        sLabel.textAlignment = .Center
        sLabel.text = NSLocalizedString("Timer", comment: "Time Meal")
        return sLabel
    }()

    lazy var startbStack: UIStackView = {
        let sStack = UIStackView(arrangedSubviews: [self.startButton, self.startLabel])
        sStack.axis = .Vertical
        sStack.spacing = 2
        return sStack
    }()

    lazy var buttonsContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.plotbStack, self.correlatebStack, self.mealbStack, self.startbStack])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 25
        return stackView
    }()

    lazy var timerStashContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.timerStashDescLabel, self.timerStashLabel])
        stackView.axis = .Vertical
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var activeTimerContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.activeTimerDescLabel, self.activeTimerLabel])
        stackView.axis = .Vertical
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var timerContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.timerStashContainerView, self.activeTimerContainerView])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var topButtonsContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.titleLabel, self.logoutButton, self.queryButton, self.settingsButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillProportionally
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
        return stackView
    }()

    lazy var userImageView : UIImageView = {
        let uimgView = UIImageView(image: UIImage(named: "icon_user")!)
        uimgView.contentMode = .ScaleAspectFit
        return uimgView
    }()

    lazy var indivLabel : UILabel = {
        let idvLabel = UILabel()
        idvLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        idvLabel.textColor = Theme.universityDarkTheme.titleTextColor
        idvLabel.textAlignment = .Center
        idvLabel.text = NSLocalizedString("Individual", comment: "Individual Statistics")
        return idvLabel
    }()

    lazy var userStack: UIStackView = {
        let uStack = UIStackView(arrangedSubviews: [self.userImageView, self.indivLabel])
        uStack.axis = .Vertical
        uStack.spacing = 5
        return uStack
    }()

    lazy var peopleImageView : UIImageView =  {
        let pView = UIImageView(image: UIImage(named: "icon_people")!)
        pView.contentMode = .ScaleAspectFit
        return pView
    }()

    lazy var popuLabel : UILabel = {
        let pLabel = UILabel()
        pLabel.font = UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)
        pLabel.textColor = Theme.universityDarkTheme.titleTextColor
        pLabel.textAlignment = .Center
        pLabel.text = NSLocalizedString("Population", comment: "Population Statistics")
        return pLabel
    }()

    lazy var peopleStack: UIStackView = {
        let pStack = UIStackView(arrangedSubviews: [self.peopleImageView, self.popuLabel])
        pStack.axis = .Vertical
        pStack.spacing = 5
        return pStack
    }()

    lazy var tableTitleContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.userStack, self.peopleStack])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 5
        stackView.tintColor = Theme.universityDarkTheme.foregroundColor
        return stackView
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRectMake(0, 0, 1000, 1000), style: UITableViewStyle.Plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(IntroCompareDataTableViewCell.self, forCellReuseIdentifier: IntroViewTableViewCellIdentifier)
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.scrollEnabled = false
        return tableView
    }()

    static let sampleFormatter = SampleFormatter()

    static let previewTypes = Array(PreviewManager.previewChoices.flatten())
    static let previewTypeStrings = PreviewManager.previewChoices.flatten().map { $0.displayText ?? HMConstants.sharedInstance.healthKitShortNames[$0.identifier]! }

    static let previewMealTypeStrings = [["Bkfast", "Lunch", "Dinner", "Snack"],
            ["5:00 AM","5:30 AM","6:00 AM","6:30 AM","7:00 AM","7:30 AM","8:00 AM","8:30 AM",
             "9:00 AM","9:30 AM","10:00 AM","10:30 AM","11:00 AM","11:30 AM","12:00 PM", "12:30 PM",
             "1:00 PM", "1:30 PM", "2:00 PM", "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM",
             "5:00 PM", "5:30 PM", "6:00 PM", "6:30 PM", "7:00 PM", "7:30 PM", "8:00 PM", "8:30 PM",
             "9:00 PM", "9:30 PM", "10:00 PM", "10:30 PM", "11:00 PM", "11:30 PM", "12:00 AM", "12:30 AM",
             "1:00 AM", "1:30 AM", "2:00 AM", "2:30 AM", "3:00 AM", "3:30 AM", "4:00 AM", "4:30 AM"],
            ["15 Min", "30 Min", "45 Min", "60 Min", "90 Min", "120 Min", "150 Min", "180 Min", "210 Min", "240 Min"]]/*,
                                         ["1✮", "2✮", "3✮", "4✮", "5✮"]*/

    lazy var dummyTextField: UITextField = {
        let textField = UITextField()
        textField.inputView = self.pickerView
        textField.inputAccessoryView = {
            let view = UIToolbar()
            view.frame = CGRectMake(0, 0, 0, 44)
            view.items = [
                UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "dismissPopup:"),
                UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: ""),
                UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "selectAttribute:")
            ]

            return view
        }()
        return textField
    }()

    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()

    enum GraphMode {
        case Plot(HKSampleType)
        case Correlate(HKSampleType, HKSampleType)
        case previewMealTypeStrings
    }

    private var selectedMode: GraphMode!


    // MARK: - Background Work

    func hkAccessNotifyLoop() {
        hkAccessAsync = Async.main(after: 10.0) {
            UINotifications.retryingHealthkit(self)
            if self.hkAccessAsync != nil {
                if let accessTime = self.hkAccessTime {
                    if NSDate() > (accessTime + hkAccessTimeout) {
                        UINotifications.genericError(self, msg: "Timed out accessing HealthKit... please reboot.", nohide: true)
                        return
                    }
                }
                self.hkAccessNotifyLoop()
            }
        }
    }

    func withHKCalAuth(completion: Void -> Void) {
        hkAccessTime = NSDate()
        hkAccessNotifyLoop()
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else {
                UINotifications.noHealthKit(self)
                return
            }
            Async.main { if let a = self.hkAccessAsync { a.cancel(); self.hkAccessAsync = nil } }
            EventManager.sharedManager.checkCalendarAuthorizationStatus(completion)
        }
    }

    func fetchInitialAggregates() {
        aggregateFetchTask = Async.background {
            self.fetchAggregatesPeriodically()
        }
    }

    func fetchAggregatesPeriodically() {
        PopulationHealthManager.sharedManager.fetchAggregates()
        let freq = UserManager.sharedManager.getRefreshFrequency()
        aggregateFetchTask = Async.background(after: Double(freq)) {
            self.fetchAggregatesPeriodically()
        }
    }

    func fetchRecentSamples() {
        withHKCalAuth {
            HealthManager.sharedManager.fetchMostRecentSamples() { (samples, error) -> Void in
                guard error == nil else { return }
                NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
            }
        }
    }

    internal func initializeBackgroundWork() {
        Async.main(after: 2) {
            self.fetchInitialAggregates()
            self.fetchRecentSamples()
            HealthManager.sharedManager.registerObservers()
        }
    }


    // MARK: - Initial, and toggling login/logout handlers.

    func loginOrRegister() {
        if UserManager.sharedManager.hasUserId() {
            loginAndInitialize()
        } else {
            registerParticipant()
        }
    }

    func doLogin(completion: (Void -> Void)?) {
        let loginVC = LoginViewController()
        loginVC.parentView = self
        loginVC.completion = completion
        navigationController?.pushViewController(loginVC, animated: true)
    }

    func doLogout(completion: (Void -> Void)?) {
        UserManager.sharedManager.logoutWithCompletion(completion)
        UINotifications.loginGoodbye(self, pop: false, user: UserManager.sharedManager.getUserId()!)

        // Clean up aggregate data fetched via the prior account.
        if let task = aggregateFetchTask {
            task.cancel()
            aggregateFetchTask = nil
        }
        PopulationHealthManager.sharedManager.resetAggregates()
        Async.main {
            self.tableView.reloadData()
            self.radarController.reloadData()
        }
    }

    func registerParticipant() {
        let registerVC = RegisterViewController()
        registerVC.parentView = self
        registerVC.consentOnLoad = true
        registerVC.registerCompletion = { self.initializeBackgroundWork() }
        self.navigationController?.pushViewController(registerVC, animated: true)
    }

    func loginAndInitialize() {
        withHKCalAuth {
            UserManager.sharedManager.ensureAccessToken { error in
                guard !error else {
                    UINotifications.loginRequest(self)
                    return
                }

                guard UserManager.sharedManager.hasAccount() else {
                    UINotifications.loginRequest(self)
                    self.doToggleLogin { self.initializeBackgroundWork() }
                    return
                }

                UserManager.sharedManager.pullProfileWithConsent { (error, msg) in
                    if !error {
                        self.initializeBackgroundWork()
                        Async.main(after: 2) { UINotifications.doWelcome(self, pop: false, user: UserManager.sharedManager.getUserId() ?? "") }
                    } else {
                        log.error("Failed to retrieve initial profile and consent: \(msg)")
                        UINotifications.profileFetchFailed(self)
                    }
                }
            }
        }
    }


    // MARK: - View Event Handlers

    override func viewDidLoad() {
        super.viewDidLoad()
        loginOrRegister()
        configureViews()
        tableView.layoutIfNeeded()
        NSNotificationCenter.defaultCenter().addObserverForName(HMDidUpdateRecentSamplesNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
            self.tableView.reloadData()
            self.radarController.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func configureViews() {
        view.backgroundColor = Theme.universityDarkTheme.backgroundColor
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentScaleFactor = 0.2
        view.addSubview(logoImageView)
        let constraints: [NSLayoutConstraint] = [
            logoImageView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.3),
            logoImageView.heightAnchor.constraintEqualToAnchor(logoImageView.widthAnchor, multiplier: 1.0744),
            NSLayoutConstraint(item: logoImageView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 0.10, constant: 0),
            logoImageView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 20)
        ]
        view.addConstraints(constraints)

        buttonsContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsContainerView)
        let buttonContainerConstraints: [NSLayoutConstraint] = [
            buttonsContainerView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.bottomAnchor, constant: -10),
            buttonsContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 0),
            buttonsContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            plotButton.heightAnchor.constraintEqualToAnchor(plotButton.widthAnchor),
            plotLabel.heightAnchor.constraintEqualToConstant(15),
            mealButton.heightAnchor.constraintEqualToAnchor(mealButton.widthAnchor),
            mealLabel.heightAnchor.constraintEqualToConstant(15),
            correlateButton.heightAnchor.constraintEqualToAnchor(correlateButton.widthAnchor),
            correlateLabel.heightAnchor.constraintEqualToConstant(15),
            startButton.heightAnchor.constraintEqualToAnchor(startButton.widthAnchor),
            startLabel.heightAnchor.constraintEqualToConstant(15)
        ]
        view.addConstraints(buttonContainerConstraints)

        topButtonsContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topButtonsContainerView)
        let topButtonsContainerConstraints: [NSLayoutConstraint] = [
            topButtonsContainerView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 40),
            topButtonsContainerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.7),
            topButtonsContainerView.leadingAnchor.constraintLessThanOrEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: ScreenManager.sharedInstance.dashboardTitleLeading()),
            topButtonsContainerView.heightAnchor.constraintEqualToConstant(mcControlButtonHeight),
            logoutButton.widthAnchor.constraintEqualToConstant(mcControlButtonHeight),
            queryButton.leadingAnchor.constraintEqualToAnchor(logoutButton.trailingAnchor, constant: 0),
            queryButton.widthAnchor.constraintEqualToConstant(mcControlButtonHeight),
            settingsButton.leadingAnchor.constraintEqualToAnchor(queryButton.trailingAnchor, constant: 0),
            settingsButton.widthAnchor.constraintEqualToConstant(mcControlButtonHeight)
        ]
        view.addConstraints(topButtonsContainerConstraints)

        timerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerContainerView)
        let timerContainerConstraints: [NSLayoutConstraint] = [
            timerContainerView.bottomAnchor.constraintEqualToAnchor(buttonsContainerView.topAnchor, constant: -25),
            timerContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 0),
            timerContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            timerContainerView.heightAnchor.constraintEqualToConstant(44)
        ]
        view.addConstraints(timerContainerConstraints)

        // Set up the page view controller.
        let tableContainer = UIViewController()
        let tcView = tableContainer.view

        tableTitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        tcView.addSubview(tableTitleContainerView)
        let tableTitleConstraints: [NSLayoutConstraint] = [
            tableTitleContainerView.topAnchor.constraintEqualToAnchor(tcView.topAnchor),
            tableTitleContainerView.leadingAnchor.constraintEqualToAnchor(tcView.leadingAnchor, constant: 37 + 27),
            tableTitleContainerView.trailingAnchor.constraintEqualToAnchor(tcView.trailingAnchor),
            userImageView.heightAnchor.constraintEqualToConstant(34),
            peopleImageView.heightAnchor.constraintEqualToConstant(34)
        ]
        tcView.addConstraints(tableTitleConstraints)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: tcView.frame.width, bottom: 0, right: 0)

        tcView.addSubview(tableView)
        let tableViewConstraints: [NSLayoutConstraint] = [
            tableView.topAnchor.constraintEqualToAnchor(tableTitleContainerView.bottomAnchor),
            tableView.leadingAnchor.constraintEqualToAnchor(tcView.layoutMarginsGuide.leadingAnchor),
            tableView.trailingAnchor.constraintEqualToAnchor(tcView.layoutMarginsGuide.trailingAnchor),
            tableView.bottomAnchor.constraintEqualToAnchor(tcView.bottomAnchor)
        ]
        tcView.addConstraints(tableViewConstraints)

        pagesController = PagesController([tableContainer, radarController, mealController])
        pagesController.enableSwipe = true
        pagesController.showBottomLine = false
        pagesController.showPageControl = true
        mealCIndex = 2

        let pageView = pagesController.view
        pageView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(pagesController)
        view.addSubview(pageView)
        let pageViewConstraints: [NSLayoutConstraint] = [
            pageView.topAnchor.constraintEqualToAnchor(topButtonsContainerView.bottomAnchor, constant: 20),
            pageView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 10),
            pageView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: -10),
            pageView.bottomAnchor.constraintEqualToAnchor(timerContainerView.topAnchor, constant: -3)
        ]
        view.addConstraints(pageViewConstraints)
        pagesController.didMoveToParentViewController(self)

        dummyTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dummyTextField)
    }


    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: - Button Events

    func toggleLogin(sender: UIButton) {
        doToggleLogin(nil)
    }

    func doToggleLogin(completion: (Void -> Void)?) {
        guard UserManager.sharedManager.hasAccount() else {
            doLogin(completion)
            return
        }
        doLogout(completion)
    }

    func showAttributes(sender: UIButton) {
        if sender == correlateButton {
            selectedMode = GraphMode.Correlate(IntroViewController.previewTypes[0], IntroViewController.previewTypes[1])
            pickerView.reloadAllComponents()
        } else if sender == plotButton {
            selectedMode = GraphMode.Plot(IntroViewController.previewTypes[0])
            pickerView.reloadAllComponents()
        } else if sender == mealButton {
            selectedMode = GraphMode.previewMealTypeStrings
            pickerView.reloadAllComponents()

        }
        dummyTextField.becomeFirstResponder()
    }

    func dismissPopup(sender: UIBarButtonItem) {
        dummyTextField.resignFirstResponder()
    }

    func selectAttribute(sender: UIBarButtonItem) {
        dummyTextField.resignFirstResponder()
        switch selectedMode! {

        case let .Correlate(type1, type2):
            correlateView(type1, type2: type2)

        case .Plot(let type):
            plotView(type)

        case .previewMealTypeStrings:
            let chosenTime = IntroViewController.previewMealTypeStrings[1][pickerView.selectedRowInComponent(1)]
            let chosenDuration = IntroViewController.previewMealTypeStrings[2][pickerView.selectedRowInComponent(2)]
            var updatedTime = chosenTime.componentsSeparatedByString(":")
            var updatedTimeMinute = updatedTime[1].componentsSeparatedByString(" ")
            var updatedDurationMinute = chosenDuration.componentsSeparatedByString(" Min")

            if (updatedTimeMinute[1] == "PM") {
                updatedTime[0] = String(Int(updatedTime[0])! + 12)
            }

            let mealStart = NSDate().startOf(.Day, inRegion: Region()) + Int(updatedTime[0])!.hours + Int(updatedTimeMinute[0])!.minutes
            let mealEnd = mealStart + Int(updatedDurationMinute[0])!.minutes

            let metaMeals = [/*String(IntroViewController.previewMealTypeStrings[3][pickerView.selectedRowInComponent(3)]):"Meal Rating", */
                             String(IntroViewController.previewMealTypeStrings[0][pickerView.selectedRowInComponent(0)]):"Meal Type"]

            HealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                mealStart, endDate: mealEnd, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                kiloCalories: 0.0, metadata: metaMeals)
            {
                (success, error ) -> Void in
                guard error == nil else { log.error(error); return }
                log.info("Meal saved as workout-type")
                self.refreshMealController()
            }
        }
    }

    private func plotView(type: HKSampleType) {
        let plotVC = PlotViewController()
        plotVC.sampleType = type

        let errorVC = ErrorViewController()
        errorVC.image = UIImage(named: "icon_broken_heart")
        errorVC.msg = "We're heartbroken to see you\nhave no \(type.displayText!) data"

        let variantVC = VariantViewController()
        variantVC.pages = [plotVC, errorVC]
        variantVC.startIndex = ( plotVC.historyChart.data == nil || plotVC.summaryChart.data == nil ) ? 1 : 0
        navigationController?.pushViewController(variantVC, animated: true)
    }

    private func correlateView(type1: HKSampleType, type2: HKSampleType) {
        let correlateVC = CorrelationViewController()
        correlateVC.sampleTypes = [type1, type2]

        let errorVC = ErrorViewController()
        errorVC.image = UIImage(named: "icon_broken_heart")
        errorVC.msg = "We're heartbroken to see you have no\n\(type1.displayText!) or \(type2.displayText!) data"

        let variantVC = VariantViewController()
        variantVC.pages = [correlateVC, errorVC]
        variantVC.startIndex = correlateVC.correlationChart.data == nil ? 1 : 0
        navigationController?.pushViewController(variantVC, animated: true)
    }

    func showSettings(sender: UIButton) {
        let settingsViewController = SettingsViewController()
        navigationController?.pushViewController(settingsViewController, animated: true)
    }

    func showQuery(sender: UIButton) {
        let queryViewController = QueryViewController()
        navigationController?.pushViewController(queryViewController, animated: true)
    }


    // MARK: - Table View

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ScreenManager.sharedInstance.dashboardRows()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(IntroViewTableViewCellIdentifier, forIndexPath: indexPath) as! IntroCompareDataTableViewCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType
        let timeSinceRefresh = NSDate().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate)
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
        let stale = timeSinceRefresh > Double(refreshPeriod)
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: PopulationHealthManager.sharedManager.mostRecentAggregates[sampleType]
                                                    ?? [DerivedQuantity(quantity: nil, quantityType: nil)],
                         stalePopulation: stale)
        return cell
    }

    // MARK: - Picker view delegate

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if case .Plot(_) = selectedMode! {
            return 1
        } else if case .previewMealTypeStrings(_) = selectedMode! {
            return 3
        } else {
            return 2
        }
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if case .Correlate(_) = selectedMode! {
            return IntroViewController.previewTypeStrings.count
        } else if case .Plot(_) = selectedMode! {
            return IntroViewController.previewTypeStrings.count
        } else {
            return IntroViewController.previewMealTypeStrings[component].count
        }
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if case .Correlate(_) = selectedMode! {
            return IntroViewController.previewTypeStrings[row]
        } else if case .Plot(_) = selectedMode! {
            return IntroViewController.previewTypeStrings[row]
        } else if case .previewMealTypeStrings = selectedMode! {
            return IntroViewController.previewMealTypeStrings[component][row]
        } else {
            return IntroViewController.previewMealTypeStrings[component][row]
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if case .Correlate(_) = selectedMode! {
            let ltype = IntroViewController.previewTypes[pickerView.selectedRowInComponent(0)]
            let rtype = IntroViewController.previewTypes[pickerView.selectedRowInComponent(1)]
            selectedMode = GraphMode.Correlate(ltype, rtype)
        } else if case .Plot(_) = selectedMode! {
            selectedMode = GraphMode.Plot(IntroViewController.previewTypes[row])
        } else if case .previewMealTypeStrings = selectedMode! {
            // Add configuration as necessary...
        }
    }

    // MARK: - Pages refresh
    private func refreshMealController() {
        if pagesController.currentIndex == mealCIndex {
            Async.main { self.mealController.reloadData() }
        }
    }


    // MARK: - Timer

    var timerLoop : Async? = nil
    let timerLoopFrequency : Double? = 1.0
    var timerCancel : Bool = false

    var timerStartDate = NSDate()
    var startTime = NSTimeInterval()

    // All timer functions run in the main thread.
    func toggleTimer(sender: AnyObject) {
        Async.main { self.timerLoop == nil ? self.startTimer(sender) : self.stopTimer(sender) }
    }

    func updateTimerPeriodically() {
        guard timerCancel else {
            self.updateTimer()
            timerLoop = Async.main(after: timerLoopFrequency) { self.updateTimerPeriodically() }
            return
        }
        resetTimer()
    }

    func startTimer(sender: AnyObject) {
        timerStartDate = NSDate()
        startTime = NSDate.timeIntervalSinceReferenceDate()
        if let b = sender as? MCButton {
            b.buttonColor = UIColor.ht_alizarinColor()
            b.shadowColor = UIColor.ht_pomegranateColor()
        }
        activeTimerLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightSemibold)
        timerLoop = Async.main(after: timerLoopFrequency) { self.updateTimerPeriodically() }
    }

    func stopTimer(sender: AnyObject) {
        if let b = sender as? MCButton {
            b.buttonColor = UIColor.ht_mediumColor()
            b.shadowColor = UIColor.ht_mediumDarkColor()
        }
        timerCancel = true
        timerStashLabel.text = activeTimerLabel.text
        activeTimerLabel.font = UIFont.systemFontOfSize(24, weight: UIFontWeightRegular)
        activeTimerLabel.text = "00:00"
        saveMealTime()
    }

    func resetTimer() {
        timerLoop = nil
        timerCancel = false
    }

    func updateTimer() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate()

        // Find the difference between current time and strart time
        var elapsedTime: NSTimeInterval = currentTime - startTime

        // calculate the minutes in elapsed time
        let minutes = UInt8(elapsedTime / 60.0)
        elapsedTime -= (NSTimeInterval(minutes) * 60)

        // calculate the seconds in elapsed time
        let seconds = UInt8(elapsedTime)
        elapsedTime -= NSTimeInterval(seconds)

        // add the leading zero for minutes, seconds and millseconds and store them as string constants
        let startMinutes  = minutes > 9 ? String(minutes):"0" + String(minutes)
        let startSeconds  = seconds > 9 ? String(seconds):"0" + String(seconds)

        activeTimerLabel.text = "\(startMinutes):\(startSeconds)"
    }

    func saveMealTime() {
        let timerEndDate = NSDate()
        let kmUnit = HKUnit(fromString: "km")
        let metaMeals = ["Source":"Timer"]

        HealthManager.sharedManager.savePreparationAndRecoveryWorkout(timerStartDate, endDate: timerEndDate,
            distance: 0.0, distanceUnit:kmUnit, kiloCalories: 0.0, metadata: metaMeals,
            completion: { (success, error ) -> Void in
                guard error == nil else {
                    log.error("Failed to save meal time: \(error)")
                    return
                }
                log.info("Timed meal saved as workout-type")
                self.refreshMealController()
            })
    }
}

class MCButton : HTPressableButton {

}