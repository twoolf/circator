//
//  EventPickerManager.swift
//  Circator
//
//  Created by Sihao Lu on 2/21/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

/**
 With this class we support the different picker menus that are present at various points in the App. Changes here can be used to support different formats for the picker wheels or different increments in time. The current choices seem to be validated by our initial beta users.
 
 - note: could be easily extended to support other metrics for data entry
 */
class EventPickerManager: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    enum Event {
        case Meal
        case Sleep
        case Exercise
    }
    
    let event: Event
    
    lazy var pickerView: UIPickerView = {
        let view = UIPickerView()
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    init(event: Event) {
        self.event = event
        super.init()
    }
    
    static let previewMealTypeStrings = [
        ["Bkfast", "Lunch", "Dinner", "Snack"],
        ["05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
            "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
            "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
            "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
            "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00", "00:30",
            "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30"],
        ["15 Min", "30 Min", "45 Min", "60 Min", "90 Min", "120 Min", "150 Min", "180 Min", "210 Min", "240 Min"]]
    
    static let sleepEndpointTypeStrings = [
        ["21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00", "00:30",
            "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30",
            "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
            "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
            "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
            "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30"],
        ["05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
            "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
            "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
            "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
            "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00", "00:30",
            "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30"]]
    
    static let exerciseEndpointTypeStrings = [
        ["21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00", "00:30",
            "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30",
            "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
            "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
            "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
            "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30"],
        ["05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
            "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
            "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
            "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
            "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00", "00:30",
            "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30"]]
    
    static let durationTypeStrings = [
        ["05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
            "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30",
            "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30",
            "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
            "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "00:00", "00:30",
            "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30"],
        ["0 Hr",  "1 Hr",  "2 Hr",  "3 Hr",  "4 Hr",  "5 Hr",  "6 Hr",  "7 Hr",  "8 Hr",  "9 Hr",  "10 Hr", "11 Hr",
            "12 Hr", "13 Hr", "14 Hr", "15 Hr", "16 Hr", "17 Hr", "18 Hr", "19 Hr", "20 Hr", "21 Hr", "22 Hr", "23 Hr"],
        ["0 Min", "5 Min", "10 Min", "15 Min", "20 Min", "25 Min", "30 Min", "35 Min", "40 Min", "45 Min", "50 Min", "55 Min"]]
    
    // MARK: - Picker view data source
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        switch event {
        case .Sleep:
            return EventPickerManager.sleepEndpointTypeStrings.count
        case .Meal:
            return EventPickerManager.previewMealTypeStrings.count
        case .Exercise:
            return EventPickerManager.durationTypeStrings.count
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch event {
        case .Sleep:
            if component >= EventPickerManager.sleepEndpointTypeStrings.count {
                log.info("Invalid PV NRC \(pickerView.numberOfComponents) \(component)")
                return 0
            }
            return EventPickerManager.sleepEndpointTypeStrings[component].count
        case .Meal:
            return EventPickerManager.previewMealTypeStrings[component].count
        case .Exercise:
            if component >= EventPickerManager.durationTypeStrings.count {
                log.info("Invalid PV NRC \(pickerView.numberOfComponents) \(component)")
                return 0
            }
            return EventPickerManager.durationTypeStrings[component].count
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch event {
        case .Sleep:
            if component >= EventPickerManager.sleepEndpointTypeStrings.count {
                log.info("Invalid PVRow \(pickerView.numberOfComponents) \(component)")
                return nil
            }
            return EventPickerManager.sleepEndpointTypeStrings[component][row]
        case .Exercise:
            if component >= EventPickerManager.durationTypeStrings.count {
                log.info("Invalid PVRow \(pickerView.numberOfComponents) \(component)")
                return nil
            }
            return EventPickerManager.durationTypeStrings[component][row]
        case .Meal:
            return EventPickerManager.previewMealTypeStrings[component][row]
        }
    }
}
