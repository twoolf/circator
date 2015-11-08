//
//  IntroViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf, Sihao Lu. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import HealthKit
import CircatorKit

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

    lazy var plotButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        button.setTitle("Plot", forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
        return button
    }()
    
    lazy var mealButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        button.setTitle("Meal", forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
        return button
    }()
    
    lazy var correlateButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Correlate", forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.addTarget(self, action: "showAttributes:", forControlEvents: .TouchUpInside)
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.2)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
        return button
    }()
    
//    let mealPickerData = ["Breakfast", "Lunch", "Dinner"]
//    lazy var mealPicker: UIPickerView = {
//        let meal = UIPickerView(frame: <#T##CGRect#>)
//        meal.
//    }
//    lazy var mealPickerLabel: UILabel = {
//        let label = UILabel(frame: <#T##CGRect#>)
//        label.
//    }
    
    
//    lazy var timerButton: UIButton = {
//        let button = UIButton(type: .Custom)
//        button.addTarget(self, action: "showTimerAttributes:", forControlEvents: .TouchUpInside)
//        button.setTitle("Meal", forState: .Normal)
//        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
//        button.titleLabel!.textAlignment = .Center
//        button.layer.cornerRadius = 7.0
//        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
//        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
//        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
//        return button
//    }()
    

//    lazy var stopButton: UIButton = {
//        let button = UIButton(type: .Custom)
//        button.setTitle("Stop", forState: .Normal)
//        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
//        button.titleLabel!.textAlignment = .Center
//        button.addTarget(self, action: "showTimerAttributes:", forControlEvents: .TouchUpInside)
//        button.layer.cornerRadius = 7.0
//        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.2)
//        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
//        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
//        return button
//    }()
    
//    lazy var settingsButton: UIButton = {
//        let button = UIButton(type: .Custom)
//        button.setTitle("Settings", forState: .Normal)
//        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
//        button.titleLabel!.textAlignment = .Center
//        button.addTarget(self, action: "showSettings:", forControlEvents: .TouchUpInside)
//        button.layer.cornerRadius = 7.0
//        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.2)
//        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
//        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
//        return button
//    }()
    
    lazy var buttonsContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.plotButton, self.correlateButton, self.mealButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 15
        return stackView
    }()
    
//    lazy var timerButtonsContainerView: UIStackView = {
//        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.stopButton])
//        stackView.axis = .Horizontal
//        stackView.distribution = UIStackViewDistribution.FillEqually
//        stackView.alignment = UIStackViewAlignment.Fill
//        stackView.spacing = 15
//        return stackView
//    }()
    
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
    static let previewTypeStrings = HealthManager.previewSampleTypes.map { $0.displayText! }
    static let previewMealTypeStrings = ["Breakfast", "Lunch", "Dinner", "Snack"]
    static let previewMealTimeStarts = ["noon", "1 PM", "3 PM", "6 PM"]
    
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
    
//    lazy var timeTextField: UITextField = {
//        let textField = UITextField()
//        textField.inputView = self.pickerView
//        textField.inputAccessoryView = {
//            let view = UIToolbar()
//            view.frame = CGRectMake(0, 0, 0, 44)
//            view.items = [
//                UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "dismissPopup:"),
//                UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: ""),
//                UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "selectAttribute:")
//            ]
//            return view
//            }()
//        return textField
//    }()
    
    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()
    
    enum GraphMode {
        case Plot(HKSampleType)
        case Correlate(HKSampleType, HKSampleType)
//        case Plot2(NSDate)
        case previewMealTypeStrings
        case previewMealTimeStarts
    }
    
    private var selectedMode: GraphMode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        tableView.layoutIfNeeded()
//        if mealPicker != nil && mealPickerLabel != nil  {
//          mealPicker!.delegate = self
//          mealPicker!.dataSource = self
//        }
        NSNotificationCenter.defaultCenter().addObserverForName(HealthManagerDidUpdateRecentSamplesNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
            self.tableView.reloadData()
        }
    }
    
//    func numberOfComponentsInMealPickerView(mealPickerView: UIPickerView) -> Int {
//        return 1
//    }
    
//    func mealPickerView(mealPickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return mealPickerData.count
//    }
    
//    func mealPickerView(mealPickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return mealPickerData[row]
//    }
    
//    func mealPickerView(mealPickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        mealPickerLabel!.text = mealPickerData[row]
//    }
    
//    func mealPickerView(mealPickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//        let titleData = mealPickerData[row]
//        let mealPickerTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "Georgia", size: 26.0)!,NSForegroundColorAttributeName:UIColor.blueColor()])
//        return mealPickerTitle
//    }
    
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
            buttonsContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 20),
            buttonsContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            buttonsContainerView.heightAnchor.constraintEqualToConstant(44)
        ]
        view.addConstraints(constraints)
//        timerButtonsContainerView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(timerButtonsContainerView)
//        let timerButtonContainerConstraints: [NSLayoutConstraint] = [
//            timerButtonsContainerView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.bottomAnchor, constant: -90),
//            timerButtonsContainerView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 20),
//            timerButtonsContainerView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
//            timerButtonsContainerView.heightAnchor.constraintEqualToConstant(44)
//        ]
        view.addConstraints(buttonContainerConstraints)
