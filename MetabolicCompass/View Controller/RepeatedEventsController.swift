//
//  RepeatedEventsController.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 2/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Former

/**
 Supports events that repeat: structued by days/times for meals, exercise, sleep
 
 - note: data structure assumes events repeat unless overridden
 - remark: supported as a set of menu picker and check-marked fields
 */
class RepeatedEventsController: UITableViewController, UITextFieldDelegate {
    
    class SegmentedCell: UITableViewCell {
        
        typealias SegmentedControlBlock = (UISegmentedControl) -> Void
        
        var segmentedControl: UISegmentedControl!
        
        var segmentSelectedHandler: SegmentedControlBlock?
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setup()
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setup()
        }
        
        private func setup() {
            selectionStyle = .None
        }
        
        func configureSegmentControlWithItems(items: [String], customizations: SegmentedControlBlock? = nil) {
            segmentedControl = UISegmentedControl(items: items)
            segmentedControl.addTarget(self, action: "segmentSelected:", forControlEvents: .ValueChanged)
            customizations?(segmentedControl)
            accessoryView = segmentedControl
        }
        
        func segmentSelected(sender: UISegmentedControl) {
            segmentSelectedHandler?(sender)
        }
    }
    
    private let titles = ["Event Type", "Name", "Days", "Time"]
    private static let dayNames = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    
    private var selectedEvent: EventPickerManager.Event = .Meal
    private var selectedDays: Set<Int> = []
    
    private var eventManager: EventPickerManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Repeated Events"
        tableView.registerClass(SegmentedCell.self, forCellReuseIdentifier: "segmentedCell")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return titles.count
        case 1:
            return 0
        default:
            return 0
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                // Event type
                let cell = tableView.dequeueReusableCellWithIdentifier("segmentedCell", forIndexPath: indexPath) as! SegmentedCell
                cell.textLabel?.text = titles[indexPath.row]
                cell.configureSegmentControlWithItems(["Meal", "Sleep", "Exercise"]) {
                    $0.selectedSegmentIndex = 0
                }
                cell.segmentSelectedHandler = { [unowned self] sender in
                    let index = sender.selectedSegmentIndex
                    switch index {
                    case 0:
                        self.selectedEvent = .Meal
                    case 1:
                        self.selectedEvent = .Sleep
                    case 2:
                        self.selectedEvent = .Exercise
                    default:
                        break
                    }
                }
                return cell
            case 1:
                var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("nameCell")
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: "nameCell")
                }
                cell.accessoryView = {
                    let textField = UITextField(frame: CGRectMake(0, 0, 200, 40))
                    textField.delegate = self
                    textField.textAlignment = .Right
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    textField.placeholder = "Enter the name of event"
                    return textField
                }()
                cell.selectionStyle = .None
                cell.textLabel?.text = "Name"
                return cell
            case 2:
                var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("nextLevelCell")
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: "nextLevelCell")
                }
                cell.textLabel?.text = titles[indexPath.row]
                cell.accessoryType = .DisclosureIndicator
                cell.detailTextLabel?.text = selectedDays.sort().map { self.dynamicType.dayNames[$0] }.joinWithSeparator(", ")
                return cell
            case 3:
                var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("timePickerCell")
                if cell == nil {
                    cell = UITableViewCell(style: .Default, reuseIdentifier: "timePickerCell")
                }
                cell.accessoryView = {
                    let textField = UITextField(frame: CGRectMake(0, 0, 0, 0))
                    textField.textAlignment = .Right
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    return textField
                }()
                cell.textLabel?.text = "Time"
                return cell
            default:
                break
            }
            
        }
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if indexPath.section == 0 {
            switch indexPath.row {
            case 2:
                let daySelectionVC = DaySelectionViewController()
                daySelectionVC.selectedIndices = selectedDays
                daySelectionVC.selectionUpdateHandler = { [unowned self] days in
                    self.selectedDays = days
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .None)
                }
                navigationController?.pushViewController(daySelectionVC, animated: true)
            case 3:
                let textField = cell.accessoryView as! UITextField
                eventManager = EventPickerManager(event: selectedEvent)
                textField.inputView = eventManager.pickerView
                textField.becomeFirstResponder()
            default:
                break
            }
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Text field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
