//
//  AddMealViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

enum EventType: Int {
    case Meal
    case Exercise
    case Sleep
}

class AddMealViewController: UIViewController {

    @IBOutlet weak var tableVIew: UITableView!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var sleepTimeLabel: UILabel!
    
    var type:EventType = .Meal
    let tableDataSource = AddMealDataSource()
    let addEventModel = AddEventModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .Plain, target: self, action: #selector(closeAction))
        let rightButton = UIBarButtonItem(image: UIImage(named: "appruve-check-icon"), style: .Plain, target: self, action: #selector(doneAction))
        
        self.navigationItem.rightBarButtonItem = rightButton
        self.navigationItem.leftBarButtonItem = leftButton
        
        registerCells()
        
        switch type {
            case .Exercise:
                addEventModel.datePickerTags = [1]
                addEventModel.countDownPickerTags = [2]
                tableDataSource.dataSourceCells = [whenCellIdentifier, durationCellIdentifier]//set base cells
                eventImage.image = UIImage(named: "add-exercises-big-image")!
                self.navigationItem.title = "ADD EXERCISE TIME"
            case .Sleep:
                addEventModel.datePickerTags = [1, 2]
                addEventModel.countDownPickerTags = []
                tableDataSource.dataSourceCells = [whenCellIdentifier, whenCellIdentifier]//set base cells
                eventImage.image = UIImage(named: "add-sleep-big-image")!
                self.navigationItem.title = "ADD SLEEP TIME"
            default:
                self.navigationItem.title = "ADD MEAL TIME"
        }
        
        tableDataSource.addEventModel = addEventModel
        
        self.tableVIew.dataSource = tableDataSource
        self.tableVIew.delegate = tableDataSource
    }
    
    
    func registerCells () {
        let typeCellNib = UINib(nibName: "TypeTableViewCell", bundle: nil)
        self.tableVIew.registerNib(typeCellNib, forCellReuseIdentifier: typeCellIdentifier)
        
        let whenCellNib = UINib(nibName: "WhenTableViewCell", bundle: nil)
        self.tableVIew.registerNib(whenCellNib, forCellReuseIdentifier: whenCellIdentifier)
        
        let durationCellNib = UINib(nibName: "DurationTableViewCell", bundle: nil)
        self.tableVIew.registerNib(durationCellNib, forCellReuseIdentifier: durationCellIdentifier)
        
        let pickerCellNib = UINib(nibName: "PickerTableViewCell", bundle: nil)
        self.tableVIew.registerNib(pickerCellNib, forCellReuseIdentifier: pickerCellIdentifier)
        
        let datePickerCellNib = UINib(nibName: "DatePickerTableViewCell", bundle: nil)
        self.tableVIew.registerNib(datePickerCellNib, forCellReuseIdentifier: datePickerCellIdentifier)
    }
    
    func closeAction () {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func doneAction () {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
