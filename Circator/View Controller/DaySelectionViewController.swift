//
//  DaySelectionViewController.swift
//  Circator
//
//  Created by Sihao Lu on 2/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class DaySelectionViewController: UIViewController {
    
    var selectedIndices: Set<Int> = []
    
    var selectionUpdateHandler: ((Set<Int>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        //navigationItem.title = "Days"
        //tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
        selectionUpdateHandler?(selectedIndices)
    }
    
    private func configureView() {
        

        
        
        //navigationController?.setNavigationBarHidden(false, animated: false)
        let navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, 44))
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        //navigationBar.delegate =
        
        let navigationItems = UINavigationItem()
        
        let left = UIBarButtonItem(title: "back", style: .Plain, target: self, action: "back:")
        
        
        navigationItems.title = "Frequency"
        navigationItems.leftBarButtonItem = left
        
        navigationBar.items = [navigationItems]
        
        view.addSubview(navigationBar)
        
        let navigationBarConstraints : [NSLayoutConstraint] = [
            
            //NSLayoutConstraint(item: navigationBar, attribute: .Top, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: UIApplication.sharedApplication().statusBarFrame.size.height),
            navigationBar.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            navigationBar.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            navigationBar.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(navigationBarConstraints)
        
        let table = DaySelection(SelectedIndices: self.selectedIndices, SelectionUpdateHandler: self.selectionUpdateHandler)
        let tableView = table.view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addChildViewController(table)
        view.addSubview(tableView)
        
        let tableViewConstraints : [NSLayoutConstraint] = [
            tableView.topAnchor.constraintEqualToAnchor(navigationBar.bottomAnchor),
            tableView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            tableView.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            tableView.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        ]
        
        view.addConstraints(tableViewConstraints)
        
        //tableView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor)
    }
    
    func back(sender: UIBarItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    class DaySelection: UITableViewController {
        
        var selectedIndices: Set<Int> = []
        
        var selectionUpdateHandler: ((Set<Int>) -> Void)?
        
        convenience init(SelectedIndices selectedIndices: Set<Int>, SelectionUpdateHandler selectionUpdateHandler: ((Set<Int>) -> Void)?) {
            self.init()
            self.selectedIndices = selectedIndices
            self.selectionUpdateHandler = selectionUpdateHandler
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.title = "Days"
            tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "dayCell")
            selectionUpdateHandler?(selectedIndices)
            self.tableView.scrollEnabled = false
        }
        
        // MARK: - Table View Formatting
        
        func format() {
            
            tableView.scrollEnabled = false
        }
        
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return 44.0
        }
        
        override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 22.0
        }
        
        override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return view.bounds.height - UIApplication.sharedApplication().statusBarFrame.size.height - 44.0*7
            
        }
        
        
        // MARK: - Table view data source
        
        private static let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 1
        }
        
        override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 7
        }
        
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("dayCell", forIndexPath: indexPath)
            cell.textLabel?.text = self.dynamicType.dayNames[indexPath.row]
            cell.accessoryType = selectedIndices.contains(indexPath.row) ? .Checkmark : .None
            return cell
        }
        
        override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            if selectedIndices.contains(indexPath.row) {
                selectedIndices.remove(indexPath.row)
            } else {
                selectedIndices.insert(indexPath.row)
            }
            cell.accessoryType = selectedIndices.contains(indexPath.row) ? .Checkmark : .None
            selectionUpdateHandler?(selectedIndices)
        }
    }

}
    
