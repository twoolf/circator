//
//  DefaultEventPeriodSelectorViewController.swift
//  Circator
//
//  Created by Edwin L. Whitman on 2/26/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import CircatorKit
import UIKit
import Async
import Former
import HTPressableButton
import Crashlytics
import SwiftDate

//minutes of hour when user awakens and goes to sleep
let wakeMinute = 0
let sleepMinute = 0

//hour of day when user awakens and goes to sleep
let wakeHour = 8
let sleepHour = 22


//specific date for time when user awakens and goes to sleep
let wakeTime = (wakeHour.hours + wakeMinute.minutes).fromDate(today())
let sleepTime = (sleepHour.hours + sleepMinute.minutes).fromDate(today())

//offset hours and minutes of lunch and dinner start times, note: breakfast is just awake to lunch
let lunchOffsetMinute = 0
let dinnerOffsetMinute = 0

let lunchOffsetHour = 11
let dinnerOffsetHour = 18

class DefaultEventPeriodSelectorViewController : UIViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = "Defaults"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}