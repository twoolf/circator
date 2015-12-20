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
import Realm
import RealmSwift
import Dodo
import HTPressableButton

let IntroViewTableViewCellIdentifier = "IntroViewTableViewCellIdentifier"

class IntroViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate {

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
        //stackView.distribution = UIStackViewDistribution.FillEqually
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
    static let previewTypeStrings = PreviewManager.previewSampleTypes.map { $0.displayText! }
    static let previewMealTypeStrings = [["Bkfast", "Lunch", "Dinner", "Snack"],
                                         ["AM", "5:00","5:30","6:00","6:30","7:00","7:30","8:00","8:30","9:00","9:30","10:00","10:30","11:00","11:30","12:00",
                                          "PM", "12:30","13:00","13:30","14:00","14:30","15:00","15:30","16:00","16:30","17:00", "17:30", "18:00", "18:30",
                                                "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "24:00",
                                          "AM", "00:30", "1:00", "1:30", "2:00", "2:30", "3:00", "3:30", "4:00", "4:30"],
                                         ["Min", "15", "30", "45", "60", "90", "120", "150", "180", "210", "240"],
                                         ["1✮", "2✮", "3✮", "4✮", "5✮"]]

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

    func fetchInitialAggregates() {
        Async.userInteractive {
            self.fetchAggregatesPeriodically()
        }
    }

    func fetchAggregatesPeriodically() {
        HealthManager.sharedManager.fetchAggregates()
        if let freq = UserManager.sharedManager.getRefreshFrequency() {
            Async.background(after: Double(freq)) {
                self.fetchAggregatesPeriodically()
            }
        } else {

        }
    }

    func fetchRecentSamples() {
        HealthManager.sharedManager.authorizeHealthKit { (success, error) -> Void in
            guard error == nil else { return }
            EventManager.sharedManager.checkCalendarAuthorizationStatus()
            HealthManager.sharedManager.fetchMostRecentSamples() { (samples, error) -> Void in
                guard error == nil else { return }
                NSNotificationCenter.defaultCenter().postNotificationName(HealthManagerDidUpdateRecentSamplesNotification, object: self)
            }
        }
    }

    func loginAndInitialize() {
        // Jump to the login screen if either the username or password are unavailable.
        guard !(UserManager.sharedManager.getUserId() == nil
            || UserManager.sharedManager.getPassword() == nil)
            else
        {
            toggleLogin(asInitial: true)
            return
        }
        initializeBackgroundWork()
    }

    func initializeBackgroundWork() {
        Async.main(after: 2) {
            self.fetchInitialAggregates()
            self.fetchRecentSamples()
            HealthManager.sharedManager.registerObservers()
        }
    }


