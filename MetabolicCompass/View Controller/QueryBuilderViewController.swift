//
//  QueryBuilderViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/18/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import MetabolicCompassKit
import UIKit
import HealthKit
import Former
import HTPressableButton
import MGSwipeTableCell
import Crashlytics
import SwiftDate
import SwiftyBeaver

enum BuilderMode {
    case Editing(Int)
    case Creating
}

private let lblFontSize = ScreenManager.sharedInstance.queryBuilderLabelFontSize()
private let inputFontSize = ScreenManager.sharedInstance.queryBuilderInputFontSize()

/**
 This class is used to build queries for filtering the displayed metrics on the 1st and 2nd dashboard screens. The advantage to our users is the ability to create a set of filters that provide an optimal, and ongoing, comparison to their own situation.

 - note: used in QueryViewController
 */
class QueryBuilderViewController: UIViewController, UITextFieldDelegate {

    let dataTableView: PredicateTableView = PredicateTableView(frame: CGRectMake(0, 0, 1000, 1000), style: .Plain)
    let queryTableView: UITableView = UITableView(frame: CGRect.zero, style: .Plain)
    lazy var former: Former = Former(tableView: self.queryTableView)

    private let log = SwiftyBeaver.self
    // TODO: meal/activity attributes.
    // TODO: humanize attribute names.
    static let attributeOptions =
        PreviewManager.supportedTypes.flatMap { type in
            HMConstants.sharedInstance.hkToMCDB[type.identifier]
        }

    static let aggregateOperators = ["avg", "min", "max"]

    var buildMode : BuilderMode! = nil

    var attribute : String = QueryBuilderViewController.attributeOptions.first!
    var queryName : String = ""
    var aggregateSelected = 0
    var lowerBound : String? = nil
    var upperBound : String? = nil

