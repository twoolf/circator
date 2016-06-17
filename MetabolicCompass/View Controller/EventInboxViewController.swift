//
//  EventInboxViewController.swift
//  MetabolicCompass
//
//  Created by Edwin L. Whitman on 5/24/16.
//  Copyright © 2016 Edwin L. Whitman, Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import SwiftDate

enum InboxItemType {
    
    case Event
    case Notfication
    var controls : [UIControl] {
        switch self {
        case Event:
            return [UIControl()]
        case Notfication:
            return [UIControl()]
        }
    }
}

protocol InboxItemData {
    
    // date is formatted as "dd-mm-YYYY" like 27-09-1991 as September 27, 1991 for inbox view
    var receiptDate : NSDate { get }
    var inboxItemType : InboxItemType { get }
    var itemContentView : UIView { get set }
    init(receiptDate date : NSDate, inboxItemType type : InboxItemType)

    
}

class InboxItem : UITableViewCell {
    
    var receiptDate : NSDate!
    var itemData : InboxItemData!

    
    init(receiptDate date : NSDate, itemData data : InboxItemData) {
        
        super.init(style: .Default, reuseIdentifier: "InboxItemTableViewCell")

        self.itemData = data
        self.receiptDate = self.itemData.receiptDate
        
        
        let controlView : UIStackView = {
            let stackView = UIStackView(arrangedSubviews: self.itemData.inboxItemType.controls)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            //TODO
            //axis
            //distribution
            //centered
            //OTHER CODE TODO
            
            return stackView
            
        }()
        
        self.contentView.addSubview(controlView)
        
        let controlViewConstraints : [NSLayoutConstraint] = [
            controlView.topAnchor.constraintEqualToAnchor(self.contentView.topAnchor, constant: 8),
            controlView.rightAnchor.constraintEqualToAnchor(self.contentView.rightAnchor, constant: -16),
            controlView.bottomAnchor.constraintEqualToAnchor(self.contentView.bottomAnchor, constant: -8),
            controlView.widthAnchor.constraintEqualToAnchor(self.contentView.widthAnchor, multiplier: 0.33)
        ]
        
        self.contentView.addConstraints(controlViewConstraints)
        
        self.itemData.itemContentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.itemData.itemContentView)
        
        let itemContentsConstraints : [NSLayoutConstraint] = [
            self.itemData.itemContentView.topAnchor.constraintEqualToAnchor(self.contentView.topAnchor, constant: 8),
            self.itemData.itemContentView.leftAnchor.constraintEqualToAnchor(self.contentView.leftAnchor, constant: 16),
            self.itemData.itemContentView.bottomAnchor.constraintEqualToAnchor(self.contentView.bottomAnchor, constant: -8),
            self.itemData.itemContentView.rightAnchor.constraintEqualToAnchor(controlView.leftAnchor, constant: -16)
        ]
        
        self.contentView.addConstraints(itemContentsConstraints)
        
        
        
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
    
    func fetchRepeatedEvents() -> [InboxItem] {
        
        
        if self.lastUpdated == nil {
            self.lastUpdated = NSDate()
        }
        
        self.loadEventsSinceUpdated()
        
        return self.items
        
        
    }
    

    
    func loadEventsSinceUpdated() {
        
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
                
                let weekday = Weekday(rawValue: 1)!
                
                print(components)
                
                //TODO
                //is componenents.seconds the same thing as number of second elapsed since midnight of that day??
                //let event = RepeatedEventsOrganizer.shared.getEventAtTimeDuringWeek(dayOfWeek: weekday, timeOfDayOffset: NSTimeInterval(components.second))
                
                /* go over events for single weekday  and append them to the inbox manager */
                
                /*
                if event != nil {
                    
                    
                    //let inboxItem = EventInboxItem(receiptDate: NSDate(), itemData: event!)
                    
                    //self.items.append(inboxItem)
                    
                */
                
                /* updates counter of minutes then until now, eventually decrementing to zero */
                
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
        
        
        
        let events = inbox.fetchRepeatedEvents()
        
        
        
        
        
    }
    
    func reloadData() {
        
    }
    
}



