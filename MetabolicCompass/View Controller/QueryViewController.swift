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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Queries"
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentView(withName: "Query",
            contentType: "",
            contentId: Date().string(),
            customAttributes: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.universityDarkTheme.backgroundColor
        tableView.register(MGSwipeTableCell.self, forCellReuseIdentifier: "queryCell")

        let addQueryButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(QueryViewController.addQuery))
        navigationItem.rightBarButtonItem = addQueryButton
    }

    func addQuery() {
        let builder = QueryBuilderViewController()
        builder.buildMode = BuilderMode.Creating
        navigationController?.pushViewController(builder, animated: true)
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QueryManager.sharedManager.getQueries().count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "queryCell", for: indexPath as IndexPath) as! MGSwipeTableCell

        let deleteButton = MGSwipeButton(title: "Delete", backgroundColor: .ht_pomegranate(), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            if let idx = tableView.indexPath(for: sender) {
                QueryManager.sharedManager.removeQuery(index: idx.row)
                tableView.deleteRows(at: [idx], with: UITableViewRowAnimation.right)
                return false
            }
            return true
        })
        deleteButton.titleLabel?.font = .boldSystemFont(ofSize: 14)

        let editButton = MGSwipeButton(title: "Edit", backgroundColor: .ht_carrot(), callback: {
            (sender: MGSwipeTableCell!) -> Bool in
            if let idx = tableView.indexPath(for: sender) {
                switch QueryManager.sharedManager.getQueries()[idx.row].1 {
                case Query.ConjunctiveQuery(_, _, _, _):
                    let builder = QueryBuilderViewController()
                    builder.buildMode = BuilderMode.Editing(idx.row)
                    self.navigationController?.pushViewController(builder, animated: true)
                }
                return false
            }
            return true
        })
        editButton.titleLabel?.font = .boldSystemFont(ofSize: 14)


        cell.rightButtons = [deleteButton, editButton]
        cell.leftSwipeSettings.transition = MGSwipeTransition.static

        if QueryManager.sharedManager.getSelectedQuery() == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.backgroundColor = Theme.universityDarkTheme.backgroundColor
        cell.tintColor = cell.isSelected ? UIColor.ht_belizeHole() : UIColor.ht_sunflower()
        cell.textLabel?.font = .boldSystemFont(ofSize: 14)
        cell.textLabel?.text = QueryManager.sharedManager.getQueries()[indexPath.row].0
        cell.textLabel?.textColor = .white
        return cell
    }

/*    override func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if QueryManager.sharedManager.getSelectedQuery() == IndexPath {
            // Deselect query 
            if let cell = tableView.cellForRow(at: IndexPath) {
                QueryManager.sharedManager.deselectQuery()
                cell.accessoryType = .none
                cell.tintColor = UIColor.ht_sunflower()
            }
        } else {
//            if let oldcell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: QueryManager.sharedManager.getSelectedQuery(), inSection: 0)) {
            if let oldcell = tableView.cellForRow(at: IndexPath(row: QueryManager.sharedManager.getSelectedQuery(), section: 0)) {
                oldcell.accessoryType = .none
                oldcell.tintColor = UIColor.ht_sunflower()
            }

            if let cell = tableView.cellForRow(at: IndexPath) {
                QueryManager.sharedManager.selectQuery(index: IndexPath)
                cell.accessoryType = .checkmark
                cell.tintColor = UIColor.ht_belizeHole()
            }
        }
    } */

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = Theme.universityDarkTheme.backgroundColor
        header.textLabel?.textColor = UIColor.white
    }

}