    lazy var addPredicateButton: UIButton = {
        let button = MCButton(frame: CGRectMake(0, 0, 100, 25), buttonStyle: .Rounded)
        button.cornerRadius = 4.0
        button.buttonColor = UIColor.ht_sunflowerColor()
        button.shadowColor = UIColor.ht_citrusColor()
        button.shadowHeight = 4
        button.setTitle("Add Predicate", forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(lblFontSize, weight: UIFontWeightRegular)
        button.addTarget(self, action: "addPredicate:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var saveQueryButton: UIButton = {
        let button = MCButton(frame: CGRectMake(0, 0, 100, 25), buttonStyle: .Rounded)
        button.cornerRadius = 4.0
        button.buttonColor = UIColor.ht_pumpkinColor()
        button.shadowColor = UIColor.ht_pomegranateColor()
        button.shadowHeight = 4
        button.setTitle("Save Query", forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(lblFontSize, weight: UIFontWeightRegular)
        button.addTarget(self, action: "saveQuery:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.addPredicateButton, self.saveQueryButton])
        stack.axis = .Horizontal
        stack.distribution = UIStackViewDistribution.FillEqually
        stack.alignment = UIStackViewAlignment.Fill
        stack.spacing = 5
        return stack
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Query Builder"
        dataTableView.reloadData()
        queryTableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("QueryBuilder",
            contentType: "",
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch buildMode! {
        case .Creating:
            self.queryName = "Query \(String(QueryManager.sharedManager.getQueries().count))"
            self.dataTableView.predicates = []
        case .Editing(let row):
            self.queryName = QueryManager.sharedManager.getQueries()[row].0

            switch QueryManager.sharedManager.getQueries()[row].1 {
            // TODO: Yanif: display start/end times and columns to fetch?
            case .ConjunctiveQuery(_, _, _, let pred):
                self.dataTableView.predicates = pred
            }
        }

        dataTableView.registerClass(MGSwipeTableCell.self, forCellReuseIdentifier: "predicateCell")
        queryTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "inputCell")
        configureViews()
        dataTableView.layoutIfNeeded()
    }

    func builderForm() {

        let attributeSelectorRow = SelectorPickerRowFormer<FormSelectorPickerCell, Any> {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Attribute"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(inputFontSize)
            $0.displayLabel.textColor = .whiteColor()
            $0.displayLabel.font = .boldSystemFontOfSize(lblFontSize)
            }.configure {
                let toolBar = UIToolbar()
                toolBar.barStyle = UIBarStyle.Default
                toolBar.translucent = true
                toolBar.tintColor = UIColor.ht_wetAsphaltColor()
                toolBar.sizeToFit()

                let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "donePicker")
                let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)

                toolBar.setItems([spaceButton, doneButton], animated: false)
                toolBar.userInteractionEnabled = true

                $0.inputAccessoryView = toolBar
                $0.selectorView.tintColor = UIColor.ht_belizeHoleColor()
                $0.pickerItems = QueryBuilderViewController.attributeOptions.map { SelectorPickerItem(title: $0) }
            }.onValueChanged { [weak self] item in
                self?.attribute = item.title
        }

        let aggregatePickerRow = SegmentedRowFormer<FormSegmentedCell>(instantiateType: .Class) {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Aggregate"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(inputFontSize)
            $0.tintColor = .whiteColor()
            }.configure {
                let attr = NSDictionary(object: UIFont.systemFontOfSize(inputFontSize), forKey: NSFontAttributeName)
                $0.cell.formSegmented().setTitleTextAttributes(attr as [NSObject : AnyObject], forState: .Normal)
                $0.segmentTitles = QueryBuilderViewController.aggregateOperators
                $0.selectedIndex = 0
            }.onSegmentSelected { [weak self] index, _ in
                self?.aggregateSelected = index
        }

        let lowerBoundRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Lower bound"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(inputFontSize)
            $0.textField.textColor = .whiteColor()
            $0.textField.font = .boldSystemFontOfSize(lblFontSize)
            $0.textField.textAlignment = .Right
            $0.textField.returnKeyType = .Next
            $0.tintColor = .blueColor()
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:"0",
                    attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            }.onTextChanged { [weak self] txt in
                self?.lowerBound = txt
        }

        let upperBoundRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Upper bound"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(inputFontSize)
            $0.textField.textColor = .whiteColor()
            $0.textField.font = .boldSystemFontOfSize(lblFontSize)
            $0.textField.textAlignment = .Right
            $0.textField.returnKeyType = .Next
            $0.tintColor = .blueColor()
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:"100",
                    attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            }.onTextChanged { [weak self] txt in
                self?.upperBound = txt
        }

        let queryNameRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Query name"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(inputFontSize)
            $0.textField.textColor = .whiteColor()
            $0.textField.font = .boldSystemFontOfSize(lblFontSize)
            $0.textField.textAlignment = .Right
            $0.textField.returnKeyType = .Next
            $0.tintColor = .blueColor()
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:self.queryName, attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            }.onTextChanged { [weak self] txt in
                self?.queryName = txt
        }

