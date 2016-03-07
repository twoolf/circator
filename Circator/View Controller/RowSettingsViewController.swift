//
//  RowSettingsViewController.swift
//  Circator
//
//  Created by Sihao Lu on 11/22/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//


import CircatorKit
import UIKit
import Crashlytics
import SwiftDate

/**
 Enables Settings for each Row to be updated.
 
 - note: this is used in SettingsViewController
 */
class RowSettingsViewController: UITableViewController {

    var selectedRow: Int!

    init() {
        super.init(style: UITableViewStyle.Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Answers.logContentViewWithName("RowSettings",
            contentType: String(selectedRow),
            contentId: NSDate().toString(DateFormat.Custom("YYYY-MM-dd:HH:mm:ss")),
            customAttributes: nil)
//        BehaviorMonitor.sharedInstance.showView("RowSettings", contentType: String(selectedRow))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        navigationItem.title = "Preview Row \(selectedRow)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewManager.previewChoices[selectedRow].count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingsCell", forIndexPath: indexPath)
        cell.tintColor = Theme.universityDarkTheme.backgroundColor
        let currentSampleType = PreviewManager.previewChoices[selectedRow][indexPath.row]
        cell.textLabel?.text = currentSampleType.displayText
        if PreviewManager.previewSampleTypes.indexOf(currentSampleType) != nil {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let chosenSampleType = PreviewManager.previewChoices[selectedRow][indexPath.row]
        PreviewManager.reselectSampleType(chosenSampleType, forPreviewRow: selectedRow)
        tableView.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
    }

}
