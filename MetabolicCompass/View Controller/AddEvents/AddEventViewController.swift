//
//  AddEventViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.      
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Async
import MCCircadianQueries

enum EventType: Int {
    case Meal
    case Exercise
    case Sleep
}

public class AddEventViewController: UIViewController, AddEventModelDelegate {

    @IBOutlet weak var tableVIew: UITableView!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var sleepTimeLabel: UILabel!
    
    var type:EventType = .Meal
    let tableDataSource = AddMealDataSource()
    let addEventModel = AddEventModel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        let leftButton = UIBarButtonItem(image: UIImage(named: "close-button"), style: .plain, target: self, action: #selector(closeAction))
        let rightButton = UIBarButtonItem(image: UIImage(named: "appruve-check-icon"), style: .plain, target: self, action: #selector(doneAction))
        
        self.navigationController!.navigationBar.barStyle = .black
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
                sleepTimeLabel.isHidden = false
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
        self.tableVIew.register(typeCellNib, forCellReuseIdentifier: typeCellIdentifier)
        
        let whenCellNib = UINib(nibName: "WhenTableViewCell", bundle: nil)
        self.tableVIew.register(whenCellNib, forCellReuseIdentifier: whenCellIdentifier)
        
        let durationCellNib = UINib(nibName: "DurationTableViewCell", bundle: nil)
        self.tableVIew.register(durationCellNib, forCellReuseIdentifier: durationCellIdentifier)
        
        let pickerCellNib = UINib(nibName: "PickerTableViewCell", bundle: nil)
        self.tableVIew.register(pickerCellNib, forCellReuseIdentifier: pickerCellIdentifier)
        
        let datePickerCellNib = UINib(nibName: "DatePickerTableViewCell", bundle: nil)
        self.tableVIew.register(datePickerCellNib, forCellReuseIdentifier: datePickerCellIdentifier)
        
        let startSleppCellNib = UINib(nibName: "StartSleepTableViewCell", bundle: nil)
        self.tableVIew.register(startSleppCellNib, forCellReuseIdentifier: startSleepCellIdentifier)
        
        let endSleepCellNib = UINib(nibName: "EndSleepTableViewCell", bundle: nil)
        self.tableVIew.register(endSleepCellNib, forCellReuseIdentifier: endSleepCellIdentifier)
    }
    
    public func closeAction () {
        switch type {
            case .Meal:
                if addEventModel.mealType != MealType.Empty {
                    showConfirmAlert()
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            default:
                if addEventModel.dataWasChanged {
                    showConfirmAlert()
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
        }
    }
    
    func showConfirmAlert (){
        let alertController = UIAlertController(title: "", message: "Are you sure you wish to leave without saving?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "YES", style: .default, handler: { (alert) in
            self.dismiss(animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "NO", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func doneAction () {
        switch type {
            case .Meal:
                addEventModel.saveMealEvent(completion: { (success, errorMessage) in
//                    Async.main {
                    OperationQueue.main.addOperation {
                        guard success else {
                            self.showValidationAlert(message: errorMessage!)
                            return
                        }
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            case .Exercise:
                addEventModel.saveExerciseEvent(completion: { (success, errorMessage) in
 //                   Async.main{
                    OperationQueue.main.addOperation {
                        guard success else {
                            self.showValidationAlert(message: errorMessage!)
                            return
                        }
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            case .Sleep:
                addEventModel.saveSleepEvent(completion: { (success, errorMessage) in
//                    Async.main {
                    OperationQueue.main.addOperation {
                        guard success else {
                            self.showValidationAlert(message: errorMessage!)
                            return
                        }
                        self.dismiss(animated: true, completion: nil)
                    }
                })
        }
    }
    
    //MARK: Validation alerts
    
    func showValidationAlert(message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: AddEventModelDelegate
    
    func sleepTimeUpdated(_ updatedTime: NSAttributedString) {
        sleepTimeLabel.attributedText = updatedTime
    }
}
//}
