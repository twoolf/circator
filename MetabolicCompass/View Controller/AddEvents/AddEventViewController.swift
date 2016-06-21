//
//  AddEventViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Async

enum EventType: Int {
    case Meal
    case Exercise
    case Sleep
}

class AddEventViewController: UIViewController, AddEventModelDelegate {

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
        
        self.navigationController!.navigationBar.barStyle = .Black
        self.navigationItem.rightBarButtonItem = rightButton
        self.navigationItem.leftBarButtonItem = leftButton
        
        registerCells()
        
        switch type {
            case .Exercise:
                addEventModel.datePickerTags = [1]
                addEventModel.countDownPickerTags = [2,3]
                tableDataSource.dataSourceCells = [whenCellIdentifier, durationCellIdentifier]//set base cells
                eventImage.image = UIImage(named: "add-exercises-big-image")!
                self.navigationItem.title = "ADD EXERCISE TIME"
            case .Sleep:
                sleepTimeLabel.hidden = false
                addEventModel.delegate = self
                addEventModel.datePickerTags = [1, 2, 3]
                addEventModel.countDownPickerTags = []
                tableDataSource.sleepMode = true
                tableDataSource.dataSourceCells = [startSleepCellIdentifier, endSleepCellIdentifier]//set base cells
                eventImage.image = UIImage(named: "add-sleep-big-image")!
                self.navigationItem.title = "ADD SLEEP TIME"
                sleepTimeLabel.attributedText = addEventModel.getSleepTimeString()
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
        
        let startSleppCellNib = UINib(nibName: "StartSleepTableViewCell", bundle: nil)
        self.tableVIew.registerNib(startSleppCellNib, forCellReuseIdentifier: startSleepCellIdentifier)
        
        let endSleepCellNib = UINib(nibName: "EndSleepTableViewCell", bundle: nil)
        self.tableVIew.registerNib(endSleepCellNib, forCellReuseIdentifier: endSleepCellIdentifier)
    }
    
    func closeAction () {
        switch type {
            case .Meal:
                if addEventModel.mealType != MealType.Empty {
                    showConfirmAlert()
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            default:
                if addEventModel.dataWasChanged {
                    showConfirmAlert()
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
        }
    }
    
    func showConfirmAlert (){
        let alertController = UIAlertController(title: "", message: "Are you sure you wish to leave without saving?", preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "YES", style: .Default, handler: { (alert) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "NO", style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func doneAction () {
        switch type {
            case .Meal:
                addEventModel.saveMealEvent({ (success, errorMessage) in
                    Async.main {
                        guard success else {
                            self.showValidationAlert(errorMessage!)
                            return
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                })
            case .Exercise:
                addEventModel.saveExerciseEvent({ (success, errorMessage) in
                    Async.main{
                        guard success else {
                            self.showValidationAlert(errorMessage!)
                            return
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                })
            case .Sleep:
                addEventModel.saveSleepEvent({ (success, errorMessage) in
                    Async.main {
                        guard success else {
                            self.showValidationAlert(errorMessage!)
                            return
                        }
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                })
        }
    }
    
    //MARK: Validation alerts
    
    func showValidationAlert(message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: AddEventModelDelegate
    
    func sleepTimeUpdated(updatedTime: NSAttributedString) {
        sleepTimeLabel.attributedText = updatedTime
    }
}
