//
//  QueryViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/19/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import MetabolicCompassKit
import UIKit
import MGSwipeTableCell
import Crashlytics
import SwiftDate

/**
 This class, along with the Builder and the Writer all together, support queries for filtering displayed metrics on 1st and 2nd dashboard screens.  By the use of these queries we enable users to view their comparisons with individuals sharing similar weights or the same genders.
 
 - note: used in IntroViewController
 */
class QueryViewController: UITableViewController {

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Queries"
        tableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("Query",
            contentType: "",
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor
        tableView.registerClass(MGSwipeTableCell.self, forCellReuseIdentifier: "queryCell")

        let addQueryButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addQuery")
        navigationItem.rightBarButtonItem = addQueryButton
    }

    func addQuery() {
        let builder = QueryBuilderViewController()
        builder.buildMode = BuilderMode.Creating
        navigationController?.pushViewController(builder, animated: true)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QueryManager.sharedManager.getQueries().count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("queryCell", forIndexPath: indexPath) as! MGSwipeTableCell
        
        let deleteButton = MGSwipeButton(title: "Delete", backgroundColor: .ht_pomegranateColor(), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            if let idx = tableView.indexPathForCell(sender) {
                QueryManager.sharedManager.removeQuery(idx.row)
                tableView.deleteRowsAtIndexPaths([idx], withRowAnimation: UITableViewRowAnimation.Right)
                return false
            }
            return true
        })
        deleteButton.titleLabel?.font = .boldSystemFontOfSize(14)

        let editButton = MGSwipeButton(title: "Edit", backgroundColor: .ht_carrotColor(), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            if let idx = tableView.indexPathForCell(sender) {
                switch QueryManager.sharedManager.getQueries()[idx.row].1 {
                case Query.ConjunctiveQuery(_):
                    let builder = QueryBuilderViewController()
                    builder.buildMode = BuilderMode.Editing(idx.row)
                    self.navigationController?.pushViewController(builder, animated: true)

                case Query.UserDefinedQuery(_):
                    let builder = QueryWriterViewController()
                    builder.buildMode = BuilderMode.Editing(idx.row)
                    builder.fromPredicateBuilder = false
                    self.navigationController?.pushViewController(builder, animated: true)
                }
                return false
            }
            return true
        })
        editButton.titleLabel?.font = .boldSystemFontOfSize(14)

        
        cell.rightButtons = [deleteButton, editButton]
        cell.leftSwipeSettings.transition = MGSwipeTransition.Static

        if QueryManager.sharedManager.getSelectedQuery() == indexPath.row {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        cell.backgroundColor = Theme.universityDarkTheme.backgroundColor
        cell.tintColor = cell.selected ? UIColor.ht_belizeHoleColor() : UIColor.ht_sunflowerColor()
        cell.textLabel?.font = .boldSystemFontOfSize(14)
        cell.textLabel?.text = QueryManager.sharedManager.getQueries()[indexPath.row].0
        cell.textLabel?.textColor = .whiteColor()
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if QueryManager.sharedManager.getSelectedQuery() == indexPath.row {
            // Deselect query
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                QueryManager.sharedManager.deselectQuery()
                cell.accessoryType = .None
                cell.tintColor = UIColor.ht_sunflowerColor()
            }
        } else {
            if let oldcell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: QueryManager.sharedManager.getSelectedQuery(), inSection: 0)) {
                oldcell.accessoryType = .None
                oldcell.tintColor = UIColor.ht_sunflowerColor()
            }

            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                QueryManager.sharedManager.selectQuery(indexPath.row)
                cell.accessoryType = .Checkmark
                cell.tintColor = UIColor.ht_belizeHoleColor()
            }
        }
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        header.textLabel?.textColor = UIColor.whiteColor()
    }

}
