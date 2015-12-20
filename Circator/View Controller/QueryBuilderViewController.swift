//
//  QueryBuilderViewController.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/18/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import CircatorKit
import UIKit
import Former
import MGSwipeTableCell

enum BuilderMode {
    case Editing(Int)
    case Creating
}

class QueryBuilderViewController: UIViewController, UITextFieldDelegate {

    let dataTableView: PredicateTableView = PredicateTableView(frame: CGRectMake(0, 0, 1000, 1000), style: .Plain)
    let queryTableView: UITableView = UITableView(frame: CGRect.zero, style: .Plain)
    lazy var former: Former = Former(tableView: self.queryTableView)

    static let attributeOptions = HealthManager.attributeNamesBySampleType.map { (key, value) in value.1 }
    static let comparisonOperators = ["<", "<=", "==", "!=", "=>", ">"]

    var buildMode : BuilderMode! = nil

    var attribute : String = QueryBuilderViewController.attributeOptions.first!
    var name : String = ""
    var value : String = "0"
    var comparisonSelected = 0

    lazy var addPredicateButton: UIButton = {
        let button = MCButton(frame: CGRectMake(0, 0, 100, 25), buttonStyle: .Rounded)
        button.cornerRadius = 4.0
        button.buttonColor = UIColor.ht_sunflowerColor()
        button.shadowColor = UIColor.ht_citrusColor()
        button.shadowHeight = 4
        button.setTitle("Add Predicate", forState: .Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
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
        button.titleLabel?.font = UIFont.systemFontOfSize(14, weight: UIFontWeightRegular)
        button.addTarget(self, action: "saveQuery:", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.addPredicateButton, self.saveQueryButton])
        stack.axis = .Horizontal
        stack.distribution = UIStackViewDistribution.FillEqually
        stack.alignment = UIStackViewAlignment.Fill
        stack.spacing = 15
        return stack
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Query Builder"
        dataTableView.reloadData()
        queryTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch buildMode! {
        case .Creating:
            self.name = "Query \(String(QueryManager.sharedManager.getQueries().count))"
            self.dataTableView.predicates = []
        case .Editing(let row):
            self.name = QueryManager.sharedManager.getQueries()[row].0
            self.dataTableView.predicates = QueryManager.sharedManager.getQueries()[row].1
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
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.displayLabel.textColor = .whiteColor()
            $0.displayLabel.font = .boldSystemFontOfSize(14)
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

        let comparatorPickerRow = SegmentedRowFormer<FormSegmentedCell>(instantiateType: .Class) {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Comparator"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.tintColor = .whiteColor()
            }.configure {
                $0.segmentTitles = QueryBuilderViewController.comparisonOperators
                $0.selectedIndex = 0
            }.onSegmentSelected { [weak self] index, _ in
                self?.comparisonSelected = index
        }

        let valueRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Value"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.textField.textColor = .whiteColor()
            $0.textField.font = .boldSystemFontOfSize(14)
            $0.textField.textAlignment = .Right
            $0.textField.returnKeyType = .Next
            $0.tintColor = .blueColor()
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:"0",
                    attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            }.onTextChanged { [weak self] txt in
                self?.value = txt
        }

        let queryNameRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Query name"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.textField.textColor = .whiteColor()
            $0.textField.font = .boldSystemFontOfSize(14)
            $0.textField.textAlignment = .Right
            $0.textField.returnKeyType = .Next
            $0.tintColor = .blueColor()
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:self.name, attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            }.onTextChanged { [weak self] txt in
                self?.name = txt
        }

        let section = SectionFormer(rowFormer: comparatorPickerRow, attributeSelectorRow, valueRow, queryNameRow)
        former.append(sectionFormer: section)
    }

    func donePicker() {
        self.view.endEditing(true)
    }

    func cancelPicker() {
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
        dataTableView.predicates.append((attribute, Comparator(rawValue: comparisonSelected)!, value))
        dataTableView.reloadData()
    }

    func saveQuery(sender: UIButton) {
        switch buildMode! {
        case .Creating:
            QueryManager.sharedManager.addQuery(self.name, query: dataTableView.predicates)
            
        case .Editing(let row):
            QueryManager.sharedManager.updateQuery(row, name: self.name, query: dataTableView.predicates)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class PredicateTableView : UITableView, UITableViewDelegate, UITableViewDataSource {

    var predicates : [(String, Comparator, String)] = []

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
        let (attr,op,val) = predicates[indexPath.row]
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = .boldSystemFontOfSize(14)
        cell.textLabel?.text = "\(attr) \(QueryBuilderViewController.comparisonOperators[op.rawValue]) \(val)"

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
}
