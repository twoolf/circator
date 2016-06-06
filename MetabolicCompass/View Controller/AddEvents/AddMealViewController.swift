//
//  AddMealViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

public let typeCellIdentifier = "typeCellIdentifier"
public let whenCellIdentifier = "whenCellIdentifier"
public let durationCellIdentifier = "durationCellIdentifier"

class AddMealViewController: UIViewController {

    @IBOutlet weak var tableVIew: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ADD MEAL TIME"
        
        let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .Plain, target: self, action: #selector(closeAction))
        let rightButton = UIBarButtonItem(image: UIImage(named: "appruve-check-icon"), style: .Plain, target: self, action: #selector(doneAction))
        
        self.navigationItem.rightBarButtonItem = rightButton
        self.navigationItem.leftBarButtonItem = leftButton
        
        let typeCellNib = UINib(nibName: "TypeTableViewCell", bundle: nil)
        self.tableVIew.registerNib(typeCellNib, forCellReuseIdentifier: typeCellIdentifier)
        
        let whenCellNib = UINib(nibName: "WhenTableViewCell", bundle: nil)
        self.tableVIew.registerNib(whenCellNib, forCellReuseIdentifier: whenCellIdentifier)
        
        let durationCellNib = UINib(nibName: "DurationTableViewCell", bundle: nil)
        self.tableVIew.registerNib(durationCellNib, forCellReuseIdentifier: durationCellIdentifier)
    }
    
    func closeAction () {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func doneAction () {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
