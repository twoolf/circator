//
//  EventItemView.swift
//  Circator
//
//  Created by Edwin L. Whitman on 3/13/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//


import UIKit
import Former

class EventItemView: UIButton {
    
    var event : Event?

    init(Event event : Event, frame: CGRect = CGRectZero) {
        
        super.init(frame : frame)
        self.event = event
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
