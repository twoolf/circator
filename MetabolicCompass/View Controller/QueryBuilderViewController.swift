//
//  QueryBuilderViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/18/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved. 
//

import UIKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Former
import HTPressableButton
import MGSwipeTableCell
import Crashlytics
import SwiftDate

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

    let dataTableView: PredicateTableView = PredicateTableView(frame: CGRect(0, 0, 1000, 1000), style: .plain)
    let queryTableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    lazy var former: Former = Former(tableView: self.queryTableView)

    // TODO: meal/activity attributes.
    // TODO: humanize attribute names.
    static let attributeOptions =
        PreviewManager.supportedTypes.flatMap { type in
//            HMConstants.sharedInstance.hkToMCDB[type.identifier]
 //           HMConstants.sharedInstance.hkToMCDB[HKDocumentTypeIdentifier]
        }

    static let aggregateOperators = ["avg", "min", "max"]

    var buildMode : BuilderMode! = nil

//    var attribute : String = QueryBuilderViewController.attributeOptions.first!
    var queryName : String = ""
    var aggregateSelected = 0
    var lowerBound : String? = nil
    var upperBound : String? = nil

    lazy var addPredicateButton: UIButton = {
        let button = MCButton(frame: CGRect(0, 0, 100, 25), buttonStyle: .rounded)
        button?.cornerRadius = 4.0
        button?.buttonColor = UIColor.ht_sunflower()
        button?.shadowColor = UIColor.ht_citrus()
        button?.shadowHeight = 4
        button?.setTitle("Add Predicate", for: .normal)
        button?.titleLabel?.font = UIFont.systemFont(ofSize: lblFontSize, weight: UIFontWeightRegular)
        button?.addTarget(self, action: "addPredicate:", for: .touchUpInside)
        return button!
    }()

    lazy var saveQueryButton: UIButton = {
        let button = MCButton(frame: CGRect(0, 0, 100, 25), buttonStyle: .rounded)
        button?.cornerRadius = 4.0
        button?.buttonColor = UIColor.ht_pumpkin()
        button?.shadowColor = UIColor.ht_pomegranate()
        button?.shadowHeight = 4
        button?.setTitle("Save Query", for: .normal)
        button?.titleLabel?.font = UIFont.systemFont(ofSize: lblFontSize, weight: UIFontWeightRegular)
        button?.addTarget(self, action: "saveQuery:", for: .touchUpInside)
        return button!
    }()

    lazy var buttonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.addPredicateButton, self.saveQueryButton])
        stack.axis = .horizontal
        stack.distribution = UIStackViewDistribution.fillEqually
        stack.alignment = UIStackViewAlignment.fill
        stack.spacing = 5
        return stack
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Query Builder"
        dataTableView.reloadData()
        queryTableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentView(withName: "QueryBuilder",
            contentType: "",
//            contentId: Date().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            contentId: Date().string(),
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

        dataTableView.register(MGSwipeTableCell.self, forCellReuseIdentifier: "predicateCell")
        queryTableView.register(UITableViewCell.self, forCellReuseIdentifier: "inputCell")
        configureViews()
        dataTableView.layoutIfNeeded()
    }

    func builderForm() {

        let attributeSelectorRow = SelectorPickerRowFormer<FormSelectorPickerCell, Any> {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Attribute"
            $0.titleLabel.textColor = .white
            $0.titleLabel.font = .boldSystemFont(ofSize: inputFontSize)
            $0.displayLabel.textColor = .white
            $0.displayLabel.font = .boldSystemFont(ofSize: lblFontSize)
            }.configure {
                let toolBar = UIToolbar()
                toolBar.barStyle = UIBarStyle.default
                toolBar.isTranslucent = true
                toolBar.tintColor = UIColor.ht_wetAsphalt()
                toolBar.sizeToFit()

                let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(QueryBuilderViewController.donePicker))
                let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

                toolBar.setItems([spaceButton, doneButton], animated: false)
                toolBar.isUserInteractionEnabled = true

                $0.inputAccessoryView = toolBar
                $0.selectorView.tintColor = UIColor.ht_belizeHole()
//                $0.pickerItems = QueryBuilderViewController.attributeOptions.map { SelectorPickerItem(title: $0) }
            }.onValueChanged { [weak self] item in
//                self?.attribute = item.title
        }

        let aggregatePickerRow = SegmentedRowFormer<FormSegmentedCell>(instantiateType: .Class) {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Aggregate"
            $0.titleLabel.textColor = .white
            $0.titleLabel.font = .boldSystemFont(ofSize: inputFontSize)
            $0.tintColor = .white
            }.configure {
                let attr = NSDictionary(object: UIFont.systemFont(ofSize: inputFontSize), forKey: NSFontAttributeName as NSCopying)
                $0.cell.formSegmented().setTitleTextAttributes(attr as [NSObject : AnyObject], for: .normal)
                $0.segmentTitles = QueryBuilderViewController.aggregateOperators
                $0.selectedIndex = 0
            }.onSegmentSelected { [weak self] index, _ in
                self?.aggregateSelected = index
        }

        let lowerBoundRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Lower bound"
            $0.titleLabel.textColor = .white
            $0.titleLabel.font = .boldSystemFont(ofSize: inputFontSize)
            $0.textField.textColor = .white
            $0.textField.font = .boldSystemFont(ofSize: lblFontSize)
            $0.textField.textAlignment = .right
            $0.textField.returnKeyType = .next
            $0.tintColor = .blue
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:"0",
                    attributes:[NSForegroundColorAttributeName: UIColor.white])
            }.onTextChanged { [weak self] txt in
                self?.lowerBound = txt
        }

        let upperBoundRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Upper bound"
            $0.titleLabel.textColor = .white
            $0.titleLabel.font = .boldSystemFont(ofSize: inputFontSize)
            $0.textField.textColor = .white
            $0.textField.font = .boldSystemFont(ofSize: lblFontSize)
            $0.textField.textAlignment = .right
            $0.textField.returnKeyType = .next
            $0.tintColor = .blue
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:"100",
                    attributes:[NSForegroundColorAttributeName: UIColor.white])
            }.onTextChanged { [weak self] txt in
                self?.upperBound = txt
        }

        let queryNameRow = TextFieldRowFormer<FormTextFieldCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Query name"
            $0.titleLabel.textColor = .white
            $0.titleLabel.font = .boldSystemFont(ofSize: inputFontSize)
            $0.textField.textColor = .white
            $0.textField.font = .boldSystemFont(ofSize: lblFontSize)
            $0.textField.textAlignment = .right
            $0.textField.returnKeyType = .next
            $0.tintColor = .blue
            }.configure {
                $0.attributedPlaceholder = NSAttributedString(string:self.queryName, attributes:[NSForegroundColorAttributeName: UIColor.white])
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
        queryTableView.isScrollEnabled = false
        queryTableView.separatorColor = Theme.universityDarkTheme.backgroundColor

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        builderForm()

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor
        view.addSubview(dataTableView)
        view.addSubview(queryTableView)
        view.addSubview(buttonStack)

        view.addConstraints([
            dataTableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            dataTableView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            dataTableView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            dataTableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),

            queryTableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
            queryTableView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            queryTableView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            queryTableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -30),

            buttonStack.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -10),
            buttonStack.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func addPredicate(sender: UIButton) {
        if ( !(lowerBound == nil && upperBound == nil) ) {

            // TODO: meal/activity info based on attribute information.
            var hkType : HKObjectType? = nil
//            let hkIdentifier = HMConstants.sharedInstance.mcdbToHK[attribute_set]!

/*            switch hkIdentifier {
            case HKCategoryTypeIdentifier.sleepAnalysis.hashValue:
                hkType = HKObjectType.categoryTypeForIdentifier(hkIdentifier)!
            case HKCategoryTypeIdentifier.appleStandHour.hashValue:
                hkType = HKObjectType.categoryTypeForIdentifier(hkIdentifier)!
            default:
                hkType = HKObjectType.quantityTypeForIdentifier(hkIdentifier)!
            } */

            let mcQueryAttr : MCQueryAttribute = (hkType!, nil)
            let pred = (Aggregate(rawValue: aggregateSelected)!, mcQueryAttr, lowerBound, upperBound)

            dataTableView.predicates.append(pred)
            dataTableView.reloadData()
        } else {
//            log.error("Invalid predicate, no bounds are set.")
        }
    }

    // TODO: Yanif: creation and editing of start/end times and columns to fetch
    func saveQuery(sender: UIButton) {
        switch buildMode! {
        case .Creating:
            QueryManager.sharedManager.addQuery(name: self.queryName, query: Query.ConjunctiveQuery(nil, nil, nil, dataTableView.predicates))

        case .Editing(let row):
            QueryManager.sharedManager.updateQuery(index: row, name: self.queryName, query: Query.ConjunctiveQuery(nil, nil, nil, dataTableView.predicates))
        }
        self.navigationController?.popViewController(animated: true)
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predicates.count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Predicates"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "predicateCell", for: indexPath as IndexPath) as! MGSwipeTableCell

        cell.backgroundColor = Theme.universityDarkTheme.backgroundColor
        let (aggr,mcattr,lb,ub) = predicates[indexPath.row]
        let aggstr = QueryBuilderViewController.aggregateOperators[aggr.rawValue]
//        let attrstr = HMConstants.sharedInstance.hkToMCDB[mcattr.0.identifier]
        let attrstr = HMConstants.sharedInstance.hkToMCDB[mcattr.0.identifier.hashValue]

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

        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = .boldSystemFont(ofSize: lblFontSize)
        cell.textLabel?.text = celltxt

        let deleteButton = MGSwipeButton(title: "Delete", backgroundColor: .ht_carrot(), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            if let idx = tableView.indexPath(for: sender) {
                self.predicates.remove(at: idx.row)
                tableView.deleteRows(at: [idx], with: UITableViewRowAnimation.right)
                return false
            }
            return true
        })
        deleteButton.titleLabel?.font = .boldSystemFont(ofSize: 14)

        cell.rightButtons = [deleteButton]
        cell.leftSwipeSettings.transition = MGSwipeTransition.static
        return cell
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        header.textLabel?.textColor = UIColor.white
    }

    class MCButton : HTPressableButton {

    }
}