    // MARK: - View Event Handlers

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        tableView.layoutIfNeeded()
        NSNotificationCenter.defaultCenter().addObserverForName(HealthManagerDidUpdateRecentSamplesNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
            self.tableView.reloadData()
        }
        Async.main(after: 2) {
            self.view.dodo.style.bar.hideAfterDelaySeconds = 3
            self.view.dodo.style.bar.hideOnTap = true
            self.view.dodo.error("Welcome " + (UserManager.sharedManager.getUserId() ?? ""))
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: self.view.frame.width, bottom: 0, right: 0)
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
            topButtonsContainerView.leadingAnchor.constraintLessThanOrEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 43 + 37),
            topButtonsContainerView.heightAnchor.constraintEqualToConstant(27),
            logoutButton.widthAnchor.constraintEqualToConstant(27),
            queryButton.leadingAnchor.constraintEqualToAnchor(logoutButton.trailingAnchor, constant: 0),
            queryButton.widthAnchor.constraintEqualToConstant(27),
            settingsButton.leadingAnchor.constraintEqualToAnchor(queryButton.trailingAnchor, constant: 0),
            settingsButton.widthAnchor.constraintEqualToConstant(27)
        ]
        view.addConstraints(topButtonsContainerConstraints)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        let tableViewConstraints: [NSLayoutConstraint] = [
            tableView.topAnchor.constraintEqualToAnchor(logoImageView.bottomAnchor, constant: 15),
            tableView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraintEqualToAnchor(buttonsContainerView.topAnchor, constant: -30)
        ]
        view.addConstraints(tableViewConstraints)

        timerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerContainerView)
        let timerContainerConstraints: [NSLayoutConstraint] = [
            timerContainerView.bottomAnchor.constraintEqualToAnchor(buttonsContainerView.topAnchor, constant: -25),
            timerContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 0),
            timerContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            timerContainerView.heightAnchor.constraintEqualToConstant(44)
        ]
        view.addConstraints(timerContainerConstraints)
        
        tableTitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableTitleContainerView)
        let tableTitleConstraints: [NSLayoutConstraint] = [
            tableTitleContainerView.bottomAnchor.constraintEqualToAnchor(tableView.topAnchor, constant: -10),
            tableTitleContainerView.leadingAnchor.constraintEqualToAnchor(tableView.leadingAnchor, constant: 37 + 27),
            tableTitleContainerView.trailingAnchor.constraintEqualToAnchor(tableView.trailingAnchor, constant: 0),
            userImageView.heightAnchor.constraintEqualToConstant(34),
            peopleImageView.heightAnchor.constraintEqualToConstant(34)
        ]
        view.addConstraints(tableTitleConstraints)

        dummyTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dummyTextField)
    }

    // MARK: - Button Events

    func toggleLogin(sender: UIButton) {
        toggleLogin(asInitial: false)
    }

    func toggleLogin(asInitial initial: Bool) {
        if let user = UserManager.sharedManager.getUserId() {
            UserManager.sharedManager.logout()
            view.dodo.style.bar.hideAfterDelaySeconds = 3
            view.dodo.style.bar.hideOnTap = true
            view.dodo.error("Goodbye \(user)")
        } else {
            let loginViewController = LoginViewController()
            loginViewController.parentView = self
            if initial { loginViewController.fetchWhenDone = true }
            navigationController?.pushViewController(loginViewController, animated: true)
        }
    }

    func showAttributes(sender: UIButton) {
        if sender == correlateButton {
            selectedMode = GraphMode.Correlate(PreviewManager.previewSampleTypes[0], PreviewManager.previewSampleTypes[1])
            pickerView.reloadAllComponents()
        } else if sender == plotButton {
            selectedMode = GraphMode.Plot(PreviewManager.previewSampleTypes[0])
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
            let correlateVC = CorrelationViewController()
            correlateVC.sampleTypes = [type1, type2]
            navigationController?.pushViewController(correlateVC, animated: true)
            break
        case .Plot(let type):
            let plotVC = PlotViewController()
            plotVC.sampleType = type
            navigationController?.pushViewController(plotVC, animated: true)
        case .previewMealTypeStrings:
            let calendar = NSCalendar.currentCalendar()
            let currentDate = NSDate()
            let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second, NSCalendarUnit.Nanosecond], fromDate: currentDate)
            let delimiter = ":"
            var updatedTime = IntroViewController.previewMealTypeStrings[1][pickerView.selectedRowInComponent(1)].componentsSeparatedByString(delimiter)
            let delimiter2 = " "
            let delimiter3 = "min"
            var updatedTimeMinute = updatedTime[1].componentsSeparatedByString(delimiter2)
            var updatedDurationMinute = IntroViewController.previewMealTypeStrings[2][pickerView.selectedRowInComponent(2)].componentsSeparatedByString(delimiter3)
            let components = NSDateComponents()
              components.day = dateComponents.day
              components.month = dateComponents.month
              components.year = dateComponents.year
              components.hour = Int(updatedTime[0])!
              components.minute = Int(updatedTimeMinute[0])!
            let newDate = calendar.dateFromComponents(components)
            let newDateComponents = NSDateComponents()
              newDateComponents.minute = Int(updatedDurationMinute[0])!
            let calculatedDate = NSCalendar.currentCalendar().dateByAddingComponents(newDateComponents, toDate: newDate!, options: NSCalendarOptions.init(rawValue: 0))
            let distanceHold = 0.0
            let kiloCaloriesHold = 0.0
            let kmUnit = HKUnit(fromString: "km")
            let metaMeals = [String(IntroViewController.previewMealTypeStrings[3][pickerView.selectedRowInComponent(3)]):"Meal Rating", String(IntroViewController.previewMealTypeStrings[0][pickerView.selectedRowInComponent(0)]):"Meal Type"]
            HealthManager.sharedManager.savePreparationAndRecoveryWorkout(newDate!, endDate: calculatedDate!, distance: distanceHold, distanceUnit:kmUnit, kiloCalories: kiloCaloriesHold, metadata: metaMeals, completion: { (success, error ) -> Void in
                if( success )
                {
                    print("Meal saved as workout-type")
                }
                else if( error != nil ) {
                    print("error made: \(error)")
                }
            })
        }
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
        return 6
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(IntroViewTableViewCellIdentifier, forIndexPath: indexPath) as! IntroCompareDataTableViewCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType
        let timeSinceRefresh = NSDate().timeIntervalSinceDate(HealthManager.sharedManager.aggregateRefreshDate)
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
        let stale = timeSinceRefresh > Double(refreshPeriod)
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: HealthManager.sharedManager.mostRecentAggregates[sampleType]
                                                    ?? [DerivedQuantity(quantity: nil, quantityType: nil)],
                         stalePopulation: stale)
        return cell
    }

    // MARK: - Picker view delegate

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if case .Plot(_) = selectedMode! {
            return 1
        } else if case .previewMealTypeStrings(_) = selectedMode! {
            return 4
        } else {
            return 2
        }
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if case .Correlate(_) = selectedMode! {
            if component == 0 {
                return IntroViewController.previewTypeStrings.count
            } else {
                return IntroViewController.previewTypeStrings.count - 1
            }
        } else if case .Plot(_) = selectedMode! {
            return IntroViewController.previewTypeStrings.count
        } else {
            return IntroViewController.previewMealTypeStrings[component].count
        }
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if case .Correlate(_) = selectedMode! {
            if component == 0 {
                return IntroViewController.previewTypeStrings[row]
            } else  {
                return IntroViewController.previewTypeStrings.filter { $0 != IntroViewController.previewTypeStrings[pickerView.selectedRowInComponent(0)] }[row]
            }
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
            if component == 0 {
                pickerView.reloadComponent(1)
            } else {
                selectedMode = GraphMode.Correlate(PreviewManager.previewSampleTypes.filter { $0.displayText == PreviewManager.previewSampleTypes[pickerView.selectedRowInComponent(0)].displayText }.first!, PreviewManager.previewSampleTypes.filter { $0.displayText == PreviewManager.previewSampleTypes[row].displayText }.first!)
            }
        } else if case .Plot(_) = selectedMode! {
            selectedMode = GraphMode.Plot(PreviewManager.previewSampleTypes.filter { $0.displayText == PreviewManager.previewSampleTypes[row].displayText }.first!)
        } else {

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
                if( success ) {
                    print("Timed meal saved as workout-type")
                } else if( error != nil ) {
                    print("error made: \(error)")
                }
            })
    }
}

class MCButton : HTPressableButton {

}