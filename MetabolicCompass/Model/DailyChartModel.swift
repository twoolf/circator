//
//  DailyChartModel.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 5/16/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit

class DailyChartModel : NSObject, UITableViewDataSource {
    
    private let dayCellIdentifier = "dayCellIdentifier"
    var daysTableView: UITableView?
    var daysArray: [String] = {
        var lastSevenDays: [String] = []
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM\ndd"
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let dateComponents = calendar.components([.Day, .Month] , fromDate: NSDate())
        for _ in 0...6 {
            let date = calendar.dateFromComponents(dateComponents)
            dateComponents.day -= 1;
            if let date = date {
                let dateString = formatter.stringFromDate(date)
                lastSevenDays.append(dateString.stringByAppendingString(" th"))
            }
        }
        return lastSevenDays
    }()
    
    func updateRowHeight (){
        self.daysTableView?.rowHeight = CGRectGetHeight(self.daysTableView!.frame)/7.0
        self.daysTableView?.reloadData()
    }
    
    func registerCells() {
        let dayCellNib = UINib(nibName: "DailyProgressDayTableViewCell", bundle: nil)
        self.daysTableView?.registerNib(dayCellNib, forCellReuseIdentifier: dayCellIdentifier)
    }
    
    //MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.daysArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(dayCellIdentifier) as! DailyProgressDayTableViewCell
        cell.dayLabel.text = self.daysArray[indexPath.row]
        cell.dayLabel.textColor = indexPath.row == 0 ? UIColor.colorWithHexString("#ffffff", alpha: 1) : UIColor.colorWithHexString("#ffffff", alpha: 0.3)
        return cell
    }
    
}