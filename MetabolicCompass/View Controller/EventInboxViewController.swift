//
//  EventInboxViewController.swift
//  MetabolicCompass
//
//  Created by Edwin L. Whitman on 5/24/16.
//  Copyright © 2016 Edwin L. Whitman, Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import SwiftDate

protocol InboxItemData {
    
}

class InboxItem : UITableViewCell {
    
    var receiptDate : NSDate?
    var itemData : InboxItemData?
    
    init(receiptDate date : NSDate, itemData data : InboxItemData) {
        super.init(style: .Default, reuseIdentifier: "InboxItemTableViewCell")
        
        self.receiptDate = date
        self.itemData = data
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
}

class EventInboxItem : InboxItem {
    
}

/*
class NotificationInboxItem : InboxItem {
    //TODO
}
*/


class InboxManager {
    
    static let shared = InboxManager()
    
    var items : [InboxItem] = []
    
    var lastUpdated : NSDate? {
        didSet {
            EventInboxViewController.shared.reloadData()
        }
    }
    
    //var lastCleared : NSDate?
    
    func fetchRepeatedEvents() {
        
        
        if self.lastUpdated == nil {
            self.lastUpdated = NSDate()
        }
        
        self.loadEventsFromLastUpdated()
        
        
        
    }
    

    
    func loadEventsFromLastUpdated() {
        
        let calender = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let components = calender.components(.Minute, fromDate: self.lastUpdated!, toDate: NSDate(), options: .WrapComponents)
        
        let dateFormatter : NSDateFormatter = {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "EEEE mmmm, dd"
            return formatter
        }()
        
        if let then = self.lastUpdated {
            
            if then.components.minute % 15 != 0 {
                let difference = 15 - (then.components.minute % 15)
                then.components.setValue(then.components.minute + difference, forComponent: .Minute)
            }
            
            
            while components.minute > 0 {
                
                //populate inbox item array
                let repeatedEventAtTime = RepeatedEventsOrganizer.shared.getEventAtTimeDuringWeek()
                
                let itemData : InboxItemData? = nil
                
                let inboxItem = EventInboxItem(receiptDate: NSDate(), itemData: itemData!)
                
                self.items.append(inboxItem)
                
                then.components.setValue(then.components.minute + 15, forComponent: .Minute)
                components.setValue(components.minute - 15, forComponent: .Minute)
            }
            
            
        }
        
        //changes date of last update to now
        self.lastUpdated = NSDate()
        
    }

    
}

class EventInboxViewController: UIViewController {
    
    static let shared = EventInboxViewController()
    
    let inbox = InboxManager.shared
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.configure()
    }
    
    private func configure() {
        
        inbox.fetchRepeatedEvents()
    }
    
    func reloadData() {
        
    }
    
}



