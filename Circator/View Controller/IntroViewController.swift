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

let IntroViewTableViewCellIdentifier = "IntroViewTableViewCellIdentifier"

class IntroViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var logoImageView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "logo_university")!)
        view.tintColor = Theme.universityDarkTheme.foregroundColor
        return view
    }()

    lazy var analyzeButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.addTarget(self, action: "analyze:", forControlEvents: .TouchUpInside)
        button.setTitle("Analyze", forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.8)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
        return button
    }()
    
    lazy var settingsButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Settings", forState: .Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel!.textAlignment = .Center
        button.addTarget(self, action: "showSettings:", forControlEvents: .TouchUpInside)
        button.layer.cornerRadius = 7.0
        button.backgroundColor = Theme.universityDarkTheme.complementForegroundColors?.colorWithVibrancy(0.2)
        button.setTitleColor(Theme.universityDarkTheme.bodyTextColor, forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
        return button
    }()
    
    lazy var buttonsContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [self.analyzeButton, self.settingsButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        tableView.layoutIfNeeded()
        
//        let realm = try! Realm()
//        let labels = Sample.attributes()
//
//        for (i,ltxt) in labels.enumerate() {
//            var labeltxt = ""
//            if i > 0 {
//                let attr = Sample.attrnames()[i-1]
//                let statistic : Double? = realm.objects(Sample).average(attr)
//                labeltxt = statistic == nil ? ltxt : ltxt + ": " + statistic!.description
//            } else {
//                labeltxt = ltxt
//            }
//
//            let lbl = UILabel()
//            lbl.text = labeltxt
//            lbl.textColor = UIColor.blackColor()
//            lbl.textAlignment = .Center
//            lbl.font = UIFont.systemFontOfSize(20)
//            lbl.frame = CGRectMake(0, 200+CGFloat(i)*30, 300, 30)
//            self.view.addSubview(lbl)
//        }
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
        view.addSubview(logoImageView)
        let constraints: [NSLayoutConstraint] = [
            logoImageView.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.6),
            logoImageView.heightAnchor.constraintEqualToAnchor(logoImageView.widthAnchor, multiplier: 1.0744),
            NSLayoutConstraint(item: logoImageView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 0.25, constant: 0),
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
        view.addConstraints(buttonContainerConstraints)
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
    }

    // MARK: - Button Events
    
    func analyze(sender: UIButton) {
        let correlationViewController = CorrelationViewController()
        navigationController?.pushViewController(correlationViewController, animated: true)
    }

    func showSettings(sender: UIButton) {
        let settingsViewController = SettingsViewController()
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    // MARK: - Table View
    
    let userData = [
        DataSample(type: HealthManager.Parameter.BodyMass, data: HKQuantity(unit: HKUnit.meterUnit(), doubleValue: 70)),
        DataSample(type: HealthManager.Parameter.EnergyIntake, data: HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 2000)),
        DataSample(type: HealthManager.Parameter.HeartRate, data: HKQuantity(unit: HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()), doubleValue: 70)),
        DataSample(type: HealthManager.Parameter.BloodPressure, data: HKQuantity(unit: HKUnit.millimeterOfMercuryUnit(), doubleValue: 120)),
        DataSample(type: HealthManager.Parameter.Sleep, data: HKQuantity(unit: HKUnit.hourUnit(), doubleValue: 6.2))
    ]
    
    let populationAverageData = [
        DataSample(type: HealthManager.Parameter.BodyMass, data: HKQuantity(unit: HKUnit.meterUnit(), doubleValue: 77)),
        DataSample(type: HealthManager.Parameter.EnergyIntake, data: HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: 2500)),
        DataSample(type: HealthManager.Parameter.HeartRate, data: HKQuantity(unit: HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()), doubleValue: 76)),
        DataSample(type: HealthManager.Parameter.BloodPressure, data: HKQuantity(unit: HKUnit.millimeterOfMercuryUnit(), doubleValue: 118)),
        DataSample(type: HealthManager.Parameter.Sleep, data: HKQuantity(unit: HKUnit.hourUnit(), doubleValue: 7.1))
    ]
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(IntroViewTableViewCellIdentifier, forIndexPath: indexPath) as! IntroCompareDataTableViewCell
        cell.setUserData(userData[indexPath.row], populationAverageData: populationAverageData[indexPath.row])
        return cell
    }

}

