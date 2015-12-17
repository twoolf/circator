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

    lazy var titleLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(22, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("Metabolic Compass", comment: "Metabolic Compass")
        return label
    }()

    lazy var plotButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        button.setTitle("Plot", forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        return button
    }()

    lazy var mealButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        button.setTitle("Meal", forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        return button
    }()

    lazy var correlateButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Correlate", forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        return button
    }()

    lazy var settingsButton: UIButton = {
        let image = UIImage(named: "noun_18964_inverted_cc") as UIImage?
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: "showSettings:", forControlEvents: .TouchUpInside)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        let wConstraint = NSLayoutConstraint(item: button,
                                             attribute: NSLayoutAttribute.Width,
                                             relatedBy: NSLayoutRelation.Equal, toItem: nil,
                                             attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 27)
        let hConstraint = NSLayoutConstraint(item: button,
                                             attribute: NSLayoutAttribute.Height,
                                             relatedBy: NSLayoutRelation.Equal, toItem: nil,
                                             attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 27)
        button.addConstraints([wConstraint, hConstraint])
        return button
    }()

    lazy var timerStashLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Last Meal")
        return label
    }()

    lazy var activeTimerLabel : UILabel = {
        let label: UILabel = UILabel()
        label.font = UIFont.systemFontOfSize(28, weight: UIFontWeightRegular)
        label.textColor = Theme.universityDarkTheme.titleTextColor
        label.textAlignment = .Center
        label.text = NSLocalizedString("00:00", comment: "Meal Timer")
        return label
    }()

    lazy var startButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Timer", forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.addTarget(self, action: "toggleTimer:", forControlEvents: .TouchUpInside)
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(16, weight: UIFontWeightRegular)
        return button
    }()

    lazy var buttonsContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.plotButton, self.correlateButton, self.mealButton, self.startButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 7
        return stackView
    }()

    lazy var timerContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.timerStashLabel, self.activeTimerLabel])
        stackView.axis = .Horizontal
        //stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 25
        return stackView
    }()

    lazy var topButtonsContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.titleLabel, self.settingsButton])
        stackView.axis = .Horizontal
        //stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 15

        return stackView
    }()

    lazy var tableTitleContainerView: UIStackView = {
        let userImageView = UIImageView(image: UIImage(named: "icon_user")!)
        userImageView.contentMode = .ScaleAspectFit
        let peopleImageView = UIImageView(image: UIImage(named: "icon_people")!)
        peopleImageView.contentMode = .ScaleAspectFit
        let stackView: UIStackView = UIStackView(arrangedSubviews: [userImageView, peopleImageView])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 0
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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        tableView.layoutIfNeeded()
        NSNotificationCenter.defaultCenter().addObserverForName(HealthManagerDidUpdateRecentSamplesNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
            self.tableView.reloadData()
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
            buttonsContainerView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.bottomAnchor, constant: -30),
            buttonsContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 0),
            buttonsContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            buttonsContainerView.heightAnchor.constraintEqualToConstant(44)
        ]
        view.addConstraints(buttonContainerConstraints)

        timerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerContainerView)
        let timerContainerConstraints: [NSLayoutConstraint] = [
            timerContainerView.bottomAnchor.constraintEqualToAnchor(buttonsContainerView.topAnchor, constant: -30),
            timerContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 0),
            timerContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            timerContainerView.heightAnchor.constraintEqualToConstant(44)
        ]
        view.addConstraints(timerContainerConstraints)

        topButtonsContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topButtonsContainerView)
        let topButtonsContainerConstraints: [NSLayoutConstraint] = [
            topButtonsContainerView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 40),
            topButtonsContainerView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.7),
            topButtonsContainerView.leadingAnchor.constraintLessThanOrEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 47 + 37),
            topButtonsContainerView.heightAnchor.constraintEqualToConstant(27)
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

        tableTitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableTitleContainerView)
        let tableTitleConstraints: [NSLayoutConstraint] = [
            tableTitleContainerView.bottomAnchor.constraintEqualToAnchor(tableView.topAnchor, constant: -10),
            tableTitleContainerView.leadingAnchor.constraintEqualToAnchor(tableView.leadingAnchor, constant: 37 + 27),
            tableTitleContainerView.trailingAnchor.constraintEqualToAnchor(tableView.trailingAnchor, constant: 0),
            tableTitleContainerView.heightAnchor.constraintEqualToConstant(34)
        ]
        view.addConstraints(tableTitleConstraints)

        dummyTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dummyTextField)
    }

    // MARK: - Button Events

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
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: HealthManager.sharedManager.mostRecentAggregates[sampleType]
                                                    ?? [DerivedQuantity(quantity: nil, quantityType: nil)])
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
        if let b = sender as? UIButton { b.backgroundColor = UIColor.redColor() }
        timerLoop = Async.main(after: timerLoopFrequency) { self.updateTimerPeriodically() }
    }

    func stopTimer(sender: AnyObject) {
        if let b = sender as? UIButton {
            b.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        }
        timerCancel = true
        timerStashLabel.text = activeTimerLabel.text
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

