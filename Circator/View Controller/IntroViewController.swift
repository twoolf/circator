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


/**
 Main view controller for Metabolic Compass.
 
 - note: enables branching to all three screens and to plots/settings
 - remark: uses in-code constraint settings 
 */
class IntroViewController: UIViewController,
                           UITableViewDataSource,
                           UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource
{
    lazy var dashboardRows : Int = {
        return ScreenManager.sharedInstance.dashboardRows()
    }()

    private var hkAccessTime : NSDate? = nil         // Time of initial access attempt.
    private var hkAccessAsync : Async? = nil         // Background task to notify if HealthKit is slow to access.
    private var aggregateFetchTask : Async? = nil    // Background task to fetch population aggregates.

    private var pagesController: PagesController!
    private var timeEventPagesController: PagesController!

    lazy var radarController: RadarViewController = { return RadarViewController() }()
    lazy var mealController: EventTimeViewController = { return EventTimeViewController() }()

    private var mealCIndex : Int = 0
    private var eventManager: EventPickerManager!

    private var tevDisplayerCIndex : Int = 0
    private var tevSelectorCIndex : Int = 0

    static let sampleFormatter = SampleFormatter()

    static let previewTypes = Array(PreviewManager.previewChoices.flatten())

    static let previewTypeStrings = PreviewManager.previewChoices.flatten().map { $0.displayText ?? HMConstants.sharedInstance.healthKitShortNames[$0.identifier]! }

    static let previewSpecs : [String: PlotSpec!] = [
        HKCategoryTypeIdentifierSleepAnalysis : .PlotPredicate("Sleep", asleepPredicate)
    ]

    static let extraPickerTypes : [(HKSampleType, PlotSpec!)] = [
        (HKObjectType.workoutType(), .PlotPredicate("Meals", mealsPredicate)),
        (HKObjectType.workoutType(), .PlotPredicate("Exercise", exercisePredicate)),
        (HKObjectType.workoutType(), .PlotFasting),
        (HKObjectType.workoutType(), nil),
    ]

    static let extraPickerTypeStrings = [
        "Meals",
        "Exercise",
        "Fasting times",
        "Meals and exercise",
    ]

    private var pickerView: UIPickerView!

    enum GraphMode {
        case Plot(HKSampleType, PlotSpec!)
        case Correlate(HKSampleType, PlotSpec!, HKSampleType, PlotSpec!)
        case Event(EventPickerManager.Event)
    }

    private var selectedMode: GraphMode!

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


    /*
     * Timed event selection
     */

    private static let subTimedEventFrame = CGRectMake(30, 200, 200, 50)
    private static let subTEBColor = UIColor.ht_alizarinColor()
    private static let subTEBSColor = UIColor.ht_pomegranateColor()

    lazy var foodButton: UIButton = {
        let image = UIImage(named: "icon_meal") as UIImage?
        let button = MCButton(frame: IntroViewController.subTimedEventFrame, buttonStyle: .Rounded)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8,8,8,8)
        button.imageView?.contentMode = .ScaleAspectFit
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = IntroViewController.subTEBColor
        button.shadowColor = IntroViewController.subTEBSColor
        button.shadowHeight = 6
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var sleepButton: UIButton = {
        let sleepType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let image = PreviewManager.rowIcons[sleepType]!

        let button = MCButton(frame: IntroViewController.subTimedEventFrame, buttonStyle: .Rounded)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8,8,8,8)
        button.imageView?.contentMode = .ScaleAspectFit
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = IntroViewController.subTEBColor
        button.shadowColor = IntroViewController.subTEBSColor
        button.shadowHeight = 6
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var exerciseButton: UIButton = {
        let exerciseType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
        let image = PreviewManager.rowIcons[exerciseType]!

        let button = MCButton(frame: IntroViewController.subTimedEventFrame, buttonStyle: .Rounded)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(8,8,8,8)
        button.imageView?.contentMode = .ScaleAspectFit
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = IntroViewController.subTEBColor
        button.shadowColor = IntroViewController.subTEBSColor
        button.shadowHeight = 6
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var tevSelectionStack: UIStackView = {
        let mStack = UIStackView(arrangedSubviews: [self.foodButton, self.sleepButton, self.exerciseButton])
        mStack.axis = .Horizontal
        mStack.distribution = UIStackViewDistribution.FillEqually
        mStack.alignment = UIStackViewAlignment.Fill
        mStack.spacing = 25
        return mStack
    }()


    // Primary timed event selection button
    lazy var timedEventButton: UIButton = {
        let image = UIImage(named: "icon_meal") as UIImage?
        let button = MCButton(frame: CGRectMake(110, 300, 100, 100), buttonStyle: .Circular)
        button.setImage(image, forState: .Normal)
        button.imageEdgeInsets = UIEdgeInsetsMake(11,11,10,10)
        button.tintColor = Theme.universityDarkTheme.foregroundColor
        button.buttonColor = UIColor.ht_sunflowerColor()
        button.shadowColor = UIColor.ht_citrusColor()
        button.shadowHeight = 6
        button.addTarget(self, action: "toggleTimedEvent", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var timedEventLabel : UILabel = {
        let mLabel = UILabel()
        mLabel.font = UIFont.systemFontOfSize(10, weight: UIFontWeightRegular)
        mLabel.textColor = Theme.universityDarkTheme.titleTextColor
        mLabel.textAlignment = .Center
        mLabel.text = NSLocalizedString("Add Events", comment: "Add Events")
        return mLabel
    }()

    lazy var tevbStack: UIStackView = {
        let mStack = UIStackView(arrangedSubviews: [self.timedEventButton, self.timedEventLabel])
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
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.plotbStack, self.correlatebStack, self.tevbStack, self.startbStack])
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

    lazy var dummyTextField: UITextField = {
        let textField = UITextField()
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
            self.radarController.authorized = true
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
        UINotifications.loginGoodbye(self, user: UserManager.sharedManager.getUserId()!)

        // Clean up aggregate data fetched via the prior account.
        if let task = aggregateFetchTask {
            task.cancel()
            aggregateFetchTask = nil
        }
        PopulationHealthManager.sharedManager.resetAggregates()
        doDataRefresh()
    }

    func doDataRefresh() {
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
                        Async.main(after: 2) { UINotifications.doWelcome(self, user: UserManager.sharedManager.getUserId() ?? "") }
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
            timedEventButton.heightAnchor.constraintEqualToAnchor(timedEventButton.widthAnchor),
            timedEventLabel.heightAnchor.constraintEqualToConstant(15),
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

        // Set up the timer page view controller.
        //
        let tevDisplayer = UIViewController()
        let tevView = tevDisplayer.view
        equateViews(tevView, v2: timerContainerView)

        let tevSelector = UIViewController()
        let tevSView = tevSelector.view
        equateViews(tevSView, v2: tevSelectionStack)

        timeEventPagesController = PagesController([tevDisplayer, tevSelector])
        timeEventPagesController.enableSwipe = false
        timeEventPagesController.showBottomLine = false
        timeEventPagesController.showPageControl = false
        tevDisplayerCIndex = 0
        tevSelectorCIndex = 1

        let tevPageView = timeEventPagesController.view
        tevPageView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(timeEventPagesController)
        view.addSubview(tevPageView)
        let tevPCConstraints: [NSLayoutConstraint] = [
            tevPageView.bottomAnchor.constraintEqualToAnchor(buttonsContainerView.topAnchor, constant: -25),
            tevPageView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 0),
            tevPageView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            tevPageView.heightAnchor.constraintEqualToConstant(44)
        ]
        view.addConstraints(tevPCConstraints)
        timeEventPagesController.didMoveToParentViewController(self)

        // Set up the chart page view controller.
        //
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

        radarController.initialImage = UIImage(named: "icon_lock")
        radarController.initialMsg = "HealthKit not authorized"

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
            pageView.bottomAnchor.constraintEqualToAnchor(tevPageView.topAnchor, constant: -3)
        ]
        view.addConstraints(pageViewConstraints)
        pagesController.didMoveToParentViewController(self)

        dummyTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dummyTextField)
    }

    func equateViews(v1: UIView, v2: UIView) {
        v2.translatesAutoresizingMaskIntoConstraints = false
        v1.addSubview(v2)
        let constraints: [NSLayoutConstraint] = [
            v2.topAnchor.constraintEqualToAnchor(v1.topAnchor),
            v2.leadingAnchor.constraintEqualToAnchor(v1.layoutMarginsGuide.leadingAnchor),
            v2.trailingAnchor.constraintEqualToAnchor(v1.layoutMarginsGuide.trailingAnchor),
            v2.bottomAnchor.constraintEqualToAnchor(v1.bottomAnchor)
        ]
        v1.addConstraints(constraints)
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

    func toggleTimedEvent() {
        guard UserManager.sharedManager.hasAccount() else {
            UINotifications.loginRequest(self)
            return
        }

        let nextIndex = timeEventPagesController.currentIndex == 0 ? 1 : 0
        timeEventPagesController.goTo(nextIndex)
    }

    func showAttributes(sender: UIButton) {
        guard UserManager.sharedManager.hasAccount() else {
            UINotifications.loginRequest(self)
            return
        }

        func initializePickerView() {
            pickerView = UIPickerView()
            pickerView.dataSource = self
            pickerView.delegate = self
        }
        if sender == correlateButton {
            initializePickerView()
            let type = IntroViewController.extraPickerTypes[0].0
            let spec = IntroViewController.extraPickerTypes[0].1
            selectedMode = GraphMode.Correlate(type, spec, type, spec)
        }
        else if sender == plotButton {
            initializePickerView()
            let type = IntroViewController.extraPickerTypes[0].0
            let spec = IntroViewController.extraPickerTypes[0].1
            selectedMode = GraphMode.Plot(type, spec)
        }
        else {
            var event: EventPickerManager.Event!
            if sender == foodButton {
                event = .Meal
            }
            else if sender == sleepButton {
                event = .Sleep
            }
            else if sender == exerciseButton {
                event = .Exercise
            }
            selectedMode = GraphMode.Event(event)
            eventManager = EventPickerManager(event: event)
            pickerView = eventManager.pickerView
        }
        self.dummyTextField.inputView = self.pickerView
        pickerView.reloadAllComponents()
        self.dummyTextField.becomeFirstResponder()
    }

    func dismissPopup(sender: UIBarButtonItem) {
        dummyTextField.resignFirstResponder()
    }

    func clampTime(t: NSDate, upper: NSDate, lower: NSDate) -> NSDate? {
        log.info("Clamp \(t) \(lower) \(upper)")
        var result = t
        if t < lower {
            result = result + 1.days
        } else if t > upper {
            result = result - 1.days
        }

        guard lower <= result && result <= upper else {
            return nil
        }
        return result
    }

    func validateTimedEvent(startTime: NSDate, endTime: NSDate, completion: () -> ()) {
        // Fetch all sleep and workout data since yesterday.
        let (yesterday, now) = (1.days.ago, NSDate())
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(yesterday, endDate: now, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Aggregate sleep, exercise and meal events.
        HealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { log.error(error); return }
            let overlaps = samples.reduce(false, combine: { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, combine: { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })

            if !overlaps { completion() }
            else { UINotifications.genericError(self, msg: "This event overlaps with another, please try again") }
        }
    }

    func selectAttribute(sender: UIBarButtonItem) {
        let now = NSDate()
        let ago24 = now - 1.days
        let today = now.startOf(.Day, inRegion: Region())
        let format = DateFormat.Custom("HH:mm")

        dummyTextField.resignFirstResponder()
        switch selectedMode! {

        case let .Correlate(type1, spec1, type2, spec2):
            correlateView(type1, type2: type2, spec1: spec1, spec2: spec2)

        case let .Plot(type, spec):
            plotView(type, spec: spec)

        case .Event(let event):
            switch event {
            case .Meal:
                let chosenTimeStr = EventPickerManager.previewMealTypeStrings[1][pickerView.selectedRowInComponent(1)]
                let chosenDurationStr = EventPickerManager.previewMealTypeStrings[2][pickerView.selectedRowInComponent(2)]
                
                let startDelta = chosenTimeStr.toDate(format)!
                let startTimeO = clampTime(today + startDelta.hour.hours + startDelta.minute.minutes, upper: now, lower: ago24)
                let durationMinuteStr = chosenDurationStr.componentsSeparatedByString(" Min")[0]
                
                if let startTime = startTimeO  {
                    let endTime = startTime + Int(durationMinuteStr)!.minutes
                    
                    let metaMeals = ["Meal Type": String(EventPickerManager.previewMealTypeStrings[0][pickerView.selectedRowInComponent(0)])]
                    
                    log.info("Meal event \(startTime) \(endTime)")
                    validateTimedEvent(startTime, endTime: endTime) {
                        HealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                            startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                            kiloCalories: 0.0, metadata: metaMeals)
                        {
                            (success, error ) -> Void in
                            guard error == nil else { log.error(error); return }
                            log.info("Meal saved as workout type")
                            self.refreshMealController()
                        }
                    }
                } else {
                    UINotifications.genericError(self, msg: "Meals can only be entered in the last 24 hours")
                }
            case .Sleep:
                let startTimeStr = EventPickerManager.sleepEndpointTypeStrings[0][pickerView.selectedRowInComponent(0)]
                let endTimeStr = EventPickerManager.sleepEndpointTypeStrings[1][pickerView.selectedRowInComponent(1)]
                
                let startDelta = startTimeStr.toDate(format)!
                let endDelta = endTimeStr.toDate(format)!
                
                let startTime : NSDate! = clampTime(today + startDelta.hour.hours + startDelta.minute.minutes, upper: now, lower: ago24)
                let endTime : NSDate! = clampTime(today + endDelta.hour.hours + endDelta.minute.minutes, upper: now, lower: ago24)
                
                log.info("Sleep event \(startTime) \(endTime)")
                if startTime == nil || endTime == nil || startTime! >= endTime! {
                    let msg = ( startTime == nil || endTime == nil ) ?
                        "Unspecified sleep time, please re-enter" : "Ending time greater than starting time, please re-enter"

                    UINotifications.genericError(self, msg: msg)
                } else {
                    log.info("Sleep event \(startTime) \(endTime)")
                    validateTimedEvent(startTime, endTime: endTime) {
                        HealthManager.sharedManager.saveSleep(startTime!, endDate: endTime!, metadata: [:], completion:
                        {
                            (success, error ) -> Void in
                            guard error == nil else { log.error(error); return }
                            log.info("Saved as sleep event")
                            self.refreshMealController()
                        })
                    }
                }
            case .Exercise:
                let startTimeStr = EventPickerManager.durationTypeStrings[0][pickerView.selectedRowInComponent(0)]
                var durationHrStr = EventPickerManager.durationTypeStrings[1][pickerView.selectedRowInComponent(1)]
                var durationMinStr = EventPickerManager.durationTypeStrings[2][pickerView.selectedRowInComponent(2)]
                
                let startDelta = startTimeStr.toDate(format)!
                durationHrStr = durationHrStr.componentsSeparatedByString(" Hr")[0]
                durationMinStr = durationMinStr.componentsSeparatedByString(" Min")[0]
                
                let startTimeO = clampTime(today + startDelta.hour.hours + startDelta.minute.minutes, upper: now, lower: ago24)
                
                if let startTime = startTimeO {
                    let endTime = startTime + Int(durationHrStr)!.hours + Int(durationMinStr)!.minutes
                    
                    log.info("Exercise event \(startTime) \(endTime)")
                    validateTimedEvent(startTime, endTime: endTime) {
                        HealthManager.sharedManager.saveRunningWorkout(
                            startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                            kiloCalories: 0.0, metadata: [:])
                        {
                            (success, error ) -> Void in
                            guard error == nil else { log.error(error); return }
                            log.info("Saved as exercise workout type")
                            self.refreshMealController()
                        }
                    }
                } else {
                    UINotifications.genericError(self, msg: "Workouts can only be entered in the last 24 hours")
                }
            }
        }
    }

    private func plotView(type: HKSampleType, spec: PlotSpec! = nil) {
        let errorVC = ErrorViewController()
        errorVC.image = UIImage(named: "icon_broken_heart")
        errorVC.msg = "We're heartbroken to see you\nhave no \(type.displayText!) data"

        let renderVC = ErrorViewController()
        renderVC.image = UIImage(named: "icon_quill")
        renderVC.msg = "Rendering data, please wait..."

        let plotVC = PlotViewController()
        plotVC.spec = spec
        plotVC.sampleType = type
        plotVC.pageIndex = 0
        plotVC.errorIndex = 1
        plotVC.loadIndex = 2

        let variantVC = VariantViewController()
        variantVC.pages = [plotVC, errorVC, renderVC]
        variantVC.startIndex = ( plotVC.historyChart.data == nil || plotVC.summaryChart.data == nil ) ? 2 : 0
        navigationController?.pushViewController(variantVC, animated: true)
    }

    private func correlateView(type1: HKSampleType, type2: HKSampleType, spec1: PlotSpec! = nil, spec2: PlotSpec! = nil) {
        let errorVC = ErrorViewController()
        errorVC.image = UIImage(named: "icon_broken_heart")
        errorVC.msg = "We're heartbroken to see you have no\n\(type1.displayText!) or \(type2.displayText!) data"

        let renderVC = ErrorViewController()
        renderVC.image = UIImage(named: "icon_quill")
        renderVC.msg = "Rendering data, please wait..."

        let correlateVC = CorrelationViewController()
        correlateVC.lspec = spec1
        correlateVC.rspec = spec2
        correlateVC.sampleTypes = [type1, type2]
        correlateVC.pageIndex = 0
        correlateVC.errorIndex = 1
        correlateVC.loadIndex = 2

        let variantVC = VariantViewController()
        variantVC.pages = [correlateVC, errorVC, renderVC]
        variantVC.startIndex = correlateVC.correlationChart.data == nil ? 2 : 0
        navigationController?.pushViewController(variantVC, animated: true)
    }

    func showSettings(sender: UIButton) {
        let settingsViewController = SettingsViewController()
        settingsViewController.introView = self
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
        return dashboardRows
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(IntroViewTableViewCellIdentifier, forIndexPath: indexPath) as! IntroCompareDataTableViewCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType
        let timeSinceRefresh = NSDate().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate)
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
        let stale = timeSinceRefresh > Double(refreshPeriod)

        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: PopulationHealthManager.sharedManager.mostRecentAggregates[sampleType] ?? [],
                         stalePopulation: stale)
        return cell
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if case .Correlate(_) = selectedMode! {
            return 2
        }
        else if case .Plot(_) = selectedMode! {
            return 1
        }
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if case .Correlate(_) = selectedMode! {
            return IntroViewController.extraPickerTypeStrings.count + IntroViewController.previewTypeStrings.count
        }
        else if case .Plot(_) = selectedMode! {
            return IntroViewController.extraPickerTypeStrings.count + IntroViewController.previewTypeStrings.count
        }
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let pcnt = IntroViewController.extraPickerTypeStrings.count
        if case .Correlate(_) = selectedMode! {
            return row < pcnt ? IntroViewController.extraPickerTypeStrings[row] : IntroViewController.previewTypeStrings[row-pcnt]
        }
        else if case .Plot(_) = selectedMode! {
            return row < pcnt ? IntroViewController.extraPickerTypeStrings[row] : IntroViewController.previewTypeStrings[row-pcnt]
        }
        return nil
    }
    
    // MARK: - Picker view delegate

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let pcnt = IntroViewController.extraPickerTypeStrings.count
        if case .Correlate(_) = selectedMode! {
            let lrow = pickerView.selectedRowInComponent(0)
            let rrow = pickerView.selectedRowInComponent(1)
            let ltype = lrow < pcnt ? IntroViewController.extraPickerTypes[lrow].0 : IntroViewController.previewTypes[lrow-pcnt]
            let rtype = rrow < pcnt ? IntroViewController.extraPickerTypes[rrow].0 : IntroViewController.previewTypes[rrow-pcnt]
            let lspec = lrow < pcnt ? IntroViewController.extraPickerTypes[lrow].1 : (IntroViewController.previewSpecs[ltype.identifier] ?? nil)
            let rspec = rrow < pcnt ? IntroViewController.extraPickerTypes[rrow].1 : (IntroViewController.previewSpecs[rtype.identifier] ?? nil)
            selectedMode = GraphMode.Correlate(ltype, lspec, rtype, rspec)
        }
        else if case .Plot(_) = selectedMode! {
            let type = row < pcnt ? IntroViewController.extraPickerTypes[row].0 : IntroViewController.previewTypes[row-pcnt]
            let spec = row < pcnt ? IntroViewController.extraPickerTypes[row].1 : (IntroViewController.previewSpecs[type.identifier] ?? nil)
            selectedMode = GraphMode.Plot(type, spec)
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
        guard UserManager.sharedManager.hasAccount() else {
            UINotifications.loginRequest(self)
            return
        }

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
        timeEventPagesController.goTo(tevDisplayerCIndex)
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
    class MCButton : HTPressableButton {

    }
}