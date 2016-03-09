//
//  QueryWriterViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import MetabolicCompassKit
import UIKit
import Former
import Crashlytics
import SwiftDate

/**
 This class supports the store of queries (saveQuery) for filtering displayed metrics on 1st and 2nd dashboard screens. This lets users tune the display to their desired comparison metric.
 
 - note: used in QueryViewController and QueryBuilderViewController
 */
class QueryWriterViewController : FormViewController {
    var query : String = ""
    var queryName : String = ""

    var buildMode : BuilderMode! = nil
    var fromPredicateBuilder : Bool = true
    
    var queryBodyRow : TextViewRowFormer<FormTextViewCell>! = nil
    var attrPicker : SelectorPickerRowFormer<FormSelectorPickerCell, Any>! = nil

    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Query Writer"
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("QueryWriter",
            contentType: "",
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch buildMode! {
        case .Creating:
            self.queryName = "Query \(String(QueryManager.sharedManager.getQueries().count))"
            self.query = ""

        case .Editing(let row):
            self.queryName = QueryManager.sharedManager.getQueries()[row].0
            switch QueryManager.sharedManager.getQueries()[row].1 {
            case .ConjunctiveQuery(_):
                self.query = ""
            case .UserDefinedQuery(let s):
                self.query = s
            }
        }

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        let queryDoneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "saveQuery")
        navigationItem.rightBarButtonItem = queryDoneButton

        queryBodyRow = TextViewRowFormer<FormTextViewCell>() {
            $0.backgroundColor = Theme.universityDarkTheme.backgroundColor
            $0.titleLabel.text = "Value"
            $0.titleLabel.textColor = .whiteColor()
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.textView.textColor = .whiteColor()
            $0.textView.font = .boldSystemFontOfSize(14)
            $0.textView.contentInset = UIEdgeInsetsMake(3,0,0,0)
            $0.tintColor = .blueColor()
            }.configure {
                let attrs = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                             NSFontAttributeName : UIFont.systemFontOfSize(14)]
                $0.attributedPlaceholder = NSAttributedString(string:"Enter query", attributes: attrs)
                $0.text = query
                $0.rowHeight = 250
            }.onTextChanged { [weak self] txt in
                self?.query = txt
        }
        
        attrPicker = SelectorPickerRowFormer<FormSelectorPickerCell, Any> {
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
                $0.attributedPlaceholder = NSAttributedString(string:self.queryName, attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
            }.onTextChanged { [weak self] txt in
                self?.queryName = txt
        }

        let section = SectionFormer(rowFormer: queryBodyRow, attrPicker, queryNameRow)
        former.append(sectionFormer: section)
    }
    
    func donePicker() {
        let attr = attrPicker.pickerItems[attrPicker.selectedRow].title
        if queryBodyRow.text == nil {
            queryBodyRow.text = ""
        }
        let withSpace = queryBodyRow.text!.characters.count == 0 ? false
                            : ( queryBodyRow.text![queryBodyRow.text!.endIndex.predecessor()] != " " )
        queryBodyRow.text? += ( withSpace ? " " : "" ) + attr + " "
        queryBodyRow.update()

        query = queryBodyRow.text!
        
        self.view.endEditing(true)
        queryBodyRow.cell.textView.becomeFirstResponder()
    }
    
    func saveQuery() {
        switch buildMode! {
        case .Creating:
            QueryManager.sharedManager.addQuery(self.queryName, query: Query.UserDefinedQuery(self.query))
            
        case .Editing(let row):
            QueryManager.sharedManager.updateQuery(row, name: self.queryName, query: Query.UserDefinedQuery(self.query))
        }

        let numvc = self.navigationController?.viewControllers.count
        if let n = numvc,
               idx = Optional(fromPredicateBuilder ? (n >= 3 ? 3 : 2) : 2),
               vc = self.navigationController?.viewControllers[n - idx]
        {
            self.navigationController?.popToViewController(vc, animated: true)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
}