        let section = SectionFormer(rowFormer: queryNameRow, aggregatePickerRow, attributeSelectorRow, lowerBoundRow, upperBoundRow)
        former.append(sectionFormer: section)
    }

    func donePicker() {
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - View setup
    private func configureViews() {
        dataTableView.translatesAutoresizingMaskIntoConstraints = false
        dataTableView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        dataTableView.rowHeight = UITableViewAutomaticDimension
        dataTableView.estimatedRowHeight = 30.0
        dataTableView.allowsSelection = false

        queryTableView.translatesAutoresizingMaskIntoConstraints = false
        queryTableView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        queryTableView.scrollEnabled = false
        queryTableView.separatorColor = Theme.universityDarkTheme.backgroundColor

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        builderForm()

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor
        view.addSubview(dataTableView)
        view.addSubview(queryTableView)
        view.addSubview(buttonStack)

        view.addConstraints([
            dataTableView.topAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.topAnchor),
            dataTableView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            dataTableView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor),
            dataTableView.bottomAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerYAnchor),

            queryTableView.topAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerYAnchor),
            queryTableView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor),
            queryTableView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor),
            queryTableView.bottomAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.bottomAnchor, constant: -30),

            buttonStack.bottomAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.bottomAnchor, constant: -10),
            buttonStack.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor),
            buttonStack.heightAnchor.constraintEqualToConstant(44)
        ])
    }

    func addPredicate(sender: UIButton) {
        if ( !(lowerBound == nil && upperBound == nil) ) {

            // TODO: meal/activity info based on attribute information.
            var hkType : HKObjectType? = nil
            let hkIdentifier = HMConstants.sharedInstance.mcdbToHK[attribute]!

            switch hkIdentifier {
            case HKCategoryTypeIdentifierSleepAnalysis:
                hkType = HKObjectType.categoryTypeForIdentifier(hkIdentifier)!
            case HKCategoryTypeIdentifierAppleStandHour:
                hkType = HKObjectType.categoryTypeForIdentifier(hkIdentifier)!
            default:
                hkType = HKObjectType.quantityTypeForIdentifier(hkIdentifier)!
            }

            let mcQueryAttr : MCQueryAttribute = (hkType!, nil)
            let pred = (Aggregate(rawValue: aggregateSelected)!, mcQueryAttr, lowerBound, upperBound)

            dataTableView.predicates.append(pred)
            dataTableView.reloadData()
        } else {
            log.error("Invalid predicate, no bounds are set.")
        }
    }

    // TODO: Yanif: creation and editing of start/end times and columns to fetch
    func saveQuery(sender: UIButton) {
        switch buildMode! {
        case .Creating:
            QueryManager.sharedManager.addQuery(self.queryName, query: Query.ConjunctiveQuery(nil, nil, nil, dataTableView.predicates))

        case .Editing(let row):
            QueryManager.sharedManager.updateQuery(row, name: self.queryName, query: Query.ConjunctiveQuery(nil, nil, nil, dataTableView.predicates))
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class PredicateTableView : UITableView, UITableViewDelegate, UITableViewDataSource {

    var predicates : [MCQueryPredicate] = []

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        self.delegate = self
        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.dataSource = self
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predicates.count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Predicates"
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("predicateCell", forIndexPath: indexPath) as! MGSwipeTableCell

        cell.backgroundColor = Theme.universityDarkTheme.backgroundColor
        let (aggr,mcattr,lb,ub) = predicates[indexPath.row]
        let aggstr = QueryBuilderViewController.aggregateOperators[aggr.rawValue]
        let attrstr = HMConstants.sharedInstance.hkToMCDB[mcattr.0.identifier]

        var celltxt = "<invalid>"
        if let lbstr = lb {
            if let ubstr = ub {
                celltxt = "\(lbstr) <= \(aggstr)(\(attrstr)) <= \(ubstr)"
            } else {
                celltxt = "\(lbstr) <= \(aggstr)(\(attrstr))"
            }
        } else {
            if let ubstr = ub {
                celltxt = "\(aggstr)(\(attrstr)) <= \(ubstr)"
            }
        }

        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = .boldSystemFontOfSize(lblFontSize)
        cell.textLabel?.text = celltxt

        let deleteButton = MGSwipeButton(title: "Delete", backgroundColor: .ht_carrotColor(), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            if let idx = tableView.indexPathForCell(sender) {
                self.predicates.removeAtIndex(idx.row)
                tableView.deleteRowsAtIndexPaths([idx], withRowAnimation: UITableViewRowAnimation.Right)
                return false
            }
            return true
        })
        deleteButton.titleLabel?.font = .boldSystemFontOfSize(14)

        cell.rightButtons = [deleteButton]
        cell.leftSwipeSettings.transition = MGSwipeTransition.Static
        return cell
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        header.textLabel?.textColor = UIColor.whiteColor()
    }

    class MCButton : HTPressableButton {

    }
}
