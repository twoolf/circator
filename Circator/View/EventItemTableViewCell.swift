//
//  EventItemTableViewCell.swift
//  Circator
//
//  Created by Edwin L. Whitman on 3/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import Former

class EventItemTableViewCell: UITableViewCell {
    
    lazy var timeLabel : UILabel = {
        let label = UILabel()
        label.text = "time"
        label.textAlignment = .Center
        return label
    }()
    
    lazy var timeView : UIView = {
        let view = UIView()
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.timeLabel as UIView)
        let constraints : [NSLayoutConstraint] = [
            self.timeLabel.topAnchor.constraintEqualToAnchor(view.topAnchor),
            self.timeLabel.leftAnchor.constraintEqualToAnchor(view.leftAnchor),
            self.timeLabel.rightAnchor.constraintEqualToAnchor(view.rightAnchor),
            NSLayoutConstraint(item: self.timeLabel, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 0.333, constant: 0)
        ]
        view.addConstraints(constraints)
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layoutMargins = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureCell(timeToDisplay time : String, eventToDisplay event : UIView) {
        
        self.timeLabel.text = time
        
        /* 
        TODO: configure when hour is written to draw line across cell
        if time != "" {
        }
        */
        
        self.contentView.addSubview(self.timeView)
        self.contentView.addSubview(event)

        let constraints : [NSLayoutConstraint] = [
            self.timeView.topAnchor.constraintEqualToAnchor(self.contentView.topAnchor),
            self.timeView.leftAnchor.constraintEqualToAnchor(self.contentView.leftAnchor),
            self.timeView.bottomAnchor.constraintEqualToAnchor(self.contentView.bottomAnchor),
            NSLayoutConstraint(item: self.timeView, attribute: .Right, relatedBy: .Equal, toItem: self.contentView, attribute: .Right, multiplier: 0.1428571429, constant: 0),
            event.topAnchor.constraintEqualToAnchor(self.contentView.topAnchor),
            event.rightAnchor.constraintEqualToAnchor(self.contentView.rightAnchor),
            event.bottomAnchor.constraintEqualToAnchor(self.contentView.bottomAnchor),
            event.leftAnchor.constraintEqualToAnchor(self.timeView.rightAnchor)
        ]
        
        self.contentView.addConstraints(constraints)
    }
}