//        view.addConstraints(timerButtonContainerConstraints)
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
            selectedMode = GraphMode.Correlate(HealthManager.previewSampleTypes[0], HealthManager.previewSampleTypes[1])
            pickerView.reloadAllComponents()
//            print("in graph mode: correlate")
        } else if sender == plotButton {
            selectedMode = GraphMode.Plot(HealthManager.previewSampleTypes[0])
            pickerView.reloadAllComponents()
//            print("in graph mode: plot")
        } else if sender == mealButton {
            selectedMode = GraphMode.previewMealTypeStrings
//            selectedMode = GraphMode.Plot2(HealthManager.previewSampleTimes[0])
            pickerView.reloadAllComponents()
//            print("in graph mode: start")
        }
        dummyTextField.becomeFirstResponder()
    }
    
//    func showTimerAttributes(sender: UIButton) {
//        if sender == correlateButton {
//            selectedMode = GraphMode.Correlate(HealthManager.previewSampleTypes[0], HealthManager.previewSampleTypes[1])
//            pickerView.reloadAllComponents()
////            print("in graph mode: correlate")
//        } else {
//            selectedMode = GraphMode.Plot(HealthManager.previewSampleTypes[0])
//            pickerView.reloadAllComponents()
////            print("in graph mode: plot")
//        }
//        dummyTextField.becomeFirstResponder()
//    }
    
//    func showTimerAttributes(sender: UIButton) {
//        if sender == startButton {
//            startButton.setTitle("pushed", forState:UIControlState.Normal)
//            pickerView.reloadAllComponents()
//        } else {
//            stopButton.setTitle("button pushed", forState:UIControlState.Normal)
//            pickerView.reloadAllComponents()
//        }
//        timeTextField.becomeFirstResponder()
//    }
    
    
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
            return
        case .previewMealTimeStarts:
            return
//            let plotVC = PlotViewController()
//            plotVC.sampleType = type
//            navigationController?.pushViewController(plotVC, animated: true)
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
        return 5
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(IntroViewTableViewCellIdentifier, forIndexPath: indexPath) as! IntroCompareDataTableViewCell
        let sampleType = HealthManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [], populationAverageData: [])
        return cell
    }
    
    // MARK: - Picker view delegate
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if case .Plot(_) = selectedMode! {
            return 1
        } else if case .previewMealTypeStrings(_) = selectedMode! {
            return 2
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
            return IntroViewController.previewMealTypeStrings.count
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if case .Correlate(_) = selectedMode! {
            if component == 0 {
                return IntroViewController.previewTypeStrings[row]
            } else if case .Plot(_) = selectedMode! {
                return IntroViewController.previewTypeStrings.filter { $0 != IntroViewController.previewTypeStrings[pickerView.selectedRowInComponent(0)] }[row]
            } else {
                return IntroViewController.previewMealTypeStrings[row]
            }
        } else if case .Plot(_) = selectedMode! {
            return IntroViewController.previewTypeStrings[row]
        } else if case .previewMealTypeStrings = selectedMode! {
            return IntroViewController.previewMealTypeStrings[row]
        } else {
            return IntroViewController.previewMealTypeStrings[row]
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if case .Correlate(_) = selectedMode! {
            if component == 0 {
                pickerView.reloadComponent(1)
            } else {
                selectedMode = GraphMode.Correlate(HealthManager.previewSampleTypes.filter { $0.displayText == HealthManager.previewSampleTypes[pickerView.selectedRowInComponent(0)].displayText }.first!, HealthManager.previewSampleTypes.filter { $0.displayText == HealthManager.previewSampleTypes[row].displayText }.first!)
            }
        } else if case .Plot(_) = selectedMode! {
            selectedMode = GraphMode.Plot(HealthManager.previewSampleTypes.filter { $0.displayText == HealthManager.previewSampleTypes[row].displayText }.first!)
        } else {
//            selectedMode = GraphMode.previewMealTypeStrings, GraphMode.previewMealTimeStarts
//            selectedMode = GraphMode.Plot(HealthManager.previewSampleTypes.filter { $0.displayText == HealthManager.previewSampleTypes[row].displayText }.first!)
//            selectedMode = GraphMode.Plot2(HealthManager.previewSampleTimes.filter { $0.accessibilityHint == HealthManager.previewSampleTimes[row].accessibilityHint }.first!)
        }
    }

    //    var timer = NSTimer()
    //    let timeInterval:NSTimeInterval = 10.0
    //    var timeCount:NSTimeInterval = 0.0
    //    func timeString(time:NSTimeInterval) -> String {
    //        let minutes = Int(time) / 60
    //        //let seconds = Int(time) % 60
    //        let seconds = time - Double(minutes) * 60
    //        let secondsFraction = seconds - Double(Int(seconds))
    //        return String(format:"%02i:%02i.%01i",minutes,Int(seconds),Int(secondsFraction * 10.0))
    //    }
    
    //    func resetTimeCount(){
    //        if countingDown.on{
    //            timeCount = timerEnd
    //        } else {
    //            timeCount = 0.0
    //        }
    //    }
    //            selectedMode = startButton.setTitle(timeString(timeCount), forState:UIControlState.Normal)
    //            timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval,
    //                target: self,
    //                selector: "timerDidEnd:",
    //                userInfo: "Meal Done",
    //                repeats: true)


}

